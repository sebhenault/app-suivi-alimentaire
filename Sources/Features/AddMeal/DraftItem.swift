import Foundation

/// Un aliment en cours d'édition avant enregistrement (issu de l'IA ou saisi à la main).
struct DraftItem: Identifiable {
    let id = UUID()
    var name: String = ""
    var quantityG: Double = 0
    var calories: Double = 0
    var proteinG: Double = 0
    var carbsG: Double = 0
    var fatG: Double = 0
    var fiberG: Double = 0
    var sugarG: Double = 0
    var sodiumMg: Double = 0
    var calciumMg: Double = 0

    init() {}

    init(from item: AnalysisResult.Item) {
        name = item.name
        quantityG = item.quantityG
        calories = item.nutrition.calories
        proteinG = item.nutrition.proteinG
        carbsG = item.nutrition.carbsG
        fatG = item.nutrition.fatG
        fiberG = item.nutrition.fiberG
        sugarG = item.nutrition.sugarG
        sodiumMg = item.nutrition.sodiumMg
        calciumMg = item.nutrition.calciumMg
    }

    var nutrition: Nutrition {
        Nutrition(
            calories: calories, proteinG: proteinG, carbsG: carbsG,
            fatG: fatG, fiberG: fiberG, sugarG: sugarG,
            sodiumMg: sodiumMg, calciumMg: calciumMg
        )
    }

    func toFoodItem() -> FoodItem {
        FoodItem(name: name.isEmpty ? "Aliment" : name, quantityG: quantityG, nutrition: nutrition)
    }
}
