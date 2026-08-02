import SwiftUI

/// Champ numérique décimal compact avec libellé et unité.
struct NumberField: View {
    var title: String
    @Binding var value: Double
    var unit: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            TextField("0", value: $value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 90)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 34, alignment: .leading)
        }
        .font(.subheadline)
    }
}
