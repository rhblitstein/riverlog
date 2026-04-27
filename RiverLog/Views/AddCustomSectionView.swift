import SwiftUI
import CoreData
import FirebaseAuth

struct AddCustomSectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    // Required fields
    @State private var riverName: String = ""
    @State private var sectionName: String = ""
    @State private var state: String = "CO"
    @State private var classRating: String = ""

    // Optional fields
    @State private var putInName: String = ""
    @State private var takeOutName: String = ""
    @State private var mileage: String = ""
    @State private var gradient: String = ""

    // Gauge selection
    @State private var showGaugePicker = false
    @State private var selectedGaugeSection: RiverSection?

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \RiverSection.riverName, ascending: true)],
        predicate: NSPredicate(format: "gaugeID != nil AND gaugeID != ''"),
        animation: .default)
    private var sectionsWithGauges: FetchedResults<RiverSection>

    var isValid: Bool {
        !riverName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !sectionName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !classRating.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section("River Info") {
                    TextField("River Name", text: $riverName)
                    TextField("Section Name (e.g., Ruby to Hecla)", text: $sectionName)

                    Picker("State", selection: $state) {
                        Text("CO").tag("CO")
                        Text("UT").tag("UT")
                        Text("NM").tag("NM")
                        Text("AZ").tag("AZ")
                        Text("WY").tag("WY")
                        Text("ID").tag("ID")
                        Text("MT").tag("MT")
                        Text("Other").tag("Other")
                    }

                    TextField("Class Rating (e.g., III-IV)", text: $classRating)
                }

                Section("Put-in / Take-out") {
                    TextField("Put-in Name (optional)", text: $putInName)
                    TextField("Take-out Name (optional)", text: $takeOutName)
                }

                Section("Details") {
                    HStack {
                        TextField("Mileage", text: $mileage)
                            .keyboardType(.decimalPad)
                        Text("miles")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        TextField("Gradient (optional)", text: $gradient)
                            .keyboardType(.decimalPad)
                        Text("fpm")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Gauge") {
                    if let gauge = selectedGaugeSection {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(gauge.gaugeName ?? "Unknown Gauge")
                                    .font(.subheadline)
                                Text(gauge.riverName ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Change") {
                                showGaugePicker = true
                            }
                        }
                    } else {
                        Button("Select a Gauge") {
                            showGaugePicker = true
                        }
                    }
                }

                Section {
                    Text("This section will be private to your account. You can share it to the community database later.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("New Custom Section")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSection()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showGaugePicker) {
                GaugePickerView(selectedSection: $selectedGaugeSection)
            }
        }
    }

    private func saveSection() {
        let section = RiverSection(context: viewContext)
        section.id = UUID()
        section.riverName = riverName.trimmingCharacters(in: .whitespaces)
        section.name = sectionName.trimmingCharacters(in: .whitespaces)
        section.state = state
        section.classRating = classRating.trimmingCharacters(in: .whitespaces)
        section.putInName = putInName.isEmpty ? nil : putInName
        section.takeOutName = takeOutName.isEmpty ? nil : takeOutName
        section.mileage = Double(mileage) ?? 0
        section.gradient = Double(gradient) ?? 0
        section.gradientUnit = "fpm"

        // Custom section flags
        section.isCustom = true
        section.contributedToDatabase = false
        section.createdByUserId = Auth.auth().currentUser?.uid

        // Copy gauge info from selected section
        if let gauge = selectedGaugeSection {
            section.gaugeID = gauge.gaugeID
            section.gaugeName = gauge.gaugeName
        }

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving custom section: \(error)")
        }
    }
}

struct GaugePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSection: RiverSection?
    @State private var searchText = ""

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \RiverSection.gaugeName, ascending: true)],
        predicate: NSPredicate(format: "gaugeID != nil AND gaugeID != ''"),
        animation: .default)
    private var sectionsWithGauges: FetchedResults<RiverSection>

    // Get unique gauges (some sections share the same gauge)
    var uniqueGauges: [RiverSection] {
        var seen = Set<String>()
        return sectionsWithGauges.filter { section in
            guard let gaugeID = section.gaugeID, !gaugeID.isEmpty else { return false }
            if seen.contains(gaugeID) { return false }
            seen.insert(gaugeID)

            if searchText.isEmpty { return true }
            return section.gaugeName?.localizedCaseInsensitiveContains(searchText) == true ||
                   section.riverName?.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(uniqueGauges, id: \.gaugeID) { section in
                    Button(action: {
                        selectedSection = section
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(section.gaugeName ?? "Unknown")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(section.riverName ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .searchable(text: $searchText, prompt: "Search gauges")
            .navigationTitle("Select Gauge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
