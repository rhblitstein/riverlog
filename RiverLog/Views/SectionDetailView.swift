import SwiftUI
import MapKit
import CoreData

struct SectionDetailView: View {
    let section: RiverSection
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var currentFlow: Double?
    @State private var isFetchingFlow = false
    @State private var flowError: String?
    @State private var showingRecordSheet = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Map header
                    if section.putInLatitude != 0 {
                        sectionMap
                            .frame(height: 200)
                    }

                    // Title area
                    VStack(alignment: .leading, spacing: 6) {
                        Text(section.riverName ?? "Unknown River")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(section.name ?? "Unknown Section")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        if let state = section.state {
                            Text(state)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)

                    Divider()

                    // Stats grid
                    statsGrid
                        .padding(16)

                    Divider()

                    // Flow section
                    if let gaugeID = section.gaugeID, !gaugeID.isEmpty {
                        flowSection
                            .padding(16)
                        Divider()
                    }

                    // Put-in / Take-out
                    putInTakeOutSection
                        .padding(16)

                    Divider()

                    // Actions
                    actionsSection
                        .padding(16)

                    Divider()

                    // AW Link
                    if let awURL = section.awURL, !awURL.isEmpty {
                        Button {
                            if let url = URL(string: awURL) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "globe")
                                Text("View on American Whitewater")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                            .foregroundColor(Theme.primaryBlue)
                            .padding(16)
                        }
                        Divider()
                    }

                    // Trip Reports placeholder
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Trip Reports")
                            .font(.headline)
                        Text("No trip reports yet. Be the first to write one!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(16)

                    Spacer(minLength: 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        toggleFavorite()
                    } label: {
                        Image(systemName: section.isFavorite ? "star.fill" : "star")
                            .foregroundColor(section.isFavorite ? .yellow : .primary)
                    }
                }
            }
        }
        .onAppear {
            fetchFlow()
        }
    }

    // MARK: - Map

    private var sectionMap: some View {
        let putIn = CLLocationCoordinate2D(latitude: section.putInLatitude, longitude: section.putInLongitude)
        let takeOut = CLLocationCoordinate2D(latitude: section.takeOutLatitude, longitude: section.takeOutLongitude)
        let hasValidTakeOut = section.takeOutLatitude != 0

        let center = hasValidTakeOut
            ? CLLocationCoordinate2D(
                latitude: (putIn.latitude + takeOut.latitude) / 2,
                longitude: (putIn.longitude + takeOut.longitude) / 2
            )
            : putIn

        let span: MKCoordinateSpan = hasValidTakeOut
            ? MKCoordinateSpan(
                latitudeDelta: abs(putIn.latitude - takeOut.latitude) * 1.8 + 0.02,
                longitudeDelta: abs(putIn.longitude - takeOut.longitude) * 1.8 + 0.02
            )
            : MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)

        return Map(coordinateRegion: .constant(MKCoordinateRegion(center: center, span: span)),
                   annotationItems: mapAnnotations) { item in
            MapAnnotation(coordinate: item.coordinate) {
                VStack(spacing: 2) {
                    Image(systemName: item.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(item.color)
                        .clipShape(Circle())
                    Text(item.label)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var mapAnnotations: [SectionMapAnnotation] {
        var annotations: [SectionMapAnnotation] = []
        if section.putInLatitude != 0 {
            annotations.append(SectionMapAnnotation(
                id: "putin",
                coordinate: CLLocationCoordinate2D(latitude: section.putInLatitude, longitude: section.putInLongitude),
                label: "Put-in",
                icon: "arrow.down.circle.fill",
                color: .green
            ))
        }
        if section.takeOutLatitude != 0 {
            annotations.append(SectionMapAnnotation(
                id: "takeout",
                coordinate: CLLocationCoordinate2D(latitude: section.takeOutLatitude, longitude: section.takeOutLongitude),
                label: "Take-out",
                icon: "flag.fill",
                color: .red
            ))
        }
        return annotations
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            statCell(label: "Class", value: formatClassRating(section.classRating ?? "—"))
            statCell(label: "Distance", value: section.mileage > 0 ? String(format: "%.1f mi", section.mileage) : "—")
            statCell(label: "Gradient", value: section.gradient > 0 ? "\(Int(section.gradient)) fpm" : "—")
        }
    }

    private func statCell(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    // MARK: - Flow

    private var flowSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "wave.3.right")
                    .foregroundColor(.teal)
                Text("Current Flow")
                    .font(.headline)
            }

            if isFetchingFlow {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Fetching flow data...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else if let flow = currentFlow {
                Text("\(Int(flow)) CFS")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.teal)
            } else if let error = flowError {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }

            if let gaugeName = section.gaugeName, !gaugeName.isEmpty {
                Text(gaugeName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Put-in / Take-out

    private var putInTakeOutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Access Points")
                .font(.headline)

            if let putIn = section.putInName, !putIn.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("Put-in")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(putIn)
                            .font(.subheadline)
                    }
                }
            }

            if let takeOut = section.takeOutName, !takeOut.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.red)
                    VStack(alignment: .leading) {
                        Text("Take-out")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(takeOut)
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                showingRecordSheet = true
            } label: {
                HStack {
                    Image(systemName: "record.circle")
                    Text("Start a Lap on This Section")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.primaryBlue)
                .cornerRadius(12)
            }

            HStack(spacing: 12) {
                actionButton(icon: "square.and.arrow.up", label: "Share")
                actionButton(icon: "exclamationmark.triangle", label: "Report Hazard")
                actionButton(icon: "doc.text", label: "Trip Report")
            }
        }
    }

    private func actionButton(icon: String, label: String) -> some View {
        Button {
            // TODO: Implement actions
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }

    // MARK: - Helpers

    private func fetchFlow() {
        guard let gaugeID = section.gaugeID, !gaugeID.isEmpty else { return }
        isFetchingFlow = true
        Task {
            do {
                let flow = try await USGSService.fetchCurrentFlow(gaugeID: gaugeID)
                await MainActor.run {
                    currentFlow = flow
                    isFetchingFlow = false
                }
            } catch FlowDataError.iceAffected {
                await MainActor.run { flowError = "Gauge is ice-affected"; isFetchingFlow = false }
            } catch FlowDataError.seasonallyClosed {
                await MainActor.run { flowError = "Gauge is seasonally closed"; isFetchingFlow = false }
            } catch FlowDataError.noData {
                await MainActor.run { flowError = "No flow data available"; isFetchingFlow = false }
            } catch {
                await MainActor.run { flowError = "Unable to fetch flow"; isFetchingFlow = false }
            }
        }
    }

    private func toggleFavorite() {
        section.isFavorite.toggle()
        try? viewContext.save()
    }

    private func formatClassRating(_ rating: String) -> String {
        rating
            .replacingOccurrences(of: "to", with: "-")
            .replacingOccurrences(of: "plus", with: "+")
            .replacingOccurrences(of: "minus", with: "-")
    }
}

// MARK: - Map Annotation Model

struct SectionMapAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let label: String
    let icon: String
    let color: Color
}
