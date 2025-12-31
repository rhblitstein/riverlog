import SwiftUI
import FirebaseAuth

struct AccountSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingGearManagement = false
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    if let user = authManager.user {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(user.displayName ?? "No name")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(user.email ?? "No email")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Gear") {
                    Button(action: {
                        showingGearManagement = true
                    }) {
                        HStack {
                            Text("My Gear")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                Section {
                    Button(action: {
                        showingSignOutAlert = true
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingGearManagement) {
                GearManagementView()
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    do {
                        try authManager.signOut()
                        dismiss()
                    } catch {
                        print("Error signing out: \(error)")
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}
