import SwiftUI
import SwiftData
import UIKit

struct AddMealView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var image: UIImage?
    @State private var mode: AnalysisMode = .plate
    @State private var mealType: MealType = MealType.suggested()
    @State private var hint: String = ""
    @State private var drafts: [DraftItem] = []

    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var confidence: Double?
    @State private var notes: String?

    @State private var showCamera = false
    @State private var showLibrary = false

    private var total: Nutrition { Nutrition.sum(drafts.map(\.nutrition)) }
    private var canSave: Bool { !drafts.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                contextSection
                photoSection
                if !drafts.isEmpty || isAnalyzing {
                    resultSection
                }
            }
            .navigationTitle("Nouveau repas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") { save() }
                        .disabled(!canSave)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera) { image = $0 }
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showLibrary) {
                ImagePicker(sourceType: .photoLibrary) { image = $0 }
            }
            .alert("Analyse impossible", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Sections

    private var contextSection: some View {
        Section {
            Picker("Type de saisie", selection: $mode) {
                ForEach(AnalysisMode.allCases) { m in
                    Label(m.label, systemImage: m.systemImage).tag(m)
                }
            }
            .pickerStyle(.segmented)

            Picker("Repas", selection: $mealType) {
                ForEach(MealType.allCases) { t in
                    Label(t.label, systemImage: t.systemImage).tag(t)
                }
            }
        }
    }

    private var photoSection: some View {
        Section("Photo") {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 220)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 4)
            }

            HStack {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button {
                        showCamera = true
                    } label: {
                        Label("Photo", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
                Button {
                    showLibrary = true
                } label: {
                    Label("Galerie", systemImage: "photo.fill")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)

            TextField("Précisions (facultatif) : « bol de 300 ml », marque…", text: $hint, axis: .vertical)
                .lineLimit(1...3)

            Button {
                analyze()
            } label: {
                if isAnalyzing {
                    HStack { ProgressView(); Text("Analyse en cours…") }
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Analyser avec l'IA", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(image == nil || isAnalyzing)

            Button {
                drafts.append(DraftItem())
            } label: {
                Label("Ajouter un aliment à la main", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var resultSection: some View {
        Section {
            if let confidence {
                HStack {
                    Label("Confiance de l'estimation", systemImage: "gauge.medium")
                    Spacer()
                    Text("\(Int(confidence * 100)) %")
                        .foregroundStyle(confidence < 0.5 ? .orange : .secondary)
                }
                .font(.footnote)
            }
            if let notes, !notes.isEmpty {
                Text(notes)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ForEach($drafts) { $draft in
                ItemEditor(draft: $draft) {
                    drafts.removeAll { $0.id == draft.id }
                }
            }

            HStack {
                Text("Total").font(.headline)
                Spacer()
                Text(Fmt.kcal(total.calories)).font(.headline)
            }
        } header: {
            Text("Aliments (modifiables)")
        } footer: {
            Text("Vérifiez et ajustez avant d'enregistrer. Les valeurs sont pour la portion indiquée.")
        }
    }

    // MARK: - Actions

    private func analyze() {
        guard let image else { return }
        isAnalyzing = true
        errorMessage = nil
        Task {
            do {
                let service = ClaudeVisionService()
                let result = try await service.analyze(image: image, mode: mode, hint: hint)
                await MainActor.run {
                    drafts = result.items.map(DraftItem.init(from:))
                    confidence = result.confidence
                    notes = result.notes
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    isAnalyzing = false
                }
            }
        }
    }

    private func save() {
        let meal = Meal(
            date: Date(),
            type: mealType,
            note: hint,
            imageData: image?.jpegData(compressionQuality: 0.6),
            confidence: confidence
        )
        context.insert(meal)
        for draft in drafts {
            let item = draft.toFoodItem()
            item.meal = meal
            meal.items.append(item)
            context.insert(item)
        }
        dismiss()
    }
}

/// Éditeur d'un aliment : nom, quantité et détails nutritionnels repliables.
struct ItemEditor: View {
    @Binding var draft: DraftItem
    var onDelete: () -> Void

    var body: some View {
        DisclosureGroup {
            NumberField(title: "Quantité", value: $draft.quantityG, unit: "g")
            NumberField(title: "Calories", value: $draft.calories, unit: "kcal")
            NumberField(title: "Protéines", value: $draft.proteinG, unit: "g")
            NumberField(title: "Glucides", value: $draft.carbsG, unit: "g")
            NumberField(title: "Lipides", value: $draft.fatG, unit: "g")
            NumberField(title: "Fibres", value: $draft.fiberG, unit: "g")
            NumberField(title: "Sucres", value: $draft.sugarG, unit: "g")
            NumberField(title: "Sodium", value: $draft.sodiumMg, unit: "mg")
            NumberField(title: "Calcium", value: $draft.calciumMg, unit: "mg")
            Button(role: .destructive, action: onDelete) {
                Label("Supprimer cet aliment", systemImage: "trash")
            }
        } label: {
            HStack {
                TextField("Nom de l'aliment", text: $draft.name)
                    .font(.headline)
                Spacer()
                Text(Fmt.kcal(draft.calories))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
