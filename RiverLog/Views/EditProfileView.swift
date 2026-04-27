import SwiftUI
import FirebaseAuth

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var bio = ""
    @State private var city = ""
    @State private var state = ""
    @State private var primaryCraft = "Raft"
    @State private var birthdate = Date()
    @State private var gender = "Prefer not to say"
    @State private var weight = ""
    @State private var isSaving = false

    private let firestoreService = FirestoreService()
    let craftTypes = ["Raft", "Kayak", "SUP", "Canoe", "Cat", "Duckie", "Packraft"]
    let genderOptions = ["Man", "Woman", "Non-binary", "Prefer not to say"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile photo + name
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(Color(.systemGray4))
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            )

                        VStack(spacing: 0) {
                            TextField("First Name", text: $firstName)
                                .padding(.vertical, 12)
                            Divider()
                            TextField("Last Name", text: $lastName)
                                .padding(.vertical, 12)
                        }
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding(16)

                    // Bio, City, State, Primary Craft
                    VStack(spacing: 0) {
                        fieldRow {
                            TextField("Add a bio", text: $bio)
                        }
                        Divider().padding(.leading, 16)
                        fieldRow {
                            TextField("City", text: $city)
                        }
                        Divider().padding(.leading, 16)
                        fieldRow {
                            TextField("State", text: $state)
                        }
                        Divider().padding(.leading, 16)
                        fieldRow {
                            HStack {
                                Text("Primary Craft")
                                    .foregroundColor(.primary)
                                Spacer()
                                Picker("", selection: $primaryCraft) {
                                    ForEach(craftTypes, id: \.self) { Text($0) }
                                }
                                .tint(.secondary)
                            }
                        }
                    }

                    // Paddler Information section
                    sectionHeader("PADDLER INFORMATION")

                    VStack(spacing: 0) {
                        fieldRow {
                            HStack {
                                Text("Select Birthdate")
                                Spacer()
                                DatePicker("", selection: $birthdate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                        }
                        Divider().padding(.leading, 16)
                        fieldRow {
                            HStack {
                                Text("Gender")
                                Spacer()
                                Picker("", selection: $gender) {
                                    ForEach(genderOptions, id: \.self) { Text($0) }
                                }
                                .tint(.secondary)
                            }
                        }
                        Divider().padding(.leading, 16)
                        fieldRow {
                            HStack {
                                Text("Weight (lbs)")
                                Spacer()
                                TextField("lbs", text: $weight)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                            }
                        }
                    }

                    Text("Used to calculate load size recommendations.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveProfile() }
                        .foregroundColor(Theme.primaryBlue)
                        .fontWeight(.semibold)
                        .disabled(isSaving)
                }
            }
        }
        .onAppear { loadProfile() }
    }

    private func saveProfile() {
        isSaving = true
        let profileData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "bio": bio,
            "city": city,
            "state": state,
            "primaryCraft": primaryCraft,
            "birthdate": birthdate.timeIntervalSince1970,
            "gender": gender,
            "weight": weight
        ]

        // Update Firebase Auth display name
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        changeRequest?.commitChanges { _ in }

        Task {
            try? await firestoreService.saveUserProfile(profileData)
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        }
    }

    private func loadProfile() {
        let parts = (authManager.user?.displayName ?? "").split(separator: " ", maxSplits: 1)
        firstName = parts.first.map(String.init) ?? ""
        lastName = parts.count > 1 ? String(parts[1]) : ""

        Task {
            if let profile = try? await firestoreService.fetchUserProfile() {
                await MainActor.run {
                    bio = profile["bio"] as? String ?? ""
                    city = profile["city"] as? String ?? ""
                    state = profile["state"] as? String ?? ""
                    primaryCraft = profile["primaryCraft"] as? String ?? "Raft"
                    gender = profile["gender"] as? String ?? "Prefer not to say"
                    weight = profile["weight"] as? String ?? ""
                    if let ts = profile["birthdate"] as? TimeInterval {
                        birthdate = Date(timeIntervalSince1970: ts)
                    }
                }
            }
        }
    }

    private func fieldRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
    }
}
