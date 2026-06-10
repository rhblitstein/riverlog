import SwiftUI

struct SectionFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filterClass: String
    @Binding var filterMinLength: Double
    @Binding var filterMaxLength: Double
    @Binding var filterState: String

    private let classOptions = ["All", "I", "II", "III", "IV", "V", "V+"]
    private let stateOptions = ["All", "CO", "UT", "NM", "AZ", "WY", "ID", "MT", "OR", "WA", "CA"]

    var body: some View {
        NavigationView {
            Form {
                Section("Class Rating") {
                    Picker("Class", selection: $filterClass) {
                        ForEach(classOptions, id: \.self) { option in
                            Text(option == "All" ? "All Classes" : "Class \(option)").tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Length") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Min: \(String(format: "%.0f", filterMinLength)) mi")
                            .font(.subheadline)
                        Slider(value: $filterMinLength, in: 0...50, step: 1)

                        Text("Max: \(filterMaxLength >= 50 ? "Any" : String(format: "%.0f mi", filterMaxLength))")
                            .font(.subheadline)
                        Slider(value: $filterMaxLength, in: 0...50, step: 1)
                    }
                }

                Section("State") {
                    Picker("State", selection: $filterState) {
                        ForEach(stateOptions, id: \.self) { state in
                            Text(state == "All" ? "All States" : state).tag(state)
                        }
                    }
                }

                Section {
                    Button("Reset Filters") {
                        filterClass = "All"
                        filterMinLength = 0
                        filterMaxLength = 50
                        filterState = "All"
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
