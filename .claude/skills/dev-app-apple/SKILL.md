---
name: dev-app-apple
description: >-
  Aide à concevoir, construire et distribuer une application iPhone/iOS pour un usage
  personnel ou familial — application NATIVE (SwiftUI/SwiftData) OU application web
  installable (PWA). Couvre le choix de l'approche, la compatibilité Xcode/macOS/iOS,
  la génération de projet Xcode, et toutes les voies d'installation sur un iPhone sans
  App Store (câble, TestFlight via Mac, TestFlight via build cloud Codemagic, PWA sur
  GitHub Pages avec QR code). Utiliser ce skill dès que l'utilisateur veut créer,
  développer, compiler ou déployer une app iPhone ; installer une app sur son iPhone
  ou celui de sa famille ; choisir entre app native et PWA ; contourner un Mac trop
  vieux ou l'absence de Mac ; gérer une clé API (ex. Claude) dans une app perso ; ou
  publier une app sans passer par l'App Store. Trigger aussi sur : iOS app, iPhone app,
  application iPhone, app native, SwiftUI, Xcode, TestFlight, PWA, « installer sur iPhone »,
  Codemagic, GitHub Pages — même si le mot « Apple » n'est pas prononcé.
---

# Développement d'app Apple (usage personnel / familial)

