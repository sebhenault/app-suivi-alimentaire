import SwiftUI
import SwiftData

@main
struct MonAssietteApp: App {
    @StateObject private var goalsStore = GoalsStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(goalsStore)
        }
        .modelContainer(for: [Meal.self, FoodItem.self])
    }
}
