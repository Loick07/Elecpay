# M1 — arrêt avant l'installation de ngrok (M1.3, par Loick)

État au 25/11/2026, branche `m1`. **M1.1 et M1.2 sont faits**, intégrés dans `main`, CI verte :
1981 tests du backend, aucun sauté. Il reste M1.3, que Loick fait lui-même : installer ngrok,
ajouter l'authtoken, mettre en ligne. Puis M1.4 : l'APK release sur l'itel.

## M1.1 — Seed sûr (accord de Loick pour `backend/`)

- Nouvelle variable **`DEMO_SEED_PASSWORD`** (secrète, jamais affichée, ni dans les journaux ni dans
  les erreurs).
- La règle est en un seul endroit, `backend/app/simulators/seed_policy.py` :
  - **en production** :
    - `DEMO_MODE=true` obligatoire ;
    - mot de passe obligatoire, refusé s'il est vide, s'il vaut `Demo2026!` (même en minuscules
      ou entouré d'espaces), ou s'il est trop faible (règles d'inscription) ;
    - un **secret 2FA tiré au hasard pour chaque** admin et super admin, chiffré en base, affiché
      **une seule fois** à la fin du seed ;
  - **en développement**, sans la variable : rien ne change (`Demo2026!` et le secret public).
    Les tests et la base `elecpay_e2e` continuent donc de marcher.
- `scripts.seed` refuse **avant d'ouvrir la base** : rien n'est écrit en cas de refus.
- **Décision prise en suivant la recommandation de `PLAN.md`** : le serveur ngrok tourne en
  `APP_ENV=production`, pour garder tous les garde-fous. `daily_tick` (relevés simulés) y est permis
  **seulement** avec des sources simulées et `DEMO_MODE=true`. `reset_db` reste refusé en production.
- Tests (`backend/tests/test_seed_policy.py`) :
  - la règle : 16 cas, dont 8 refus ;
  - un seed complet avec le mot de passe du serveur : chaque compte l'a, et `Demo2026!` ne
    marche sur aucun ;
  - les secrets 2FA : tous différents, chiffrés, et produisant les bons codes ;
  - la commande refuse sans toucher à la base.
- **Test modifié** : `test_daily_tick.py` attendait un refus en production. Il attend maintenant une
  acceptation en production de démonstration, et un refus sans `DEMO_MODE`. Ce changement vient
  de la décision ci-dessus.

## M1.2 — Configuration ngrok et guide

- **`backend/deploy/ngrok.env.example`**, sans aucun secret :
  - `APP_ENV=production`, `DEMO_MODE=true` ;
  - `RECEIPT_VERIFY_URL=https://omnivore-pardon-sixth.ngrok-free.dev/api/v1/receipts/verify` ;
  - `CORS_ORIGINS=https://omnivore-pardon-sixth.ngrok-free.dev` ;
  - `TRUSTED_PROXIES=127.0.0.1/32,::1/128` : l'agent ngrok tourne sur ce PC, et seule cette
    origine peut donner l'IP réelle du visiteur.
- **`backend/deploy/public.ps1`**, une étape par action :
  - `preparer` crée la base **dédiée** `elecpay_public` (nom écrit en dur) avec **son propre
    utilisateur MySQL**, et tire tous les secrets au hasard **sur le PC**, dans
    `deploy\ngrok.env`, ignoré par git et jamais affiché ;
  - les autres étapes : `config`, `migrer`, `seed`, `api` (sur `127.0.0.1` seulement), `taches`,
    `sauvegarde` (14 gardées), `restaurer` (confirmation à taper), `verifier`.
- **Guide pas à pas** : `backend/docs/DEPLOIEMENT.md`, **section 7**. Il couvre l'installation de
  ngrok (Microsoft Store ou WinGet), l'authtoken que **tu ajoutes toi-même**, la mise en ligne en
  trois fenêtres, la vérification, la sauvegarde et les limites de l'offre gratuite.
- Tests (`backend/tests/test_deploy_ngrok.py`) :
  - le modèle ne contient aucun secret, et une fois rempli, l'API l'accepte en production ;
  - le vrai fichier et les sauvegardes sont ignorés par git ;
  - le garde-fou du script : 8 refus, dont les bases `elecpay` et `elecpay_e2e`, une autre machine
    ou un secret vide ; 1 acceptation ; aucun secret affiché. Ces tests tournent aussi en CI.
- **Essayé pour de vrai sur ce PC, sans `seed`** :
  - `preparer`, `config`, `migrer` (23 tables) ;
  - `api` : production, journaux JSON, en-têtes de sécurité ;
  - `verifier` : réponse locale « ok » ; la partie ngrok répond 404, normal puisque ngrok n'est
    pas encore installé ;
  - `sauvegarde` : 23 tables et 17 garde-fous (triggers) ;
  - `taches` : un tour sans échec.
  - Je n'ai **pas** lancé `seed`, qui affiche une seule fois les secrets 2FA : ils sont pour toi.

## À savoir avant de suivre le guide

- **La base `elecpay_public` existe déjà**, avec ses tables mais **aucun compte**, à cause de mon
  essai. Ce n'est pas un problème : ton `preparer` change le mot de passe de son utilisateur et
  tire de nouveaux secrets, puis ton `seed` remplit la base vide.
- Mon essai a laissé **une sauvegarde** de la base vide dans `backend\deploy\sauvegardes\`, ignorée
  par git. Tu peux la supprimer ou la garder.
- Ma configuration d'essai est dans mon dossier temporaire, hors du dépôt. Ses secrets ne servent
  plus, puisque ton `preparer` en tire de nouveaux.

## Ce que tu fais maintenant (M1.3)

Suivre `backend/docs/DEPLOIEMENT.md`, **section 7**, dans l'ordre :
1. section 7.1 : `preparer`, `config`, `migrer`, `seed`. Note les secrets 2FA affichés **une seule
   fois** dans ton application d'authentification ; le mot de passe des comptes se lit dans
   `deploy\ngrok.env` ;
2. section 7.2 : installer ngrok et **ajouter l'authtoken toi-même**. Ne me le donne jamais ;
3. section 7.3 : l'API, les tâches et ngrok dans trois fenêtres, puis `verifier`.

Dis-moi quand `verifier` répond « ok » par ngrok. Je passerai alors à **M1.4** : l'APK release,
signé avec ta clé, sur l'itel, contre `https://omnivore-pardon-sixth.ngrok-free.dev`.
