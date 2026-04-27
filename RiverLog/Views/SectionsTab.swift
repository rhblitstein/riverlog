import SwiftUI

struct SectionsTab: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "map")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)

                Text("Sections")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Coming Soon")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("Browse and discover river sections.\nSearch, filter, and check conditions.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
            }
            .navigationTitle("Sections")
        }
    }
}
