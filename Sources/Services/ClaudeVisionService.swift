import Foundation
import UIKit

/// Résultat brut décodé depuis la réponse JSON de Claude.
struct AnalysisResult: Codable {
    struct Item: Codable {
        var name: String
        var quantityG: Double
        var nutrition: Nutrition

        enum CodingKeys: String, CodingKey {
            case name
            case quantityG = "quantity_g"
            case calories
            case proteinG = "protein_g"
            case carbsG = "carbs_g"
            case fatG = "fat_g"
            case fiberG = "fiber_g"
            case sugarG = "sugar_g"
            case sodiumMg = "sodium_mg"
            case calciumMg = "calcium_mg"
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            name = try c.decode(String.self, forKey: .name)
            quantityG = (try? c.decode(Double.self, forKey: .quantityG)) ?? 0
            nutrition = Nutrition(
                calories: (try? c.decode(Double.self, forKey: .calories)) ?? 0,
                proteinG: (try? c.decode(Double.self, forKey: .proteinG)) ?? 0,
                carbsG: (try? c.decode(Double.self, forKey: .carbsG)) ?? 0,
                fatG: (try? c.decode(Double.self, forKey: .fatG)) ?? 0,
                fiberG: (try? c.decode(Double.self, forKey: .fiberG)) ?? 0,
                sugarG: (try? c.decode(Double.self, forKey: .sugarG)) ?? 0,
                sodiumMg: (try? c.decode(Double.self, forKey: .sodiumMg)) ?? 0,
                calciumMg: (try? c.decode(Double.self, forKey: .calciumMg)) ?? 0
            )
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(name, forKey: .name)
            try c.encode(quantityG, forKey: .quantityG)
            try c.encode(nutrition.calories, forKey: .calories)
            try c.encode(nutrition.proteinG, forKey: .proteinG)
            try c.encode(nutrition.carbsG, forKey: .carbsG)
            try c.encode(nutrition.fatG, forKey: .fatG)
            try c.encode(nutrition.fiberG, forKey: .fiberG)
            try c.encode(nutrition.sugarG, forKey: .sugarG)
            try c.encode(nutrition.sodiumMg, forKey: .sodiumMg)
            try c.encode(nutrition.calciumMg, forKey: .calciumMg)
        }
    }

    var items: [Item]
    var confidence: Double?
    var notes: String?
}

enum AnalysisError: LocalizedError {
    case missingAPIKey
    case badImage
    case network(String)
    case api(String)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Aucune clé API Claude enregistrée. Ajoutez-la dans Réglages."
        case .badImage:
            return "Image invalide."
        case .network(let m):
            return "Problème de connexion : \(m)"
        case .api(let m):
            return "Erreur de l'API Claude : \(m)"
        case .decoding(let m):
            return "Réponse illisible : \(m)"
        }
    }
}

/// Appelle l'API Claude (messages) avec une image et renvoie l'estimation nutritionnelle.
struct ClaudeVisionService {
    var apiKey: String?
    var model: String

    init(apiKey: String? = KeychainStore.loadAPIKey(),
         model: String = UserDefaults.standard.string(forKey: "claudeModel") ?? "claude-sonnet-5") {
        self.apiKey = apiKey
        self.model = model
    }

    func analyze(image: UIImage, mode: AnalysisMode, hint: String = "") async throws -> AnalysisResult {
        guard let apiKey, !apiKey.isEmpty else { throw AnalysisError.missingAPIKey }
        guard let jpeg = image.resizedForUpload().jpegData(compressionQuality: 0.7) else {
            throw AnalysisError.badImage
        }
        let base64 = jpeg.base64EncodedString()

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1500,
            "system": Self.systemPrompt(for: mode),
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "image",
                     "source": ["type": "base64", "media_type": "image/jpeg", "data": base64]],
                    ["type": "text", "text": Self.userPrompt(for: mode, hint: hint)]
                ]
            ]]
        ]

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 60

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AnalysisError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AnalysisError.network("Réponse inattendue.")
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = Self.extractAPIError(from: data) ?? "Code \(http.statusCode)"
            throw AnalysisError.api(message)
        }

        let text = try Self.extractText(from: data)
        return try Self.decodeResult(from: text)
    }

    // MARK: - Prompts

    private static func systemPrompt(for mode: AnalysisMode) -> String {
        switch mode {
        case .plate:
            return """
            Tu es un nutritionniste expert. À partir d'une photo de repas, tu estimes \
            le contenu de l'assiette. Estime les portions en grammes de façon réaliste. \
            Réponds UNIQUEMENT avec un objet JSON valide, sans texte autour, sans balises Markdown.
            """
        case .label:
            return """
            Tu lis une étiquette nutritionnelle (valeurs officielles imprimées). \
            Reporte fidèlement les valeurs affichées pour la portion indiquée sur l'étiquette. \
            Réponds UNIQUEMENT avec un objet JSON valide, sans texte autour, sans balises Markdown.
            """
        }
    }

    private static func userPrompt(for mode: AnalysisMode, hint: String) -> String {
        let schema = """
        {
          "items": [
            {
              "name": "nom de l'aliment en français",
              "quantity_g": nombre,
              "calories": nombre (kcal),
              "protein_g": nombre,
              "carbs_g": nombre,
              "fat_g": nombre,
              "fiber_g": nombre,
              "sugar_g": nombre,
              "sodium_mg": nombre,
              "calcium_mg": nombre
            }
          ],
          "confidence": nombre entre 0 et 1,
          "notes": "brève remarque (hypothèses de portion, incertitudes)"
        }
        """
        let base: String
        switch mode {
        case .plate:
            base = "Identifie chaque aliment visible et estime ses valeurs nutritionnelles POUR LA PORTION visible (pas pour 100 g)."
        case .label:
            base = "Lis l'étiquette et renvoie les valeurs POUR LA PORTION indiquée sur l'emballage."
        }
        let hintLine = hint.isEmpty ? "" : "\nInformation fournie par l'utilisateur : \(hint)"
        return "\(base)\(hintLine)\n\nRéponds avec ce schéma JSON exact :\n\(schema)"
    }

    // MARK: - Décodage réponse Anthropic

    private static func extractText(from data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]] else {
            throw AnalysisError.decoding("Structure de réponse inattendue.")
        }
        let text = content.compactMap { block -> String? in
            (block["type"] as? String) == "text" ? block["text"] as? String : nil
        }.joined()
        guard !text.isEmpty else { throw AnalysisError.decoding("Réponse vide.") }
        return text
    }

    private static func decodeResult(from text: String) throws -> AnalysisResult {
        // Claude peut parfois entourer le JSON ; on isole le premier objet { ... }.
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") else {
            throw AnalysisError.decoding("Aucun JSON trouvé dans la réponse.")
        }
        let jsonSlice = String(text[start...end])
        guard let jsonData = jsonSlice.data(using: .utf8) else {
            throw AnalysisError.decoding("Encodage JSON invalide.")
        }
        do {
            return try JSONDecoder().decode(AnalysisResult.self, from: jsonData)
        } catch {
            throw AnalysisError.decoding(error.localizedDescription)
        }
    }

    private static func extractAPIError(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = json["error"] as? [String: Any],
              let message = error["message"] as? String else {
            return nil
        }
        return message
    }
}

private extension UIImage {
    /// Réduit l'image pour limiter la taille d'upload (max 1280 px sur le grand côté).
    func resizedForUpload(maxDimension: CGFloat = 1280) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
