import SwiftUI
import SwiftData

struct HistoryView: View {
    @EnvironmentObject private var goalsStore: GoalsStore
    @Query(sort: \Meal.date, order: .reverse) private var allMeals: [Meal]

    private struct DaySummary: Identifiable {
        let id: Date
        let date: Date
        let total: Nutrition
        let mealCount: Int
    }

    private var days: [DaySummary] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: allMeals) { cal.startOfDay(for: $0.date) }
        return grouped
            .map { key, meals in
                DaySummary(id: key, date: key,
                           total: Nutrition.sum(meals.map(\.total)),
                           mealCount: meals.count)
            }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            Group {
                if days.isEmpty {
                    ContentUnavailableView(
                        "Pas encore d'historique",
                        systemImage: "chart.bar",
                        description: Text("Vos journées apparaîtront ici au fur et à mesure.")
                    )
                } else {
                    List(days) { day in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(Fmt.dayTitle(day.date)).font(.headline)
                                Spacer()
                                Text(Fmt.kcal(day.total.calories))
                                    .font(.subheadline.weight(.semibold))
                            }
                            MacroBar(
                                title: "vs objectif",
                                consumed: day.total.calories,
                                goal: goalsStore.goals.calories,
                                unit: "kcal",
                                color: .accentColor
                            )
                            Text("\(day.mealCount) repas · P \(Fmt.n(day.total.proteinG))g · G \(Fmt.n(day.total.carbsG))g · L \(Fmt.n(day.total.fatG))g")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Historique")
        }
    }
}
