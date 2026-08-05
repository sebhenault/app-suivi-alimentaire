# Distribution : installer une app iPhone sans App Store

La distribution est la contrainte reine. Choisissez-la avant l'architecture.

## Matrice de compatibilité macOS ↔ Xcode ↔ iOS

Le macOS installé fixe le Xcode maximal ; le Xcode fixe le SDK iOS et les technos
disponibles (SwiftData exige Xcode 15+ / SDK iOS 17).

| macOS | Xcode max | SDK iOS | Notes |
|---|---|---|---|
| Ventura (13.5+) | **15.2** | 17.2 | Dernier Xcode sous Ventura. SwiftData OK. |
| Sonoma (14.5+) | 16.x | 18.x | |
| Monterey (12) | 14.2 | 16 | Pas de SwiftData → Core Data, cible iOS 16. |
| Big Sur (11) | 13.2 | 15 | Core Data, cible iOS 15. |

**Avant de conclure « Mac trop vieux »** : vérifiez si une mise à jour **gratuite** de
macOS est possible (Réglages → Mise à jour). Beaucoup de Macs tournent un vieux macOS
faute de MAJ, pas par incompatibilité matérielle.

### Le point contre-intuitif le plus important

Un Xcode ancien (ex. 15.2) **ne peut pas installer par câble** sur un iPhone bien plus
récent (ex. iOS 26) : il manque les fichiers *DeviceSupport* de cette version d'iOS, et
l'écart de versions est trop grand pour le contournement habituel.

**MAIS** ce même Xcode 15.2 peut **archiver et téléverser sur TestFlight** un build qui
s'installera parfaitement sur cet iPhone iOS 26. Raison : une app compilée avec un SDK
plus ancien tourne sur un iOS plus récent (compatibilité ascendante), et l'installation
via TestFlight ne compare pas le SDK à la version d'iOS de l'appareil.

Conséquence pratique : **un iPhone « trop récent » n'oblige pas à acheter un nouveau Mac.**
On passe simplement par TestFlight plutôt que par le câble.

## Les quatre voies

### 1. Xcode → câble (le plus simple si compatible)
Brancher l'iPhone, choisir la destination, ⌘R. Nécessite que le Xcode installé supporte
la version d'iOS de l'iPhone. Pour un usage durable sur l'appareil (au-delà de 7 jours),
il faut le compte Apple Developer ; le « free provisioning » gratuit expire tous les 7 jours
et exige de rebrancher au Mac.

### 2. Xcode (Mac) → archive → TestFlight
Product → Archive → distribuer vers App Store Connect → l'app apparaît dans TestFlight.
Marche même avec un Xcode plus ancien que l'iOS de l'iPhone (voir ci-dessus). Nécessite le
compte Apple Developer (99 $/an). Idéal pour la famille (chacun installe via l'app TestFlight).

### 3. Codemagic (build cloud) → TestFlight — **sans Mac**
Un Mac cloud compile et signe à chaque push, puis publie sur TestFlight. Configuration 100 %
web. Voir le fichier `codemagic.yaml` de ce dépôt (workflow `ios-testflight` avec signature
automatique via une **clé API App Store Connect**) et `docs/DEPLOIEMENT-TESTFLIGHT.md` pour
le pas-à-pas (créer la fiche App Store Connect, la clé API `.p8` + Key ID + Issuer ID,
connecter Codemagic au dépôt). Offre gratuite ~500 min/mois — large pour un usage perso.
Nécessite quand même le compte Apple Developer.

Prérequis résumés : compte Apple Developer actif · fiche app dans App Store Connect ·
Bundle ID enregistré · clé API App Store Connect (rôle *App Manager*) · intégration
Codemagic nommée exactement comme référencée dans `codemagic.yaml`.

### 4. PWA → GitHub Pages — **gratuit, sans Mac, sans compte Apple**
La seule voie totalement gratuite et sans Apple. L'app s'installe via Safari →
Partager → « Sur l'écran d'accueil », plein écran, hors-ligne. On fournit une URL + un
**QR code**. Voir `references/pwa.md`. Limite honnête : c'est une app web (pas de vraies
API natives type HealthKit/Widgets riches), mais pour beaucoup d'apps perso c'est
indiscernable d'une native à l'usage.

## Déploiement d'une PWA sur GitHub Pages (recette)

Workflow GitHub Actions : voir `.github/workflows/deploy-pwa.yml`. Points clés :

- **Piège de l'environnement `github-pages`** : par défaut il n'autorise le déploiement
  que depuis la **branche par défaut** (`main`). Un workflow qui tourne sur une branche de
  travail échoue *instantanément* (job bloqué avant tout runner, ~0 s, conclusion `failure`).
  Solution : déclencher le déploiement depuis `main` (`on: push: branches: [main]`), ou
  ajouter la branche aux branches autorisées de l'environnement (Settings → Environments →
  github-pages).
- **Activation** (action ponctuelle de l'utilisateur, non scriptable ici) : Settings →
  Pages → Source → « GitHub Actions ».
- **Offre gratuite** : GitHub Pages sur un **dépôt privé** exige un plan payant. En gratuit,
  le dépôt doit être **public** (le code devient visible ; l'URL de l'app est de toute façon
  publique — c'est inhérent à une app web installable). Alternative pour garder le code privé
  gratuitement : héberger sur **Cloudflare Pages** ou **Netlify** (déploie depuis un dépôt
  privé, URL publique).
- **URL type** d'un site de projet : `https://<user>.github.io/<repo>/`. Prévisible → on
  peut générer le QR d'installation à l'avance (voir `scripts/make_qr.py`).
- Déclencher un déploiement à la demande : dispatch du workflow (`workflow_dispatch`) via
  l'API GitHub, ou un push touchant `pwa/**`.

## Vérifications utiles

- Build simulateur (Xcode) pour confirmer que le code compile, **avant** un build cloud
  (qui consomme des minutes et du temps).
- Après déploiement Pages : vérifier que le run Actions est vert (étapes checkout →
  configure-pages → upload-pages-artifact → deploy-pages toutes en succès). Un `curl` de
  l'URL peut être bloqué par un proxy côté assistant — le succès du run Actions fait foi.
