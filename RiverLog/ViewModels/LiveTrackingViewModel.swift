import Foundation
import SwiftUI
import CoreLocation
import MapKit
import Combine

class LiveTrackingViewModel: ObservableObject {
    @Published var trackingState: TrackingState = .idle
    @Published var currentSpeed: Double = 0  // mph
    @Published var totalDistance: Double = 0  // miles
    @Published var currentAltitude: Double = 0  // feet
    @Published var elevationGain: Double = 0  // feet
    @Published var elapsedTime: TimeInterval = 0
    @Published var currentHeading: Double = 0
    @Published var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.7392, longitude: -104.9903),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var showAuthorizationAlert = false
    @Published var authorizationStatus: LocationAuthorizationStatus = .notDetermined

    private let locationManager = LocationManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
    }

    private func setupBindings() {
        locationManager.$trackingState
            .receive(on: DispatchQueue.main)
            .assign(to: &$trackingState)

        locationManager.$currentSpeed
            .map { $0 * 2.237 }  // m/s to mph
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentSpeed)

        locationManager.$totalDistance
            .map { $0 / 1609.34 }  // meters to miles
            .receive(on: DispatchQueue.main)
            .assign(to: &$totalDistance)

        locationManager.$currentAltitude
            .map { $0 * 3.281 }  // meters to feet
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentAltitude)

        locationManager.$elevationGain
            .map { $0 * 3.281 }  // meters to feet
            .receive(on: DispatchQueue.main)
            .assign(to: &$elevationGain)

        locationManager.$elapsedTime
            .receive(on: DispatchQueue.main)
            .assign(to: &$elapsedTime)

        locationManager.$currentHeading
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentHeading)

        locationManager.$currentLocation
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.updateMapRegion(for: location)
                self?.routeCoordinates.append(location.coordinate)
            }
            .store(in: &cancellables)

        locationManager.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .assign(to: &$authorizationStatus)
    }

    private func updateMapRegion(for location: CLLocation) {
        mapRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
    }

    // MARK: - Actions

    func checkAuthorization() {
        if authorizationStatus == .notDetermined {
            locationManager.requestAuthorization()
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            showAuthorizationAlert = true
        }
    }

    func startTracking() {
        guard authorizationStatus == .authorizedAlways ||
              authorizationStatus == .authorizedWhenInUse else {
            showAuthorizationAlert = true
            return
        }
        routeCoordinates = []
        locationManager.startTracking()
    }

    func pauseTracking() {
        locationManager.pauseTracking()
    }

    func resumeTracking() {
        locationManager.resumeTracking()
    }

    func stopTracking() -> [CLLocation] {
        return locationManager.stopTracking()
    }

    // MARK: - Formatting

    var formattedSpeed: String {
        String(format: "%.1f mph", currentSpeed)
    }

    var formattedDistance: String {
        String(format: "%.2f mi", totalDistance)
    }

    var formattedAltitude: String {
        String(format: "%.0f ft", currentAltitude)
    }

    var formattedElevationGain: String {
        String(format: "+%.0f ft", elevationGain)
    }

    var formattedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var isTracking: Bool {
        trackingState == .tracking
    }

    var isPaused: Bool {
        trackingState == .paused || trackingState == .autoPaused
    }

    var isAutoPaused: Bool {
        trackingState == .autoPaused
    }
}
