# MonAssiette 🍽️

Application iPhone **native** (SwiftUI) de suivi alimentaire par photo, pour usage
personnel et familial. On photographie un repas, l'IA (API Claude) estime les
valeurs nutritionnelles, on ajuste, et tout est enregistré dans un journal comparé
à ses objectifs quotidiens.

- **Native**, pas une page web : vraie app installée via Xcode.
- **Hors-ligne** pour tout sauf l'analyse d'une nouvelle photo (qui nécessite Internet).
- **Sans compte** : la clé API Claude est saisie une seule fois et stockée dans le Keychain.
- **Trois modes de saisie** : photo d'un plat (estimation), photo d'étiquette (lecture
  précise), saisie manuelle (recette / aliment connu).

## Fonctionnalités (MVP actuel)

- 📷 Prise de photo (appareil ou galerie) et analyse par l'API Claude.
- 🧮 Estimation calories + macros (protéines, glucides, lipides, fibres, sucres)
  + micronutriments (sodium, calcium), éditable avant enregistrement.
- 📓 Journal du jour avec anneau de calories et barres de progression vs objectifs.
- 📊 Historique par journée.
- 🎯 Objectifs quotidiens personnalisables.
- 🔐 Clé API stockée dans le Keychain, données locales sur l'appareil.

## Prérequis

- Un **Mac** avec **Xcode 15+**.
  - Sur **macOS Ventura (13)**, installez **Xcode 15.2** (dernier compatible Ventura,
    SDK iOS 17.2 — SwiftData inclus) depuis
    [developer.apple.com/download/all](https://developer.apple.com/download/all/),
    pas depuis le Mac App Store.
  - iPhone en **iOS 18** + Xcode 15.2 : si Xcode affiche *« device support files
    not found »*, ajoutez les fichiers *DeviceSupport* d'iOS 18 (procédure fournie sur demande).
- Un **compte développeur Apple** (pour installer sur l'iPhone au-delà de 7 jours).
- Une **clé API Claude** : https://console.anthropic.com → *API Keys*.
- **XcodeGen** (génère le projet Xcode à partir de `project.yml`) :
  ```bash
  brew install xcodegen
  ```

## Démarrage

```bash
# 1. Récupérer le projet
git clone <votre-repo>
cd app-suivi-alimentaire

# 2. Générer le projet Xcode
xcodegen generate

# 3. Ouvrir dans Xcode
open MonAssiette.xcodeproj
```

Dans Xcode :

1. Sélectionnez la cible **MonAssiette** → onglet **Signing & Capabilities**.
2. Choisissez votre **Team** (compte Apple). Le *bundle identifier*
   (`com.henault.monassiette`) peut être modifié si besoin.
3. Branchez l'iPhone, sélectionnez-le comme destination, puis **Run** (⌘R).
4. Sur l'iPhone : *Réglages → Général → VPN et gestion de l'appareil* → faites
   confiance à votre profil développeur (première installation seulement).

À la première ouverture, allez dans l'onglet **Réglages** de l'app et collez votre
clé API Claude. C'est tout : plus aucune connexion demandée ensuite.

## Structure du code

```
project.yml                 Définition du projet (XcodeGen)
Resources/                  Info.plist, Assets (icône, couleur d'accent)
Sources/
  App/                      Point d'entrée + navigation (onglets)
  Models/                   SwiftData : Meal, FoodItem + Nutrition, DailyGoals
  Services/                 ClaudeVisionService (API), KeychainStore
  Features/
    Journal/                Journal du jour + détail d'un repas
    AddMeal/                Capture photo, analyse, édition, enregistrement
    History/                Historique par journée
    Goals/                  Objectifs quotidiens
    Settings/               Clé API, modèle, à propos
  Design/                   Composants réutilisables (anneau, barres, champs)
```

## Coût d'utilisation

Chaque analyse de photo est un appel à l'API Claude (facturé à l'usage sur votre
compte Anthropic). En pratique, quelques repas par jour représentent typiquement
quelques centimes par jour. Le modèle est réglable dans *Réglages* (Sonnet par
défaut ; Haiku pour réduire le coût, Opus pour plus de précision).

## Feuille de route (prochaines tranches)

- [ ] Lecture d'étiquette optimisée (le mode existe, à affiner).
- [ ] Bibliothèque d'aliments/recettes réutilisables (saisie ultra-rapide).
- [ ] Graphiques d'historique (Swift Charts) et moyennes hebdomadaires.
- [ ] Profils multiples pour la famille.
- [ ] Rappels / widgets.
- [ ] Export des données (CSV).

> ⚠️ Note de sécurité : la clé API réside sur l'appareil. Pour un usage familial
> c'est acceptable. Si vous distribuez l'app plus largement, envisagez un petit
> proxy serveur qui garde la clé côté serveur.