Ce skill capture une méthode éprouvée pour amener une idée d'app iPhone jusqu'à une
installation réelle sur le téléphone, **sans supposer** que l'utilisateur possède le
dernier Mac ni un compte payant. Il a été semé à partir d'un vrai projet — **MonAssiette**,
une app de suivi alimentaire par photo (analyse via l'API Claude) — dont le code sert
d'exemple vivant dans ce dépôt.

Le piège classique est de foncer sur « app native SwiftUI » puis de se heurter, des heures
plus tard, à un mur d'installation (Mac trop vieux, iPhone trop récent, compte Apple absent).
**La contrainte qui décide de tout, c'est la distribution — traitez-la en premier.**

## Étape 0 — Cadrer AVANT de coder

Avant d'écrire la moindre ligne, établissez ces faits. Ils déterminent l'architecture,
pas l'inverse.

1. **Usage** : perso/famille seulement, ou diffusion large ? (Ici : perso/famille.)
2. **Natif exigé, ou une app web installable suffit ?** Beaucoup d'utilisateurs disent
   « pas une page web » en pensant à un simple marque-page. Une **PWA** moderne s'installe
   sur l'écran d'accueil, tourne en plein écran et fonctionne hors-ligne — souvent, c'est
   exactement ce qu'ils veulent, en gratuit et sans Mac.
3. **Mac disponible ?** Si oui, **quelle version de macOS** (fixe le Xcode maximal) ?
4. **iPhone : quelle version d'iOS ?** (Détermine si un Xcode ancien peut installer par câble.)
5. **Compte Apple Developer (99 $/an) ?** Actif, prêt à payer, ou refus catégorique ?
6. **Fonctions nécessitant Internet** (ex. analyse IA d'une photo) vs. ce qui doit marcher
   hors-ligne (journal, réglages, consultation).

Posez ces questions explicitement (l'outil de questions à choix est idéal). N'inventez pas
les réponses. Une seule d'entre elles (ex. « iPhone en iOS 26, Mac bloqué en Ventura »)
peut invalider toute une approche.

## Étape 1 — Choisir la voie de distribution

C'est le cœur du skill. Voir **`references/distribution.md`** pour le détail complet, la
matrice de compatibilité et les recettes. Résumé décisionnel :

| Situation | Voie recommandée |
|---|---|
| Veut du natif, Mac récent, iPhone compatible avec ce Xcode | Xcode → **câble** (le plus simple) |
| Veut du natif, a un Mac (même ancien), compte Apple OK | Xcode → **archive → TestFlight** |
| Veut du natif, **pas** de Mac (ou Mac trop vieux pour l'iPhone), compte Apple OK | **Codemagic (build cloud) → TestFlight** |
| Veut **gratuit / sans Mac / sans compte Apple**, web installable accepté | **PWA → GitHub Pages** (QR d'installation) |

Insights à retenir (et à expliquer à l'utilisateur, car contre-intuitifs) :

- **Un vieux Xcode ne peut pas installer par CÂBLE sur un iPhone bien plus récent**
  (fichiers « DeviceSupport » manquants), **MAIS** ce même Xcode peut très bien
  **archiver et envoyer sur TestFlight** — l'install TestFlight ne vérifie pas le SDK
  contre la version d'iOS de l'appareil (compatibilité ascendante). Donc « iPhone trop
  récent » ne force **pas** l'achat d'un nouveau Mac.
- **Compiler une app iOS native exige macOS quelque part.** Sans Mac, ce macOS est
  **dans le cloud** (Codemagic/Xcode Cloud). Vous (l'assistant, souvent sous Linux) ne
  pouvez pas produire de `.ipa` localement — soyez honnête là-dessus.
- **Installer une app native sur un vrai iPhone via lien/QR (TestFlight) exige le compte
  Apple à 99 $/an.** Il n'existe aucun contournement gratuit compatible avec « sans Mac +
  install par QR ». La seule voie vraiment gratuite et sans compte est la **PWA**.

## Étape 2 — Construire

Selon la voie :

- **Native SwiftUI** → voir **`references/native-swiftui.md`** : structure du projet,
  SwiftData, stockage sécurisé d'une clé API (Keychain), service d'appel à l'API Claude,
  génération du projet Xcode (XcodeGen *ou* `.xcodeproj` généré à la main quand on ne veut
  pas d'outillage supplémentaire), `Info.plist`, icône.
- **PWA** → voir **`references/pwa.md`** : `manifest.webmanifest`, service worker
  (hors-ligne), stockage IndexedDB, appel à l'API Claude **depuis le navigateur** (en-tête
  `anthropic-dangerous-direct-browser-access`), spécificités iOS (Safari + « Sur l'écran
  d'accueil »), hébergement GitHub Pages + déploiement automatique.

Dans les deux cas, l'app **MonAssiette** de ce dépôt est un exemple complet à copier :
- Natif : `Sources/`, `MonAssiette.xcodeproj/`, `project.yml`, `Resources/Info.plist`.
- PWA : `pwa/` (tout le code), `.github/workflows/deploy-pwa.yml`, `codemagic.yaml`,
  `docs/DEPLOIEMENT-TESTFLIGHT.md`.

## Principes transverses

- **Clé API dans une app perso.** Faites saisir à l'utilisateur SA propre clé, stockée
  **sur l'appareil** (Keychain en natif, `localStorage` en PWA), jamais dans le code ni le
  dépôt. C'est acceptable en usage familial (préciser le compromis : extractible si le
  téléphone est déverrouillé ; révocable à tout moment). Chaque appareil garde ses propres
  données ; la clé ne mélange jamais les données entre utilisateurs.
- **Hors-ligne d'abord.** Tout ce qui n'a pas besoin du réseau (journal, objectifs,
  consultation) doit marcher sans connexion. Seuls les appels IA nécessitent Internet.
  Reformulez « je ne veux pas me connecter à chaque fois » en « pas de compte, l'app s'ouvre
  et marche instantanément ; seule l'analyse d'une nouvelle photo fait un appel réseau ».
- **Vie privée avant de rendre public.** Si un dépôt privé doit devenir public (ex. pour
  GitHub Pages en offre gratuite), retirez d'abord les données personnelles de
  l'historique Git (e-mails dans les fichiers ET dans les métadonnées de commits) avec
  `git filter-repo`, puis force-push. Demander l'accord explicite avant de réécrire `main`.
- **Honnêteté sur les limites.** Dire clairement ce que vous ne pouvez pas faire (compiler
  un `.ipa` sous Linux, garantir un comportement non testé) et pourquoi. Proposer une
  vérification concrète (build simulateur, `node --check`, curl de l'URL déployée).

## Comment étendre ce skill

Ce skill est fait pour grossir avec l'expérience. Bonnes façons d'ajouter :

- **Nouvelle voie de distribution** (ex. Xcode Cloud détaillé, AltStore, ad-hoc + Diawi)
  → nouvelle section dans `references/distribution.md`.
- **Nouveau patron d'app** (widgets, notifications, WatchKit, Live Activities, App Intents)
  → nouveau fichier `references/<sujet>.md` + une ligne de renvoi ici.
- **Piège rencontré** (une erreur de build et sa cause/solution) → ajoutez-la à
  `references/gotchas.md` avec le message d'erreur exact, la cause, et le correctif.
  Les messages d'erreur littéraux sont précieux : ils rendent le diagnostic futur immédiat.
- **Nouvelle recette** (génération d'icône, QR, scaffolding) → un script dans `scripts/`
  et un renvoi depuis la référence concernée.

Gardez `SKILL.md` sous ~500 lignes : il route, les références détaillent.
