import Foundation
import CoreLocation
import Combine
import UIKit

enum LocationAuthorizationStatus {
    case notDetermined
    case restricted
    case denied
    case authorizedWhenInUse
    case authorizedAlways
}

enum TrackingState {
    case idle
    case tracking
    case paused
    case autoPaused
}

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    private let locationManager = CLLocationManager()
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    // Published properties for UI binding
    @Published var authorizationStatus: LocationAuthorizationStatus = .notDetermined
    @Published var trackingState: TrackingState = .idle
    @Published var currentLocation: CLLocation?
    @Published var currentSpeed: Double = 0  // m/s
    @Published var currentAltitude: Double = 0  // meters
    @Published var currentHeading: Double = 0
    @Published var totalDistance: Double = 0  // meters
    @Published var elevationGain: Double = 0  // meters
    @Published var elevationLoss: Double = 0  // meters
    @Published var elapsedTime: TimeInterval = 0
    @Published var lastError: Error?

    // Tracking data
    private(set) var recordedLocations: [CLLocation] = []
    private var startTime: Date?
    private var pauseStartTime: Date?
    private var totalPausedTime: TimeInterval = 0
    private var lastValidLocation: CLLocation?
    private var timer: Timer?

    // Auto-pause configuration
    private let autoPauseSpeedThreshold: Double = 0.5  // m/s (about 1 mph)
    private let autoPauseDelay: TimeInterval = 30  // seconds of low speed before auto-pause
    private var lowSpeedStartTime: Date?

    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5  // meters - battery optimization
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .otherNavigation
        updateAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    // MARK: - Tracking Control

    func startTracking() {
        guard trackingState == .idle else { return }

        recordedLocations = []
        totalDistance = 0
        elevationGain = 0
        elevationLoss = 0
        elapsedTime = 0
        totalPausedTime = 0
        lastValidLocation = nil
        lowSpeedStartTime = nil
        startTime = Date()

        trackingState = .tracking
        startBackgroundTask()

        // Enable background location updates only when starting tracking and authorized
        if authorizationStatus == .authorizedAlways {
            enableBackgroundLocationIfAvailable()
        }

        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        startTimer()
    }

    private func enableBackgroundLocationIfAvailable() {
        // Check if background location is available in Info.plist
        guard let backgroundModes = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String],
              backgroundModes.contains("location") else {
            return
        }

        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
    }

    func pauseTracking() {
        guard trackingState == .tracking else { return }
        trackingState = .paused
        pauseStartTime = Date()
        stopTimer()
    }

    func resumeTracking() {
        guard trackingState == .paused || trackingState == .autoPaused else { return }
        if let pauseStart = pauseStartTime {
            totalPausedTime += Date().timeIntervalSince(pauseStart)
        }
        pauseStartTime = nil
        lowSpeedStartTime = nil
        trackingState = .tracking
        startTimer()
    }

    func stopTracking() -> [CLLocation] {
        trackingState = .idle
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()

        // Only disable if background modes are available
        if let backgroundModes = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String],
           backgroundModes.contains("location") {
            locationManager.allowsBackgroundLocationUpdates = false
        }

        stopTimer()
        endBackgroundTask()

        let locations = recordedLocations
        return locations
    }

    // MARK: - Private Methods

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateElapsedTime() {
        guard let start = startTime else { return }
        elapsedTime = Date().timeIntervalSince(start) - totalPausedTime
        if trackingState == .paused || trackingState == .autoPaused,
           let pauseStart = pauseStartTime {
            elapsedTime -= Date().timeIntervalSince(pauseStart)
        }
    }

    private func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }

    private func updateAuthorizationStatus() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .restricted:
            authorizationStatus = .restricted
        case .denied:
            authorizationStatus = .denied
        case .authorizedWhenInUse:
            authorizationStatus = .authorizedWhenInUse
        case .authorizedAlways:
            authorizationStatus = .authorizedAlways
        @unknown default:
            authorizationStatus = .notDetermined
        }
    }

    private func processLocation(_ location: CLLocation) {
        guard trackingState == .tracking else { return }

        // Filter out inaccurate locations
        guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy < 50 else { return }

        currentLocation = location
        currentSpeed = max(0, location.speed)
        currentAltitude = location.altitude

        // Auto-pause logic
        checkAutoPause(speed: currentSpeed)

        // Calculate distance from last location
        if let last = lastValidLocation {
            let distance = location.distance(from: last)
            // Filter noise - reasonable distance change
            if distance > 2 && distance < 100 {
                totalDistance += distance

                // Elevation tracking
                let elevationDelta = location.altitude - last.altitude
                if elevationDelta > 0 {
                    elevationGain += elevationDelta
                } else {
                    elevationLoss += abs(elevationDelta)
                }
            }
        }

        lastValidLocation = location
        recordedLocations.append(location)
    }

    private func checkAutoPause(speed: Double) {
        if speed < autoPauseSpeedThreshold {
            if lowSpeedStartTime == nil {
                lowSpeedStartTime = Date()
            } else if let start = lowSpeedStartTime,
                      Date().timeIntervalSince(start) > autoPauseDelay,
                      trackingState == .tracking {
                // Auto-pause
                trackingState = .autoPaused
                pauseStartTime = Date()
                stopTimer()
            }
        } else {
            lowSpeedStartTime = nil
            if trackingState == .autoPaused {
                // Auto-resume
                resumeTracking()
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateAuthorizationStatus()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.forEach { processLocation($0) }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        currentHeading = newHeading.trueHeading
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastError = error
        print("Location manager error: \(error.localizedDescription)")
    }
}
