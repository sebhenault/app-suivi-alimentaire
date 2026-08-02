import SwiftUI

struct SettingsView: View {
    @AppStorage("claudeModel") private var model: String = "claude-sonnet-5"
    @State private var apiKey: String = ""
    @State private var hasKey: Bool = KeychainStore.hasAPIKey
    @State private var saved = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if hasKey {
                        Label("Clé API enregistrée", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Button(role: .destructive) {
                            KeychainStore.deleteAPIKey()
                            hasKey = false
                            apiKey = ""
                        } label: {
                            Label("Supprimer la clé", systemImage: "trash")
                        }
                    } else {
                        SecureField("sk-ant-...", text: $apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button("Enregistrer la clé") {
                            KeychainStore.saveAPIKey(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
                            hasKey = KeychainStore.hasAPIKey
                            apiKey = ""
                            saved = true
                        }
                        .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } header: {
                    Text("Clé API Claude")
                } footer: {
                    Text("Saisie une seule fois, stockée dans le Keychain de l'iPhone. Créez une clé sur console.anthropic.com. Aucune connexion requise ensuite.")
                }

                Section {
                    Picker("Modèle", selection: $model) {
                        Text("Sonnet (équilibré)").tag("claude-sonnet-5")
                        Text("Opus (plus précis)").tag("claude-opus-5")
                        Text("Haiku (plus rapide/éco)").tag("claude-haiku-4-5-20251001")
                    }
                } header: {
                    Text("Modèle d'analyse")
                } footer: {
                    Text("Sonnet est un bon compromis qualité/coût pour l'estimation de repas.")
                }

                Section("À propos") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion).foregroundStyle(.secondary)
                    }
                    Text("Vos données (journal, photos, objectifs) restent sur votre iPhone. Seules les photos que vous analysez sont envoyées à l'API Claude, uniquement au moment de l'analyse.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Réglages")
            .alert("Clé enregistrée", isPresented: $saved) {
                Button("OK") {}
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }
}
