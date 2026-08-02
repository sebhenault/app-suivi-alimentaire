import Foundation
import SwiftData

/// Un aliment individuel à l'intérieur d'un repas (ex. « riz », « poulet grillé »).
@Model
final class FoodItem {
    var name: String
    var quantityG: Double

    // Valeurs nutritionnelles pour la quantité indiquée (pas pour 100 g).
    var calories: Double
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var fiberG: Double
    var sugarG: Double
    var sodiumMg: Double
    var calciumMg: Double

    var meal: Meal?

    init(
        name: String,
        quantityG: Double = 0,
        nutrition: Nutrition = .zero
    ) {
        self.name = name
        self.quantityG = quantityG
        self.calories = nutrition.calories
        self.proteinG = nutrition.proteinG
        self.carbsG = nutrition.carbsG
        self.fatG = nutrition.fatG
        self.fiberG = nutrition.fiberG
        self.sugarG = nutrition.sugarG
        self.sodiumMg = nutrition.sodiumMg
        self.calciumMg = nutrition.calciumMg
    }

    var nutrition: Nutrition {
        get {
            Nutrition(
                calories: calories, proteinG: proteinG, carbsG: carbsG,
                fatG: fatG, fiberG: fiberG, sugarG: sugarG,
                sodiumMg: sodiumMg, calciumMg: calciumMg
            )
        }
        set {
            calories = newValue.calories
            proteinG = newValue.proteinG
            carbsG = newValue.carbsG
            fatG = newValue.fatG
            fiberG = newValue.fiberG
            sugarG = newValue.sugarG
            sodiumMg = newValue.sodiumMg
            calciumMg = newValue.calciumMg
        }
    }
}
