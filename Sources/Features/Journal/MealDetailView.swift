import SwiftUI
import SwiftData

struct MealDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var meal: Meal

    var body: some View {
        Form {
            if let data = meal.imageData, let ui = UIImage(data: data) {
                Section {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .listRowInsets(EdgeInsets())
                }
            }

            Section {
                Picker("Repas", selection: $meal.type) {
                    ForEach(MealType.allCases) { t in
                        Label(t.label, systemImage: t.systemImage).tag(t)
                    }
                }
                TextField("Note", text: $meal.note)
            }

            Section("Aliments") {
                ForEach(meal.items) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name).font(.subheadline.weight(.medium))
                            Text("\(Fmt.g(item.quantityG)) · P \(Fmt.n(item.proteinG)) · G \(Fmt.n(item.carbsG)) · L \(Fmt.n(item.fatG))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(Fmt.kcal(item.calories)).font(.subheadline)
                    }
                }
            }

            Section("Total") {
                labeled("Calories", Fmt.kcal(meal.total.calories))
                labeled("Protéines", Fmt.g(meal.total.proteinG))
                labeled("Glucides", Fmt.g(meal.total.carbsG))
                labeled("Lipides", Fmt.g(meal.total.fatG))
                labeled("Fibres", Fmt.g(meal.total.fiberG))
                labeled("Sucres", Fmt.g(meal.total.sugarG))
                labeled("Sodium", Fmt.mg(meal.total.sodiumMg))
                labeled("Calcium", Fmt.mg(meal.total.calciumMg))
            }

            Section {
                Button(role: .destructive) {
                    context.delete(meal)
                    dismiss()
                } label: {
                    Label("Supprimer ce repas", systemImage: "trash")
                }
            }
        }
        .navigationTitle(Fmt.time(meal.date))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func labeled(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.subheadline)
    }
}
