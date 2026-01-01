import SwiftUI
import MapKit
import CoreLocation

struct LiveTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = LiveTrackingViewModel()

    @State private var showingStopConfirmation = false
    @State private var navigateToAddActivity = false
    @State private var recordedLocations: [CLLocation] = []
    @State private var recordedDuration: Double = 0
    @State private var recordedDistance: Double = 0
    @State private var showingGearPicker = false
    @State private var selectedGear: Gear?
    @State private var showingExtraOptions = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Map background
                Map(coordinateRegion: $viewModel.mapRegion,
                    showsUserLocation: true,
                    annotationItems: routeAnnotations) { item in
                    MapAnnotation(coordinate: item.coordinate) {
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .ignoresSafeArea()

                // UI Overlay
                VStack(spacing: 0) {
                    // Top bar with dismiss button
                    HStack {
                        Button(action: {
                            if viewModel.isTracking || viewModel.isPaused {
                                showingStopConfirmation = true
                            } else {
                                dismiss()
                            }
                        }) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    Spacer()

                    // Bottom control area
                    VStack(spacing: 0) {
                        // Stats panel (darker background)
                        statsPanel

                        // Control panel
                        controlPanel
                    }
                }
            }
            .onAppear {
                viewModel.checkAuthorization()
            }
            .alert("Location Access Required", isPresented: $viewModel.showAuthorizationAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enable location access in Settings to track your river trip.")
            }
            .confirmationDialog("Stop Recording?", isPresented: $showingStopConfirmation, titleVisibility: .visible) {
                Button("Stop & Save", role: .destructive) {
                    stopAndSave()
                }
                Button("Discard Trip", role: .destructive) {
                    _ = viewModel.stopTracking()
                    dismiss()
                }
                Button("Continue Recording", role: .cancel) {}
            } message: {
                Text("Do you want to save this trip or discard it?")
            }
            .navigationDestination(isPresented: $navigateToAddActivity) {
                AddActivityView(
                    gpsLocations: recordedLocations,
                    gpsDuration: recordedDuration,
                    gpsDistance: recordedDistance
                )
            }
            .sheet(isPresented: $showingGearPicker) {
                GearPickerView(selectedGear: $selectedGear, onSelect: { gear in
                    selectedGear = gear
                })
            }
        }
    }

    // MARK: - Stats Panel

    private var statsPanel: some View {
        VStack(spacing: 12) {
            // Header
            Text(craftLapLabel)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)

            // Stats row
            HStack(spacing: 0) {
                statItem(value: viewModel.formattedTime, label: "Duration")
                Divider().frame(height: 40).background(Color.white.opacity(0.3))
                statItem(value: viewModel.formattedDistance, label: "Distance")
                Divider().frame(height: 40).background(Color.white.opacity(0.3))
                statItem(value: formattedGradient, label: "Gradient")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.black)
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }

    private var craftLapLabel: String {
        if let gear = selectedGear, let craftType = gear.craftType {
            return "\(craftType) Lap"
        }
        return "River Lap"
    }

    private var craftEmoji: String {
        if let gear = selectedGear,
           let craftTypeString = gear.craftType,
           let craftType = CraftType(rawValue: craftTypeString) {
            return craftType.emoji
        }
        return "🌊"
    }

    private var formattedGradient: String {
        let feet = viewModel.elevationGain * 3.281
        return String(format: "%.0f ft", feet)
    }

    // MARK: - Control Panel

    private var controlPanel: some View {
        VStack(spacing: 12) {
            // Swipe up indicator at top
            Button(action: {
                withAnimation(.spring()) {
                    showingExtraOptions.toggle()
                }
            }) {
                Image(systemName: showingExtraOptions ? "chevron.down" : "chevron.up")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)

            // Main control buttons
            HStack(spacing: 20) {
                // Craft button
                Button(action: {
                    showingGearPicker = true
                }) {
                    VStack(spacing: 6) {
                        Text(craftEmoji)
                            .font(.system(size: 28))
                        Text(selectedGear?.name ?? "Craft")
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .frame(width: 80, height: 70)
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
                }
                .foregroundColor(.primary)

                // Start/Pause/Resume button
                Button(action: {
                    if viewModel.isTracking {
                        viewModel.pauseTracking()
                    } else if viewModel.isPaused {
                        viewModel.resumeTracking()
                    } else {
                        viewModel.startTracking()
                    }
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: buttonIcon)
                            .font(.system(size: 28, weight: .semibold))
                        Text(buttonLabel)
                            .font(.caption.weight(.semibold))
                    }
                    .frame(width: 100, height: 70)
                    .background(buttonColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                // Add Section button
                Button(action: {
                    // TODO: Add section functionality
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 24))
                        Text("Section")
                            .font(.caption)
                    }
                    .frame(width: 80, height: 70)
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
                }
                .foregroundColor(.primary)
            }
            .padding(.horizontal, 20)

            // Extra options (revealed on swipe up)
            if showingExtraOptions {
                VStack(spacing: 12) {
                    Button(action: {
                        // TODO: Share live location
                    }) {
                        Label("Share Live Location", systemImage: "location.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .cornerRadius(10)
                    }
                    .foregroundColor(.primary)

                    Button(action: {
                        // TODO: Customize
                    }) {
                        Label("Customize", systemImage: "slider.horizontal.3")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .cornerRadius(10)
                    }
                    .foregroundColor(.primary)
                }
                .padding(.horizontal, 20)
            }

            Spacer().frame(height: 20)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }

    private var buttonIcon: String {
        if viewModel.isTracking {
            return "pause.fill"
        } else if viewModel.isPaused {
            return "play.fill"
        } else {
            return "play.fill"
        }
    }

    private var buttonLabel: String {
        if viewModel.isTracking {
            return "Pause"
        } else if viewModel.isPaused {
            return "Resume"
        } else {
            return "Start"
        }
    }

    private var buttonColor: Color {
        if viewModel.isTracking {
            return .orange
        } else if viewModel.isPaused {
            return Theme.primaryBlue
        } else {
            return .green
        }
    }

    // MARK: - Helpers

    private var routeAnnotations: [RouteAnnotation] {
        viewModel.routeCoordinates.enumerated().map { index, coord in
            RouteAnnotation(id: index, coordinate: coord)
        }
    }

    private func stopAndSave() {
        recordedLocations = viewModel.stopTracking()
        recordedDuration = viewModel.elapsedTime
        recordedDistance = viewModel.totalDistance
        navigateToAddActivity = true
    }
}

// MARK: - Route Annotation

struct RouteAnnotation: Identifiable {
    let id: Int
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Route Polyline View

struct RoutePolylineView: UIViewRepresentable {
    let coordinates: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isUserInteractionEnabled = false
        mapView.alpha = 0
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)
        guard coordinates.count > 1 else { return }
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        uiView.addOverlay(polyline)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(Theme.primaryBlue)
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

#Preview {
    LiveTrackingView()
}
