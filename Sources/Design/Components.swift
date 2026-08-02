import SwiftUI

/// Anneau de progression (calories du jour vs objectif).
struct CalorieRing: View {
    var consumed: Double
    var goal: Double

    private var progress: Double {
        goal > 0 ? min(consumed / goal, 1.0) : 0
    }
    private var over: Bool { consumed > goal && goal > 0 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 14)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    over ? Color.orange : Color.accentColor,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
            VStack(spacing: 2) {
                Text(Fmt.n(consumed))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("/ \(Fmt.n(goal)) kcal")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if over {
                    Text("dépassé")
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                }
            }
        }
        .frame(width: 150, height: 150)
    }
}

/// Barre d'un macronutriment avec valeur / objectif.
struct MacroBar: View {
    var title: String
    var consumed: Double
    var goal: Double
    var unit: String
    var color: Color
    /// true = objectif à ne pas dépasser (sucre, sodium) -> devient rouge au dépassement.
    var isLimit: Bool = false

    private var progress: Double { goal > 0 ? min(consumed / goal, 1.0) : 0 }
    private var over: Bool { consumed > goal && goal > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.subheadline.weight(.medium))
                Spacer()
                Text("\(Fmt.n(consumed)) / \(Fmt.n(goal)) \(unit)")
                    .font(.caption)
                    .foregroundStyle(over && isLimit ? .red : .secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15))
                    Capsule()
                        .fill(over && isLimit ? Color.red : color)
                        .frame(width: geo.size.width * progress)
                        .animation(.easeOut, value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

/// Petite carte de statistique.
struct StatChip: View {
    var label: String
    var value: String
    var systemImage: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .foregroundStyle(.accent)
            Text(value).font(.headline)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}
