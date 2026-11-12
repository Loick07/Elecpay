# ElecPay — Plan de construction du backend (A → Z)

Ce document est la feuille de route du backend. On le suit **dans l'ordre**, une étape à la fois.
Une étape n'est terminée que quand **tous** ses critères « Terminé quand » sont vrais.
À la fin de chaque étape : tests + Ruff au vert, commit, push, et mise à jour du tableau ci-dessous.

## Tableau de bord

| Étape | Nom | État |
|---|---|---|
| B0 | Socle technique | ✅ terminé (12/11/2026) |
| B1 | Modèle de données | prochaine étape |
| B2 | Simulateurs et données de démo | à faire |
| B3 | Comptes et authentification | à faire |
| B4 | Foyers, compteurs et délégation | à faire |
| B5 | Consommation | à faire |
| B6 | Factures | à faire |
| B7 | Paiements | à faire |
| B8 | Reçus | à faire |
| B9 | Notifications | à faire |
| B10 | API d'administration | à faire |
| B11 | Durcissement et contrat d'API | à faire |

Après B11 seulement : application Flutter, puis back-office Next.js.

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
