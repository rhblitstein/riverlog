import SwiftUI
import MapKit
import CoreData

struct RouteMapView: View {
    let activity: RiverActivity
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = RoutePlaybackViewModel()

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Map
            ZStack {
                Map(coordinateRegion: $viewModel.mapRegion,
                    annotationItems: mapAnnotations) { item in
                    MapAnnotation(coordinate: item.coordinate) {
                        annotationView(for: item)
                    }
                }
                .overlay(
                    RouteOverlayView(
                        coordinates: viewModel.routeCoordinates,
                        currentIndex: viewModel.currentIndex
                    )
                )
                .frame(height: isExpanded ? 400 : 200)
                .cornerRadius(12)

                // Expand/collapse button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.spring()) {
                                isExpanded.toggle()
                            }
                        }) {
                            Image(systemName: isExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .padding(8)
                    }
                    Spacer()
                }
            }

            // Playback controls (only show if there are GPS points)
            if viewModel.totalPoints > 1 {
                playbackControls
                    .padding(.top, 12)
            }
        }
        .onAppear {
            viewModel.loadGPSPoints(for: activity, context: viewContext)
        }
    }

    private var mapAnnotations: [MapAnnotationItem] {
        var items: [MapAnnotationItem] = []

        if let start = viewModel.startCoordinate {
            items.append(MapAnnotationItem(id: "start", coordinate: start, type: .start))
        }
        if let end = viewModel.endCoordinate, viewModel.routeCoordinates.count > 1 {
            items.append(MapAnnotationItem(id: "end", coordinate: end, type: .end))
        }
        if let current = viewModel.currentPosition, viewModel.isPlaying || viewModel.currentIndex > 0 {
            items.append(MapAnnotationItem(id: "current", coordinate: current, type: .current))
        }

        return items
    }

    @ViewBuilder
    private func annotationView(for item: MapAnnotationItem) -> some View {
        switch item.type {
        case .start:
            Image(systemName: "flag.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
                .background(
                    Circle()
                        .fill(.white)
                        .frame(width: 30, height: 30)
                )
        case .end:
            Image(systemName: "flag.checkered")
                .font(.system(size: 20))
                .foregroundColor(.red)
                .background(
                    Circle()
                        .fill(.white)
                        .frame(width: 30, height: 30)
                )
        case .current:
            Circle()
                .fill(Theme.primaryBlue)
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: 3)
                )
                .shadow(radius: 2)
        }
    }

    private var playbackControls: some View {
        VStack(spacing: 12) {
            // Progress slider
            HStack {
                Text(formatIndex(viewModel.currentIndex))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .leading)

                Slider(value: Binding(
                    get: { viewModel.progress },
                    set: { viewModel.seekTo(progress: $0) }
                ))
                .tint(Theme.primaryBlue)

                Text(formatIndex(viewModel.totalPoints - 1))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
            }

            // Current stats during playback
            if viewModel.isPlaying || viewModel.currentIndex > 0 {
                HStack(spacing: 20) {
                    Label(viewModel.formattedCurrentSpeed, systemImage: "speedometer")
                    Label(viewModel.formattedCurrentElevation, systemImage: "arrow.up.right")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            // Control buttons
            HStack(spacing: 30) {
                // Stop button
                Button(action: {
                    viewModel.stop()
                }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                        .frame(width: 44, height: 44)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }

                // Play/Pause button
                Button(action: {
                    if viewModel.isPlaying {
                        viewModel.pause()
                    } else {
                        viewModel.play()
                    }
                }) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Theme.primaryBlue)
                        .clipShape(Circle())
                }

                // Speed button
                Button(action: {
                    viewModel.cyclePlaybackSpeed()
                }) {
                    Text(viewModel.formattedPlaybackSpeed)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal)
    }

    private func formatIndex(_ index: Int) -> String {
        let minutes = index / 60
        let seconds = index % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Map Annotation Item

struct MapAnnotationItem: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let type: AnnotationType

    enum AnnotationType {
        case start
        case end
        case current
    }
}

// MARK: - Route Overlay View

struct RouteOverlayView: UIViewRepresentable {
    let coordinates: [CLLocationCoordinate2D]
    let currentIndex: Int

    func makeUIView(context: Context) -> RouteOverlayUIView {
        let view = RouteOverlayUIView()
        return view
    }

    func updateUIView(_ uiView: RouteOverlayUIView, context: Context) {
        uiView.coordinates = coordinates
        uiView.currentIndex = currentIndex
        uiView.setNeedsDisplay()
    }
}

class RouteOverlayUIView: UIView {
    var coordinates: [CLLocationCoordinate2D] = []
    var currentIndex: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard coordinates.count > 1 else { return }

        let path = UIBezierPath()

        // This is a simplified visualization - in production, you'd convert
        // coordinates to view points based on the map's visible region
        // For now, we rely on the map's built-in polyline rendering
    }
}

// MARK: - Simple Route Map (Non-playback version)

struct SimpleRouteMapView: View {
    let coordinates: [CLLocationCoordinate2D]
    @State private var region: MKCoordinateRegion

    init(coordinates: [CLLocationCoordinate2D]) {
        self.coordinates = coordinates

        // Calculate initial region
        if let first = coordinates.first {
            var minLat = first.latitude
            var maxLat = first.latitude
            var minLon = first.longitude
            var maxLon = first.longitude

            for coord in coordinates {
                minLat = min(minLat, coord.latitude)
                maxLat = max(maxLat, coord.latitude)
                minLon = min(minLon, coord.longitude)
                maxLon = max(maxLon, coord.longitude)
            }

            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )
            let span = MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 1.3, 0.005),
                longitudeDelta: max((maxLon - minLon) * 1.3, 0.005)
            )

            _region = State(initialValue: MKCoordinateRegion(center: center, span: span))
        } else {
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 39.7392, longitude: -104.9903),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: annotations) { item in
            MapAnnotation(coordinate: item.coordinate) {
                if item.id == "start" {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                } else if item.id == "end" {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                }
            }
        }
        .overlay(
            RoutePolylineOverlay(coordinates: coordinates)
        )
    }

    private var annotations: [MapAnnotationItem] {
        var items: [MapAnnotationItem] = []
        if let start = coordinates.first {
            items.append(MapAnnotationItem(id: "start", coordinate: start, type: .start))
        }
        if let end = coordinates.last, coordinates.count > 1 {
            items.append(MapAnnotationItem(id: "end", coordinate: end, type: .end))
        }
        return items
    }
}

// MARK: - Route Polyline Overlay

struct RoutePolylineOverlay: UIViewRepresentable {
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
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
