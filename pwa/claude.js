// Appel direct de l'API Claude (vision) depuis le navigateur.
// La clé API est stockée localement (localStorage) — usage personnel/familial.

const NUTRIENT_SCHEMA = `{
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
}`;

function systemPrompt(mode) {
  if (mode === "label") {
    return "Tu lis une étiquette nutritionnelle (valeurs officielles imprimées). " +
      "Reporte fidèlement les valeurs affichées pour la portion indiquée sur l'étiquette. " +
      "Réponds UNIQUEMENT avec un objet JSON valide, sans texte autour, sans balises Markdown.";
  }
  return "Tu es un nutritionniste expert. À partir d'une photo de repas, tu estimes " +
    "le contenu de l'assiette. Estime les portions en grammes de façon réaliste. " +
    "Réponds UNIQUEMENT avec un objet JSON valide, sans texte autour, sans balises Markdown.";
}

function userPrompt(mode, hint) {
  const base = mode === "label"
    ? "Lis l'étiquette et renvoie les valeurs POUR LA PORTION indiquée sur l'emballage."
    : "Identifie chaque aliment visible et estime ses valeurs nutritionnelles POUR LA PORTION visible (pas pour 100 g).";
  const hintLine = hint ? `\nInformation fournie par l'utilisateur : ${hint}` : "";
  return `${base}${hintLine}\n\nRéponds avec ce schéma JSON exact :\n${NUTRIENT_SCHEMA}`;
}

// dataURL -> { media_type, base64 }
function parseDataURL(dataURL) {
  const m = /^data:(image\/[a-zA-Z+]+);base64,(.*)$/.exec(dataURL);
  if (!m) throw new Error("Image invalide.");
  return { media_type: m[1], base64: m[2] };
}

export async function analyze(imageDataURL, mode, hint, { apiKey, model }) {
  if (!apiKey) throw new Error("Aucune clé API Claude. Ajoutez-la dans Réglages.");
  const { media_type, base64 } = parseDataURL(imageDataURL);

  const body = {
    model: model || "claude-sonnet-5",
    max_tokens: 1500,
    system: systemPrompt(mode),
    messages: [{
      role: "user",
      content: [
        { type: "image", source: { type: "base64", media_type, data: base64 } },
        { type: "text", text: userPrompt(mode, hint) }
      ]
    }]
  };

  let res;
  try {
    res = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
        "anthropic-dangerous-direct-browser-access": "true"
      },
      body: JSON.stringify(body)
    });
  } catch (e) {
    throw new Error("Problème de connexion : " + e.message);
  }

  if (!res.ok) {
    let msg = "Code " + res.status;
    try { const j = await res.json(); if (j.error && j.error.message) msg = j.error.message; } catch {}
    throw new Error("Erreur API Claude : " + msg);
  }

  const data = await res.json();
  const text = (data.content || [])
    .filter(b => b.type === "text").map(b => b.text).join("");
  if (!text) throw new Error("Réponse vide de Claude.");

  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start < 0 || end < 0) throw new Error("Aucun JSON dans la réponse.");
  let parsed;
  try { parsed = JSON.parse(text.slice(start, end + 1)); }
  catch (e) { throw new Error("Réponse illisible : " + e.message); }

  const items = (parsed.items || []).map(it => ({
    name: it.name || "Aliment",
    quantityG: num(it.quantity_g),
    calories: num(it.calories),
    protein: num(it.protein_g),
    carbs: num(it.carbs_g),
    fat: num(it.fat_g),
    fiber: num(it.fiber_g),
    sugar: num(it.sugar_g),
    sodium: num(it.sodium_mg),
    calcium: num(it.calcium_mg)
  }));
  return { items, confidence: parsed.confidence ?? null, notes: parsed.notes || "" };
}

function num(v) { const n = Number(v); return isFinite(n) ? n : 0; }
