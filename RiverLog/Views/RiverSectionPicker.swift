import SwiftUI

struct RiverSectionPicker: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \RiverSection.riverName, ascending: true),
            NSSortDescriptor(keyPath: \RiverSection.name, ascending: true)
        ],
        animation: .default)
    private var sections: FetchedResults<RiverSection>
    
    @Binding var selectedSection: RiverSection?
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    var filteredSections: [RiverSection] {
        if searchText.isEmpty {
            return Array(sections)
        } else {
            return sections.filter { section in
                section.riverName?.localizedCaseInsensitiveContains(searchText) == true ||
                section.name?.localizedCaseInsensitiveContains(searchText) == true ||
                section.classRating?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    private func formatClassRating(_ rating: String) -> String {
        var formatted = rating
            .replacingOccurrences(of: "to", with: "-")
            .replacingOccurrences(of: "plus", with: "+")
            .replacingOccurrences(of: "minus", with: "-")
            .replacingOccurrences(of: "standout", with: "(")
            .replacingOccurrences(of: ")", with: ")")
        if formatted.contains("(") && !formatted.contains(")") {
            formatted += ")"
        }
        
        return formatted
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredSections, id: \.id) { section in
                    Button(action: {
                        selectedSection = section
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(section.riverName ?? "")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
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
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search rivers or sections")
            .navigationTitle("Select River Section")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
