import Foundation

/// Ce que l'utilisateur photographie, ce qui change les consignes envoyées à Claude.
enum AnalysisMode: String, CaseIterable, Identifiable {
    case plate   // photo d'un plat -> estimation
    case label   // photo d'une étiquette nutritionnelle -> lecture précise

    var id: String { rawValue }

    var label: String {
        switch self {
        case .plate: return "Plat"
        case .label: return "Étiquette"
        }
    }

    var systemImage: String {
        switch self {
        case .plate: return "fork.knife"
        case .label: return "tag.fill"
        }
    }
}
