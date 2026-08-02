import Foundation

/// Objectifs quotidiens de l'utilisateur. Persistés localement (UserDefaults).
struct DailyGoals: Codable, Equatable {
    var calories: Double = 2000
    var proteinG: Double = 100
    var carbsG: Double = 250
    var fatG: Double = 70
    var fiberG: Double = 30
    var sugarG: Double = 50          // limite (à ne pas dépasser)
    var sodiumMg: Double = 2300      // limite (à ne pas dépasser)
    var calciumMg: Double = 1000     // cible à atteindre

    static let `default` = DailyGoals()
}

/// Stocke et publie les objectifs. Simple wrapper UserDefaults + Codable.
@MainActor
final class GoalsStore: ObservableObject {
    private let key = "dailyGoals.v1"

    @Published var goals: DailyGoals {
        didSet { save() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(DailyGoals.self, from: data) {
            goals = decoded
        } else {
            goals = .default
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
