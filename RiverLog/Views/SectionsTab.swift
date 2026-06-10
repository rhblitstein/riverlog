import SwiftUI
import MapKit
import CoreData

struct SectionsTab: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \RiverSection.riverName, ascending: true),
            NSSortDescriptor(keyPath: \RiverSection.name, ascending: true)
        ],
        animation: .default
    ) private var sections: FetchedResults<RiverSection>

    @ObservedObject private var locationManager = LocationManager.shared
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.5, longitude: -105.8),
        span: MKCoordinateSpan(latitudeDelta: 3.0, longitudeDelta: 3.0)
    )
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var selectedSection: RiverSection?
    @State private var showingSectionDetail = false

    // Filters
    @State private var filterClass: String = "All"
    @State private var filterMinLength: Double = 0
    @State private var filterMaxLength: Double = 50
    @State private var filterState: String = "All"

    private let classOptions = ["All", "I", "II", "III", "IV", "V", "V+"]

    // MARK: - Computed

    var filteredSections: [RiverSection] {
        sections.filter { section in
            let matchesSearch = searchText.isEmpty ||
                section.riverName?.localizedCaseInsensitiveContains(searchText) == true ||
                section.name?.localizedCaseInsensitiveContains(searchText) == true ||
                section.classRating?.localizedCaseInsensitiveContains(searchText) == true

            let matchesClass = filterClass == "All" ||
                section.classRating?.contains(filterClass) == true

            let matchesLength = section.mileage >= filterMinLength &&
                (filterMaxLength >= 50 || section.mileage <= filterMaxLength)

            let matchesState = filterState == "All" || section.state == filterState

            return matchesSearch && matchesClass && matchesLength && matchesState
        }
    }

    var sectionsWithCoordinates: [RiverSection] {
        filteredSections.filter { $0.putInLatitude != 0 && $0.putInLongitude != 0 }
    }

    var nearbySections: [RiverSection] {
        guard let userLoc = locationManager.currentLocation else {
            return Array(filteredSections.prefix(10))
        }
        let userLocation = CLLocation(latitude: userLoc.coordinate.latitude, longitude: userLoc.coordinate.longitude)
        return filteredSections
            .filter { $0.putInLatitude != 0 }
            .sorted { a, b in
                let locA = CLLocation(latitude: a.putInLatitude, longitude: a.putInLongitude)
                let locB = CLLocation(latitude: b.putInLatitude, longitude: b.putInLongitude)
                return userLocation.distance(from: locA) < userLocation.distance(from: locB)
            }
            .prefix(10)
            .map { $0 }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar
                    mapView
                        .frame(height: 280)

                    ScrollView {
                        VStack(spacing: 16) {
                            filterPills
                                .padding(.top, 12)

                            if !nearbySections.isEmpty {
                                sectionListHeader("Nearby Sections")
                                ForEach(nearbySections, id: \.id) { section in
                                    Button {
                                        selectedSection = section
                                        showingSectionDetail = true
                                    } label: {
                                        SectionCardView(section: section)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }

                            if !searchText.isEmpty || filterClass != "All" {
                                sectionListHeader("Results (\(filteredSections.count))")
                                ForEach(filteredSections.prefix(50), id: \.id) { section in
                                    Button {
                                        selectedSection = section
                                        showingSectionDetail = true
                                    } label: {
                                        SectionCardView(section: section)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }

                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSectionDetail) {
                if let section = selectedSection {
                    SectionDetailView(section: section)
                }
            }
            .sheet(isPresented: $showingFilters) {
                SectionFiltersView(
                    filterClass: $filterClass,
                    filterMinLength: $filterMinLength,
                    filterMaxLength: $filterMaxLength,
                    filterState: $filterState
                )
            }
        }
        .onAppear {
            centerOnUser()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Text("Sections")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.primaryBlue)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            HStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search sections or rivers...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)

                Button { showingFilters = true } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18))
                        .foregroundColor(hasActiveFilters ? Theme.primaryBlue : .primary)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 2)
    }

    private var hasActiveFilters: Bool {
        filterClass != "All" || filterMinLength > 0 || filterMaxLength < 50 || filterState != "All"
    }

    // MARK: - Map

    private var mapView: some View {
        Map(coordinateRegion: $mapRegion,
            showsUserLocation: true,
            annotationItems: sectionsWithCoordinates) { section in
            MapAnnotation(coordinate: CLLocationCoordinate2D(
                latitude: section.putInLatitude,
                longitude: section.putInLongitude
            )) {
                Button {
                    selectedSection = section
                    showingSectionDetail = true
                } label: {
                    SectionMapPin(section: section)
                }
            }
        }
    }

    // MARK: - Filter Pills

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(classOptions, id: \.self) { classOption in
                    Button {
                        filterClass = classOption
                    } label: {
                        Text(classOption == "All" ? "All Classes" : "Class \(classOption)")
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(filterClass == classOption ? Theme.primaryBlue : Color(.systemGray6))
                            .foregroundColor(filterClass == classOption ? .white : .primary)
                            .cornerRadius(18)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionListHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
    }

    private func centerOnUser() {
        if let location = locationManager.currentLocation {
            mapRegion = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
            )
        }
    }
}

// MARK: - Section Map Pin

struct SectionMapPin: View {
    let section: RiverSection

    var pinColor: Color {
        guard let rating = section.classRating else { return .blue }
        if rating.contains("V") { return .red }
        if rating.contains("IV") { return .orange }
        if rating.contains("III") { return .yellow }
        if rating.contains("II") { return .green }
        return .blue
    }

    var body: some View {
        Circle()
            .fill(pinColor)
            .frame(width: 12, height: 12)
            .overlay(
                Circle().stroke(Color.white, lineWidth: 1.5)
            )
            .shadow(radius: 2)
    }
}

// MARK: - Section Card View

struct SectionCardView: View {
    let section: RiverSection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.riverName ?? "Unknown River")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(section.name ?? "Unknown Section")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if section.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }

            HStack(spacing: 12) {
                if let classRating = section.classRating, !classRating.isEmpty {
                    Label(formatClassRating(classRating), systemImage: "drop.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                if section.mileage > 0 {
                    Label(String(format: "%.1f mi", section.mileage), systemImage: "arrow.left.and.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if section.gradient > 0 {
                    Label("\(Int(section.gradient)) fpm", systemImage: "arrow.down.forward")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let gaugeID = section.gaugeID, !gaugeID.isEmpty {
                    Image(systemName: "wave.3.right")
                        .font(.caption)
                        .foregroundColor(.teal)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private func formatClassRating(_ rating: String) -> String {
        rating
            .replacingOccurrences(of: "to", with: "-")
            .replacingOccurrences(of: "plus", with: "+")
            .replacingOccurrences(of: "minus", with: "-")
    }
}
