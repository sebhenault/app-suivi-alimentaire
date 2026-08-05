# Déployer MonAssiette sur votre iPhone — sans Mac (Codemagic → TestFlight)

Objectif : pousser du code → un Mac cloud compile et signe → l'app arrive sur
votre iPhone via **TestFlight** (lien / QR code). Vous ne touchez jamais un Mac.

Tout se fait dans le **navigateur**. Comptez ~45 min la première fois. Ensuite,
chaque nouvelle version est automatique.

---

## Étape 0 — Prérequis (une seule fois)

- [ ] **Programme Apple Developer actif** (99 $/an) : https://developer.apple.com/programs/
      → « Enroll ». Validation Apple de quelques heures à ~48 h.
- [ ] **App TestFlight** installée sur l'iPhone (depuis l'App Store).

---

## Étape 1 — Créer la fiche de l'app dans App Store Connect

1. Allez sur https://appstoreconnect.apple.com → **Apps** → bouton **+** → **New App**.
2. Remplissez :
   - **Platforms** : iOS
   - **Name** : `MonAssiette` (doit être unique sur l'App Store ; si pris, mettez
     par ex. `MonAssiette Henault`)
   - **Primary Language** : Français
   - **Bundle ID** : sélectionnez `com.henault.monassiette`
     *(s'il n'apparaît pas, voir l'encadré ci-dessous)*
   - **SKU** : `monassiette` (identifiant libre)
3. **Create**.

> **Le Bundle ID n'apparaît pas ?** Créez-le : https://developer.apple.com/account/resources/identifiers
> → **+** → **App IDs** → **App** → Description `MonAssiette`,
> Bundle ID **Explicit** = `com.henault.monassiette` → **Continue** → **Register**.
> Revenez ensuite créer la fiche.

---

## Étape 2 — Créer une clé API App Store Connect

Cette clé permet au Mac cloud de signer et d'envoyer sans mot de passe.

1. https://appstoreconnect.apple.com/access/integrations/api (Users and Access → Integrations).
2. Section **Team Keys** → **+** (Generate API Key).
   - **Name** : `Codemagic`
   - **Access** : `App Manager`
3. **Generate**. Puis **notez / téléchargez** :
   - Le fichier **`.p8`** (⚠️ téléchargeable **une seule fois** — gardez-le bien)
   - Le **Key ID** (ex. `ABCD1234EF`)
   - L'**Issuer ID** (en haut de la page, format `xxxxxxxx-xxxx-...`)

---

## Étape 3 — Configurer Codemagic

1. Créez un compte sur https://codemagic.io/signup → **Sign up with GitHub**
   (autorisez l'accès au dépôt `sebhenault/app-suivi-alimentaire`).
2. **Ajouter la clé Apple** : avatar en haut à droite → **Team / User settings** →
   **Integrations** → **App Store Connect** → **Manage keys** → **Add key** :
   - **Name** : `AppStoreConnect` *(exactement ce nom — il est référencé dans `codemagic.yaml`)*
   - **Issuer ID** / **Key ID** / fichier **`.p8`** (de l'étape 2)
   - **Save**.
3. **Ajouter l'app** : **Applications** → **Add application** → choisissez le dépôt
   `app-suivi-alimentaire` → Codemagic détecte automatiquement `codemagic.yaml`.

---

## Étape 4 — Lancer le premier build

1. Dans Codemagic, ouvrez l'app → **Start new build**.
2. **Branch** : `claude/iphone-food-tracking-app-qrtqz3` — **Workflow** : `MonAssiette – iOS TestFlight`.
3. **Start build**. Durée : ~8-15 min.
4. À la fin : l'IPA est envoyé sur TestFlight. Apple « traite » le build encore
   ~5-15 min (vous recevez un mail quand c'est prêt).

> En cas d'échec, copiez-moi le log (onglet du build) : je corrige le `codemagic.yaml`
> ou le code, je repousse, et on relance.

---

## Étape 5 — Installer sur l'iPhone

**Pour vous (immédiat, sans revue Apple)** — testeur interne :
1. https://appstoreconnect.apple.com → votre app → onglet **TestFlight**.
2. **Internal Testing** → groupe → **+** → ajoutez votre adresse
   (elle doit être un utilisateur de votre équipe App Store Connect).
3. Sur l'iPhone : ouvrez **TestFlight** → l'app **MonAssiette** apparaît → **Install**.

**Pour la famille (lien / QR public)** — testeurs externes :
1. TestFlight → **External Testing** → créez un groupe **Famille** → ajoutez le build.
2. La 1ʳᵉ fois, Apple demande une courte **revue bêta** (souvent < 24 h).
3. Activez **Public Link** → vous obtenez une URL + **QR code** à partager.

---

## Le cycle de travail ensuite

1. Je code une amélioration → je pousse sur GitHub.
2. Build Codemagic (automatique si activé, ou « Start new build »).
3. Notification TestFlight sur l'iPhone → **Update**. C'est tout. 🎉

> Astuce : dans Codemagic, activez le déclenchement automatique
> (**triggers** : on push) pour que chaque `git push` lance un build sans clic.
