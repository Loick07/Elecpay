# ElecPay — Plan de construction du backend (A → Z)

Ce document est la feuille de route du backend. On le suit **dans l'ordre**, une étape à la fois.
Une étape n'est terminée que quand **tous** ses critères « Terminé quand » sont vrais.
À la fin de chaque étape : tests + Ruff au vert, commit, push, et mise à jour du tableau ci-dessous.

## Tableau de bord

| Étape | Nom | État |
|---|---|---|
| B0 | Socle technique | ✅ terminé (12/11/2026) |
| B1 | Modèle de données | ✅ terminé (12/11/2026) |
| B2 | Simulateurs et données de démo | ✅ terminé (12/11/2026) |
| B3 | Comptes et authentification | ✅ terminé (12/11/2026) |
| B4 | Foyers, compteurs et délégation | ✅ terminé (12/11/2026) |
| B5 | Consommation | ✅ terminé (12/11/2026) |
| B6 | Factures | ✅ terminé (12/11/2026) |
| B7 | Paiements | prochaine étape |
| B8 | Reçus | à faire |
| B9 | Notifications | à faire |
| B10 | API d'administration | à faire |
| B11 | Durcissement et contrat d'API | à faire |

Après B11 seulement : application Flutter, puis back-office Next.js.

## Point de reprise (mis à jour le 12/11/2026, fin de session)

- **Terminé** : B0 → B6, tout commité et poussé, CI verte.
  1122 tests, Ruff au vert, `alembic check` sans écart. Détails de chaque étape dans sa section « Réalisé ».
- **Reste** : B7 Paiements, B8 Reçus, B9 Notifications, B10 API d'administration,
  B11 Durcissement et contrat d'API. Puis Flutter, puis Next.js.
- **Prochaine sous-étape** : proposer à Loick le **découpage de B7** (B7.1, B7.2…), l'expliquer en français
  et attendre sa validation avant d'écrire du code. Points déjà connus pour B7 : interface `PaymentProvider`
  + `SimulatedProvider` ; clé d'idempotence ; une seule transaction `en_attente` par facture (trigger B1) ;
  montant = celui de la facture ; facture `pending_payment` pendant le paiement (`can_pay` faux, déjà
  géré par B6) ; webhook signé, seul à passer `reussie` ; colonne `operator` (MTN / Airtel) ; état
  « PIN saisi » ; droit de payer = `HouseholdAccess.can_pay` (propriétaire ou payeur délégué).
- **Méthode** : chaque étape découpée en sous-étapes validées une à une ; tests et Ruff avant de dire « fini » ;
  vérification en conditions réelles (API lancée sur la base de démo) en fin d'étape ; commit + push +
  CI + tableaux de bord à la fin de l'étape, annoncés en tête de message (« ✅ Commit et push faits »).

### Bugs trouvés en conditions réelles (et corrigés)

| Étape | Symptôme | Cause | Correction |
|---|---|---|---|
| B5.6 | `GET /meters/{id}/consumption?granularity=bimester` sur 18 mois → **erreur 500** | la comparaison chiffrait une « facture estimée » de 18 mois d'un bloc, refusée par `compute_bill` (12 mois au plus) | au-delà de 12 mois, seul `energy_cost` est calculé (`estimated_total = null`) ; 2 tests de non-régression (`test_consumption_costs.py`, `test_b5_acceptance.py`) |

Bugs trouvés par les tests pendant la session (tous corrigés, avec un test) : `downgrade` Alembic qui
supprimait un index utilisé par une clé étrangère ; CHECK « anomalie ⇔ motif » contourné par NULL ;
JSON `None` stocké comme texte `null` ; empreinte Argon2 corrompue qui faisait planter `verify_password` ;
message trompeur pour un numéro vide.

### Décisions techniques transverses (session du 12/11/2026)

