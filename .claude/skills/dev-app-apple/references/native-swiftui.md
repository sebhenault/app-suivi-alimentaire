# App native SwiftUI (iOS 17+)

Exemple vivant : dossier `Sources/` de ce dépôt (app MonAssiette). Cible iOS 17,
SwiftUI + SwiftData. Adapter la cible/les technos selon la matrice de compatibilité
(voir `distribution.md`) — sous Xcode 14 ou moins, remplacer SwiftData par Core Data.

## Structure recommandée

```
Sources/
  App/        Point d'entrée (@main App) + navigation (TabView)
  Models/     @Model SwiftData + structs (ex. Nutrition, objectifs)
  Services/   Appels réseau (API), stockage sécurisé (Keychain)
  Features/   Un dossier par écran/fonction (Journal, AddMeal, …)
  Design/     Composants et helpers réutilisables (formatage, champs)
Resources/    Info.plist, Assets.xcassets (icône, AccentColor)
```

Isoler la couche stockage dans `Models/` : si un jour il faut descendre de SwiftData à
Core Data (Xcode ancien), seul ce dossier change, pas toute l'app.

## SwiftData en bref

- `@Model final class Meal { … }`, relations avec
  `@Relationship(deleteRule: .cascade, inverse: \FoodItem.meal)`.
- Enum stockée via une propriété `typeRaw: String` + accès calculé typé.
- Requêtes : `@Query(sort: \Meal.date, order: .reverse)`. Filtrer « aujourd'hui » en
  mémoire pour un petit dataset perso est acceptable.
- Conteneur : `.modelContainer(for: [Meal.self, FoodItem.self])` sur la `WindowGroup`.

## Clé API stockée dans le Keychain

Voir `Sources/Services/KeychainStore.swift`. Points clés :
- `kSecClassGenericPassword`, service = bundle id, account = nom logique.
- `kSecAttrAccessibleAfterFirstUnlock` pour un accès fiable après déverrouillage.
- Saisie une seule fois dans un écran Réglages, jamais dans le code/dépôt.

## Appel vision à l'API Claude

Voir `Sources/Services/ClaudeVisionService.swift`. Recette :
- `POST https://api.anthropic.com/v1/messages`
- En-têtes : `x-api-key`, `anthropic-version: 2023-06-01`, `content-type: application/json`.
- Corps : `model`, `max_tokens`, `system`, `messages[0].content` = un bloc `image`
  (`source.type = base64`, `media_type`, `data`) + un bloc `text`.
- Redimensionner l'image avant upload (max ~1280 px) pour la latence/le coût.
- Demander une **réponse JSON stricte** (schéma explicite dans le prompt), puis isoler
  le premier objet `{ … }` et décoder. Prévoir des valeurs par défaut (champs manquants).
- Modèle par défaut raisonnable pour la vision : un Sonnet récent (équilibre qualité/coût) ;
  rendre le modèle configurable dans les Réglages.

## Génération du projet Xcode

Deux options selon le confort de l'utilisateur :

1. **XcodeGen** (`project.yml`) — propre et versionnable, mais exige `brew install xcodegen`
   puis `xcodegen generate`. Bon si l'utilisateur est à l'aise avec le terminal.
2. **`.xcodeproj` généré et commité** — pour un utilisateur peu technique : « ouvrir → Run »
   sans installer d'outil. On peut générer un `project.pbxproj` valide par script
   (déterministe : IDs = hash du chemin, `objectVersion = 56`, `compatibilityVersion
   "Xcode 14.0"`), + un schéma partagé (`xcshareddata/xcschemes/…`). ⚠️ Ne PAS utiliser les
   « file system synchronized groups » (Xcode 16 seulement) si la cible est Xcode 15.
   Voir `MonAssiette.xcodeproj/` de ce dépôt comme modèle.

## Info.plist essentiel (GENERATE_INFOPLIST_FILE = NO)

Inclure : `CFBundleDisplayName/Name/Identifier`, `CFBundleExecutable = $(EXECUTABLE_NAME)`,
`CFBundlePackageType = $(PRODUCT_BUNDLE_PACKAGE_TYPE)`, `CFBundleShortVersionString`,
`CFBundleVersion`, `UILaunchScreen`, orientations, et les usages :
`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`. Pour TestFlight, ajouter
`ITSAppUsesNonExemptEncryption = false` (HTTPS standard) pour éviter la question de
conformité export à chaque build. Pour l'auto-incrément du build en CI :
`VERSIONING_SYSTEM = apple-generic` + `agvtool`.

## Icône

Icône marketing 1024×1024 requise (TestFlight/App Store), sans canal alpha. On peut la
générer par script (voir `scripts/make_icon.py`). Caméra indisponible sur simulateur :
masquer le bouton via `UIImagePickerController.isSourceTypeAvailable(.camera)`.

## Écueils de compilation fréquents

- `.foregroundStyle(.accent)` n'existe pas comme ShapeStyle ; utiliser `.tint` ou
  `Color.accentColor`.
- Vérifier la disponibilité des API par version : `ContentUnavailableView`, `@Bindable`,
  `.foregroundStyle` sémantiques = iOS 17.
- Ne pas se fier à `node`/lint pour du Swift ; la vraie validation est un **build simulateur**
  sur le Mac de l'utilisateur. Demander le message d'erreur exact et corriger avec lui.
