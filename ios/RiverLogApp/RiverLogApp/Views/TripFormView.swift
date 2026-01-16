import SwiftUI

struct TripFormView: View {
    @StateObject private var viewModel = TripFormViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var tripToEdit: Trip?
    
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    SectionPickerView(
                        sections: viewModel.sections,
                        selectedSection: $viewModel.selectedSection,
                        searchText: $viewModel.searchText,
                        isLoading: viewModel.isLoadingSections,
                        onSearch: {
                            Task {
                                await viewModel.loadSections()
                            }
                        }
                    )
                } label: {
                    HStack {
                        Text("Section")
                        Spacer()
                        if let section = viewModel.selectedSection {
                            Text(section.displayName)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        } else {
                            Text("Select...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onChange(of: viewModel.selectedSection) { _, newSection in
                    if let rating = newSection?.classRating, viewModel.difficulty.isEmpty {
                        viewModel.difficulty = formatClassRating(rating)
                    }
                    if let mileage = newSection?.mileage, viewModel.mileage.isEmpty {
                        viewModel.mileage = String(format: "%.1f", mileage)
                    }
                }
                
                DatePicker("Date", selection: $viewModel.tripDate, displayedComponents: .date)
                
                TextField("Difficulty (e.g., III, IV+)", text: $viewModel.difficulty)
                
                HStack {
                    TextField("Flow", text: $viewModel.flow)
                        .keyboardType(.numberPad)
                    
                    Picker("", selection: $viewModel.flowUnit) {
                        Text("CFS").tag("cfs")
                        Text("Feet").tag("feet")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
                
                TextField("Craft Type", text: $viewModel.craftType)
                    .textInputAutocapitalization(.never)
                
                TextField("Duration (minutes)", text: $viewModel.durationMinutes)
                    .keyboardType(.numberPad)
                
                TextField("Mileage", text: $viewModel.mileage)
                    .keyboardType(.decimalPad)
                
                TextEditor(text: $viewModel.notes)
                    .frame(minHeight: 100)
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Trip" : "Log New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(viewModel.isEditing ? "Update" : "Save") {
                        Task {
                            let success = await viewModel.saveTrip()
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading || viewModel.selectedSection == nil)
                }
            }
            .task {
                await viewModel.loadSections()
                
                if let trip = tripToEdit {
                    await viewModel.loadTrip(trip)
                }
            }
        }
    }
}

struct SectionPickerView: View {
    let sections: [Section]
    @Binding var selectedSection: Section?
    @Binding var searchText: String
    let isLoading: Bool
    let onSearch: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var filteredSections: [Section] {
        if searchText.isEmpty {
            return sections
        }
        return sections.filter { section in
            section.riverName.localizedCaseInsensitiveContains(searchText) ||
            section.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar at top
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search rivers or sections", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .onChange(of: searchText) { _, _ in
                onSearch()
            }
            
            List {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    ForEach(filteredSections) { section in
                        Button {
                            selectedSection = section
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(section.riverName)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(section.name)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        Text(section.state)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        if let rating = section.classRating {
                                            Text("•")
                                                .foregroundColor(.secondary)
                                            Text(formatClassRating(rating))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        if let mileage = section.mileage {
                                            Text("•")
                                                .foregroundColor(.secondary)
                                            Text(String(format: "%.1f mi", mileage))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                if selectedSection?.id == section.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Select Section")
        .navigationBarTitleDisplayMode(.inline)
    }
}
