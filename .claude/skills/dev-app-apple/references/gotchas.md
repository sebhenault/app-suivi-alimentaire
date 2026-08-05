# Pièges rencontrés (message d'erreur → cause → correctif)

Journal des embûches réelles. Ajoutez-en à chaque nouvelle : le message littéral rend le
diagnostic futur immédiat.

## Distribution / environnement

**Xcode : « device support files not found » (ou l'iPhone n'apparaît pas / install câble
échoue).** Cause : Xcode trop ancien pour la version d'iOS de l'iPhone. Correctif : passer
par TestFlight (l'archive marche même avec un vieux Xcode) plutôt que le câble ; ne pas
acheter de Mac pour ça.

**GitHub Actions Pages : run en échec en ~0 s, job « failure » sans logs, aucun runner.**
Cause : l'environnement `github-pages` n'autorise que la branche par défaut. Correctif :
déployer depuis `main` (`on: push: branches: [main]`) ou autoriser la branche dans
Settings → Environments → github-pages.

**GitHub Pages refuse un dépôt privé (offre gratuite).** Cause : Pages sur dépôt privé =
plan payant. Correctif : rendre le dépôt public (après nettoyage de l'historique), ou
héberger sur Cloudflare Pages / Netlify pour garder le code privé.

**`get_job_logs` renvoie 404 sur les logs.** Les logs peuvent être indisponibles ; se
rabattre sur `list_workflow_jobs` (étapes + conclusions) pour diagnostiquer. Un job à 0 s
sans runner = blocage par règle d'environnement, pas une erreur de build.

## Code natif (Swift)

**`.foregroundStyle(.accent)` — erreur de compilation.** `.accent` n'est pas un ShapeStyle.
Correctif : `.tint` ou `Color.accentColor`.

**Projet ne s'ouvre pas / SwiftData indisponible.** Vérifier la matrice : SwiftData exige
Xcode 15+. Sous Xcode 14, migrer vers Core Data + cible iOS 16.

## Code PWA (JS)

**`SyntaxError: Missing } in template expression`.** Cause : une chaîne simple contenant une
apostrophe échappée en `\\'` à l'intérieur d'un `${…}` de template literal ferme la chaîne
prématurément. Correctif : guillemets doubles (`"…l'IA"`) ou échappement correct.

**`node --check` dit OK mais le code casse à l'exécution.** `--check` rate certaines erreurs
dans les modules ES. Valider en important le module avec des globals navigateur stubés
(voir `references/pwa.md` § Validation).

**`TypeError: Cannot set property navigator/crypto … only a getter` (Node récent).** En
stubbant des globals pour valider, `navigator`/`crypto` sont en lecture seule : utiliser
`Object.defineProperty(globalThis, "navigator", {value:{}, configurable:true})` et ne pas
réassigner `crypto` (déjà présent dans Node).

## Confidentialité / Git

**Rendre public un dépôt qui contient des données perso dans l'historique.** Les e-mails
peuvent être dans le contenu des fichiers **et** dans les métadonnées d'auteur des commits.
Correctif : `git filter-repo --replace-text` (contenu) + `--email-callback`/`--name-callback`
(auteurs), puis force-push. `filter-repo` retire le remote `origin` par sécurité : le
recapturer avant et le rajouter après. Demander l'accord explicite avant de réécrire `main`.
