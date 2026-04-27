import SwiftUI

struct GroupsTab: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "person.3")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)

                Text("Groups")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Coming Soon")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("Connect with paddling crews and\ncompanies you work for.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
            }
            .navigationTitle("Groups")
        }
    }
}
