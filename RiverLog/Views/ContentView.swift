import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: RiverActivity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \RiverActivity.date, ascending: false)]
    ) private var activities: FetchedResults<RiverActivity>
    
    @State private var showingAddActivity = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(activities, id: \.id) { activity in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(activity.title ?? "Untitled")
                            .font(.headline)
                        Text("\(activity.sectionName ?? "") - \(activity.craftType ?? "")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if let date = activity.date {
                            Text(date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("River Log")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addActivity) {
                        Label("Add Activity", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddActivity) {
                AddActivityView()
            }
        }
    }
    
    private func addActivity() {
        showingAddActivity = true
    }
}
