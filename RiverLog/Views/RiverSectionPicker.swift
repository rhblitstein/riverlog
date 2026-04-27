import SwiftUI
import CoreData

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
    @State private var showAddCustomSection = false
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
    
    var favoriteSections: [RiverSection] {
        filteredSections.filter { $0.isFavorite }
    }

    var customSections: [RiverSection] {
        filteredSections.filter { $0.isCustom && !$0.isFavorite }
    }

    var standardSections: [RiverSection] {
        filteredSections.filter { !$0.isCustom && !$0.isFavorite }
    }

    private func toggleFavorite(_ section: RiverSection) {
        section.isFavorite.toggle()
        try? viewContext.save()
    }

    var body: some View {
        NavigationView {
            List {
                // Add custom section button
                Section {
                    Button(action: {
                        showAddCustomSection = true
                    }) {
                        Label("Add Custom Section", systemImage: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }

                // Favorites first
                if !favoriteSections.isEmpty {
                    Section("Favorites") {
                        ForEach(favoriteSections, id: \.id) { section in
                            sectionRow(section)
                                .swipeActions(edge: .leading) {
                                    Button {
                                        toggleFavorite(section)
                                    } label: {
                                        Label("Unfavorite", systemImage: "star.slash")
                                    }
                                    .tint(.yellow)
                                }
                        }
                    }
                }

                // Custom sections
                if !customSections.isEmpty {
                    Section("My Sections") {
                        ForEach(customSections, id: \.id) { section in
                            sectionRow(section)
                                .swipeActions(edge: .leading) {
                                    Button {
                                        toggleFavorite(section)
                                    } label: {
                                        Label("Favorite", systemImage: "star.fill")
                                    }
                                    .tint(.yellow)
                                }
                        }
                    }
                }

                // Standard sections
                Section(favoriteSections.isEmpty && customSections.isEmpty ? "" : "All Sections") {
                    ForEach(standardSections, id: \.id) { section in
                        sectionRow(section)
                            .swipeActions(edge: .leading) {
                                Button {
                                    toggleFavorite(section)
                                } label: {
                                    Label("Favorite", systemImage: "star.fill")
                                }
                                .tint(.yellow)
                            }
                    }
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
            .sheet(isPresented: $showAddCustomSection) {
                AddCustomSectionView()
            }
        }
    }

    @ViewBuilder
    private func sectionRow(_ section: RiverSection) -> some View {
        Button(action: {
            selectedSection = section
            dismiss()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(section.riverName ?? "")
                            .font(.headline)
                            .foregroundColor(.primary)
                        if section.isCustom {
                            Text("Custom")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }

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

                Spacer()

                Button {
                    toggleFavorite(section)
                } label: {
                    Image(systemName: section.isFavorite ? "star.fill" : "star")
                        .foregroundColor(section.isFavorite ? .yellow : .gray)
                        .font(.system(size: 20))
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
