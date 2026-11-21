# Arrêt de F9 avant la mise en ligne (F9.5)

Arrêt demandé par Loick le 21/11/2026 : « Pour la mise en ligne (F9.5), arrête-toi avant de toucher
`backend/` et dis-moi ce que je dois préparer. » F9.0 à F9.4 sont terminées, intégrées dans `main`,
CI verte (`5690543`). Le rapport complet de F9 suivra après F9.5.

## Fait jusqu'ici (F9.0 → F9.4)

- **F9.0** : les lignes d'« Activité récente » de l'accueil s'ouvrent (un paiement ouvre son reçu, une
  facture son détail), décision de Loick ; test.
- **F9.1** :
  - **écran Compte** (en-tête, « Mon compte », déconnexion, « ElecPay 1.0.0 · Mode démo ») ;
  - **Mon profil** : nom et e-mail, adresse vérifiée par un code (en démo, le code est affiché) ;
  - **réglages gardés sur l'appareil** (D9.1 : fichier JSON privé, sans nouveau paquet). La
    dernière page d'attente (`PendingTab`) est retirée.
- **F9.2** :
  - « Me prévenir » : 4 interrupteurs. Si l'API refuse, l'interrupteur revient en arrière.
    Hors ligne, les interrupteurs ne sont pas modifiables ;
  - thème **Nuit (par défaut)** / Jour / Auto, et « Effet verre » désactivé par défaut. Les deux
    sont gardés d'un lancement à l'autre.
- **F9.3** — « Mot de passe et sécurité » :
  - changer de mot de passe : les nouveaux jetons sont enregistrés et cet appareil reste connecté ;
  - « Déconnecter tous mes appareils », avec confirmation. ⚠️ L'API révoque **toutes** les
    sessions, celle-ci comprise. Le bouton le dit et déconnecte cet appareil tout de suite ; pour ne
    déconnecter que les autres, il faut changer de mot de passe (expliqué à l'écran).
- **F9.4** — **Assistance** :
  - la recherche ;
  - les 5 questions de la maquette ;
  - **« Contacts du support : bientôt disponibles », sans aucun faux numéro** (testé) ;
  - le rappel « pannes : contacter E²C ».
- **Défaut corrigé** (aussi en F8) : des boutons tournaient derrière leur feuille de confirmation. Un
  test le garde ; il échoue bien sur l'ancien code.
- **1706 tests au vert.**

## Ce que je propose pour F9.5 (rien n'est fait : j'attends ton accord)

Choix validé (D10.2) : **Oracle Cloud Always Free + Caddy (HTTPS automatique) + DuckDNS**, avec
**Cloudflare Tunnel** en secours.

Fichiers que j'écrirais, **dans `backend/deploy/`** (à valider : c'est dans `backend/`) :

