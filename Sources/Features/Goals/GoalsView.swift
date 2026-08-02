import SwiftUI

struct GoalsView: View {
    @EnvironmentObject private var goalsStore: GoalsStore

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NumberField(title: "Calories", value: binding(\.calories), unit: "kcal")
                } header: {
                    Text("Énergie")
                } footer: {
                    Text("Objectif quotidien d'apport calorique.")
                }

                Section("Macronutriments (cibles)") {
                    NumberField(title: "Protéines", value: binding(\.proteinG), unit: "g")
                    NumberField(title: "Glucides", value: binding(\.carbsG), unit: "g")
                    NumberField(title: "Lipides", value: binding(\.fatG), unit: "g")
                    NumberField(title: "Fibres", value: binding(\.fiberG), unit: "g")
                }

                Section {
                    NumberField(title: "Sucres", value: binding(\.sugarG), unit: "g")
                    NumberField(title: "Sodium", value: binding(\.sodiumMg), unit: "mg")
                } header: {
                    Text("Limites à ne pas dépasser")
                } footer: {
                    Text("Ces valeurs deviennent rouges dans le journal quand elles sont dépassées.")
                }

                Section("Micronutriments (cibles)") {
                    NumberField(title: "Calcium", value: binding(\.calciumMg), unit: "mg")
                }

                Section {
                    Button("Réinitialiser les valeurs par défaut") {
                        goalsStore.goals = .default
                    }
                }
            }
            .navigationTitle("Objectifs")
        }
    }

    private func binding(_ keyPath: WritableKeyPath<DailyGoals, Double>) -> Binding<Double> {
        Binding(
            get: { goalsStore.goals[keyPath: keyPath] },
            set: { goalsStore.goals[keyPath: keyPath] = $0 }
        )
    }
}
