import SwiftUI

struct TripListView: View {
    @StateObject private var viewModel = TripListViewModel()
    @EnvironmentObject private var authService: AuthService
    @State private var showingNewTrip = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("River Log")
                            .font(.system(size: 36, weight: .bold))
                        
                        Text("Every river mile, flip, and swim")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Stats
                    HStack(spacing: 16) {
                        StatBox(
                            value: String(Int(viewModel.totalMiles)),
                            label: "TOTAL MILES"
                        )
                        
                        StatBox(
                            value: String(viewModel.totalTrips),
                            label: "TOTAL TRIPS"
                        )
                        
                        StatBox(
                            value: String(viewModel.uniqueRivers),
                            label: "RIVERS"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Trips List
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else if viewModel.trips.isEmpty {
                        VStack(spacing: 16) {
                            Text("🚣")
                                .font(.system(size: 60))
                            
                            Text("No trips logged yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Button("Log Your First Trip") {
                                showingNewTrip = true
                            }
                            .padding()
                            .background(Color.primary)
                            .foregroundColor(Color(.systemBackground))
                            .cornerRadius(8)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary, lineWidth: 2)
                        )
                        .padding(.horizontal)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.trips) { trip in
                                NavigationLink(destination: TripDetailView(trip: trip)) {
                                    TripCard(trip: trip)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Error Message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGray6))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        // TODO: Profile view
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.title2)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewTrip = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // TODO: Settings view
                        authService.logout()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingNewTrip, onDismiss: {
                Task {
                    await viewModel.loadTrips()
                }
            }) {
                TripFormView()
            }
            .task {
                await viewModel.loadTrips()
            }
            .refreshable {
                await viewModel.loadTrips()
            }
        }
    }
}
