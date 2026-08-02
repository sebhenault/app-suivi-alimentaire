import Foundation

/// Valeurs nutritionnelles pour un aliment ou un total de repas / journée.
/// Sert à la fois au décodage de la réponse de Claude et à l'affichage.
struct Nutrition: Codable, Equatable {
    var calories: Double = 0
    var proteinG: Double = 0
    var carbsG: Double = 0
    var fatG: Double = 0
    var fiberG: Double = 0
    var sugarG: Double = 0
    var sodiumMg: Double = 0
    var calciumMg: Double = 0

    static let zero = Nutrition()

    static func + (lhs: Nutrition, rhs: Nutrition) -> Nutrition {
        Nutrition(
            calories: lhs.calories + rhs.calories,
            proteinG: lhs.proteinG + rhs.proteinG,
            carbsG: lhs.carbsG + rhs.carbsG,
            fatG: lhs.fatG + rhs.fatG,
            fiberG: lhs.fiberG + rhs.fiberG,
            sugarG: lhs.sugarG + rhs.sugarG,
            sodiumMg: lhs.sodiumMg + rhs.sodiumMg,
            calciumMg: lhs.calciumMg + rhs.calciumMg
        )
    }

    static func sum(_ values: [Nutrition]) -> Nutrition {
        values.reduce(.zero, +)
    }
}
