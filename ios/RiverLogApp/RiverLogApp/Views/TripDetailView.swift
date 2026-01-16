import SwiftUI

struct TripDetailView: View {
    let trip: Trip
    @StateObject private var listViewModel = TripListViewModel()
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(trip.riverName)
                                .font(.system(size: 32, weight: .bold))
                            
                            Text(trip.sectionName)
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if let difficulty = trip.difficulty {
                            Text(difficulty)
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.primary)
                                .foregroundColor(Color(.systemBackground))
                                .cornerRadius(6)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary, lineWidth: 2)
                )
                
                // Details Grid
                VStack(spacing: 16) {
                    DetailRow(label: "Date", value: formattedDate)
                    
                    if let flow = trip.flow {
                        DetailRow(label: "Flow", value: "\(flow) \(trip.flowUnit ?? "cfs")")
                    }
                    
                    if let craft = trip.craftType {
                        DetailRow(label: "Craft Type", value: craft.capitalized)
                    }
                    
                    if let duration = trip.durationMinutes {
                        DetailRow(label: "Duration", value: formatDuration(duration))
                    }
                    
                    if let mileage = trip.mileage {
                        DetailRow(
                            label: "Mileage",
                            value: String(format: "%.1f miles", mileage),
                            valueColor: .blue
                        )
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary, lineWidth: 2)
                )
                
                // Notes
                if let notes = trip.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(notes)
                            .font(.body)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary, lineWidth: 2)
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            TripFormView(tripToEdit: trip)
        }
        .alert("Delete Trip", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await listViewModel.deleteTrip(trip)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this trip?")
        }
    }
    
    private var formattedDate: String {
        guard let date = trip.formattedDate else { return trip.tripDate }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}
