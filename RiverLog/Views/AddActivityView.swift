import SwiftUI
import CoreLocation

struct AddActivityView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: AddActivityViewModel
    @State private var selectedSection: RiverSection?
    @State private var showingSectionPicker = false
    @State private var showingGearPicker = false
    @State private var selectedNotesTab: NotesTab = .quick

    // GPS data from live tracking
    private let gpsLocations: [CLLocation]?
    private let gpsDuration: Double?
    private let gpsDistance: Double?

    enum NotesTab {
        case quick, report, `private`
    }

    init(gpsLocations: [CLLocation]? = nil, gpsDuration: Double? = nil, gpsDistance: Double? = nil) {
        self.gpsLocations = gpsLocations
        self.gpsDuration = gpsDuration
        self.gpsDistance = gpsDistance

        // Initialize view model with GPS data
        let vm = AddActivityViewModel()
        if let duration = gpsDuration {
            vm.duration = duration / 3600.0  // Convert seconds to hours
        }
        if let distance = gpsDistance {
            vm.gpsDistance = distance
        }
        if let locations = gpsLocations, !locations.isEmpty {
            vm.hasGPSData = true
            vm.gpsLocations = locations
        }
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Activity Info") {
                    TextField("Title", text: $viewModel.title)

                    // Trip Type
                    Picker("Trip Type", selection: $viewModel.tripType) {
                        ForEach(TripType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                // GPS Route Preview (only if we have GPS data)
                if viewModel.hasGPSData, let locations = gpsLocations, !locations.isEmpty {
                    Section("Recorded Route") {
                        let coordinates = locations.map { $0.coordinate }
                        SimpleRouteMapView(coordinates: coordinates)
                            .frame(height: 180)
                            .listRowInsets(EdgeInsets())

                        // GPS Stats
                        HStack(spacing: 20) {
                            VStack(alignment: .leading) {
                                Text("Distance")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.2f mi", viewModel.gpsDistance))
                                    .font(.headline)
                            }

                            VStack(alignment: .leading) {
                                Text("Duration")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatDuration(viewModel.duration * 3600))
                                    .font(.headline)
                            }

                            VStack(alignment: .leading) {
                                Text("Points")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(locations.count)")
                                    .font(.headline)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                Section("Gear & Craft") {
                    // Gear Selection
                    Button(action: { showingGearPicker = true }) {
                        HStack {
                            Label(viewModel.selectedGear?.name ?? "No Gear Selected", systemImage: "figure.wave")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Manual craft type if no gear
                    if viewModel.selectedGear == nil {
                        Picker("Craft Type", selection: $viewModel.craftType) {
                            ForEach(CraftType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                    }
                    
                    // Lap Type
                    if !viewModel.availableLapTypes.isEmpty {
                        Picker("Lap Type", selection: $viewModel.lapType) {
                            Text("Select...").tag(nil as LapType?)
                            ForEach(viewModel.availableLapTypes, id: \.self) { type in
                                Text(type.displayName).tag(type as LapType?)
                            }
                        }
                    }
                    
                    // Load size for paddle guide
                    if viewModel.lapType == .paddleGuide {
                        HStack {
                            Text("Load Size")
                            TextField("0", value: $viewModel.loadSize, format: .number)
                                .keyboardType(.numberPad)
                        }
                    }
                }
                
                Section("River Section") {
                    if let section = selectedSection {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Selected Section")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("Change") {
                                    showingSectionPicker = true
                                }
                                .font(.subheadline)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(section.riverName ?? "")
                                    .font(.headline)
                                Text(section.name ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    if let classRating = section.classRating {
                                        Label("Class \(formatClassRating(classRating))", systemImage: "drop.fill")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    if section.mileage > 0 {
                                        Label("\(String(format: "%.1f", section.mileage)) mi", systemImage: "arrow.left.and.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if section.gradient > 0 {
                                        Label("\(Int(section.gradient)) fpm", systemImage: "arrow.down.forward")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        Button(action: { showingSectionPicker = true }) {
                            HStack {
                                Label("Select River Section", systemImage: "map")
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Trip Details") {
                    DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    DatePicker("Launch Time", selection: $viewModel.launchTime, displayedComponents: .hourAndMinute)
                    HStack {
                        Text("Duration (hours)")
                        TextField("0", value: $viewModel.duration, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }

                Section {
                    Toggle("Had a Swim", isOn: $viewModel.didSwim)
                    Toggle("Had Carnage", isOn: $viewModel.hadCarnage)
                } header: {
                    Text("Trip Outcome")
                } footer: {
                    Text("Track swims and carnage for your streak statistics")
                }

                Section("Flow") {
                    HStack {
                        Text("Flow")
                        TextField("0", value: $viewModel.flowValue, format: .number)
                            .keyboardType(.decimalPad)
                        Picker("", selection: $viewModel.flowUnit) {
                            ForEach(viewModel.flowUnits, id: \.self) { unit in
                                Text(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }
                    
                    // Show gauge info if section selected with USGS gauge
                    if let section = selectedSection, let gaugeID = section.gaugeID, !gaugeID.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Gauge: \(section.gaugeName ?? "")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if viewModel.isFetchingFlow {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Fetching flow data...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else if let errorMessage = viewModel.flowErrorMessage {
                                Text("⚠️ \(errorMessage)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                
                Section {
                    Picker("Notes Type", selection: $selectedNotesTab) {
                        Text("Quick Notes").tag(NotesTab.quick)
                        Text("Trip Report").tag(NotesTab.report)
                        Text("Private Notes").tag(NotesTab.private)
                    }
                    .pickerStyle(.segmented)
                    
                    switch selectedNotesTab {
                    case .quick:
                        TextEditor(text: $viewModel.notes)
                            .frame(minHeight: 100)
                    case .report:
                        TextEditor(text: $viewModel.tripReport)
                            .frame(minHeight: 150)
                    case .private:
                        TextEditor(text: $viewModel.privateNotes)
                            .frame(minHeight: 100)
                    }
                } header: {
                    Text("Notes")
                } footer: {
                    switch selectedNotesTab {
                    case .quick:
                        Text("Quick notes about your trip (public)")
                    case .report:
                        Text("Detailed trip report (public)")
                    case .private:
                        Text("Private notes - only visible to you")
                    }
                }
                
                Section("Privacy") {
                    Picker("Visibility", selection: $viewModel.visibility) {
                        ForEach(VisibilityType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon).tag(type)
                        }
                    }
                    
                    if viewModel.visibility != .private {
                        Toggle("Hide Flow", isOn: $viewModel.hideFlow)
                        Toggle("Hide Duration", isOn: $viewModel.hideDuration)
                        Toggle("Hide Photos", isOn: $viewModel.hidePhotos)
                        Toggle("Hide Notes", isOn: $viewModel.hideNotes)
                    }
                }
                
                Section("Photos") {
                    PhotoPicker(selectedPhotos: $viewModel.selectedPhotos)
                }
            }
            .navigationTitle("Add Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save(context: viewContext, section: selectedSection)
                        dismiss()
                    }
                    .disabled(!viewModel.isValid || selectedSection == nil)
                }
            }
            .sheet(isPresented: $showingSectionPicker) {
                RiverSectionPicker(selectedSection: $selectedSection)
            }
            .sheet(isPresented: $showingGearPicker) {
                GearPickerView(selectedGear: $viewModel.selectedGear, onSelect: { gear in
                    viewModel.selectGear(gear)
                })
            }
            .onChange(of: selectedSection) { newSection in
                // Auto-fetch flow when section is selected
                if let section = newSection, let gaugeID = section.gaugeID, !gaugeID.isEmpty {
                    Task {
                        await fetchCurrentFlow(gaugeID: gaugeID)
                    }
                }
            }
        }
    }
    
    private func formatClassRating(_ rating: String) -> String {
        var formatted = rating
            .replacingOccurrences(of: "to", with: "-")
            .replacingOccurrences(of: "plus", with: "+")
            .replacingOccurrences(of: "minus", with: "-")
            .replacingOccurrences(of: "standout", with: "(")
        
        if formatted.contains("(") && !formatted.contains(")") {
            formatted += ")"
        }
        
        return formatted
    }
    
    private func fetchCurrentFlow(gaugeID: String) async {
        await viewModel.fetchFlow(gaugeID: gaugeID)
    }

    private func formatDuration(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
}
