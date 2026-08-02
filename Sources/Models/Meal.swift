import Foundation
import SwiftData

/// Un repas enregistré au journal : une photo (optionnelle) + une liste d'aliments.
@Model
final class Meal {
    var date: Date
    var typeRaw: String
    var note: String
    var imageData: Data?
    /// Confiance de l'estimation IA entre 0 et 1 (nil si saisie manuelle).
    var confidence: Double?

    @Relationship(deleteRule: .cascade, inverse: \FoodItem.meal)
    var items: [FoodItem] = []

    init(
        date: Date = Date(),
        type: MealType = .snack,
        note: String = "",
        imageData: Data? = nil,
        confidence: Double? = nil
    ) {
        self.date = date
        self.typeRaw = type.rawValue
        self.note = note
        self.imageData = imageData
        self.confidence = confidence
    }

    var type: MealType {
        get { MealType(rawValue: typeRaw) ?? .snack }
        set { typeRaw = newValue.rawValue }
    }

    var total: Nutrition {
        Nutrition.sum(items.map(\.nutrition))
    }

    var title: String {
        if !note.isEmpty { return note }
        if let first = items.first?.name {
            return items.count > 1 ? "\(first) +\(items.count - 1)" : first
        }
        return type.label
    }
}
