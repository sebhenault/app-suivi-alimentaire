import SwiftUI

struct RootView: View {
    @State private var showAddMeal = false

    var body: some View {
        TabView {
            JournalView()
                .tabItem { Label("Journal", systemImage: "book.pages.fill") }

            HistoryView()
                .tabItem { Label("Historique", systemImage: "chart.bar.fill") }

            GoalsView()
                .tabItem { Label("Objectifs", systemImage: "target") }

            SettingsView()
                .tabItem { Label("Réglages", systemImage: "gearshape.fill") }
        }
        .tint(.accentColor)
    }
}
