import Foundation
import SwiftUI
import CoreLocation
import MapKit
import CoreData
import Combine

class RoutePlaybackViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var playbackSpeed: Double = 1.0
    @Published var currentIndex: Int = 0
    @Published var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.7392, longitude: -104.9903),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var currentPosition: CLLocationCoordinate2D?
    @Published var currentSpeed: Double = 0
    @Published var currentElevation: Double = 0

    private var gpsPoints: [GPSPoint] = []
    private var playbackTimer: Timer?
    private let gpsDataService = GPSDataService()

    let availableSpeeds: [Double] = [0.5, 1.0, 2.0, 4.0, 8.0]

    var progress: Double {
        guard !gpsPoints.isEmpty else { return 0 }
        return Double(currentIndex) / Double(gpsPoints.count - 1)
    }

    var totalPoints: Int {
        gpsPoints.count
    }

    var startCoordinate: CLLocationCoordinate2D? {
        routeCoordinates.first
    }

    var endCoordinate: CLLocationCoordinate2D? {
        routeCoordinates.last
    }

    var formattedCurrentSpeed: String {
        let mph = currentSpeed * 2.237  // m/s to mph
        return String(format: "%.1f mph", mph)
    }

    var formattedCurrentElevation: String {
        let feet = currentElevation * 3.281  // meters to feet
        return String(format: "%.0f ft", feet)
    }

    var formattedPlaybackSpeed: String {
        if playbackSpeed == 1.0 {
            return "1x"
        } else if playbackSpeed < 1.0 {
            return String(format: "%.1fx", playbackSpeed)
        } else {
            return String(format: "%.0fx", playbackSpeed)
        }
    }

    // MARK: - Load Data

    func loadGPSPoints(for activity: RiverActivity, context: NSManagedObjectContext) {
        gpsPoints = gpsDataService.fetchGPSPoints(for: activity, context: context)
        routeCoordinates = gpsPoints.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }

        if let first = gpsPoints.first {
            currentPosition = CLLocationCoordinate2D(latitude: first.latitude, longitude: first.longitude)
            currentSpeed = first.speed
            currentElevation = first.altitude
        }

        fitMapToRoute()
    }

    func loadFromCoordinates(_ coordinates: [CLLocationCoordinate2D]) {
        routeCoordinates = coordinates
        currentPosition = coordinates.first
        fitMapToRoute()
    }

    // MARK: - Playback Controls

    func play() {
        guard !gpsPoints.isEmpty, currentIndex < gpsPoints.count - 1 else { return }
        isPlaying = true
        startPlaybackTimer()
    }

    func pause() {
        isPlaying = false
        stopPlaybackTimer()
    }

    func stop() {
        isPlaying = false
        stopPlaybackTimer()
        currentIndex = 0
        updateCurrentPosition()
    }

    func seekTo(progress: Double) {
        let index = Int(progress * Double(gpsPoints.count - 1))
        currentIndex = max(0, min(index, gpsPoints.count - 1))
        updateCurrentPosition()
    }

    func cyclePlaybackSpeed() {
        guard let currentSpeedIndex = availableSpeeds.firstIndex(of: playbackSpeed) else {
            playbackSpeed = 1.0
            return
        }

        let nextIndex = (currentSpeedIndex + 1) % availableSpeeds.count
        playbackSpeed = availableSpeeds[nextIndex]

        // Restart timer with new speed if playing
        if isPlaying {
            stopPlaybackTimer()
            startPlaybackTimer()
        }
    }

    func setPlaybackSpeed(_ speed: Double) {
        playbackSpeed = speed
        if isPlaying {
            stopPlaybackTimer()
            startPlaybackTimer()
        }
    }

    // MARK: - Map Region

    func fitMapToRoute() {
        guard let bounds = gpsDataService.getBoundingRegion(for: routeCoordinates) else { return }

        mapRegion = MKCoordinateRegion(
            center: bounds.center,
            span: MKCoordinateSpan(
                latitudeDelta: bounds.span.latDelta,
                longitudeDelta: bounds.span.lonDelta
            )
        )
    }

    func centerOnCurrentPosition() {
        guard let position = currentPosition else { return }
        mapRegion = MKCoordinateRegion(
            center: position,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
    }

    // MARK: - Private Methods

    private func startPlaybackTimer() {
        // Base interval is 100ms, adjusted by playback speed
        let interval = 0.1 / playbackSpeed
        playbackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.advancePlayback()
        }
    }

    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    private func advancePlayback() {
        guard currentIndex < gpsPoints.count - 1 else {
            // Reached end of route
            pause()
            return
        }

        currentIndex += 1
        updateCurrentPosition()
    }

    private func updateCurrentPosition() {
        guard currentIndex < gpsPoints.count else { return }

        let point = gpsPoints[currentIndex]
        currentPosition = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
        currentSpeed = point.speed
        currentElevation = point.altitude
    }

    deinit {
        stopPlaybackTimer()
    }
}
