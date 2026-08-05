# PWA installable sur iPhone (gratuit, sans Mac, sans compte Apple)

Exemple vivant : dossier `pwa/` de ce dépôt. App statique, sans build, sans dépendance
externe (compatible offline et GitHub Pages). Tout en chemins **relatifs** (`./…`) car un
site de projet GitHub Pages est servi sous `/<repo>/`.

## Structure

```
pwa/
  index.html            Coquille + barre d'onglets
  styles.css            Thème clair/sombre (variables CSS)
  app.js                Logique, rendu des écrans, navigation, ajout de repas
  db.js                 IndexedDB (stockage local des données)
  claude.js             Appel à l'API Claude depuis le navigateur
  manifest.webmanifest  Métadonnées d'installation (nom, icônes, standalone)
  service-worker.js     Cache pour le hors-ligne
  icons/                192, 512, maskable-512, apple-touch-icon (180)
```

## Manifest (installation façon app)

`display: "standalone"`, `start_url: "./"`, `scope: "./"`, `theme_color`, et 3 icônes
(192 « any », 512 « any », 512 « maskable »). Lier via `<link rel="manifest">`.

## Spécificités iOS (importantes)

- L'installation se fait **dans Safari** uniquement (pas Chrome) : Partager → « Sur l'écran
  d'accueil » → Ajouter. Le décrire explicitement à l'utilisateur (avec visuels si possible).
- Métas iOS dans `<head>` : `apple-mobile-web-app-capable = yes`,
  `apple-mobile-web-app-status-bar-style`, `apple-mobile-web-app-title`, et
  `<link rel="apple-touch-icon" href="./icons/apple-touch-icon.png">` (180 px, sans alpha).
- iOS supporte les service workers et IndexedDB. Attention : données potentiellement évincées
  après ~7 jours d'inactivité (ITP) — négligeable pour un usage quotidien ; proposer un
  export si nécessaire.
- Caméra : `<input type="file" accept="image/*" capture="environment">` ouvre l'appareil
  photo ; sans `capture`, ça ouvre la photothèque.

## Appel à l'API Claude depuis le navigateur

Voir `pwa/claude.js`. Identique au natif, avec **un en-tête en plus** obligatoire pour le
CORS navigateur :
```
"anthropic-dangerous-direct-browser-access": "true"
```
La clé API est saisie dans les Réglages et rangée dans `localStorage` (usage perso ;
préciser le compromis de sécurité). Convertir l'image en dataURL, extraire le base64 et le
`media_type`, envoyer image + texte, demander un JSON strict, isoler `{ … }`, décoder.

## Hors-ligne

Service worker : précacher la coquille (`./`, `index.html`, css, js, manifest, icônes) sous
un nom de cache versionné ; `skipWaiting()` + `clients.claim()`. Sur `fetch`, ne PAS
intercepter les autres origines (laisser passer l'appel à `api.anthropic.com`) ;
cache-first pour les ressources same-origin ; pour une navigation, renvoyer `index.html`
en secours. Bump le nom du cache (`-v2`, …) à chaque release pour forcer le rafraîchissement.

## Données locales

IndexedDB via un petit wrapper (voir `pwa/db.js`) : un store `meals` (keyPath `id`), index
sur `date`. Objectifs/réglages dans `localStorage`. Chaque appareil garde ses propres
données — séparation automatique entre membres de la famille, quelle que soit la clé API.

## Validation sans navigateur

On ne peut pas ouvrir un vrai Safari iOS depuis l'assistant. Valider ce qui est possible :
- `node --check` **ne suffit pas** pour les modules ES et rate certaines erreurs de
  template literal. Valider en **important** le module dans Node avec des globals navigateur
  stubés (document/window/localStorage/indexedDB) : l'import force le parse complet + le
  code top-level ; une `SyntaxError` = vrai problème, une erreur runtime de stub = parse OK.
- Piège classique déjà rencontré : une apostrophe dans une chaîne simple imbriquée dans un
  template literal (`'…l\\'IA'` casse la chaîne). Utiliser des guillemets doubles
  (`"…l'IA"`) ou échapper correctement.
- Après déploiement : le succès du run GitHub Actions fait foi (un `curl` peut être bloqué
  par le proxy côté assistant).

## Déploiement

Voir `references/distribution.md` § GitHub Pages (dont le piège de l'environnement
`github-pages` limité à la branche par défaut, et la question dépôt public vs
Cloudflare/Netlify pour garder le code privé).
