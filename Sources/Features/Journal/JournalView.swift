import SwiftUI
import SwiftData

struct JournalView: View {
    @EnvironmentObject private var goalsStore: GoalsStore
    @Environment(\.modelContext) private var context
    @Query(sort: \Meal.date, order: .reverse) private var allMeals: [Meal]

    @State private var showAdd = false

    private var todayMeals: [Meal] {
        allMeals.filter { Calendar.current.isDateInToday($0.date) }
    }

    private var total: Nutrition {
        Nutrition.sum(todayMeals.map(\.total))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    summaryCard
                    if todayMeals.isEmpty {
                        emptyState
                    } else {
                        mealsList
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Aujourd'hui")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "camera.fill")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddMealView()
            }
        }
    }

    private var goals: DailyGoals { goalsStore.goals }

    private var summaryCard: some View {
        VStack(spacing: 18) {
            CalorieRing(consumed: total.calories, goal: goals.calories)
            VStack(spacing: 12) {
                MacroBar(title: "Protéines", consumed: total.proteinG, goal: goals.proteinG, unit: "g", color: .blue)
                MacroBar(title: "Glucides", consumed: total.carbsG, goal: goals.carbsG, unit: "g", color: .green)
                MacroBar(title: "Lipides", consumed: total.fatG, goal: goals.fatG, unit: "g", color: .yellow)
                MacroBar(title: "Fibres", consumed: total.fiberG, goal: goals.fiberG, unit: "g", color: .brown)
                MacroBar(title: "Sucres", consumed: total.sugarG, goal: goals.sugarG, unit: "g", color: .pink, isLimit: true)
                MacroBar(title: "Sodium", consumed: total.sodiumMg, goal: goals.sodiumMg, unit: "mg", color: .red, isLimit: true)
                MacroBar(title: "Calcium", consumed: total.calciumMg, goal: goals.calciumMg, unit: "mg", color: .teal)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private var mealsList: some View {
        VStack(spacing: 12) {
            ForEach(todayMeals) { meal in
                NavigationLink {
                    MealDetailView(meal: meal)
                } label: {
                    MealRow(meal: meal)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Aucun repas aujourd'hui")
                .font(.headline)
            Text("Touchez l'appareil photo en haut à droite pour ajouter votre premier repas.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showAdd = true
            } label: {
                Label("Ajouter un repas", systemImage: "plus")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct MealRow: View {
    let meal: Meal

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 3) {
                Text(meal.title)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Label(meal.type.label, systemImage: meal.type.systemImage)
                    Text("·")
                    Text(Fmt.time(meal.date))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Text(Fmt.kcal(meal.total.calories))
                .font(.subheadline.weight(.semibold))
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder private var thumbnail: some View {
        if let data = meal.imageData, let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.accentColor.opacity(0.15))
                .frame(width: 52, height: 52)
                .overlay(Image(systemName: meal.type.systemImage).foregroundStyle(.accent))
        }
    }
}