- **Python 3.14** partout (local, CI). Dépendances fixées dans `requirements*.txt` ; le client de test utilise
  **`httpx2`** (Starlette déprécie l'ancien paquet `httpx`).
- **Règle de dépendance** : un module métier (`app/modules/*`) n'importe **jamais** `app.simulators`.
  Les versions simulées des intégrations (`app/integrations/*/simulated.py`) le peuvent. Le métier ne
  connaît que les interfaces (`BillingSource`, `ConsumptionSource`, `SmsSender`, bientôt `PaymentProvider`).
- **Socle partagé** : `app/core/` (config, erreurs, validation des saisies, calendrier, fuseau UTC+1,
  pagination, limitation des tentatives, contexte de requête) ; notifications créées par
  `app/modules/notifications/service.py` ; audit par `app/modules/audit/service.py` (refuse les secrets).
- **Migrations** autonomes (n'importent jamais `app.*`), relues après génération ; garde-fous métier en
  **triggers MySQL** (option `log_bin_trust_function_creators=1` dans `docker-compose.yml` et la CI).
- **Tests** : session transactionnelle annulée après chaque test ; `auth_headers` pour fabriquer un jeton ;
  Argon2 allégé **pendant les tests uniquement** ; un limiteur de tentatives par application ;
  date du jour injectée dans les services (`today`) pour des tests reproductibles.
- **Consommation** : semaines du lundi au dimanche ; kWh à 3 décimales pour l'affichage seulement (la valeur
  exacte est en Wh) ; comparaisons sur les mêmes journées relevées ; RAV et timbre au prorata des mois.
- **Commits** : un commit par étape + un commit des tableaux de bord ; message écrit dans un fichier
  `.git/COMMIT_MSG_*` (PowerShell 5.1 abîme les accents et ajoute un BOM sinon), puis supprimé.
- **Environnement** : ouvrir Docker Desktop avant de travailler. Avec peu de mémoire libre (≈ 2 Go sur 16 Go
  constatés), la suite de tests passe de ~2 à ~7 min : fermer les applications lourdes accélère tout.

### Notes reportées aux étapes suivantes

- **B7** : colonne `operator` (MTN / Airtel) distincte de `provider` ; état « PIN saisi » sans expiration (A8).
  Une facture `pending_payment` dont la transaction échoue ou expire doit revenir à `unpaid` (ou `overdue`
  si l'échéance est passée : `displayed_status` le montre déjà à la lecture).
- **B10** : réémettre la facture d'une période annulée (`generate_bill` refuse : `BILLING_PERIOD_CANCELLED`) ;
  afficher les messages `BillingError` du relevé quotidien aux administrateurs.
- **B11** : IP réelle derrière un proxy (`X-Forwarded-For`) ; compteurs de tentatives partagés si plusieurs
  processus ; durée de conservation du journal d'audit (loi congolaise).
- **Flutter** : un seul rafraîchissement de jeton à la fois. **Next.js** : appeler l'API via le serveur Next
  (cookies `SameSite=Strict`) et recopier `elecpay_csrf` dans `X-CSRF-Token`.
- Les autres besoins des maquettes à placer dans les étapes : tableau en fin de section B1.

---

## Organisation du code (rappel)

```
backend/
  app/
    main.py                 # création de l'app, routers, middlewares
    core/                   # config, sécurité (hash, JWT), erreurs, dépendances, pagination
    db/                     # moteur, session, Base, mixins (id, created_at, updated_at)
    modules/<domaine>/      # models.py, schemas.py, service.py, router.py, (repository.py)
    integrations/
      payment_providers/    # base.py (PaymentProvider), simulated.py, mtn.py, airtel.py (plus tard)
      billing_sources/      # base.py (BillingSource / ConsumptionSource), simulated.py, e2c.py (plus tard)
    simulators/             # génération des relevés, factures, scénarios de paiement
  alembic/                  # migrations
  tests/                    # unitaires + API + parcours complets
  scripts/                  # seed.py, reset_db.py
```

Règle : un `router` ne contient pas de logique métier, il appelle un `service`.
Les `service` ne connaissent pas HTTP. Les règles métier vivent dans les services et sont testées.

## Format commun de l'API
- Préfixe : `/api/v1`. Routes admin : `/api/v1/admin/...`.
- Erreurs toujours au même format : `{"error": {"code": "BILL_ALREADY_PAID", "message": "...", "details": {...}}}`.
- Listes paginées : `?page=1&size=20` → `{"items": [...], "total": 132, "page": 1, "size": 20}`.
- Dates en ISO 8601 UTC ; montants en FCFA entiers ; énergie en kWh (décimal à 3 chiffres max, stocké en Wh entiers).
- Chaque réponse issue de données simulées porte `"source": "simulated"` quand c'est pertinent.

---

## B0 — Socle technique

**Objectif :** une API vide mais saine, qui démarre, se connecte à la base et est testée automatiquement.

À faire :
- `pyproject.toml` (ou `requirements.txt` + `requirements-dev.txt`) avec versions fixées.
- `core/config.py` : Pydantic Settings, lecture du `.env` (`DATABASE_URL`, `JWT_SECRET`, `PAYMENT_PROVIDER`, `DEMO_MODE`…).
- `db/session.py` : moteur SQLAlchemy 2, session par requête (dépendance `get_db`).
- `main.py` : app FastAPI, CORS, gestionnaire d'erreurs au format commun.
- Route `GET /api/v1/health` → `{"status": "ok", "database": "ok", "demo_mode": true}`.
- Alembic initialisé et branché sur la config.
- Pytest : base de test séparée (`elecpay_test`), fixture client HTTPX.
- Ruff configuré.
- CI GitHub Actions : Ruff + tests avec un service MySQL 8.
- Pas de reprise des anciens projets : reconstruction propre dans ce dépôt.

Terminé quand : `uvicorn app.main:app --reload` démarre ; `/health` répond `ok` avec la base ; `/docs` s'affiche ;
`pytest` et `ruff check` passent en local **et** sur GitHub.

---

## B1 — Modèle de données

**Objectif :** toutes les tables, avec leurs contraintes, créées par une migration Alembic.

| Table | Colonnes clés | Contraintes / remarques |
|---|---|---|
| `users` | id, phone (unique), email (unique, null), full_name, password_hash, role, is_active, last_login_at | role ∈ client, support, admin, super_admin |
| `refresh_tokens` | id, user_id, token_hash, expires_at, revoked_at, replaced_by_id, user_agent | jamais le jeton en clair |
| `households` | id, name, address, district (quartier), city, owner_id | un foyer = un logement ; quartier pour les annonces ciblées (A9) |
| `household_members` | id, household_id, user_id, role, status, invited_by | role ∈ payer (payeur délégué), viewer ; status ∈ invited, active, revoked ; unique (household_id, user_id). Le propriétaire n'y figure pas : `households.owner_id` est la seule source de vérité |
| `meters` | id, household_id (null = détaché), reference (unique, N° Branchement), label, type, contract_number (N° Police), customer_number (N° Client), e2c_center, subscribed_power_va, status, installed_at | type ∈ postpaid (prépayé plus tard) ; puissance en VA entiers (3 kVA → 3000) |
| `meter_readings` | id, meter_id, read_at, index_wh, consumption_wh, source, is_estimated, is_anomaly, anomaly_reason | source ∈ simulated, manual, e2c ; unique (meter_id, read_at) ; anomalie ⇔ motif |
| `tariffs` | id, code, label, price_per_kwh_milli, fixed_fee_per_month, vat_rate_bp, additional_tax_rate_bp, audiovisual_fee, stamp_fee, valid_from, valid_to, is_assumption, source_note | prix en millièmes de FCFA (49,08 → 49 080) ; taux en points de base ; pas de chevauchement (triggers MySQL). Structure : voir `backend/docs/FACTURE_E2C.md` |
| `bills` | id, meter_id, tariff_id, reference (unique), period_start, period_end, months_count, previous_index_wh, current_index_wh, consumption_wh, billed_power_va, amount_ht, amount_tax, amount_fees, amount_total, due_date, status, issued_at, paid_at, cancelled_at, cancelled_reason, source | status ∈ unpaid, pending_payment, paid, overdue, cancelled ; jamais supprimée ; contenu figé, seul le statut évolue ; motif d'annulation ≥ 10 caractères (A6) ; index et puissance figés au moment de la facture |
| `bill_lines` | id, bill_id, label, quantity, unit_price, amount, kind | kind ∈ energy, fixed_fee, audiovisual_fee, vat, additional_tax, stamp, other (lignes d'une facture E²C) |
| `payment_transactions` | id, bill_id, payer_id, provider, phone_number, amount, status, idempotency_key (unique), provider_ref, failure_reason, initiated_at, confirmed_at, expires_at | status ∈ en_attente, reussie, echouee, expiree |
| `receipts` | id, transaction_id (unique), number (unique), issued_at, pdf_path, verification_code | 1 reçu par transaction réussie |
| `notifications` | id, user_id, type, title, body, data_json, read_at | |
| `audit_logs` | id, actor_id, action, entity_type, entity_id, before_json, after_json, ip, user_agent, created_at | jamais modifié ni supprimé ; IP + navigateur affichés en A10 |

Index sur : `meter_readings(meter_id, read_at)`, `bills(meter_id, period_start)`, `bills(status, due_date)`,
`payment_transactions(status, initiated_at)`, `notifications(user_id, read_at)`.

Terminé quand : `alembic upgrade head` crée tout sur une base vide ; `alembic downgrade base` revient à vide ;
tests sur les contraintes (unicité, montants entiers, enum).

Réalisé : schéma, relations et garde-fous (triggers MySQL) décrits dans `backend/docs/SCHEMA.md`.

**Besoins des maquettes validées à ajouter dans les étapes concernées** (chacun avec sa propre migration) :

| Besoin (écran) | Étape | Ce qu'il faudra |
|---|---|---|
| Code de réinitialisation à 6 chiffres (client 4) | B3 | table des codes (haché, expiration, nombre d'essais) |
| Double authentification de l'équipe (A11) | B3 / B10 | secret TOTP chiffré par membre de l'équipe |
| Désactivation avec motif, fermeture des sessions (A3) | B3 / B10 | motif dans `audit_logs` + révocation des `refresh_tokens` |
| Interrupteurs d'alertes (client 14) | B9 | préférences de notification par utilisateur |
| Annonces ciblées, programmées, taux de lecture (A9) | B9 / B10 | table des annonces (cible, date d'envoi) liée aux `notifications` |
| Anomalie de relevé : « relevé de contrôle » / « classer sans suite » (A4) | B10 | statut de traitement de l'anomalie |
| PIN saisi mais débit non confirmé : pas d'expiration (A8) | B7 | état « PIN saisi » sur la transaction |
| Opérateur choisi MTN MoMo / Airtel Money (client 8) | B7 | colonne `operator` distincte de `provider` (qui vaut `simulated` en démo : aucune donnée simulée présentée comme réelle) |
| « Ouvrir un litige » (A8) | B10 | table des litiges |
| Durée de conservation du journal (loi congolaise) | B11 | à définir ; le journal est aujourd'hui strictement non supprimable |

Note : les données de démonstration des maquettes montrent une facture **mensuelle** (octobre 2026, 12 500 FCFA).
La référence reste la vraie facture E²C (bimestrielle, `backend/docs/FACTURE_E2C.md`) ; le mois est servi par les vues
d'estimation de B5.

---

## B2 — Simulateurs et données de démo

**Objectif :** une base qui ressemble à la réalité, recréable en une commande.

- `scripts/seed.py` (et `reset_db.py`) : 1 super admin, 1 admin, 1 support, ~10 clients, 1 à 3 foyers chacun, 1 à 2 compteurs par foyer.
- **Tarif :** structure et valeurs relevées sur une vraie facture E²C BT (voir `backend/docs/FACTURE_E2C.md`) :
  49,08 FCFA/kWh, droit à la consommation, TVA 18 %, C.A. 5 % de la TVA, RAV, timbre.
  Stocké comme tarif daté et **marqué hypothèse** jusqu'à vérification sur 5 à 10 vraies factures E²C.
- **Calcul :** troncature au FCFA à chaque ligne (comme E²C : 571 × 49,08 = 28 024,68 → 28 024).
  Test de référence : reproduire exactement la facture réelle (571 kWh → 40 384 FCFA).
- **Relevés :** 18 mois d'historique par compteur, un relevé par jour, avec des profils réalistes
  (petit ménage, famille, commerce), saisons, week-ends, quelques jours de coupure, de rares anomalies.
  L'index ne descend jamais sauf anomalie volontaire marquée.
- **Factures :** **bimestrielles** comme E²C (durée paramétrable, `BILLING_PERIOD_MONTHS=2`), générées à partir des relevés
  et du tarif en vigueur ; anciennes payées, quelques impayées, une ou deux en retard.
- **Paiements :** historique cohérent avec les factures payées (dont quelques échecs).
- Job quotidien (commande ou tâche planifiée) qui ajoute le relevé du jour, pour que l'app « vive ».

Terminé quand : `python -m scripts.reset_db && python -m scripts.seed` donne une base complète en moins d'une minute ;
les totaux des factures = somme de leurs lignes ; la consommation facturée = somme des relevés de la période (tests).

Réalisé :
- `app/modules/bills/calculator.py` : **unique** moteur de calcul (troncature, entiers) ; reproduit la vraie facture
  au franc près (571 kWh → 40 384 FCFA). Réutilisé par B5 (estimations) et B6 (factures).
- `app/simulators/` : relevés (3 profils, saisons, coupures, anomalies), factures bimestrielles calées sur le calendrier,
  historique de paiements (échecs, expirations, payeur délégué), jeu de démo fictif, écriture en base commune,
  relevé quotidien `scripts.daily_tick` (idempotent, rattrape les jours manqués, émet les factures, passe en retard).
- `app/core/security.py` (Argon2id) et `app/core/timezone.py` (UTC+1) : réutilisés par B3 et B5.
- Mesuré sur la base de dev : reset + seed en ~19 s ; 144/144 factures conformes aux deux critères.
- À reprendre en B5 : l'estimation sur 1 mois doit répartir la RAV (1 000 FCFA par facture de 2 mois, hypothèse).
- À reprendre en B6 : l'émission des factures du relevé quotidien passera par le service `generate_bill`.

---

## B3 — Comptes et authentification

| Méthode | Route | Rôle |
|---|---|---|
| POST | `/auth/register` | public |
| POST | `/auth/login` | public (téléphone + mot de passe) |
| POST | `/auth/refresh` | public (refresh token) |
| POST | `/auth/logout` | connecté |
| POST | `/auth/password/forgot` | public (code OTP simulé, affiché en mode démo) |
| POST | `/auth/password/reset` | public |
| GET / PATCH | `/me` | connecté |
| POST | `/me/password` | connecté |

- Argon2 ; access token 15 min ; refresh 30 jours, rotatif ; réutilisation d'un refresh révoqué → révocation de toute la famille.
- Dépendances `current_user` et `require_role(...)`.
- Limitation des tentatives de connexion.
- Numéros au format congolais normalisé (+242…).

Terminé quand : tests de tous les cas (mauvais mot de passe, compte désactivé, jeton expiré, refresh réutilisé, rôle insuffisant).

Réalisé (guide pour Flutter et Next.js : `backend/docs/AUTHENTIFICATION.md`) :
- Jeton d'accès JWT HS256 (15 min, algorithme imposé) ; refresh opaque 64 car. (empreinte SHA-256), rotatif,
  familles, réutilisation → famille révoquée ; `current_user` relit le compte à chaque requête.
- Routes ajoutées au plan : `POST /auth/logout-all` ; mode navigateur du back-office `POST /auth/web/{login,refresh,logout}`
  (cookies httpOnly + Secure + SameSite=Strict, CSRF « double cookie » `X-CSRF-Token`, réservé à l'équipe).
- Mot de passe oublié : table `password_reset_codes` (code HMAC, 10 min, 5 essais, usage unique), SMS via
  `SmsSender` (simulé), code renvoyé en mode démo ; réinitialisation et changement → appareils déconnectés + audit.
- Limitation des tentatives en mémoire (`app/core/rate_limit.py`), limites dans `app/modules/auth/rate_limits.py`.
- Numéros normalisés en +242 (04, 05, 06, 22) ; mot de passe ≥ 8 car. avec lettre et chiffre.
- À reprendre en B11 : IP réelle derrière un proxy (X-Forwarded-For), compteurs partagés si plusieurs processus.
- Pour Flutter : un seul rafraîchissement à la fois. Pour Next.js : appeler l'API via le serveur Next (même site).

---

## B4 — Foyers, compteurs et délégation

| Méthode | Route | Description |
|---|---|---|
| GET / POST | `/households` | mes foyers / créer |
| GET / PATCH | `/households/{id}` | détail / modifier |
| GET / POST | `/households/{id}/members` | membres / inviter (par téléphone) |
| DELETE | `/households/{id}/members/{member_id}` | retirer un membre |
| POST | `/invitations/{id}/accept` | accepter une invitation |
| GET / POST | `/households/{id}/meters` | compteurs / ajouter par référence |
| GET / PATCH | `/meters/{id}` | détail / renommer |

- Un utilisateur ne voit que les foyers dont il est membre (test d'accès croisé obligatoire).
- Payeur délégué : peut voir et payer les factures du foyer, pas le modifier.
- Ajout de compteur : vérifié via `BillingSource` (simulé aujourd'hui, E²C demain).

Réalisé (guide pour Flutter : `backend/docs/FOYERS_COMPTEURS.md`) :
- Règles d'accès centralisées (`app/modules/households/access.py`) : propriétaire, payeur, lecteur ;
  pas d'accès → 404 identique à « n'existe pas » ; numéros des autres toujours masqués.
- Routes ajoutées au plan : `GET /invitations`, `POST /invitations/{id}/decline`, `POST /households/{id}/leave`,
  `GET /households/{id}/members`.
- Décisions (12/11/2026) : personne invitée = compte existant ; ajout de compteur = N° branchement + N° client
  (preuve de la facture) ; en démo, 18 mois d'historique importés (anciennes factures payées hors ElecPay,
  sans transaction inventée).
- Interfaces `BillingSource` (vérifier un compteur) et `ConsumptionSource` (importer son historique),
  simulées, choisies par `BILLING_SOURCE`. Limites : 10 foyers, 10 membres, 5 compteurs ; 20 invitations / jour.
- Le métier ne dépend plus des simulateurs : notifications créées par `app/modules/notifications/service.py`.

---

## B5 — Consommation

| Méthode | Route | Description |
|---|---|---|
| GET | `/meters/{id}/consumption?granularity=day\|week\|month\|bimester\|quarter\|semester\|year&from=&to=` | série agrégée en kWh **et** coût estimé en FCFA |
| GET | `/meters/{id}/consumption/summary` | ce mois, mois dernier, variation %, moyenne journalière, estimation fin de mois |
| GET | `/meters/{id}/readings` | relevés bruts paginés |

- Chaque valeur indique si elle est estimée. Jamais présentée comme « temps réel ».
- **Vue par période (demande de Loick) :** l'abonné consulte sa consommation et son coût par mois, bimestre,
  trimestre, semestre ou année. Le coût est calculé avec **le même moteur que les factures** (tarif en vigueur,
  troncature, TVA, C.A.…) et affiché comme **« estimation »**, jamais comme une facture officielle.
  La facture officielle reste bimestrielle (B6). La somme de deux estimations mensuelles peut différer de
  quelques francs de la facture bimestrielle (troncature par ligne) : c'est attendu et documenté.
- Estimation de fin de mois en kWh **et** en FCFA, avec le tarif en vigueur.

Réalisé (guide pour Flutter : `backend/docs/CONSOMMATION.md`) :
- Moteur d'agrégation pur (`app/modules/consumption/aggregation.py`) : 7 granularités calées sur le calendrier,
  journée locale de Brazzaville ; états estimé / anomalie / incomplet / en cours ; total indépendant du découpage.
- Deux coûts (choix du 12/11/2026) : `energy_cost` (énergie seule, maquette) et `estimated_total` (facture
  estimée, RAV et timbre au prorata, 1 à 12 mois) via le moteur unique (`costs.py`) ; un bimestre estimé =
  la facture émise au franc près ; tarif appliqué jour par jour.
- Routes ajoutées au plan : `GET /meters/{id}/consumption/days/{date}` (onglet Jour : index, moyenne du même
  jour, classement) ; comparaisons `last_year` / `previous` sur les mêmes journées relevées.
- Pagination commune `app/core/pagination.py` (`Page[T]`, `paginate`), réutilisée par B6, B7 et B10.
- Mesuré sur la base de démo : 40 à 130 ms par requête. Bug trouvé en vérification réelle et corrigé :
  une comparaison sur plus de 12 mois provoquait une erreur 500.

---

## B6 — Factures

| Méthode | Route | Description |
|---|---|---|
| GET | `/bills?status=&meter_id=&year=` | liste filtrée (tous mes foyers) |
| GET | `/bills/{id}` | détail avec lignes, période, consommation, échéance |
| GET | `/bills/{id}/pdf` | facture en PDF |

- Service `generate_bill(meter, period)` : unique endroit qui calcule une facture ; idempotent.
  Le calcul lui-même est une fonction pure (relevés + tarif → lignes), réutilisée par les estimations de B5.
- Structure et calculs conformes à `backend/docs/FACTURE_E2C.md` (troncature par ligne).
- Passage automatique en `overdue` après échéance.
- Facture payée : aucune modification possible (test).

Réalisé (guide pour Flutter : `backend/docs/FACTURES.md`), sous-étapes validées une à une par Loick :
- **B6.1** `generate_bill` (`app/modules/bills/service.py`) : unique endroit qui crée une facture (garde-fou
  d'architecture testé) ; idempotent ; refuse une période annulée, non close, sans tarif, ou dont un relevé de
  facturation manque / est en anomalie (erreurs `BillingError`). Périodes et dates dans `periods.py`.
  Décisions : compteur détaché facturé (E²C facture le compteur) ; **numéro = AAAAMMJJ + séquence du jour
  d'émission** ; émissions simultanées sérialisées par un verrou sur les numéros du jour ; tarif = celui du
  premier jour de la période ; source `e2c` seulement si tous les relevés viennent d'E²C.
- **B6.2** relevé quotidien, seed et import d'historique passent par `generate_bill` ; `mark_overdue_bills`
  (seules les `unpaid`, lendemain de l'échéance, propriétaire prévenu). Seed vérifié identique au franc
  près (144 factures, 6 284 343 FCFA) ; seuls les numéros changent. Textes des notifications de facture
  dans `bills/notifications.py`, `format_fcfa` dans `app/core/money.py`.
- **B6.3** `GET /bills` (`queries.py`) : filtres `status` (`to_pay` = impayées + en retard + en cours ;
  annulées seulement sur demande), `household_id`, `meter_id`, `year` ; « reste à payer » (`outstanding`,
  suit foyer et compteur, ignore statut et année) ; **retard affiché à la lecture** sans modifier la base ;
  `can_pay` = propriétaire ou payeur délégué ET facture impayée ou en retard (jamais en cours de paiement).
- **B6.4** `GET /bills/{id}` : lignes (valeurs exactes en entiers + valeurs d'affichage), index, tarif
  (hypothèse signalée), comparaison avec la facture précédente non annulée du même compteur ; facture
  annulée consultable avec son motif ; autre foyer = `404 BILL_NOT_FOUND`, comme une facture inexistante.
- **B6.5** `GET /bills/{id}/pdf` (`pdf.py`, fpdf2) : mise en page E²C aux couleurs de la charte, bandeau
  « Mode démo » si simulé, « seule la facture E²C fait foi », filigrane « ANNULÉE » ; généré à la demande,
  jamais stocké, `Cache-Control: private, no-store`. Police Helvetica intégrée (latin-1).
- **B6.6** tests d'acceptation `test_b6_acceptance.py` (cycle émission → retard par le relevé quotidien,
  facture payée figée même en SQL brut, écrans 6 et 7 par rôle). Vérifié sur l'API lancée avec la base de
  démo : liste 40–80 ms, détail 33–113 ms, PDF 60–150 ms (~3,4 Ko).

---

## B7 — Paiements

| Méthode | Route | Description |
|---|---|---|
| POST | `/payments` | initier (bill_id, provider, phone, en-tête `Idempotency-Key`) |
| GET | `/payments/{id}` | état d'une transaction |
| GET | `/payments` | historique filtré |
| POST | `/webhooks/payments/{provider}` | confirmation du prestataire (signature vérifiée) |

- Interface `PaymentProvider` : `initiate()`, `check_status()`, `verify_webhook()`.
- `SimulatedProvider` : confirme après quelques secondes ; scénarios réglables via le numéro de test
  (succès, solde insuffisant, refus, délai dépassé, statut inconnu).
- Verrou : une seule transaction `en_attente` par facture ; montant = montant de la facture, jamais choisi par le client.
- Même `Idempotency-Key` → même transaction, jamais un double débit.
- Expiration automatique des transactions en attente trop longtemps (10 min sans saisie du code PIN). Exception : PIN saisi mais débit non confirmé → reste `en_attente` jusqu'à la réponse de l'opérateur ou une relance admin (voir maquette admin A8).
- Paiement pour un proche : autorisé si payeur délégué du foyer.

Terminé quand : tests de double clic, double webhook, webhook mal signé, paiement d'une facture déjà payée, échec puis nouvelle tentative.

---

## B8 — Reçus

| Méthode | Route | Description |
|---|---|---|
| GET | `/receipts` | mes reçus |
| GET | `/receipts/{id}` | détail |
| GET | `/receipts/{id}/pdf` | PDF |
| GET | `/receipts/verify/{code}` | vérification publique d'un reçu |

- Créé automatiquement à la confirmation du paiement ; numéro séquentiel `EP-2026-000123` ; mention « mode démo » tant que c'est simulé.

---

## B9 — Notifications

| Méthode | Route | Description |
|---|---|---|
| GET | `/notifications` | liste |
| POST | `/notifications/{id}/read` · `/notifications/read-all` | marquer lu |
| GET | `/notifications/unread-count` | badge |

Événements : nouvelle facture, échéance proche, facture en retard, paiement réussi / échoué, invitation reçue, consommation anormale.
(Envoi push FCM : phase 2.)

---

## B10 — API d'administration (`/api/v1/admin`)

| Domaine | Routes | Rôles |
|---|---|---|
| Tableau de bord | `GET /stats` (utilisateurs, factures par statut, montants encaissés, taux d'échec) | support, admin |
| Utilisateurs | liste filtrée, détail, activer/désactiver, changer le rôle | lecture : support ; écriture : admin ; rôles : super_admin |
| Compteurs | liste, détail, rattacher/détacher | admin |
| Factures | liste, détail, annuler (motif obligatoire) | admin |
| Transactions | liste, détail, relancer la vérification chez le prestataire | admin ; **jamais** de passage manuel à `reussie` |
| Notifications | envoyer une annonce | admin |
| Journaux | `GET /audit-logs` filtrés | admin, super_admin |

Chaque action d'écriture admin → une ligne `audit_logs` (test).

---

## B11 — Durcissement et contrat d'API

- Rate limiting global et sur l'auth ; en-têtes de sécurité ; CORS limité aux origines connues.
- Journalisation structurée ; aucun mot de passe, jeton ou numéro complet dans les logs.
- Export du contrat `openapi.json` dans `backend/openapi.json` (sert de référence au mobile et à l'admin).
- Tests de parcours complets : inscription → ajout compteur → consultation → paiement → reçu → historique ; et côté admin.
- Couverture visée ≥ 80 % sur `modules/` et `integrations/`.
- `Dockerfile` de l'API prêt pour le déploiement.

Terminé quand : le backend permet de faire **tout** le parcours client et admin uniquement depuis `/docs`, sans erreur.
C'est le feu vert pour commencer Flutter.