- `docker-compose.prod.yml` : l'API (image du `Dockerfile` existant), MySQL 8 avec un volume
  persistant, et Caddy (ports 80 et 443, certificat Let's Encrypt automatique).
- `Caddyfile` : `https://<ton-sous-domaine>.duckdns.org` vers l'API ; en-têtes de sécurité ; journaux.
- `.env.production.example` : toutes les variables (sans aucun secret), avec la commande pour
  générer les secrets **sur le serveur**.
- Les tâches planifiées (`check_pending_payments`, `send_emails`, `send_announcements` chaque minute ;
  `daily_alerts` à 6 h) : un petit conteneur « cron », ou des minuteurs systemd (au choix).
- `backup.sh` : une sauvegarde quotidienne de MySQL (`mysqldump` compressé, 14 jours gardés).
- `duckdns-update.sh` : met à jour l'adresse IP (toutes les 5 minutes), pour le cas où elle change.
- Une **section « Oracle Cloud »** dans `backend/docs/DEPLOIEMENT.md`, pas à pas :
  - créer la machine ;
  - ouvrir les ports ;
  - installer Docker ;
  - lancer, vérifier, mettre à jour, restaurer une sauvegarde ;
  - Cloudflare Tunnel en secours.

Côté application (dans `frontend/`, sans accord nécessaire) : un APK release qui pointe vers
`https://<sous-domaine>.duckdns.org/api/v1` (F10), et `tool/apk_check.dart` qui vérifie cette adresse
https.

## ⚠️ Décision à prendre : la démo publique

En production (`APP_ENV=production`), l'API **refuse** :

- `scripts.seed`, qui crée les comptes de démo ;
- `scripts.daily_tick`, qui ajoute chaque jour les relevés simulés ;
- `scripts.reset_db`.

Elle **exige** en revanche `DEMO_MODE=true` tant que les paiements et les relevés sont simulés. Comme
tout est encore simulé, un serveur en production aurait donc des comptes vides et des relevés qui
s'arrêtent.

- **a) Serveur de démonstration** : `APP_ENV=development` + `DEMO_MODE=true`, en HTTPS derrière Caddy.
  Seed et relevés quotidiens fonctionnent, sans modifier le backend. En revanche, les garde-fous de
  production (secrets forts, cookies sécurisés, CORS https, 2FA de l'équipe obligatoire) ne sont plus
  **imposés** par l'API ; je les mettrais à la main dans `.env`, et un script de vérification les
  contrôlerait.
- **b) Petite modification du backend** : autoriser `seed` et `daily_tick` en production
  **seulement si** `DEMO_MODE=true` (jamais `reset_db`). Les garde-fous de production restent imposés.
  Cela ajoute environ 10 lignes, avec leurs tests.
- **Ma recommandation : b)**. Tous les garde-fous restent actifs, et la démo vit, avec de nouveaux
  relevés chaque jour. Quand E²C et MTN / Airtel seront branchés, `DEMO_MODE=false` coupera seed et
  relevés simulés, sans autre changement.

## Ce que tu dois préparer (toi seul peux le faire)

1. **Compte Oracle Cloud** (cloud.oracle.com, offre « Always Free »). La carte bancaire sert
   seulement à vérifier ton identité ; rien n'est débité tant qu'on reste dans le gratuit.
   - **Choisis bien la région d'origine, car elle ne se change pas.** Pour le Congo, la plus proche
     est **Johannesburg** ; sinon **Marseille** ou **Paris**. Les machines ARM gratuites sont parfois
     « épuisées » dans une région : il faut alors réessayer plus tard.
2. **Créer la machine**, ou me laisser te guider pas à pas au moment voulu :
   - forme **VM.Standard.A1.Flex** (ARM), 2 cœurs et 12 Go suffisent (le gratuit va jusqu'à 4 et
     24) ;
   - **Ubuntu 24.04** ;
   - tu gardes **ta clé SSH**. **Ne m'envoie jamais la clé privée**.
3. **Compte DuckDNS** (duckdns.org, connexion par Google ou GitHub) :
   - réserver un sous-domaine, par exemple `elecpay-demo.duckdns.org` ;
   - noter le **jeton DuckDNS** (il ira dans `.env` sur le serveur, pas dans le dépôt).
4. **Ta réponse à la décision a) / b)** ci-dessus, et ton **accord pour écrire dans
   `backend/deploy/`** et `backend/docs/DEPLOIEMENT.md`.
5. **Cloudflare** : seulement si Oracle refuse la machine ou si le port 443 reste bloqué (secours).
   Rien à faire pour l'instant.
6. **Plus tard (pas pour F9.5)** :
   - un vrai service d'e-mail. Aujourd'hui, l'API **simule** l'envoi : aucun e-mail réel ne part,
     même en ligne ;
   - les vrais contacts du support (D9.3) ;
   - les vrais textes des conditions d'utilisation et de la confidentialité ;
   - un nom de domaine à toi, si tu en veux un plus tard (`elecpay.cg`…).

Les secrets (`JWT_SECRET`, `TWO_FACTOR_KEY`, `PAYMENT_WEBHOOK_SECRET`, mot de passe MySQL) seront
**générés sur le serveur** par une commande que je te donnerai. Ils ne passent jamais par moi, ni par
le dépôt.
