// CODE GÉNÉRÉ depuis backend/openapi.json : ne pas modifier à la main.
// Régénérer : npm run generate:api (vérifié par tool/api-types.test.ts).

export interface paths {
    "/api/v1/admin/alert-settings": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Alertes automatiques : lesquelles sont activées pour toute la plateforme (A9) */
        get: operations["get_alert_settings_api_v1_admin_alert_settings_get"];
        /**
         * Activer ou couper une alerte automatique pour toute la plateforme
         * @description Rappels d'échéance, avis et rappels de retard, consommation inhabituelle. Couper une alerte n'arrête que les notifications : une facture échue passe quand même « en retard ». Les réglages de chaque abonné (écran 14) s'appliquent en plus. Inscrit au journal.
         */
        put: operations["update_alert_settings_api_v1_admin_alert_settings_put"];
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/announcements": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Annonces envoyées ou programmées, avec leur taux de lecture (A9) */
        get: operations["list_announcements_api_v1_admin_announcements_get"];
        put?: never;
        /**
         * Envoyer ou programmer une annonce
         * @description Cibles : all (tous les clients), overdue (foyers ayant une facture en retard : titulaires et payeurs délégués), district (tous les membres des foyers du quartier), client. Sans `scheduled_at` : envoi immédiat (refusé s'il n'y a aucun destinataire). Avec : programmée (5 min à 90 jours), envoyée par la tâche `scripts.send_announcements` ; les destinataires sont alors calculés à l'envoi. Une notification « announcement » par personne, que l'abonné ne peut pas couper. Push : phase 2. Inscrit au journal.
         */
        post: operations["create_announcement_api_v1_admin_announcements_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/announcements/audience": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Nombre de destinataires d'une cible, si l'annonce partait maintenant */
        get: operations["preview_audience_api_v1_admin_announcements_audience_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/announcements/districts": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Quartiers connus (choix de la cible « un quartier ») */
        get: operations["list_districts_api_v1_admin_announcements_districts_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/announcements/{announcement_id}/cancel": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /** Annuler une annonce programmée (pas encore envoyée) */
        post: operations["cancel_announcement_api_v1_admin_announcements__announcement_id__cancel_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/audit-logs": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Journal d'activité (A10) : toutes les actions sensibles, les plus récentes d'abord
         * @description Filtres : `domain` (premier mot de l'action : bill, payment, user…), `action` exacte, `actor` (team, client, system), `actor_id`, `entity_type` + `entity_id`, `from` / `to` (dates incluses, heure de Brazzaville). Chaque ligne : avant / après, IP, navigateur. Ni modifiable ni supprimable (aucune route, et la base l'interdit).
         */
        get: operations["list_journal_api_v1_admin_audit_logs_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/audit-logs/domains": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Types d'actions présents dans le journal (filtres de l'écran A10) */
        get: operations["list_domains_api_v1_admin_audit_logs_domains_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/bills": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Factures (A5) : totaux du mois, filtres, recherche
         * @description `status` : unpaid (échéance pas encore dépassée), overdue, pending_payment, paid, cancelled. `month` (AAAA-MM) filtre sur le mois d'émission ; les totaux portent sur ce mois, ou sur le mois en cours sans filtre. Les plus récentes d'abord.
         */
        get: operations["list_bills_api_v1_admin_bills_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/bills/export.csv": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Exporter les factures en CSV (mêmes filtres que la liste)
         * @description UTF-8, séparateur « ; ». 10 000 lignes au plus (`422 EXPORT_TOO_LARGE` sinon). Inscrit au journal.
         */
        get: operations["export_bills_api_v1_admin_bills_export_csv_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/bills/{bill_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Détail d'une facture (A6)
         * @description Lignes, période, index, tarif appliqué, source des relevés, payeurs autorisés, transactions liées (numéros masqués), historique, facture remplacée ou de remplacement. Montants jamais modifiables.
         */
        get: operations["bill_detail_api_v1_admin_bills__bill_id__get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/bills/{bill_id}/cancel": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Annuler une facture (motif d'au moins 10 caractères)
         * @description Jamais de suppression. Refusé si la facture est payée, déjà annulée ou si un paiement est en cours. La période peut ensuite être réémise. Inscrit au journal.
         */
        post: operations["cancel_bill_api_v1_admin_bills__bill_id__cancel_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/bills/{bill_id}/reissue": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Réémettre la période d'une facture annulée
         * @description Nouvelle facture calculée avec les relevés de facturation actuels et le tarif du début de période ; nouveau numéro, émise aujourd'hui, échéance dans 15 jours. Le titulaire et les payeurs délégués sont prévenus. Erreurs de facturation renvoyées telles quelles (relevé manquant, en anomalie…). Inscrit au journal.
         */
        post: operations["reissue_bill_api_v1_admin_bills__bill_id__reissue_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/integrations": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Intégrations (A11) : simulateurs ou services branchés, mode démo
         * @description Aucun secret n'est renvoyé (seulement s'il est configuré ou non).
         */
        get: operations["integrations_api_v1_admin_integrations_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/meters": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Compteurs (A4) : état du jour, anomalies, compteurs inactifs
         * @description `today` : received, anomaly, missing (actif et rattaché sans relevé ce matin), inactive (suspendu, résilié ou détaché). `attached` : true / false. Recherche par N° de branchement, N° client, nom du compteur, du foyer ou du titulaire. Les compteurs du haut de l'écran ignorent les filtres. Heure de Brazzaville ; énergies en Wh.
         */
        get: operations["list_meters_api_v1_admin_meters_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/meters/{meter_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Détail d'un compteur (A4, panneau)
         * @description Index d'hier et d'aujourd'hui, explication, foyer, dernière facture, anomalies non classées, 14 derniers relevés.
         */
        get: operations["meter_detail_api_v1_admin_meters__meter_id__get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/meters/{meter_id}/anomalies/{reading_id}/control": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Demander un relevé de contrôle pour une anomalie
         * @description Note facultative. Le relevé n'est pas modifié (il reste exclu des factures) ; la demande est notée (auteur, date) et inscrite au journal.
         */
        post: operations["request_control_api_v1_admin_meters__meter_id__anomalies__reading_id__control_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/meters/{meter_id}/anomalies/{reading_id}/dismiss": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Classer une anomalie sans suite (note obligatoire)
         * @description Possible aussi après une demande de contrôle. Le relevé reste gardé et exclu des factures. Inscrit au journal.
         */
        post: operations["dismiss_anomaly_api_v1_admin_meters__meter_id__anomalies__reading_id__dismiss_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/meters/{meter_id}/attach": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Rattacher un compteur détaché à un foyer (motif obligatoire)
         * @description 5 compteurs au plus par foyer. Refusé si un paiement est en cours sur l'une de ses factures. Inscrit au journal.
         */
        post: operations["attach_meter_api_v1_admin_meters__meter_id__attach_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/meters/{meter_id}/detach": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Détacher un compteur de son foyer (motif obligatoire)
         * @description Relevés et factures restent attachés au compteur. Refusé si un paiement est en cours sur l'une de ses factures. Inscrit au journal.
         */
        post: operations["detach_meter_api_v1_admin_meters__meter_id__detach_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/permissions": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Mes droits dans le back-office (matrice de l'onglet « Permissions », A11)
         * @description Pour afficher ou masquer les boutons. Le serveur contrôle de toute façon chaque route (403 sinon). « Marquer une transaction comme réussie » : jamais.
         */
        get: operations["my_permissions_api_v1_admin_permissions_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/stats": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Tableau de bord (A1) : indicateurs, encaissements 30 jours, points à surveiller
         * @description Encaissé du mois (comparé au mois précédent au même moment), factures impayées, taux de paiements non aboutis sur 7 jours, transactions en attente, encaissements jour par jour, dernière période facturée par statut, points « À surveiller », activité récente de l'équipe. Heure de Brazzaville ; FCFA entiers.
         */
        get: operations["admin_stats_api_v1_admin_stats_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/tariffs": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Tarifs datés (A11), avec le nombre de factures émises par version */
        get: operations["list_tariffs_api_v1_admin_tariffs_get"];
        put?: never;
        /**
         * Créer une nouvelle version datée d'un tarif
         * @description À partir de demain au plus tôt, après la dernière version du même code ; la version en cours s'arrête à cette date. Les factures émises ne changent jamais ; une facture prend le tarif en vigueur au premier jour de sa période. Renvoie tous les tarifs. Inscrit au journal.
         */
        post: operations["create_tariff_api_v1_admin_tariffs_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/team": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Équipe (A11) : membres, rôle, dernière connexion, invitation en attente
         * @description `two_factor` : enabled, pending (QR code affiché, pas confirmée) ou disabled.
         */
        get: operations["list_team_api_v1_admin_team_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/team/invite": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Inviter un membre de l'équipe (support, admin ou super admin)
         * @description Crée le compte et envoie par SMS un code pour choisir le mot de passe ; le code n'est jamais montré à l'équipe. Refusé si le numéro ou l'e-mail a déjà un compte (un client n'est jamais promu). Inscrit au journal.
         */
        post: operations["invite_member_api_v1_admin_team_invite_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/team/{member_id}/2fa/reset": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Réinitialiser la double authentification d'un membre (téléphone perdu)
         * @description Motif obligatoire. Efface sa 2FA et ses codes de secours, ferme toutes ses sessions ; il la réactive à sa prochaine connexion. Jamais sur soi-même. Inscrit au journal.
         */
        post: operations["reset_two_factor_api_v1_admin_team__member_id__2fa_reset_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/team/{member_id}/role": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        /**
         * Changer le rôle d'un membre de l'équipe (motif obligatoire)
         * @description Effet immédiat (le rôle est relu à chaque requête). Personne ne change son propre rôle ; il reste toujours au moins un super admin actif. Inscrit au journal.
         */
        put: operations["change_role_api_v1_admin_team__member_id__role_put"];
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/transactions": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Transactions (A7) : indicateurs du jour, filtres, numéros masqués
         * @description `status` : en_attente, reussie, echouee, expiree, to_reconcile (anomalie signalée par l'opérateur, sans litige clos), open_dispute. Recherche par TX-…, N° de facture, nom du payeur, référence opérateur ou numéro (au moins 3 chiffres). `day` : transactions lancées ce jour-là. Les plus récentes d'abord.
         */
        get: operations["list_transactions_api_v1_admin_transactions_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/transactions/{transaction_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Détail et rapprochement d'une transaction (A8)
         * @description Comparaison ElecPay ↔ opérateur (d'après la dernière vérification par l'équipe), chronologie, clé d'idempotence, verrou de facture, anomalies signalées, litiges. Pas de bouton « Marquer comme payée » : il n'existe pas.
         */
        get: operations["transaction_detail_api_v1_admin_transactions__transaction_id__get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/transactions/{transaction_id}/disputes": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Ouvrir un litige (le client affirme avoir été débité)
         * @description Motif d'au moins 10 caractères ; référence du SMS de débit facultative. Un seul litige ouvert par transaction. Ne change ni la transaction ni la facture. Inscrit au journal.
         */
        post: operations["open_dispute_api_v1_admin_transactions__transaction_id__disputes_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/transactions/{transaction_id}/disputes/{dispute_id}/close": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Clore un litige avec la conclusion de l'opérateur
         * @description `resolution` : no_debit, refunded, debit_confirmed ; note d'au moins 10 caractères. La conclusion est enregistrée, jamais appliquée au paiement : un débit confirmé se régularise hors ElecPay. Un litige clos ne change plus. Inscrit au journal.
         */
        post: operations["close_dispute_api_v1_admin_transactions__transaction_id__disputes__dispute_id__close_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/transactions/{transaction_id}/recheck": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Relancer la vérification auprès de l'opérateur
         * @description Demande l'état du débit à l'opérateur et l'applique par le même chemin que les webhooks : un succès n'est enregistré que si l'opérateur le confirme (montant identique). Une réponse qui contredit une transaction terminée ne modifie rien et est signalée. 503 si l'opérateur ne répond pas (rien n'est modifié). Inscrit au journal.
         */
        post: operations["recheck_transaction_api_v1_admin_transactions__transaction_id__recheck_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/users": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Utilisateurs (A2) : recherche, filtres, impayés, dernière connexion
         * @description Recherche par nom ou par numéro (au moins 3 chiffres). `kind` : client, delegated_payer (payeur actif dans au moins un foyer), team. Numéros masqués pour le support. Les plus récents d'abord. Pagination : `page`, `size`.
         */
        get: operations["list_users_api_v1_admin_users_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/users/export.csv": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Exporter les utilisateurs en CSV (mêmes filtres que la liste)
         * @description UTF-8, séparateur « ; » (Excel en français). 10 000 lignes au plus (`422 EXPORT_TOO_LARGE` sinon). Sortie de données personnelles : inscrite au journal.
         */
        get: operations["export_users_api_v1_admin_users_export_csv_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/users/{user_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Détail d'un utilisateur (A3)
         * @description Identité, foyers et compteurs, transactions récentes, résumé financier, sessions ouvertes, journal du compte, motif de la dernière désactivation.
         */
        get: operations["user_detail_api_v1_admin_users__user_id__get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/users/{user_id}/deactivate": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Désactiver un compte (motif obligatoire ; ferme toutes ses sessions)
         * @description Factures et historique conservés ; réactivable. Personne ne se désactive soi-même ; seul un super admin agit sur un compte de l'équipe. Inscrit au journal.
         */
        post: operations["deactivate_api_v1_admin_users__user_id__deactivate_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/users/{user_id}/reactivate": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /** Réactiver un compte */
        post: operations["reactivate_api_v1_admin_users__user_id__reactivate_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/admin/users/{user_id}/reset-code": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Envoyer à l'utilisateur un code de réinitialisation du mot de passe (SMS)
         * @description Le code part par SMS au titulaire du compte ; il n'est jamais montré à l'équipe ni écrit au journal (seul l'envoi y figure).
         */
        post: operations["send_reset_code_api_v1_admin_users__user_id__reset_code_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/auth/login": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Se connecter (téléphone + mot de passe)
         * @description Clients : renvoie les jetons. Membre de l'équipe avec la double authentification : renvoie `two_factor_required: true` et un `challenge_token` (5 min), à compléter avec `POST /auth/login/2fa`.
         */
        post: operations["login_api_v1_auth_login_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/auth/login/2fa": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Connexion, étape 2 : code de double authentification (équipe)
         * @description Code à 6 chiffres de l'application d'authentification, ou un code de secours (usage unique). 5 codes faux au plus en 15 minutes.
         */
        post: operations["login_two_factor_api_v1_auth_login_2fa_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/auth/logout": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Se déconnecter de cet appareil
         * @description Révoque le jeton de rafraîchissement. Répond 204 même s'il est déjà invalide.
         */
        post: operations["logout_api_v1_auth_logout_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/auth/logout-all": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Déconnecter tous mes appareils
         * @description Le jeton d'accès en cours reste valable jusqu'à son expiration (15 min au plus).
         */
        post: operations["logout_all_api_v1_auth_logout_all_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/auth/password/forgot": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Mot de passe oublié : recevoir un code par SMS
         * @description Répond toujours la même chose, que le numéro ait un compte ou non. En mode démo, le code est renvoyé dans `demo_code` (aucun SMS réel).
         */
        post: operations["forgot_password_api_v1_auth_password_forgot_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/auth/password/reset": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Choisir un nouveau mot de passe avec le code reçu
         * @description Déconnecte tous les appareils. Se reconnecter ensuite avec le nouveau mot.
         */
        post: operations["reset_password_api_v1_auth_password_reset_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/auth/refresh": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /** Obtenir de nouveaux jetons (rotation du jeton de rafraîchissement) */
        post: operations["refresh_api_v1_auth_refresh_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/auth/register": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /** Créer un compte client */
        post: operations["register_api_v1_auth_register_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/auth/web/login": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Connexion au back-office (cookies httpOnly)
         * @description Dépose les cookies `elecpay_access`, `elecpay_refresh` (httpOnly) et `elecpay_csrf` (à recopier dans l'en-tête `X-CSRF-Token` des requêtes qui modifient). Avec la double authentification : aucun cookie, mais `two_factor_required: true` et un `challenge_token`, à compléter avec `POST /auth/web/login/2fa`.
         */
        post: operations["web_login_api_v1_auth_web_login_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/auth/web/login/2fa": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Connexion au back-office, étape 2 : code de double authentification
         * @description Dépose les cookies de session une fois le code accepté.
         */
        post: operations["web_login_two_factor_api_v1_auth_web_login_2fa_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/auth/web/logout": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Déconnexion du back-office
         * @description Révoque la session et efface les cookies ; exige l'en-tête `X-CSRF-Token`.
         */
        post: operations["web_logout_api_v1_auth_web_logout_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/auth/web/refresh": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Rafraîchir la session du back-office
         * @description Lit le cookie `elecpay_refresh` ; exige l'en-tête `X-CSRF-Token`.
         */
        post: operations["web_refresh_api_v1_auth_web_refresh_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/bills": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Mes factures (tous mes foyers), de la plus récente à la plus ancienne
         * @description Sans `status` : toutes les factures sauf les annulées. `to_pay` = impayées, en retard et en cours de paiement. Une facture impayée dont l'échéance est dépassée est renvoyée `overdue`. `outstanding` (reste à payer) tient compte de `household_id` et `meter_id`, pas de `status` ni de `year`. Pagination : `page`, `size` (≤ 100).
         */
        get: operations["list_bills_api_v1_bills_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/bills/{bill_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Détail d'une facture : lignes, index, tarif, comparaison avec la précédente
         * @description Les lignes reprennent la facture E²C (troncature au FCFA à chaque ligne). Une facture annulée reste consultable avec son motif.
         */
        get: operations["bill_detail_api_v1_bills__bill_id__get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/bills/{bill_id}/pdf": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Facture en PDF (copie d'information, mention « mode démo » si simulée)
         * @description Mêmes accès que le détail. Le PDF est généré à la demande (`Content-Disposition: attachment`). Il n'est jamais présenté comme la facture officielle E²C.
         */
        get: operations["bill_pdf_api_v1_bills__bill_id__pdf_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/health": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** État de l'API et de la base de données */
        get: operations["health_api_v1_health_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/households": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Mes foyers (possédés et ceux dont je suis membre) */
        get: operations["list_households_api_v1_households_get"];
        put?: never;
        /** Créer un foyer */
        post: operations["create_household_api_v1_households_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/households/{household_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Détail d'un foyer : compteurs, membres, mon rôle */
        get: operations["read_household_api_v1_households__household_id__get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        /** Modifier un foyer (propriétaire) */
        patch: operations["update_household_api_v1_households__household_id__patch"];
        trace?: never;
    };
    "/api/v1/households/{household_id}/leave": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /** Quitter un foyer (membre) */
        post: operations["leave_household_api_v1_households__household_id__leave_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/households/{household_id}/members": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Membres du foyer (le propriétaire voit aussi les invitations en attente) */
        get: operations["list_members_api_v1_households__household_id__members_get"];
        put?: never;
        /**
         * Inviter quelqu'un par son numéro (payeur délégué ou lecteur)
         * @description La personne doit déjà avoir un compte ElecPay. Elle reçoit une notification et un SMS, puis accepte ou refuse avec `/invitations/{id}/accept|decline`.
         */
        post: operations["invite_member_api_v1_households__household_id__members_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/households/{household_id}/members/{member_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        post?: never;
        /** Retirer un membre ou annuler une invitation (propriétaire) */
        delete: operations["remove_member_api_v1_households__household_id__members__member_id__delete"];
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/households/{household_id}/meters": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Compteurs d'un foyer */
        get: operations["list_meters_api_v1_households__household_id__meters_get"];
        put?: never;
        /**
         * Ajouter un compteur (N° branchement + N° client, vérifiés chez E²C)
         * @description En mode démo, 18 mois d'historique simulé sont importés (`history.source = "simulated"`).
         */
        post: operations["add_meter_api_v1_households__household_id__meters_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/invitations": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Mes invitations en attente */
        get: operations["my_invitations_api_v1_invitations_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/invitations/{invitation_id}/accept": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /** Accepter une invitation (renvoie le foyer rejoint) */
        post: operations["accept_invitation_api_v1_invitations__invitation_id__accept_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/invitations/{invitation_id}/decline": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /** Refuser une invitation */
        post: operations["decline_invitation_api_v1_invitations__invitation_id__decline_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/me": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Mon profil */
        get: operations["read_me_api_v1_me_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        /** Modifier mon nom ou mon e-mail */
        patch: operations["update_me_api_v1_me_patch"];
        trace?: never;
    };
    "/api/v1/me/2fa": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** État de ma double authentification */
        get: operations["my_two_factor_api_v1_me_2fa_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/me/2fa/backup-codes": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /** Nouveaux codes de secours (les anciens ne marchent plus) */
        post: operations["regenerate_backup_codes_api_v1_me_2fa_backup_codes_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/me/2fa/disable": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Désactiver ma double authentification (support seulement)
         * @description Mot de passe + code. Impossible pour admin et super admin (obligatoire). Inscrit au journal.
         */
        post: operations["disable_api_v1_me_2fa_disable_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/me/2fa/enable": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Activer (2/2) : confirmer avec un premier code
         * @description Renvoie 10 codes de secours, montrés UNE seule fois. Inscrit au journal.
         */
        post: operations["enable_api_v1_me_2fa_enable_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/me/2fa/setup": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Activer (1/2) : obtenir le QR code à scanner
         * @description Avec Google Authenticator, Microsoft Authenticator, Aegis… Rien n'est actif tant que le premier code n'a pas été confirmé (`/enable`). Recommencer remplace le QR code.
         */
        post: operations["start_setup_api_v1_me_2fa_setup_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/me/email/verification": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Recevoir un code pour vérifier mon adresse e-mail
         * @description Code à 6 chiffres envoyé à l'adresse du profil, valable 15 minutes ; un nouveau code annule le précédent. 3 demandes par heure. Une adresse vérifiée reçoit les reçus.
         */
        post: operations["request_verification_api_v1_me_email_verification_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/me/email/verification/confirm": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Confirmer mon adresse e-mail avec le code reçu
         * @description 5 essais par code. Renvoie le profil avec `email_verified_at`.
         */
        post: operations["confirm_verification_api_v1_me_email_verification_confirm_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/me/notification-preferences": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Mes interrupteurs « Me prévenir » (écran 14)
         * @description Par défaut : échéances et paiements activés, consommation inhabituelle désactivée. Les autres messages sont toujours envoyés.
         */
        get: operations["my_preferences_api_v1_me_notification_preferences_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        /**
         * Changer un ou plusieurs interrupteurs
         * @description Seuls les interrupteurs envoyés changent. Une alerte désactivée n'est plus créée du tout (rien ne s'accumule en secret).
         */
        patch: operations["change_preferences_api_v1_me_notification_preferences_patch"];
        trace?: never;
    };
    "/api/v1/me/password": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Changer mon mot de passe
         * @description Les autres appareils sont déconnectés ; cet appareil reçoit de nouveaux jetons.
         */
        post: operations["change_my_password_api_v1_me_password_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/meters/{meter_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Détail d'un compteur */
        get: operations["read_meter_api_v1_meters__meter_id__get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        /** Renommer un compteur (propriétaire) */
        patch: operations["rename_meter_api_v1_meters__meter_id__patch"];
        trace?: never;
    };
    "/api/v1/meters/{meter_id}/consumption": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Consommation agrégée par période (kWh et coût estimé)
         * @description Valeurs relevées (jamais en temps réel) jusqu'à `measured_until`. Par défaut : l'année en cours en mois ; comparaison avec l'an dernier (ou avec la période précédente pour les vues jour et semaine).
         */
        get: operations["consumption_series_api_v1_meters__meter_id__consumption_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/meters/{meter_id}/consumption/days/{day}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Détail d'une journée : index, coût, moyenne du même jour, classement dans le mois */
        get: operations["consumption_day_api_v1_meters__meter_id__consumption_days__day__get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/meters/{meter_id}/consumption/summary": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Résumé : ce mois, le mois dernier, la variation, l'estimation de fin de mois
         * @description L'estimation de fin de mois est une ESTIMATION (consommation relevée + moyenne journalière × jours restants) ; `basis` dit sur quelles journées elle repose.
         */
        get: operations["consumption_summary_api_v1_meters__meter_id__consumption_summary_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/meters/{meter_id}/readings": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Relevés bruts du compteur (du plus récent au plus ancien)
         * @description Filtres `from` / `to` : journée consommée. Pagination : `page`, `size` (≤ 100).
         */
        get: operations["meter_readings_api_v1_meters__meter_id__readings_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/notifications": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Mes notifications (écran 13), de la plus récente à la plus ancienne
         * @description `group` : `today`, `this_week` (depuis lundi), `earlier` — heure de Brazzaville. `data` permet d'ouvrir le bon écran (facture, paiement, reçu…). `unread_count` : non lues, tous filtres confondus. Pagination : `page`, `size`.
         */
        get: operations["list_notifications_api_v1_notifications_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/notifications/read-all": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /** Tout marquer comme lu */
        post: operations["read_all_api_v1_notifications_read_all_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/notifications/unread-count": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Nombre de notifications non lues (badge de la cloche) */
        get: operations["unread_count_api_v1_notifications_unread_count_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/notifications/{notification_id}/read": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /** Marquer une notification comme lue (sans effet si elle l'est déjà) */
        post: operations["read_one_api_v1_notifications__notification_id__read_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/payments": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Historique des paiements (écran 12), du plus récent au plus ancien
         * @description Paiements des factures de mes foyers (lecteurs compris) et mes propres paiements. Réussis, échoués (avec le motif), expirés et en cours ; `payer_name` dit qui a payé (titulaire ou payeur délégué). Filtres combinables : `status`, `bill_id`, `household_id`, `month` (AAAA-MM, heure de Brazzaville). Pagination : `page`, `size`.
         */
        get: operations["list_payments_api_v1_payments_get"];
        put?: never;
        /**
         * Payer une facture en Mobile Money (le montant est celui de la facture)
         * @description En-tête `Idempotency-Key` obligatoire (8 à 64 caractères : lettres, chiffres, `-`, `_`), une nouvelle clé par tentative. Renvoyer la même demande avec la même clé (double clic, réseau coupé) rend la même transaction (`200`), sans second débit. Ensuite, suivre l'état avec `GET /payments/{id}`. Prestataire injoignable : la transaction est créée `echouee` avec son motif, et la facture reste payable.
         */
        post: operations["create_payment_api_v1_payments_post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/payments/{payment_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * État d'un paiement (écran 9 « Confirmez sur votre téléphone »)
         * @description À interroger toutes les 2 à 3 secondes pendant l'attente. Une transaction en attente est vérifiée auprès du prestataire à chaque lecture ; sans code PIN au bout de 10 minutes, elle expire et la facture redevient payable. `step` donne l'étape : `requested` → `pin_entered` → `succeeded` | `failed` | `expired`. Visible par le payeur et les membres du foyer (numéro masqué pour les autres).
         */
        get: operations["get_payment_api_v1_payments__payment_id__get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/receipts": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Mes reçus, du plus récent au plus ancien
         * @description Reçus des paiements des factures de mes foyers (lecteurs compris) et de mes propres paiements. Filtres : `household_id`, `year` (année d'émission, heure de Brazzaville). Pagination : `page`, `size`.
         */
        get: operations["list_receipts_api_v1_receipts_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/receipts/verify/{code}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Vérification PUBLIQUE d'un reçu (sans connexion)
         * @description Avec le code imprimé sur le reçu (ou lu dans son QR code), avec ou sans tirets. Ne montre que le minimum : numéro, date, montant, période, compteur masqué, mode démo — ni nom, ni numéro de téléphone. Code inconnu : 404. Nombre de vérifications limité par adresse IP.
         */
        get: operations["verify_api_v1_receipts_verify__code__get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/receipts/{receipt_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Un reçu (écran 10) : montant, facture, payeur, code de vérification
         * @description Le numéro débité est toujours masqué : un reçu est fait pour être partagé.
         */
        get: operations["get_receipt_api_v1_receipts__receipt_id__get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/receipts/{receipt_id}/pdf": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Reçu en PDF (bouton « Télécharger » / « Partager » de l'écran 10)
         * @description Mêmes accès que le détail. QR code et code de vérification menant à la vérification publique ; bandeau « Mode démo » si le paiement est simulé. Généré à la demande (`Content-Disposition: attachment`).
         */
        get: operations["receipt_pdf_api_v1_receipts__receipt_id__pdf_get"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/webhooks/payments/{provider}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Notification du prestataire de paiement (signée)
         * @description Réservée au prestataire : pas de jeton, mais une signature HMAC obligatoire (`X-ElecPay-Signature: t=<horodatage>,v1=<hmac>` pour le simulateur). Seule voie, avec le suivi d'état, qui peut confirmer un paiement. Une notification reçue deux fois ne change rien la seconde fois.
         */
        post: operations["payment_webhook_api_v1_webhooks_payments__provider__post"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
}
export type webhooks = Record<string, never>;
export interface components {
    schemas: {
        /** AccountChange */
        AccountChange: {
            /** Id */
            id: number;
            /** Is Active */
            is_active: boolean;
            /**
             * Sessions Closed
             * @default 0
             */
            sessions_closed: number;
        };
        /**
         * AccountStatus
         * @enum {string}
         */
        AccountStatus: "active" | "disabled";
        /**
         * ActorKind
         * @enum {string}
         */
        ActorKind: "team" | "client" | "system";
        /** AdminBillDetail */
        AdminBillDetail: {
            /** Amount Fees */
            amount_fees: number;
            /** Amount Ht */
            amount_ht: number;
            /** Amount Tax */
            amount_tax: number;
            /** Amount Total */
            amount_total: number;
            /** Authorized Payers */
            authorized_payers: components["schemas"]["AuthorizedPayer"][];
            /** Billed Power Va */
            billed_power_va: number | null;
            /**
             * Can Cancel
             * @description État de la facture seulement (le rôle est vérifié à part)
             */
            can_cancel: boolean;
            /** Can Reissue */
            can_reissue: boolean;
            /** Cancelled At */
            cancelled_at: string | null;
            /** Cancelled By */
            cancelled_by: string | null;
            /** Cancelled Reason */
            cancelled_reason: string | null;
            /** Consumption Wh */
            consumption_wh: number;
            /** Contract Number */
            contract_number: string | null;
            /** Current Index Wh */
            current_index_wh: number;
            /** Customer Number */
            customer_number: string | null;
            /** Days Overdue */
            days_overdue: number;
            /**
             * Due Date
             * Format: date
             */
            due_date: string;
            /** E2C Center */
            e2c_center: string | null;
            /** History */
            history: components["schemas"]["HistoryEvent"][];
            /**
             * Household Id
             * @description NULL : compteur détaché depuis
             */
            household_id: number | null;
            /** Household Name */
            household_name: string | null;
            /** Id */
            id: number;
            /**
             * Issued At
             * Format: date-time
             */
            issued_at: string;
            /** Lines */
            lines: components["schemas"]["BillLinePublic"][];
            /** Meter Id */
            meter_id: number;
            /** Meter Label */
            meter_label: string | null;
            /** Meter Reference */
            meter_reference: string;
            /** Months Count */
            months_count: number;
            /** Owner Name */
            owner_name: string | null;
            /** Paid At */
            paid_at: string | null;
            /**
             * Period End
             * Format: date
             */
            period_end: string;
            /** Period Label */
            period_label: string;
            /**
             * Period Start
             * Format: date
             */
            period_start: string;
            /** Previous Index Wh */
            previous_index_wh: number;
            readings: components["schemas"]["ReadingSources"];
            /** Reference */
            reference: string;
            /** @description Facture réémise pour cette période */
            replaced_by: components["schemas"]["RelatedBill"] | null;
            /** @description Facture annulée que celle-ci remplace */
            replaces: components["schemas"]["RelatedBill"] | null;
            /** @description Statut affiché (en retard si échéance dépassée) */
            status: components["schemas"]["BillStatus"];
            tariff: components["schemas"]["TariffPublic"];
            /** Transactions */
            transactions: components["schemas"]["BillTransaction"][];
        };
        /**
         * AdminBillFilter
         * @description Filtres de l'écran A5 (le retard est calculé à la lecture, comme côté abonné).
         * @enum {string}
         */
        AdminBillFilter: "unpaid" | "overdue" | "pending_payment" | "paid" | "cancelled";
        /** AdminBillList */
        AdminBillList: {
            /** Items */
            items: components["schemas"]["AdminBillRow"][];
            /** Page */
            page: number;
            /** Size */
            size: number;
            /** Total */
            total: number;
            totals: components["schemas"]["MonthTotals"];
        };
        /** AdminBillRow */
        AdminBillRow: {
            /** Amount Total */
            amount_total: number;
            /** Consumption Wh */
            consumption_wh: number;
            /** Days Overdue */
            days_overdue: number;
            /**
             * Due Date
             * Format: date
             */
            due_date: string;
            /**
             * Household Id
             * @description NULL : compteur détaché depuis
             */
            household_id: number | null;
            /** Household Name */
            household_name: string | null;
            /** Id */
            id: number;
            /**
             * Issued At
             * Format: date-time
             */
            issued_at: string;
            /** Meter Id */
            meter_id: number;
            /** Meter Reference */
            meter_reference: string;
            /** Owner Name */
            owner_name: string | null;
            /** Paid At */
            paid_at: string | null;
            /** Period Label */
            period_label: string;
            /**
             * Period Start
             * Format: date
             */
            period_start: string;
            /** Reference */
            reference: string;
            /** @description Statut affiché (en retard si échéance dépassée) */
            status: components["schemas"]["BillStatus"];
        };
        /** AdminMeterDetail */
        AdminMeterDetail: {
            /**
             * Anomalies
             * @description Anomalies non classées, plus récentes d'abord
             */
            anomalies: components["schemas"]["AnomalyLine"][];
            /** Contract Number */
            contract_number: string | null;
            /** Customer Number */
            customer_number: string | null;
            /**
             * Day
             * Format: date
             */
            day: string;
            /** E2C Center */
            e2c_center: string | null;
            /**
             * Explanation
             * @description Phrase d'explication pour l'équipe
             */
            explanation: string;
            /** @description NULL : compteur détaché */
            household: components["schemas"]["app__modules__admin__meters_schemas__HouseholdBrief"] | null;
            /** Id */
            id: number;
            /** Installed At */
            installed_at: string | null;
            /** Label */
            label: string | null;
            last_bill: components["schemas"]["LastBill"] | null;
            /**
             * Recent Readings
             * @description 14 derniers relevés
             */
            recent_readings: components["schemas"]["ReadingLine"][];
            /** Reference */
            reference: string;
            status: components["schemas"]["MeterStatus"];
            /** Subscribed Power Va */
            subscribed_power_va: number | null;
            /** @description Relevé de ce matin (minuit) */
            today: components["schemas"]["ReadingLine"] | null;
            today_status: components["schemas"]["TodayStatus"];
            /** @description Relevé de la veille (minuit) */
            yesterday: components["schemas"]["ReadingLine"] | null;
        };
        /** AdminMeterList */
        AdminMeterList: {
            counters: components["schemas"]["MeterCounters"];
            /**
             * Day
             * Format: date
             * @description Journée affichée (heure de Brazzaville)
             */
            day: string;
            /** Items */
            items: components["schemas"]["AdminMeterRow"][];
            /** Page */
            page: number;
            /** Size */
            size: number;
            /** Total */
            total: number;
        };
        /** AdminMeterRow */
        AdminMeterRow: {
            /** Customer Number */
            customer_number: string | null;
            /** District */
            district: string | null;
            /** E2C Center */
            e2c_center: string | null;
            /**
             * Household Id
             * @description NULL : compteur détaché
             */
            household_id: number | null;
            /** Household Name */
            household_name: string | null;
            /** Id */
            id: number;
            /** Label */
            label: string | null;
            /** Last Reading At */
            last_reading_at: string | null;
            /** Open Anomalies */
            open_anomalies: number;
            /** Owner Name */
            owner_name: string | null;
            /**
             * Reference
             * @description N° de branchement E²C
             */
            reference: string;
            status: components["schemas"]["MeterStatus"];
            /** Today Index Wh */
            today_index_wh: number | null;
            today_status: components["schemas"]["TodayStatus"];
        };
        /** AdminStats */
        AdminStats: {
            collected_this_month: components["schemas"]["Collected"];
            collections_30_days: components["schemas"]["Collections30Days"];
            /**
             * Demo
             * @description Données simulées (mode démo)
             */
            demo: boolean;
            failure_rate_7_days: components["schemas"]["FailureRate"];
            /**
             * Generated At
             * Format: date-time
             */
            generated_at: string;
            latest_bills: components["schemas"]["LatestBills"];
            /**
             * Month Label
             * @example Novembre 2026
             */
            month_label: string;
            pending_transactions: components["schemas"]["PendingTransactions"];
            /** Team Activity */
            team_activity: components["schemas"]["TeamActivity"][];
            unpaid_bills: components["schemas"]["UnpaidBills"];
            /** Watchlist */
            watchlist: components["schemas"]["WatchItem"][];
        };
        /** AdminTransactionDetail */
        AdminTransactionDetail: {
            /** Amount */
            amount: number;
            /** Anomalies */
            anomalies: components["schemas"]["Anomaly"][];
            /** Bill Id */
            bill_id: number;
            bill_lock: components["schemas"]["BillLock"];
            /** Bill Reference */
            bill_reference: string;
            /** Can Open Dispute */
            can_open_dispute: boolean;
            /**
             * Can Recheck
             * @description État de la transaction seulement (rôle vérifié à part)
             */
            can_recheck: boolean;
            /** Comparison */
            comparison: components["schemas"]["app__modules__admin__transactions_schemas__Comparison"][];
            /** Confirmed At */
            confirmed_at: string | null;
            /** Disputes */
            disputes: components["schemas"]["DisputePublic"][];
            /**
             * Expires At
             * Format: date-time
             */
            expires_at: string;
            /** Failure Reason */
            failure_reason: string | null;
            /** Id */
            id: number;
            /** Idempotency Key */
            idempotency_key: string;
            /**
             * Initiated At
             * Format: date-time
             */
            initiated_at: string;
            /** Open Dispute */
            open_dispute: boolean;
            operator: components["schemas"]["MobileOperator"];
            /** Operator Label */
            operator_label: string;
            /** @description NULL : jamais vérifiée par l'équipe */
            operator_view: components["schemas"]["OperatorView"] | null;
            /** Payer Id */
            payer_id: number;
            /** Payer Name */
            payer_name: string;
            /**
             * Phone Number
             * @description Toujours masqué
             */
            phone_number: string;
            /** Pin Entered */
            pin_entered: boolean;
            /** Pin Entered At */
            pin_entered_at: string | null;
            provider: components["schemas"]["PaymentProvider"];
            /** Provider Ref */
            provider_ref: string | null;
            /**
             * Reference
             * @example TX-00000042
             */
            reference: string;
            status: components["schemas"]["TransactionStatus"];
            /** Timeline */
            timeline: components["schemas"]["TimelineEvent"][];
            /**
             * To Reconcile
             * @description Anomalie signalée (montant, contradiction…)
             */
            to_reconcile: boolean;
        };
        /** AdminTransactionList */
        AdminTransactionList: {
            /** Items */
            items: components["schemas"]["AdminTransactionRow"][];
            /** Page */
            page: number;
            /** Size */
            size: number;
            today: components["schemas"]["DayIndicators"];
            /** Total */
            total: number;
        };
        /** AdminTransactionRow */
        AdminTransactionRow: {
            /** Amount */
            amount: number;
            /** Bill Id */
            bill_id: number;
            /** Bill Reference */
            bill_reference: string;
            /** Confirmed At */
            confirmed_at: string | null;
            /** Failure Reason */
            failure_reason: string | null;
            /** Id */
            id: number;
            /**
             * Initiated At
             * Format: date-time
             */
            initiated_at: string;
            /** Open Dispute */
            open_dispute: boolean;
            operator: components["schemas"]["MobileOperator"];
            /** Operator Label */
            operator_label: string;
            /** Payer Id */
            payer_id: number;
            /** Payer Name */
            payer_name: string;
            /**
             * Phone Number
             * @description Toujours masqué
             */
            phone_number: string;
            /** Pin Entered */
            pin_entered: boolean;
            /**
             * Reference
             * @example TX-00000042
             */
            reference: string;
            status: components["schemas"]["TransactionStatus"];
            /**
             * To Reconcile
             * @description Anomalie signalée (montant, contradiction…)
             */
            to_reconcile: boolean;
        };
        /** AdminUserDetail */
        AdminUserDetail: {
            /**
             * Created At
             * Format: date-time
             */
            created_at: string;
            /** @description Dernière désactivation, si désactivé */
            deactivation: components["schemas"]["Deactivation"] | null;
            /** Email */
            email: string | null;
            /** Full Name */
            full_name: string;
            /** Households */
            households: components["schemas"]["HouseholdLine"][];
            /** Id */
            id: number;
            /** Is Active */
            is_active: boolean;
            /** Journal */
            journal: components["schemas"]["JournalLine"][];
            /** Last Login At */
            last_login_at: string | null;
            /** Open Sessions */
            open_sessions: components["schemas"]["SessionLine"][];
            /**
             * Phone
             * @description Masqué pour le support
             */
            phone: string;
            /** Recent Transactions */
            recent_transactions: components["schemas"]["TransactionLine"][];
            role: components["schemas"]["UserRole"];
            summary: components["schemas"]["FinancialSummary"];
        };
        /** AdminUserList */
        AdminUserList: {
            /**
             * Accounts
             * @description Tous les comptes, filtres ignorés (« 1 284 comptes »)
             */
            accounts: number;
            /** Active Accounts */
            active_accounts: number;
            /** Items */
            items: components["schemas"]["AdminUserRow"][];
            /** Page */
            page: number;
            /** Size */
            size: number;
            /** Total */
            total: number;
        };
        /** AdminUserRow */
        AdminUserRow: {
            /**
             * Created At
             * Format: date-time
             */
            created_at: string;
            /** Email */
            email: string | null;
            /** Full Name */
            full_name: string;
            /**
             * Households
             * @description Foyers possédés + foyers où il est membre actif
             */
            households: number;
            /** Id */
            id: number;
            /** Is Active */
            is_active: boolean;
            /** Is Delegated Payer */
            is_delegated_payer: boolean;
            /** Last Login At */
            last_login_at: string | null;
            /**
             * Phone
             * @description Masqué pour le support
             */
            phone: string;
            role: components["schemas"]["UserRole"];
            unpaid: components["schemas"]["UnpaidSummary"];
        };
        /** AlertSettingsPublic */
        AlertSettingsPublic: {
            /**
             * Due Soon
             * @description Rappels d'échéance (5 jours avant, puis le jour même)
             */
            due_soon: boolean;
            /**
             * High Consumption
             * @description Consommation inhabituelle
             */
            high_consumption: boolean;
            /**
             * Overdue
             * @description Avis de retard puis rappel tous les 7 jours
             */
            overdue: boolean;
            /** Updated At */
            updated_at: string | null;
            /** Updated By */
            updated_by: string | null;
        };
        /** AlertSettingsUpdate */
        AlertSettingsUpdate: {
            /** Due Soon */
            due_soon: boolean;
            /** High Consumption */
            high_consumption: boolean;
            /** Overdue */
            overdue: boolean;
        };
        /**
         * AnnouncementCreate
         * @description Envoi immédiat sans `scheduled_at`, sinon programmation (UTC, dans le futur).
         */
        AnnouncementCreate: {
            audience: components["schemas"]["Audience"];
            /**
             * Body
             * @example E²C annonce une coupure jeudi de 8 h à 12 h pour travaux sur le réseau.
             */
            body: string;
            /**
             * District
             * @description Obligatoire pour « district »
             */
            district?: string | null;
            /**
             * Scheduled At
             * @description NULL : envoi immédiat
             */
            scheduled_at?: string | null;
            /**
             * Title
             * @example Coupure programmée à Mpita
             */
            title: string;
            /**
             * User Id
             * @description Obligatoire pour « client »
             */
            user_id?: number | null;
        };
        /** AnnouncementList */
        AnnouncementList: {
            /** Items */
            items: components["schemas"]["AnnouncementRow"][];
            /** Page */
            page: number;
            /** Size */
            size: number;
            /** Total */
            total: number;
        };
        /** AnnouncementRow */
        AnnouncementRow: {
            audience: components["schemas"]["Audience"];
            /**
             * Audience Label
             * @example Tous les clients
             * @example Quartier Mpita
             */
            audience_label: string;
            /** Body */
            body: string;
            /** Cancelled At */
            cancelled_at: string | null;
            /**
             * Created At
             * Format: date-time
             */
            created_at: string;
            /** Created By */
            created_by: string;
            /** District */
            district: string | null;
            /** Id */
            id: number;
            /**
             * Read
             * @description Notifications lues (annonces envoyées)
             */
            read: number | null;
            /**
             * Read Rate Percent
             * @description None : pas encore envoyée, ou 0 envoi
             */
            read_rate_percent: number | null;
            /** Recipients */
            recipients: number | null;
            /** Scheduled At */
            scheduled_at: string | null;
            /** Sent At */
            sent_at: string | null;
            status: components["schemas"]["AnnouncementStatus"];
            /** Title */
            title: string;
            /** User Id */
            user_id: number | null;
        };
        /**
         * AnnouncementStatus
         * @enum {string}
         */
        AnnouncementStatus: "scheduled" | "sent" | "cancelled";
        /** Anomaly */
        Anomaly: {
            /**
             * Action
             * @example payment.amount_mismatch
             * @example payment.provider_conflict
             */
            action: string;
            /**
             * At
             * Format: date-time
             */
            at: string;
            /** Detail */
            detail: {
                [key: string]: string;
            };
            /** Label */
            label: string;
        };
        /** AnomalyHandled */
        AnomalyHandled: {
            /**
             * Handled At
             * Format: date-time
             */
            handled_at: string;
            /** Meter Id */
            meter_id: number;
            /** Reading Id */
            reading_id: number;
            status: components["schemas"]["AnomalyStatus"];
        };
        /** AnomalyLine */
        AnomalyLine: {
            /** Handled At */
            handled_at: string | null;
            /** Handled By */
            handled_by: string | null;
            /**
             * Index Wh
             * @description Index lu (en baisse)
             */
            index_wh: number;
            /** Note */
            note: string | null;
            /**
             * Previous Index Wh
             * @description Dernier index valide avant ce relevé
             */
            previous_index_wh: number | null;
            /**
             * Read At
             * Format: date-time
             */
            read_at: string;
            /** Reading Id */
            reading_id: number;
            /** Reason */
            reason: string;
            /** @description NULL : à traiter */
            status: components["schemas"]["AnomalyStatus"] | null;
        };
        /**
         * AnomalyStatus
         * @description Traitement d'un relevé en anomalie par l'équipe (B10.4, maquette A4). NULL = ouverte.
         * @enum {string}
         */
        AnomalyStatus: "control_requested" | "dismissed";
        /** AttachRequest */
        AttachRequest: {
            /** Household Id */
            household_id: number;
            /**
             * Reason
             * @example Compteur rattaché par erreur à un autre foyer
             */
            reason: string;
        };
        /**
         * Audience
         * @enum {string}
         */
        Audience: "all" | "overdue" | "district" | "client";
        /** AudiencePreview */
        AudiencePreview: {
            audience: components["schemas"]["Audience"];
            /** Label */
            label: string;
            /**
             * Recipients
             * @description Nombre de destinataires si l'annonce partait maintenant
             */
            recipients: number;
        };
        /** AuthorizedPayer */
        AuthorizedPayer: {
            /** Full Name */
            full_name: string;
            /**
             * Phone
             * @description Masqué pour le support
             */
            phone: string;
            /**
             * Role
             * @description owner (titulaire) ou payer (payeur délégué)
             */
            role: string;
            /** User Id */
            user_id: number;
        };
        /** BackupCodesResponse */
        BackupCodesResponse: {
            /**
             * Backup Codes
             * @description À noter et garder en lieu sûr : montrés UNE seule fois, un usage chacun
             */
            backup_codes: string[];
        };
        /** BillCancelled */
        BillCancelled: {
            /**
             * Cancelled At
             * Format: date-time
             */
            cancelled_at: string;
            /** Cancelled Reason */
            cancelled_reason: string;
            /** Id */
            id: number;
            status: components["schemas"]["BillStatus"];
        };
        /**
         * BillDetail
         * @description Écran 7 « Détail de la facture ».
         */
        BillDetail: {
            /**
             * Amount Fees
             * @description RAV + timbre (hors TVA)
             */
            amount_fees: number;
            /** Amount Ht */
            amount_ht: number;
            /**
             * Amount Tax
             * @description TVA + centimes additionnels
             */
            amount_tax: number;
            /**
             * Amount Total
             * @description FCFA
             */
            amount_total: number;
            /** Billed Power Va */
            billed_power_va: number | null;
            /**
             * Can Pay
             * @description Bouton « Payer » : facture à payer et droit de payer
             */
            can_pay: boolean;
            /** Cancelled At */
            cancelled_at: string | null;
            /** Cancelled Reason */
            cancelled_reason: string | null;
            /** Consumption Kwh */
            consumption_kwh: number;
            /** Consumption Wh */
            consumption_wh: number;
            /** Current Index Kwh */
            current_index_kwh: number;
            /** Current Index Wh */
            current_index_wh: number;
            /**
             * Days Overdue
             * @description Jours de retard (0 si la facture n'est pas en retard)
             */
            days_overdue: number;
            /**
             * Due Date
             * Format: date
             */
            due_date: string;
            /** E2C Center */
            e2c_center: string | null;
            /** Household Id */
            household_id: number;
            /** Household Name */
            household_name: string;
            /** Id */
            id: number;
            /**
             * Issued At
             * Format: date-time
             */
            issued_at: string;
            /** Lines */
            lines: components["schemas"]["BillLinePublic"][];
            /**
             * Meter Contract Number
             * @description N° Police
             */
            meter_contract_number: string | null;
            /**
             * Meter Customer Number
             * @description N° Client
             */
            meter_customer_number: string | null;
            /** Meter Id */
            meter_id: number;
            /** Meter Label */
            meter_label: string | null;
            /**
             * Meter Reference
             * @description N° Branchement
             */
            meter_reference: string;
            /** Months Count */
            months_count: number;
            my_role: components["schemas"]["HouseholdRole"];
            /** Paid At */
            paid_at: string | null;
            /**
             * Period End
             * Format: date
             * @description Dernier jour de la période (inclus)
             */
            period_end: string;
            /**
             * Period Label
             * @example Juil.-Août 2026
             */
            period_label: string;
            /**
             * Period Start
             * Format: date
             */
            period_start: string;
            /** @description None : première facture */
            previous_bill: components["schemas"]["PreviousBillComparison"] | null;
            /** Previous Index Kwh */
            previous_index_kwh: number;
            /** Previous Index Wh */
            previous_index_wh: number;
            /**
             * Reference
             * @example 20260903000001
             */
            reference: string;
            /** @description « simulated » en mode démo : données simulées */
            source: components["schemas"]["BillSource"];
            /** @description Statut affiché (retard calculé à la lecture) */
            status: components["schemas"]["BillStatus"];
            tariff: components["schemas"]["TariffPublic"];
        };
        /**
         * BillFilter
         * @description Filtres de l'écran « Mes factures » (sans filtre : toutes, sauf les annulées).
         * @enum {string}
         */
        BillFilter: "to_pay" | "overdue" | "paid" | "pending_payment" | "cancelled";
        /**
         * BillLineKind
         * @description Les lignes d'une facture E²C, dans l'ordre où elles apparaissent.
         * @enum {string}
         */
        BillLineKind: "energy" | "fixed_fee" | "audiovisual_fee" | "vat" | "additional_tax" | "stamp" | "other";
        /**
         * BillLinePublic
         * @description Une ligne de la facture, avec de quoi refaire le calcul à la main.
         *
         *     Valeurs exactes en entiers (`*_milli`, `rate_bp`) ; `quantity`, `unit_price` et
         *     `rate_percent` sont les mêmes valeurs prêtes à afficher. `amount` : FCFA, tronqué.
         */
        BillLinePublic: {
            /** Amount */
            amount: number;
            /**
             * Base Amount
             * @description Assiette du taux, FCFA
             */
            base_amount: number | null;
            kind: components["schemas"]["BillLineKind"];
            /**
             * Label
             * @example Montant consommation
             */
            label: string;
            /** Position */
            position: number;
            /**
             * Quantity
             * @example 571
             */
            quantity: number | null;
            /**
             * Quantity Milli
             * @description Millièmes d'unité (571 kWh → 571 000)
             */
            quantity_milli: number | null;
            /**
             * Rate Bp
             * @description Points de base (18 % → 1 800)
             */
            rate_bp: number | null;
            /**
             * Rate Percent
             * @example 18
             */
            rate_percent: number | null;
            /**
             * Unit
             * @example kWh
             */
            unit: string | null;
            /**
             * Unit Price
             * @example 49.08
             */
            unit_price: number | null;
            /**
             * Unit Price Milli
             * @description Millièmes de FCFA (49,08 → 49 080)
             */
            unit_price_milli: number | null;
        };
        /** BillList */
        BillList: {
            /** Items */
            items: components["schemas"]["BillSummary"][];
            outstanding: components["schemas"]["Outstanding"];
            /** Page */
            page: number;
            /** Size */
            size: number;
            /** Total */
            total: number;
        };
        /**
         * BillLock
         * @description Verrou de facture : une seule transaction en attente par facture.
         */
        BillLock: {
            /** Amount Total */
            amount_total: number;
            /** Bill Id */
            bill_id: number;
            /** Bill Reference */
            bill_reference: string;
            bill_status: components["schemas"]["BillStatus"];
            /** Locked By This Transaction */
            locked_by_this_transaction: boolean;
        };
        /** BillReissued */
        BillReissued: {
            bill: components["schemas"]["AdminBillRow"];
            /** Cancelled Bill Id */
            cancelled_bill_id: number;
            /**
             * Notifications
             * @description Titulaire et payeurs délégués prévenus
             */
            notifications: number;
        };
        /**
         * BillSource
         * @enum {string}
         */
        BillSource: "simulated" | "e2c";
        /**
         * BillStatus
         * @enum {string}
         */
        BillStatus: "unpaid" | "pending_payment" | "paid" | "overdue" | "cancelled";
        /** BillSummary */
        BillSummary: {
            /**
             * Amount Total
             * @description FCFA
             */
            amount_total: number;
            /**
             * Can Pay
             * @description Bouton « Payer » : facture à payer et droit de payer
             */
            can_pay: boolean;
            /** Consumption Kwh */
            consumption_kwh: number;
            /** Consumption Wh */
            consumption_wh: number;
            /**
             * Days Overdue
             * @description Jours de retard (0 si la facture n'est pas en retard)
             */
            days_overdue: number;
            /**
             * Due Date
             * Format: date
             */
            due_date: string;
            /** Household Id */
            household_id: number;
            /** Household Name */
            household_name: string;
            /** Id */
            id: number;
            /**
             * Issued At
             * Format: date-time
             */
            issued_at: string;
            /** Meter Id */
            meter_id: number;
            /** Meter Label */
            meter_label: string | null;
            /**
             * Meter Reference
             * @description N° Branchement
             */
            meter_reference: string;
            /** Months Count */
            months_count: number;
            my_role: components["schemas"]["HouseholdRole"];
            /** Paid At */
            paid_at: string | null;
            /**
             * Period End
             * Format: date
             * @description Dernier jour de la période (inclus)
             */
            period_end: string;
            /**
             * Period Label
             * @example Juil.-Août 2026
             */
            period_label: string;
            /**
             * Period Start
             * Format: date
             */
            period_start: string;
            /**
             * Reference
             * @example 20260903000001
             */
            reference: string;
            /** @description « simulated » en mode démo : données simulées */
            source: components["schemas"]["BillSource"];
            /** @description Statut affiché (retard calculé à la lecture) */
            status: components["schemas"]["BillStatus"];
        };
        /** BillTransaction */
        BillTransaction: {
            /** Amount */
            amount: number;
            /** Confirmed At */
            confirmed_at: string | null;
            /** Failure Reason */
            failure_reason: string | null;
            /** Id */
            id: number;
            /**
             * Initiated At
             * Format: date-time
             */
            initiated_at: string;
            operator: components["schemas"]["MobileOperator"];
            /** Operator Label */
            operator_label: string;
            /** Payer Id */
            payer_id: number;
            /** Payer Name */
            payer_name: string;
            /**
             * Phone Number
             * @description Toujours masqué
             */
            phone_number: string;
            /**
             * Reference
             * @example TX-00000042
             */
            reference: string;
            status: components["schemas"]["TransactionStatus"];
        };
        /**
         * BillingReading
         * @description Relevé de facturation (index de début ou de fin de période).
         */
        BillingReading: {
            /** Index Wh */
            index_wh: number;
            /** Is Estimated */
            is_estimated: boolean;
            /**
             * Read At
             * Format: date-time
             */
            read_at: string;
            source: components["schemas"]["ReadingSource"];
        };
        /**
         * CancelRequest
         * @description Motif obligatoire, au moins 10 caractères (maquette A6).
         */
        CancelRequest: {
            /**
             * Reason
             * @example Index de fin de période erroné (relevé de contrôle)
             */
            reason: string;
        };
        /** CapabilityPublic */
        CapabilityPublic: {
            /**
             * Allowed
             * @description Le membre connecté peut-il le faire ?
             */
            allowed: boolean;
            /**
             * Key
             * @example cancel_bill
             */
            key: string;
            /**
             * Label
             * @example Annuler une facture (motif)
             */
            label: string;
            /**
             * Roles
             * @description Rôles autorisés (vide : jamais, pour personne)
             */
            roles: components["schemas"]["UserRole"][];
        };
        /** ChangePasswordRequest */
        ChangePasswordRequest: {
            /** Current Password */
            current_password: string;
            /** New Password */
            new_password: string;
        };
        /**
         * Collected
         * @description « Encaissé en novembre » : paiements réussis confirmés depuis le 1er du mois.
         */
        Collected: {
            /** Amount */
            amount: number;
            /**
             * Change Percent
             * @description None si rien le mois précédent
             */
            change_percent: number | null;
            /** Payments */
            payments: number;
            /**
             * Previous Month Same Point
             * @description Encaissé le mois précédent, du 1er au même moment (même durée écoulée)
             */
            previous_month_same_point: number;
        };
        /** Collections30Days */
        Collections30Days: {
            /**
             * Days
             * @description 30 journées, la plus ancienne d'abord
             */
            days: components["schemas"]["DailyCollection"][];
            /** Payments */
            payments: number;
            /** Total */
            total: number;
        };
        /**
         * Comparison
         * @enum {string}
         */
        "Comparison-Input": "previous" | "last_year";
        /** ConsumptionComparison */
        ConsumptionComparison: {
            current: components["schemas"]["ConsumptionTotals"];
            mode: components["schemas"]["app__modules__consumption__schemas__Comparison"];
            reference: components["schemas"]["ConsumptionTotals"];
            /**
             * Variation Percent
             * @description Évolution de la consommation (%), sur les mêmes journées relevées
             */
            variation_percent: number | null;
        };
        /** ConsumptionPoint */
        ConsumptionPoint: {
            /** Consumption Kwh */
            consumption_kwh: number;
            /** Consumption Wh */
            consumption_wh: number;
            /** Daily Average Wh */
            daily_average_wh: number;
            /** Days With Data */
            days_with_data: number;
            /**
             * End
             * Format: date
             */
            end: string;
            /**
             * Energy Cost
             * @description Énergie seule, FCFA (affiché par la maquette)
             */
            energy_cost: number | null;
            /**
             * Estimated Total
             * @description Facture estimée complète, FCFA (à partir du mois ; toujours une estimation)
             */
            estimated_total: number | null;
            /** Has Anomaly */
            has_anomaly: boolean;
            /**
             * Is Current
             * @description La période n'est pas terminée
             */
            is_current: boolean;
            /**
             * Is Estimated
             * @description Contient des valeurs estimées ou des anomalies
             */
            is_estimated: boolean;
            /**
             * Is Partial
             * @description Des journées manquent (période en cours…)
             */
            is_partial: boolean;
            /**
             * Label
             * @example Oct. 2026
             */
            label: string;
            /**
             * Start
             * Format: date
             */
            start: string;
        };
        /** ConsumptionSeries */
        ConsumptionSeries: {
            comparison: components["schemas"]["ConsumptionComparison"] | null;
            /**
             * End
             * Format: date
             */
            end: string;
            granularity: components["schemas"]["Granularity"];
            /**
             * Measured Until
             * @description Dernière journée relevée (en général hier)
             */
            measured_until: string | null;
            /** Meter Id */
            meter_id: number;
            /** Points */
            points: components["schemas"]["ConsumptionPoint"][];
            /**
             * Source
             * @description « simulated » en mode démo : données simulées
             */
            source: string;
            /**
             * Start
             * Format: date
             */
            start: string;
            /**
             * Tariff Is Assumption
             * @description Le tarif utilisé n'est pas encore vérifié
             */
            tariff_is_assumption: boolean;
        };
        /** ConsumptionSummary */
        ConsumptionSummary: {
            last_month: components["schemas"]["LastMonth"];
            /** Measured Until */
            measured_until: string | null;
            /** Meter Id */
            meter_id: number;
            /** @description None si aucune journée n'a encore été relevée */
            month_end_estimate: components["schemas"]["MonthEndEstimate"] | null;
            /** Source */
            source: string;
            /** Tariff Is Assumption */
            tariff_is_assumption: boolean;
            this_month: components["schemas"]["MonthSoFar"];
            /**
             * Variation Percent
             * @description Ce mois-ci comparé au mois dernier, sur les mêmes jours du mois
             */
            variation_percent: number | null;
        };
        /** ConsumptionTotals */
        ConsumptionTotals: {
            /** Consumption Kwh */
            consumption_kwh: number;
            /** Consumption Wh */
            consumption_wh: number;
            /** Days With Data */
            days_with_data: number;
            /**
             * End
             * Format: date
             */
            end: string;
            /** Energy Cost */
            energy_cost: number | null;
            /**
             * Start
             * Format: date
             */
            start: string;
        };
        /** ControlRequest */
        ControlRequest: {
            /**
             * Note
             * @example Index à vérifier sur place
             */
            note?: string | null;
        };
        /** DailyCollection */
        DailyCollection: {
            /** Amount */
            amount: number;
            /**
             * Day
             * Format: date
             */
            day: string;
            /** Payments */
            payments: number;
        };
        /**
         * DayDetail
         * @description Onglet « Jour » de l'écran Consommation.
         */
        DayDetail: {
            /** Anomaly Reason */
            anomaly_reason: string | null;
            /** Consumption Kwh */
            consumption_kwh: number;
            /** Consumption Wh */
            consumption_wh: number;
            /**
             * Day
             * Format: date
             */
            day: string;
            /** Days Ranked */
            days_ranked: number;
            /** Energy Cost */
            energy_cost: number | null;
            /**
             * Index End Wh
             * @description Index à minuit à la fin de la journée
             */
            index_end_wh: number;
            /**
             * Index Start Wh
             * @description Index à minuit au début de la journée
             */
            index_start_wh: number | null;
            /** Is Anomaly */
            is_anomaly: boolean;
            /**
             * Is Estimated
             * @description Relevé non transmis : valeur estimée
             */
            is_estimated: boolean;
            /**
             * Label
             * @example Mer. 14 oct.
             */
            label: string;
            /** Meter Id */
            meter_id: number;
            /**
             * Rank In Month
             * @description 1 = journée la plus consommatrice du mois
             */
            rank_in_month: number;
            /** Source */
            source: string;
            /**
             * Weekday Average Wh
             * @description Moyenne du même jour de la semaine sur les 12 semaines précédentes
             */
            weekday_average_wh: number | null;
            /** Weekday Samples */
            weekday_samples: number;
        };
        /**
         * DayIndicators
         * @description Indicateurs du jour (heure de Brazzaville).
         */
        DayIndicators: {
            /**
             * Average Confirmation Seconds
             * @description Délai moyen demande → confirmation des réussies du jour
             */
            average_confirmation_seconds: number | null;
            /**
             * Collected
             * @description FCFA encaissés aujourd'hui (paiements réussis)
             */
            collected: number;
            /**
             * Day
             * Format: date
             */
            day: string;
            /**
             * Failed
             * @description Échouées ou expirées, lancées aujourd'hui
             */
            failed: number;
            /** Open Disputes */
            open_disputes: number;
            /**
             * Pending
             * @description En attente en ce moment (toutes dates)
             */
            pending: number;
            /** Succeeded */
            succeeded: number;
            /**
             * To Reconcile
             * @description Transactions avec une anomalie à rapprocher
             */
            to_reconcile: number;
        };
        /** DayPeak */
        DayPeak: {
            /** Consumption Kwh */
            consumption_kwh: number;
            /** Consumption Wh */
            consumption_wh: number;
            /**
             * Day
             * Format: date
             */
            day: string;
        };
        /**
         * DeactivateRequest
         * @description Motif obligatoire (maquette A3 : « Demande du titulaire », « Suspicion de fraude »,
         *     « Compte en double »… ou un motif libre).
         */
        DeactivateRequest: {
            /**
             * Reason
             * @example Demande du titulaire
             */
            reason: string;
        };
        /** Deactivation */
        Deactivation: {
            /**
             * At
             * Format: date-time
             */
            at: string;
            /** By */
            by: string | null;
            /** Reason */
            reason: string;
        };
        /** DetachRequest */
        DetachRequest: {
            /**
             * Reason
             * @example Déménagement du titulaire
             */
            reason: string;
        };
        /**
         * DismissRequest
         * @description Note obligatoire : pourquoi l'anomalie ne mérite pas de suite.
         */
        DismissRequest: {
            /**
             * Note
             * @example Erreur de lecture ponctuelle, relevé suivant normal
             */
            note: string;
        };
        /** DisputeCloseRequest */
        DisputeCloseRequest: {
            /**
             * Note
             * @example MTN confirme : aucun débit sur ce numéro le 12/11
             */
            note: string;
            resolution: components["schemas"]["DisputeResolution"];
        };
        /** DisputeOpenRequest */
        DisputeOpenRequest: {
            /**
             * Customer Reference
             * @description ID de transaction du SMS reçu par le client
             */
            customer_reference?: string | null;
            /**
             * Reason
             * @example Le client affirme avoir été débité de 40 384 FCFA
             */
            reason: string;
        };
        /** DisputePublic */
        DisputePublic: {
            /** Customer Reference */
            customer_reference: string | null;
            /** Id */
            id: number;
            /**
             * Opened At
             * Format: date-time
             */
            opened_at: string;
            /** Opened By */
            opened_by: string;
            /** Reason */
            reason: string;
            resolution: components["schemas"]["DisputeResolution"] | null;
            /** Resolution Note */
            resolution_note: string | null;
            /** Resolved At */
            resolved_at: string | null;
            /** Resolved By */
            resolved_by: string | null;
            status: components["schemas"]["DisputeStatus"];
        };
        /**
         * DisputeResolution
         * @description Ce que l'opérateur a confirmé à la clôture (enregistré, jamais appliqué au paiement).
         * @enum {string}
         */
        DisputeResolution: "no_debit" | "refunded" | "debit_confirmed";
        /**
         * DisputeStatus
         * @enum {string}
         */
        DisputeStatus: "open" | "closed";
        /** DistrictLine */
        DistrictLine: {
            /** District */
            district: string;
            /** Households */
            households: number;
        };
        /** DomainCount */
        DomainCount: {
            /** Count */
            count: number;
            /** Domain */
            domain: string;
            /** Label */
            label: string;
        };
        /** ErrorBody */
        ErrorBody: {
            /** Code */
            code: string;
            /**
             * Details
             * @default {}
             */
            details: {
                [key: string]: unknown;
            };
            /** Message */
            message: string;
        };
        /**
         * ErrorResponse
         * @description Format de toutes les erreurs (documenté dans OpenAPI).
         */
        ErrorResponse: {
            error: components["schemas"]["ErrorBody"];
        };
        /**
         * EstimateBasis
         * @enum {string}
         */
        EstimateBasis: "current_month" | "last_7_days";
        /**
         * FailureRate
         * @description « Paiements non aboutis (7 jours) » : échoués + expirés / paiements terminés.
         */
        FailureRate: {
            /** Change Points */
            change_points: number | null;
            /** Finished */
            finished: number;
            /** Not Completed */
            not_completed: number;
            /**
             * Previous Rate Percent
             * @description Les 7 jours d'avant
             */
            previous_rate_percent: number | null;
            /**
             * Rate Percent
             * @description None si aucun paiement terminé
             */
            rate_percent: number | null;
        };
        /** FinancialSummary */
        FinancialSummary: {
            /**
             * Attempts
             * @description Paiements terminés cette année
             */
            attempts: number;
            /**
             * Left To Pay
             * @description Factures à payer de ses foyers
             */
            left_to_pay: number;
            /**
             * Not Completed
             * @description Paiements non aboutis cette année
             */
            not_completed: number;
            /**
             * Paid This Year
             * @description Paiements réussis faits par la personne cette année
             */
            paid_this_year: number;
            preferred_operator: components["schemas"]["MobileOperator"] | null;
            /** Year */
            year: number;
        };
        /** ForgotPasswordRequest */
        ForgotPasswordRequest: {
            /**
             * Phone
             * @example +242060000101
             */
            phone: string;
        };
        /** ForgotPasswordResponse */
        ForgotPasswordResponse: {
            /**
             * Demo Code
             * @description MODE DÉMO UNIQUEMENT : le code, affiché à l'écran au lieu d'un vrai SMS
             */
            demo_code?: string | null;
            /**
             * Expires In
             * @description Durée de validité du code, en secondes
             */
            expires_in: number;
            /** Message */
            message: string;
        };
        /**
         * Granularity
         * @enum {string}
         */
        Granularity: "day" | "week" | "month" | "bimester" | "quarter" | "semester" | "year";
        /** HealthResponse */
        HealthResponse: {
            /**
             * Database
             * @enum {string}
             */
            database: "ok" | "error";
            /** Demo Mode */
            demo_mode: boolean;
            /**
             * Status
             * @enum {string}
             */
            status: "ok" | "degraded";
        };
        /** HistoryEvent */
        HistoryEvent: {
            /**
             * Action
             * @example bill.issued
             * @example payment.succeeded
             * @example bill.cancel
             */
            action: string;
            /**
             * Actor Name
             * @description NULL : le système ou l'opérateur
             */
            actor_name: string | null;
            /**
             * At
             * Format: date-time
             */
            at: string;
            /** Detail */
            detail: string | null;
            /** Label */
            label: string;
        };
        /** HistoryImportPublic */
        HistoryImportPublic: {
            /** Bills */
            bills: number;
            /** Readings */
            readings: number;
            /**
             * Source
             * @description « simulated » en mode démo : données simulées
             */
            source: string;
        };
        /** HouseholdCreate */
        HouseholdCreate: {
            /**
             * Address
             * @example Rue Mboukou, n° 12
             */
            address?: string | null;
            /**
             * City
             * @example Pointe-Noire
             */
            city: string;
            /**
             * District
             * @example Mpita
             */
            district?: string | null;
            /**
             * Name
             * @example Maison de maman
             */
            name: string;
        };
        /** HouseholdDetail */
        HouseholdDetail: {
            /** Address */
            address: string | null;
            /** Can Manage */
            can_manage: boolean;
            /** Can Pay */
            can_pay: boolean;
            /** City */
            city: string;
            /**
             * Created At
             * Format: date-time
             */
            created_at: string;
            /** District */
            district: string | null;
            /** Id */
            id: number;
            /** Members */
            members: components["schemas"]["MemberPublic"][];
            /** Meters */
            meters: components["schemas"]["MeterSummary"][];
            my_role: components["schemas"]["HouseholdRole"];
            /** Name */
            name: string;
            owner: components["schemas"]["PersonPublic"];
        };
        /** HouseholdLine */
        HouseholdLine: {
            /**
             * Delegated Payers
             * @description Noms des payeurs délégués actifs
             */
            delegated_payers: string[];
            /** Id */
            id: number;
            /** Meters */
            meters: components["schemas"]["MeterLine"][];
            /** Name */
            name: string;
            role: components["schemas"]["HouseholdRole"];
            /** Unpaid Amount */
            unpaid_amount: number;
            /** Unpaid Count */
            unpaid_count: number;
        };
        /**
         * HouseholdRole
         * @description Le rôle d'un utilisateur DANS un foyer (à ne pas confondre avec le rôle du compte).
         * @enum {string}
         */
        HouseholdRole: "owner" | "payer" | "viewer";
        /**
         * HouseholdSummary
         * @description Une ligne de « Mes foyers ».
         */
        HouseholdSummary: {
            /** City */
            city: string;
            /** District */
            district: string | null;
            /** Id */
            id: number;
            /** Members Count */
            members_count: number;
            /** Meters Count */
            meters_count: number;
            my_role: components["schemas"]["HouseholdRole"];
            /** Name */
            name: string;
            /** Owner Name */
            owner_name: string;
        };
        /**
         * HouseholdUpdate
         * @description Champs modifiables. Absent = inchangé ; `null` efface le quartier ou l'adresse.
         */
        HouseholdUpdate: {
            /** Address */
            address?: string | null;
            /** City */
            city?: string | null;
            /** District */
            district?: string | null;
            /** Name */
            name?: string | null;
        };
        /** Integration */
        Integration: {
            /** Detail */
            detail: string;
            /**
             * Key
             * @example mtn_momo
             */
            key: string;
            /** Label */
            label: string;
            mode: components["schemas"]["IntegrationMode"];
        };
        /**
         * IntegrationMode
         * @enum {string}
         */
        IntegrationMode: "simulated" | "live" | "phase_2";
        /** IntegrationsStatus */
        IntegrationsStatus: {
            /** Demo Mode */
            demo_mode: boolean;
            /**
             * Environment
             * @example development
             */
            environment: string;
            /** Integrations */
            integrations: components["schemas"]["Integration"][];
            /** Receipt Verify Url Is Https */
            receipt_verify_url_is_https: boolean;
            /** Webhook Secret Configured */
            webhook_secret_configured: boolean;
        };
        /**
         * InvitationPublic
         * @description Une invitation reçue (écran « Compteurs et foyers » de la personne invitée).
         */
        InvitationPublic: {
            /**
             * Created At
             * Format: date-time
             */
            created_at: string;
            household: components["schemas"]["app__modules__households__schemas__HouseholdBrief"];
            /** Id */
            id: number;
            invited_by: components["schemas"]["PersonPublic"];
            role: components["schemas"]["MemberRole"];
        };
        /** InviteRequest */
        InviteRequest: {
            /**
             * Phone
             * @example 06 000 01 04
             */
            phone: string;
            /**
             * @description payer (payeur délégué) ou viewer
             * @example payer
             */
            role: components["schemas"]["MemberRole"];
        };
        /** JournalActor */
        JournalActor: {
            /** Full Name */
            full_name: string;
            /** Id */
            id: number;
            role: components["schemas"]["UserRole"];
        };
        /** JournalEntry */
        JournalEntry: {
            /**
             * Action
             * @example bill.cancel
             */
            action: string;
            /** @description NULL : le système ou l'opérateur */
            actor: components["schemas"]["JournalActor"] | null;
            /**
             * After
             * @description État après
             */
            after: {
                [key: string]: unknown;
            } | null;
            /**
             * At
             * Format: date-time
             */
            at: string;
            /**
             * Before
             * @description État avant (détail dépliable)
             */
            before: {
                [key: string]: unknown;
            } | null;
            /**
             * Domain
             * @example bill
             */
            domain: string;
            /**
             * Domain Label
             * @example Factures
             */
            domain_label: string;
            /** Entity Id */
            entity_id: number | null;
            /** Entity Type */
            entity_type: string;
            /** Id */
            id: number;
            /** Ip */
            ip: string | null;
            /**
             * Label
             * @example a annulé une facture
             */
            label: string;
            /** User Agent */
            user_agent: string | null;
        };
        /** JournalLine */
        JournalLine: {
            /** Action */
            action: string;
            /**
             * Actor Name
             * @description None : le système
             */
            actor_name: string | null;
            /**
             * At
             * Format: date-time
             */
            at: string;
            /** Is Staff Action */
            is_staff_action: boolean;
            /** Label */
            label: string;
        };
        /** JournalPage */
        JournalPage: {
            /** Items */
            items: components["schemas"]["JournalEntry"][];
            /** Page */
            page: number;
            /** Size */
            size: number;
            /** Total */
            total: number;
        };
        /** LastBill */
        LastBill: {
            /**
             * Amount Total
             * @description FCFA
             */
            amount_total: number;
            /**
             * Due Date
             * Format: date
             */
            due_date: string;
            /** Id */
            id: number;
            /** Period Label */
            period_label: string;
            /** Reference */
            reference: string;
            /** @description Statut affiché (en retard si échéance dépassée) */
            status: components["schemas"]["BillStatus"];
        };
        /** LastMonth */
        LastMonth: {
            /** Consumption Kwh */
            consumption_kwh: number;
            /** Consumption Wh */
            consumption_wh: number;
            /** Days With Data */
            days_with_data: number;
            /**
             * End
             * Format: date
             */
            end: string;
            /** Energy Cost */
            energy_cost: number | null;
            /** Estimated Total */
            estimated_total: number | null;
            /**
             * Start
             * Format: date
             */
            start: string;
        };
        /**
         * LatestBills
         * @description « Factures d'octobre par statut » : la dernière période facturée.
         */
        LatestBills: {
            /** By Status */
            by_status: components["schemas"]["StatusCount"][];
            /** Issued */
            issued: number;
            /** Issued On */
            issued_on: string | null;
            /**
             * Period Label
             * @example Sept.-Oct. 2026
             */
            period_label: string | null;
            /** Period Start */
            period_start: string | null;
        };
        /** LoginRequest */
        LoginRequest: {
            /**
             * Password
             * @example Demo2026!
             */
            password: string;
            /**
             * Phone
             * @example +242060000101
             */
            phone: string;
        };
        /** LogoutAllResponse */
        LogoutAllResponse: {
            /**
             * Revoked Sessions
             * @description Nombre de sessions (appareils) déconnectées
             */
            revoked_sessions: number;
        };
        /** MemberPublic */
        MemberPublic: {
            /**
             * Created At
             * Format: date-time
             */
            created_at: string;
            /** Id */
            id: number;
            person: components["schemas"]["PersonPublic"];
            role: components["schemas"]["MemberRole"];
            status: components["schemas"]["MemberStatus"];
        };
        /**
         * MemberRole
         * @enum {string}
         */
        MemberRole: "payer" | "viewer";
        /**
         * MemberStatus
         * @enum {string}
         */
        MemberStatus: "invited" | "active" | "revoked";
        /**
         * MeterAddRequest
         * @description Les deux numéros figurent sur la facture E²C : les demander prouve qu'on l'a en main.
         */
        MeterAddRequest: {
            /**
             * Customer Number
             * @description N° Client (sur la facture)
             * @example 0758340H
             */
            customer_number: string;
            /**
             * Label
             * @example Maison
             */
            label?: string | null;
            /**
             * Reference
             * @description N° Branchement (sur la facture)
             * @example 0018 09 5408
             */
            reference: string;
        };
        /** MeterAddResponse */
        MeterAddResponse: {
            history: components["schemas"]["HistoryImportPublic"];
            meter: components["schemas"]["MeterDetail"];
        };
        /**
         * MeterCounters
         * @description Compteurs du haut de l'écran (filtres ignorés).
         */
        MeterCounters: {
            /**
             * Attached
             * @description Compteurs rattachés à un foyer
             */
            attached: number;
            /**
             * Control Requested
             * @description Relevés de contrôle demandés, en attente
             */
            control_requested: number;
            /** Inactive */
            inactive: number;
            /** Missing Today */
            missing_today: number;
            /**
             * Open Anomalies
             * @description Anomalies pas encore traitées par l'équipe, des 30 derniers jours
             */
            open_anomalies: number;
            /**
             * Received Today
             * @description Relevés reçus ce matin (anomalies comprises)
             */
            received_today: number;
        };
        /** MeterDetail */
        MeterDetail: {
            /** Can Manage */
            can_manage: boolean;
            /** Contract Number */
            contract_number: string | null;
            /**
             * Created At
             * Format: date-time
             */
            created_at: string;
            /** Customer Number */
            customer_number: string | null;
            /** E2C Center */
            e2c_center: string | null;
            /** Household Id */
            household_id: number;
            /** Id */
            id: number;
            /** Installed At */
            installed_at: string | null;
            /** Label */
            label: string | null;
            my_role: components["schemas"]["HouseholdRole"];
            /** Reference */
            reference: string;
            status: components["schemas"]["MeterStatus"];
            /** Subscribed Power Va */
            subscribed_power_va: number | null;
            type: components["schemas"]["MeterType"];
        };
        /** MeterLine */
        MeterLine: {
            /** Id */
            id: number;
            /** Label */
            label: string | null;
            /** Reference */
            reference: string;
            /** Subscribed Power Va */
            subscribed_power_va: number | null;
        };
        /** MeterLink */
        MeterLink: {
            /** Household Id */
            household_id: number | null;
            /** Meter Id */
            meter_id: number;
            /**
             * Unpaid Bills
             * @description Factures à payer de ce compteur (elles suivent le compteur)
             */
            unpaid_bills: number;
        };
        /**
         * MeterStatus
         * @enum {string}
         */
        MeterStatus: "active" | "suspended" | "terminated";
        /** MeterSummary */
        MeterSummary: {
            /** E2C Center */
            e2c_center: string | null;
            /** Id */
            id: number;
            /** Label */
            label: string | null;
            /** Reference */
            reference: string;
            status: components["schemas"]["MeterStatus"];
            /** Subscribed Power Va */
            subscribed_power_va: number | null;
            type: components["schemas"]["MeterType"];
        };
        /**
         * MeterType
         * @enum {string}
         */
        MeterType: "postpaid";
        /**
         * MeterUpdate
         * @description Seul le nom choisi par l'abonné se modifie ; `null` l'efface.
         */
        MeterUpdate: {
            /** Label */
            label?: string | null;
        };
        /**
         * MobileOperator
         * @description L'opérateur choisi par l'abonné (écran 8). En démo, `provider` vaut `simulated` :
         *     l'opérateur est affiché, mais aucun débit réel n'a lieu chez lui.
         * @enum {string}
         */
        MobileOperator: "mtn" | "airtel";
        /**
         * MonthEndEstimate
         * @description ESTIMATION : consommation relevée + moyenne journalière × jours restants.
         */
        MonthEndEstimate: {
            basis: components["schemas"]["EstimateBasis"];
            /** Consumption Kwh */
            consumption_kwh: number;
            /** Consumption Wh */
            consumption_wh: number;
            /** Energy Cost */
            energy_cost: number | null;
            /**
             * Estimated Total
             * @description Facture estimée du mois (FCFA)
             */
            estimated_total: number | null;
            /** Remaining Days */
            remaining_days: number;
        };
        /** MonthSoFar */
        MonthSoFar: {
            /** Consumption Kwh */
            consumption_kwh: number;
            /** Consumption Wh */
            consumption_wh: number;
            /** Daily Average Wh */
            daily_average_wh: number;
            /** Days With Data */
            days_with_data: number;
            /**
             * End
             * @description Dernière journée relevée du mois (None le 1er du mois)
             */
            end: string | null;
            /** Energy Cost */
            energy_cost: number | null;
            highest_day: components["schemas"]["DayPeak"] | null;
            /**
             * Start
             * Format: date
             */
            start: string;
        };
        /**
         * MonthTotals
         * @description Factures ÉMISES dans le mois choisi (heure de Brazzaville), annulées à part.
         */
        MonthTotals: {
            /**
             * Billed
             * @description Montant facturé, FCFA
             */
            billed: number;
            /**
             * Cancelled
             * @description Factures émises ce mois puis annulées
             */
            cancelled: number;
            /**
             * Collected
             * @description Montant de ces factures déjà payé, FCFA
             */
            collected: number;
            /**
             * Issued
             * @description Factures émises (hors annulées)
             */
            issued: number;
            /**
             * Month
             * @example 2026-11
             */
            month: string;
            /**
             * Overdue
             * @description Parmi elles, factures en retard
             */
            overdue: number;
            /**
             * Remaining
             * @description Facturé − encaissé, FCFA
             */
            remaining: number;
        };
        /**
         * MyPermissions
         * @description Ce que le membre connecté peut faire : le back-office affiche ou masque ses boutons
         *     d'après `allowed` (le serveur contrôle de toute façon chaque route).
         */
        MyPermissions: {
            /** Capabilities */
            capabilities: components["schemas"]["CapabilityPublic"][];
            /**
             * Levels
             * @description Niveaux accessibles : staff, admin, super_admin
             */
            levels: components["schemas"]["Permission"][];
            role: components["schemas"]["UserRole"];
        };
        /**
         * NotificationGroup
         * @description Groupes de l'écran 13, en heure de Brazzaville.
         * @enum {string}
         */
        NotificationGroup: "today" | "this_week" | "earlier";
        /** NotificationList */
        NotificationList: {
            /** Items */
            items: components["schemas"]["NotificationPublic"][];
            /** Page */
            page: number;
            /** Size */
            size: number;
            /** Total */
            total: number;
            /**
             * Unread Count
             * @description Non lues, tous filtres confondus (badge)
             */
            unread_count: number;
        };
        /**
         * NotificationPreferences
         * @description Interrupteurs « Me prévenir » de l'écran 14. Les autres messages (nouvelle facture,
         *     retard, invitation, relevé anormal, annonces) sont toujours envoyés.
         */
        NotificationPreferences: {
            /**
             * Due Soon
             * @description Échéances : 5 jours avant, puis le jour même
             */
            due_soon: boolean;
            /**
             * Email Receipts
             * @description Recevoir mes reçus par e-mail (adresse vérifiée requise ; reçu PDF joint)
             */
            email_receipts: boolean;
            /**
             * High Consumption
             * @description Consommation inhabituelle : un jour au-dessus de la moyenne de 30 %
             */
            high_consumption: boolean;
            /**
             * Payments
             * @description Paiements : réussis, échoués, reçus disponibles
             */
            payments: boolean;
        };
        /** NotificationPublic */
        NotificationPublic: {
            /** Body */
            body: string;
            /**
             * Created At
             * Format: date-time
             */
            created_at: string;
            /**
             * Data
             * @description De quoi ouvrir le bon écran : bill_id, transaction_id, receipt_id, meter_id, household_id…
             * @example {
             *       "bill_id": 42,
             *       "receipt_id": 3,
             *       "transaction_id": 7
             *     }
             */
            data: {
                [key: string]: unknown;
            } | null;
            group: components["schemas"]["NotificationGroup"];
            /** Id */
            id: number;
            /** Is Read */
            is_read: boolean;
            /** Read At */
            read_at: string | null;
            /**
             * Title
             * @example Paiement réussi
             */
            title: string;
            type: components["schemas"]["NotificationType"];
        };
        /**
         * NotificationType
         * @enum {string}
         */
        NotificationType: "bill_issued" | "bill_due_soon" | "bill_overdue" | "payment_succeeded" | "payment_failed" | "invitation_received" | "consumption_anomaly" | "high_consumption" | "announcement";
        /**
         * OperatorView
         * @description Ce que l'opérateur a répondu lors de la dernière vérification par l'équipe.
         */
        OperatorView: {
            /** Amount */
            amount: number | null;
            /**
             * Checked At
             * Format: date-time
             */
            checked_at: string;
            /** Checked By */
            checked_by: string | null;
            /** Failure Reason */
            failure_reason: string | null;
            /** Provider Ref */
            provider_ref: string;
            state: components["schemas"]["ProviderState"];
        };
        /**
         * Outstanding
         * @description « Reste à payer » : impayées, en retard et en cours de paiement (filtres de statut
         *     et d'année ignorés ; filtres de foyer et de compteur appliqués).
         */
        Outstanding: {
            /**
             * Amount
             * @description FCFA
             */
            amount: number;
            /** Count */
            count: number;
            /** Overdue Amount */
            overdue_amount: number;
            /** Overdue Count */
            overdue_count: number;
        };
        /** Page[PaymentPublic] */
        Page_PaymentPublic_: {
            /** Items */
            items: components["schemas"]["PaymentPublic"][];
            /** Page */
            page: number;
            /** Size */
            size: number;
            /** Total */
            total: number;
        };
        /** Page[ReadingPublic] */
        Page_ReadingPublic_: {
            /** Items */
            items: components["schemas"]["ReadingPublic"][];
            /** Page */
            page: number;
            /** Size */
            size: number;
            /** Total */
            total: number;
        };
        /** Page[ReceiptPublic] */
        Page_ReceiptPublic_: {
            /** Items */
            items: components["schemas"]["ReceiptPublic"][];
            /** Page */
            page: number;
            /** Size */
            size: number;
            /** Total */
            total: number;
        };
        /**
         * PaymentCreate
         * @description Écran 8 : la facture, l'opérateur et le numéro à débiter (modifiable : payer depuis le
         *     téléphone d'un proche).
         */
        PaymentCreate: {
            /** Bill Id */
            bill_id: number;
            operator: components["schemas"]["MobileOperator"];
            /**
             * Phone Number
             * @example 06 123 45 67
             */
            phone_number: string;
        };
        /**
         * PaymentProvider
         * @description Qui traite réellement le paiement (l'intégration utilisée).
         * @enum {string}
         */
        PaymentProvider: "simulated" | "mtn" | "airtel";
        /** PaymentPublic */
        PaymentPublic: {
            /**
             * Amount
             * @description FCFA (= total de la facture)
             */
            amount: number;
            /** Bill Id */
            bill_id: number;
            /**
             * Bill Period End
             * Format: date
             * @description Dernier jour de la période de la facture (inclus)
             */
            bill_period_end: string;
            /**
             * Bill Period Label
             * @example Juil.-Août 2026
             */
            bill_period_label: string;
            /**
             * Bill Period Start
             * Format: date
             * @description Premier jour de la période de la facture
             */
            bill_period_start: string;
            /** Bill Reference */
            bill_reference: string;
            /** Confirmed At */
            confirmed_at: string | null;
            /**
             * Expires At
             * Format: date-time
             * @description Sans code PIN saisi avant cette heure : expirée
             */
            expires_at: string;
            /** Failure Reason */
            failure_reason: string | null;
            /**
             * Household Id
             * @description None si le compteur est détaché depuis
             */
            household_id: number | null;
            /** Household Name */
            household_name: string | null;
            /** Id */
            id: number;
            /**
             * Initiated At
             * Format: date-time
             */
            initiated_at: string;
            /**
             * Is Mine
             * @description C'est moi qui ai lancé ce paiement
             */
            is_mine: boolean;
            /** Meter Id */
            meter_id: number;
            /**
             * Meter Reference
             * @description N° Branchement
             */
            meter_reference: string;
            operator: components["schemas"]["MobileOperator"];
            /**
             * Operator Label
             * @example MTN MoMo
             */
            operator_label: string;
            /** Payer Id */
            payer_id: number;
            /**
             * Payer Name
             * @description Qui a payé (titulaire ou payeur délégué)
             */
            payer_name: string;
            /**
             * Phone Number
             * @description Numéro débité (masqué si ce n'est pas le vôtre)
             */
            phone_number: string;
            /** Pin Entered At */
            pin_entered_at: string | null;
            /**
             * Receipt Id
             * @description Reçu du paiement réussi (écran 10 : `GET /receipts/{id}`), sinon None
             */
            receipt_id: number | null;
            /**
             * Receipt Number
             * @example EP-2026-000123
             */
            receipt_number: string | null;
            /**
             * Reference
             * @description Référence à communiquer à l'assistance
             * @example TX-00000042
             */
            reference: string;
            /**
             * Source
             * @description « simulated » en mode démo : aucun débit réel
             */
            source: string;
            status: components["schemas"]["TransactionStatus"];
            step: components["schemas"]["PaymentStep"];
        };
        /**
         * PaymentStep
         * @description Les étapes de l'écran 9, déduites du statut.
         * @enum {string}
         */
        PaymentStep: "requested" | "pin_entered" | "succeeded" | "failed" | "expired";
        /** PendingTransactions */
        PendingTransactions: {
            /** Count */
            count: number;
            /** Older Than 10 Minutes */
            older_than_10_minutes: number;
        };
        /**
         * Permission
         * @enum {string}
         */
        Permission: "staff" | "admin" | "super_admin";
        /**
         * PersonPublic
         * @description Une personne vue par les autres membres : nom et numéro MASQUÉ.
         */
        PersonPublic: {
            /** Full Name */
            full_name: string;
            /** Id */
            id: number;
            /** Phone Masked */
            phone_masked: string;
        };
        /**
         * PreferencesUpdate
         * @description Seuls les interrupteurs envoyés changent.
         */
        PreferencesUpdate: {
            /** Due Soon */
            due_soon?: boolean | null;
            /** Email Receipts */
            email_receipts?: boolean | null;
            /** High Consumption */
            high_consumption?: boolean | null;
            /** Payments */
            payments?: boolean | null;
        };
        /**
         * PreviousBillComparison
         * @description Comparaison avec la facture précédente du même compteur (non annulée).
         */
        PreviousBillComparison: {
            /** Amount Change */
            amount_change: number;
            /** Amount Change Percent */
            amount_change_percent: number | null;
            /** Amount Total */
            amount_total: number;
            /** Bill Id */
            bill_id: number;
            /**
             * Consumption Change Percent
             * @description None si la précédente vaut 0
             */
            consumption_change_percent: number | null;
            /** Consumption Change Wh */
            consumption_change_wh: number;
            /** Consumption Kwh */
            consumption_kwh: number;
            /** Consumption Wh */
            consumption_wh: number;
            /**
             * Period End
             * Format: date
             * @description Dernier jour de la période de la précédente (inclus)
             */
            period_end: string;
            /** Period Label */
            period_label: string;
            /**
             * Period Start
             * Format: date
             * @description Premier jour de la période de la précédente
             */
            period_start: string;
            /** Reference */
            reference: string;
        };
        /**
         * ProviderState
         * @description Où en est le débit, vu par le prestataire.
         * @enum {string}
         */
        ProviderState: "pending" | "pin_entered" | "succeeded" | "failed";
        /** ReactivateRequest */
        ReactivateRequest: {
            /** Reason */
            reason?: string | null;
        };
        /** ReadAllResult */
        ReadAllResult: {
            /**
             * Marked
             * @description Notifications passées à « lue » par cet appel
             */
            marked: number;
            /**
             * Unread Count
             * @default 0
             */
            unread_count: number;
        };
        /** ReadingLine */
        ReadingLine: {
            /** Anomaly Reason */
            anomaly_reason: string | null;
            anomaly_status: components["schemas"]["AnomalyStatus"] | null;
            /**
             * Consumption Wh
             * @description Consommation depuis le relevé valide précédent
             */
            consumption_wh: number;
            /** Id */
            id: number;
            /** Index Wh */
            index_wh: number;
            /** Is Anomaly */
            is_anomaly: boolean;
            /** Is Estimated */
            is_estimated: boolean;
            /**
             * Read At
             * Format: date-time
             */
            read_at: string;
        };
        /**
         * ReadingPublic
         * @description Un relevé brut tel qu'enregistré (index à minuit, heure du Congo).
         */
        ReadingPublic: {
            /** Anomaly Reason */
            anomaly_reason: string | null;
            /** Consumption Kwh */
            consumption_kwh: number;
            /** Consumption Wh */
            consumption_wh: number;
            /**
             * Day
             * Format: date
             * @description Journée dont il porte la consommation (veille du relevé)
             */
            day: string;
            /** Id */
            id: number;
            /** Index Wh */
            index_wh: number;
            /** Is Anomaly */
            is_anomaly: boolean;
            /** Is Estimated */
            is_estimated: boolean;
            /**
             * Read At
             * Format: date-time
             * @description Instant du relevé (UTC)
             */
            read_at: string;
            /** Source */
            source: string;
        };
        /**
         * ReadingSource
         * @enum {string}
         */
        ReadingSource: "simulated" | "manual" | "e2c";
        /**
         * ReadingSources
         * @description D'où viennent les relevés de la période (maquette A6 : « source des relevés »).
         */
        ReadingSources: {
            /**
             * Anomalies
             * @description Relevés en anomalie, exclus du calcul
             */
            anomalies: number;
            /** @description « simulated » : données simulées (démo) */
            bill_source: components["schemas"]["BillSource"];
            /** By Source */
            by_source: {
                [key: string]: number;
            };
            current: components["schemas"]["BillingReading"] | null;
            /** Daily Readings */
            daily_readings: number;
            /**
             * Estimated
             * @description Relevés estimés (non transmis)
             */
            estimated: number;
            previous: components["schemas"]["BillingReading"] | null;
        };
        /** ReceiptPublic */
        ReceiptPublic: {
            /**
             * Amount
             * @description Montant payé, FCFA
             */
            amount: number;
            /** Bill Id */
            bill_id: number;
            /**
             * Bill Period End
             * Format: date
             * @description Dernier jour de la période de la facture (inclus)
             */
            bill_period_end: string;
            /**
             * Bill Period Label
             * @example Sept.-Oct. 2026
             */
            bill_period_label: string;
            /**
             * Bill Period Start
             * Format: date
             * @description Premier jour de la période de la facture
             */
            bill_period_start: string;
            /** Bill Reference */
            bill_reference: string;
            /** Household Id */
            household_id: number | null;
            /** Household Name */
            household_name: string | null;
            /** Id */
            id: number;
            /**
             * Is Mine
             * @description C'est moi qui ai payé
             */
            is_mine: boolean;
            /**
             * Issued At
             * Format: date-time
             * @description Date du paiement confirmé
             */
            issued_at: string;
            /** Meter Id */
            meter_id: number;
            /**
             * Meter Reference
             * @description N° Branchement
             */
            meter_reference: string;
            /**
             * Number
             * @example EP-2026-000123
             */
            number: string;
            operator: components["schemas"]["MobileOperator"];
            /**
             * Operator Label
             * @example MTN MoMo
             */
            operator_label: string;
            /** Payer Id */
            payer_id: number;
            /** Payer Name */
            payer_name: string;
            /**
             * Phone Number
             * @description Toujours masqué
             * @example +242 06 *** ** 67
             */
            phone_number: string;
            /**
             * Source
             * @description « simulated » en mode démo : aucun débit réel
             */
            source: string;
            /** Transaction Id */
            transaction_id: number;
            /**
             * Transaction Reference
             * @example TX-00000042
             */
            transaction_reference: string;
            /**
             * Verification Code
             * @description Code à afficher (groupes de 4) et à saisir sur la vérification publique
             * @example 8F3K-2Q9M-7XHT
             */
            verification_code: string;
        };
        /**
         * ReceiptVerification
         * @description Vérification publique : le minimum, sans nom ni numéro de téléphone.
         */
        ReceiptVerification: {
            /**
             * Amount
             * @description Montant payé, FCFA
             */
            amount: number;
            /**
             * Bill Period Label
             * @example Sept.-Oct. 2026
             */
            bill_period_label: string;
            /**
             * Demo
             * @description Paiement simulé (mode démo) : aucun débit réel
             */
            demo: boolean;
            /**
             * Issued At
             * Format: date-time
             */
            issued_at: string;
            /** Message */
            message: string;
            /**
             * Meter Reference
             * @description N° Branchement partiellement masqué
             * @example 0412-••33
             */
            meter_reference: string;
            /**
             * Number
             * @example EP-2026-000123
             */
            number: string;
            /**
             * Valid
             * @description Toujours vrai (sinon : erreur 404)
             * @default true
             */
            valid: boolean;
        };
        /** RecheckResult */
        RecheckResult: {
            /** Message */
            message: string;
            operator_state: components["schemas"]["ProviderState"];
            /**
             * Outcome
             * @description unchanged, pin_entered, succeeded, failed, expired, amount_mismatch, conflict
             */
            outcome: string;
            status_after: components["schemas"]["TransactionStatus"];
            status_before: components["schemas"]["TransactionStatus"];
            /** Transaction Id */
            transaction_id: number;
        };
        /** RefreshRequest */
        RefreshRequest: {
            /** Refresh Token */
            refresh_token: string;
        };
        /** RegisterRequest */
        RegisterRequest: {
            /**
             * Email
             * @example grace.ngoma@example.com
             */
            email?: string | null;
            /**
             * Full Name
             * @example Grâce Ngoma
             */
            full_name: string;
            /**
             * Password
             * @example Demo2026!
             */
            password: string;
            /**
             * Phone
             * @example 06 123 45 67
             */
            phone: string;
        };
        /** ReissueRequest */
        ReissueRequest: {
            /**
             * Reason
             * @example Réémission après correction de l'index
             */
            reason: string;
        };
        /** RelatedBill */
        RelatedBill: {
            /** Amount Total */
            amount_total: number;
            /** Id */
            id: number;
            /** Reference */
            reference: string;
            status: components["schemas"]["BillStatus"];
        };
        /** ResetCodeSent */
        ResetCodeSent: {
            /**
             * Phone
             * @description Numéro masqué : le code n'est jamais montré à l'équipe
             */
            phone: string;
            /**
             * Sent
             * @default true
             */
            sent: boolean;
        };
        /** ResetPasswordRequest */
        ResetPasswordRequest: {
            /**
             * Code
             * @example 048213
             */
            code: string;
            /**
             * New Password
             * @example Nouveau2026!
             */
            new_password: string;
            /**
             * Phone
             * @example +242060000101
             */
            phone: string;
        };
        /** RoleChange */
        RoleChange: {
            /**
             * Reason
             * @example Passe responsable des remboursements
             */
            reason: string;
            role: components["schemas"]["TeamRole"];
        };
        /** SessionLine */
        SessionLine: {
            /**
             * Expires At
             * Format: date-time
             */
            expires_at: string;
            /** Id */
            id: number;
            /**
             * Last Activity At
             * Format: date-time
             * @description Dernière ouverture ou rotation du jeton
             */
            last_activity_at: string;
            /** User Agent */
            user_agent: string | null;
        };
        /** StatusCount */
        StatusCount: {
            /** Count */
            count: number;
            /** Percent */
            percent: number;
            status: components["schemas"]["BillStatus"];
        };
        /**
         * TariffCreate
         * @description Nouvelle version DATÉE d'un tarif existant : la version en cours s'arrête au
         *     `valid_from` de la nouvelle (exclu), sans trou ni chevauchement.
         */
        TariffCreate: {
            /** Additional Tax Rate Bp */
            additional_tax_rate_bp: number;
            /** Audiovisual Fee */
            audiovisual_fee: number;
            /**
             * Code
             * @example BT_DOMESTIQUE
             */
            code: string;
            /** Fixed Fee Per Month */
            fixed_fee_per_month: number;
            /**
             * Is Assumption
             * @description Vrai tant que non vérifié sur de vraies factures
             */
            is_assumption: boolean;
            /**
             * Label
             * @example Basse tension domestique
             */
            label: string;
            /** Price Per Kwh Milli */
            price_per_kwh_milli: number;
            /**
             * Source Note
             * @example Arrêté tarifaire E²C du 01/01/2027
             */
            source_note: string;
            /** Stamp Fee */
            stamp_fee: number;
            /**
             * Valid From
             * Format: date
             * @description Au plus tôt demain
             */
            valid_from: string;
            /** Vat Rate Bp */
            vat_rate_bp: number;
        };
        /** TariffPublic */
        TariffPublic: {
            /** Code */
            code: string;
            /** Id */
            id: number;
            /**
             * Is Assumption
             * @description Valeurs pas encore vérifiées sur de vraies factures
             */
            is_assumption: boolean;
            /** Label */
            label: string;
            /** Price Per Kwh Milli */
            price_per_kwh_milli: number;
        };
        /** TariffRow */
        TariffRow: {
            /** Additional Tax Rate Bp */
            additional_tax_rate_bp: number;
            /** Audiovisual Fee */
            audiovisual_fee: number;
            /**
             * Bills
             * @description Factures émises avec ce tarif
             */
            bills: number;
            /** Code */
            code: string;
            /** Fixed Fee Per Month */
            fixed_fee_per_month: number;
            /** Id */
            id: number;
            /**
             * In Force
             * @description En vigueur aujourd'hui (heure de Brazzaville)
             */
            in_force: boolean;
            /** Is Assumption */
            is_assumption: boolean;
            /** Label */
            label: string;
            /**
             * Price Per Kwh Milli
             * @description Millièmes de FCFA : 49,08 → 49 080
             */
            price_per_kwh_milli: number;
            /** Source Note */
            source_note: string | null;
            /** Stamp Fee */
            stamp_fee: number;
            /**
             * Valid From
             * Format: date
             */
            valid_from: string;
            /**
             * Valid To
             * @description Exclu ; NULL : sans fin
             */
            valid_to: string | null;
            /**
             * Vat Rate Bp
             * @description Points de base : 18 % → 1 800
             */
            vat_rate_bp: number;
        };
        /** TeamActivity */
        TeamActivity: {
            /** Action */
            action: string;
            /** Actor Id */
            actor_id: number;
            /** Actor Name */
            actor_name: string;
            actor_role: components["schemas"]["UserRole"];
            /**
             * At
             * Format: date-time
             */
            at: string;
            /** Entity Id */
            entity_id: number | null;
            /** Entity Type */
            entity_type: string;
            /**
             * Label
             * @example a annulé une facture
             */
            label: string;
        };
        /** TeamInvite */
        TeamInvite: {
            /** Email */
            email?: string | null;
            /**
             * Full Name
             * @example Patrick Moukala
             */
            full_name: string;
            /**
             * Phone
             * @example 06 555 12 34
             */
            phone: string;
            role: components["schemas"]["TeamRole"];
        };
        /** TeamInvited */
        TeamInvited: {
            member: components["schemas"]["TeamMember"];
            /**
             * Sms Sent To
             * @description Numéro masqué ; le code n'est jamais montré à l'équipe
             */
            sms_sent_to: string;
        };
        /** TeamMember */
        TeamMember: {
            /** Email */
            email: string | null;
            /** Full Name */
            full_name: string;
            /** Id */
            id: number;
            /**
             * Invitation Pending
             * @description Jamais connecté : mot de passe pas encore choisi
             */
            invitation_pending: boolean;
            /**
             * Invited At
             * Format: date-time
             * @description Création du compte
             */
            invited_at: string;
            /** Is Active */
            is_active: boolean;
            /** Last Login At */
            last_login_at: string | null;
            /** Phone */
            phone: string;
            role: components["schemas"]["UserRole"];
            /**
             * Two Factor
             * @description Double authentification : enabled, pending (QR affiché, pas confirmée) ou disabled
             * @example enabled
             */
            two_factor: string;
        };
        /**
         * TeamRole
         * @description Les rôles d'un membre de l'équipe (un compte client n'est jamais promu).
         * @enum {string}
         */
        TeamRole: "support" | "admin" | "super_admin";
        /** TimelineEvent */
        TimelineEvent: {
            /** Action */
            action: string;
            /**
             * Actor Name
             * @description NULL : le système ou l'opérateur
             */
            actor_name: string | null;
            /**
             * At
             * Format: date-time
             */
            at: string;
            /** Detail */
            detail: string | null;
            /** Label */
            label: string;
        };
        /**
         * TodayStatus
         * @description État du compteur ce jour-là (heure de Brazzaville).
         * @enum {string}
         */
        TodayStatus: "received" | "anomaly" | "missing" | "inactive";
        /**
         * TokenResponse
         * @description Réponse de connexion, d'inscription et de rafraîchissement.
         */
        TokenResponse: {
            /**
             * Access Expires At
             * Format: date-time
             */
            access_expires_at: string;
            /** Access Token */
            access_token: string;
            /**
             * Expires In
             * @description Durée de validité du jeton d'accès, en secondes
             */
            expires_in: number;
            /**
             * Refresh Expires At
             * Format: date-time
             */
            refresh_expires_at: string;
            /** Refresh Token */
            refresh_token: string;
            /**
             * Token Type
             * @default bearer
             */
            token_type: string;
            user: components["schemas"]["UserPublic"];
        };
        /**
         * TransactionFilter
         * @description Filtres de l'écran A7 : les 4 statuts, plus deux listes de travail.
         * @enum {string}
         */
        TransactionFilter: "en_attente" | "reussie" | "echouee" | "expiree" | "to_reconcile" | "open_dispute";
        /** TransactionLine */
        TransactionLine: {
            /** Amount */
            amount: number;
            /** Bill Id */
            bill_id: number;
            /** Bill Period Label */
            bill_period_label: string;
            /** Confirmed At */
            confirmed_at: string | null;
            /** Failure Reason */
            failure_reason: string | null;
            /** Household Name */
            household_name: string | null;
            /** Id */
            id: number;
            /**
             * Initiated At
             * Format: date-time
             */
            initiated_at: string;
            operator: components["schemas"]["MobileOperator"];
            /** Operator Label */
            operator_label: string;
            /** Payer Id */
            payer_id: number;
            /** Payer Name */
            payer_name: string;
            /**
             * Reference
             * @example TX-00000042
             */
            reference: string;
            status: components["schemas"]["TransactionStatus"];
        };
        /**
         * TransactionStatus
         * @enum {string}
         */
        TransactionStatus: "en_attente" | "reussie" | "echouee" | "expiree";
        /**
         * TwoFactorChallenge
         * @description Mot de passe correct, mais un code est demandé (membre de l'équipe avec la 2FA).
         */
        TwoFactorChallenge: {
            /**
             * Challenge Token
             * @description À renvoyer avec le code ; valable 5 minutes
             */
            challenge_token: string;
            /**
             * Expires At
             * Format: date-time
             */
            expires_at: string;
            /**
             * Methods
             * @default [
             *       "totp",
             *       "backup_code"
             *     ]
             */
            methods: string[];
            /**
             * Two Factor Required
             * @default true
             * @constant
             */
            two_factor_required: true;
        };
        /** TwoFactorCodeRequest */
        TwoFactorCodeRequest: {
            /**
             * Code
             * @example 123456
             */
            code: string;
        };
        /** TwoFactorDisableRequest */
        TwoFactorDisableRequest: {
            /** Code */
            code: string;
            /** Password */
            password: string;
        };
        /** TwoFactorLoginRequest */
        TwoFactorLoginRequest: {
            /** Challenge Token */
            challenge_token: string;
            /**
             * Code
             * @description 6 chiffres de l'application, ou un code de secours « ABCD-EFGH »
             * @example 123456
             */
            code: string;
        };
        /** TwoFactorReset */
        TwoFactorReset: {
            /**
             * Reason
             * @example Téléphone perdu, identité vérifiée par appel
             */
            reason: string;
        };
        /** TwoFactorSetupResponse */
        TwoFactorSetupResponse: {
            /**
             * Otpauth Uri
             * @description Contenu du QR code (Google Authenticator, etc.)
             */
            otpauth_uri: string;
            /**
             * Qr Svg
             * @description QR code prêt à afficher (SVG)
             */
            qr_svg: string;
            /**
             * Secret
             * @description À saisir à la main si le QR code ne peut pas être scanné
             */
            secret: string;
        };
        /** TwoFactorStatus */
        TwoFactorStatus: {
            /** Backup Codes Left */
            backup_codes_left: number;
            /** Enabled */
            enabled: boolean;
            /** Enabled At */
            enabled_at: string | null;
            /**
             * Pending Setup
             * @description QR code affiché, premier code pas encore saisi
             */
            pending_setup: boolean;
            /**
             * Required
             * @description Obligatoire pour mon rôle (admin, super admin)
             */
            required: boolean;
        };
        /**
         * UnpaidBills
         * @description « Factures impayées » : à payer, en retard ou en cours de paiement.
         */
        UnpaidBills: {
            /** Amount */
            amount: number;
            /** Count */
            count: number;
            /** Overdue Count */
            overdue_count: number;
        };
        /**
         * UnpaidSummary
         * @description Factures à payer des foyers dont la personne est titulaire.
         */
        UnpaidSummary: {
            /**
             * Amount
             * @description FCFA
             */
            amount: number;
            /** Count */
            count: number;
            /**
             * Oldest Overdue Days
             * @description Retard le plus ancien, en jours
             */
            oldest_overdue_days: number | null;
            /** Overdue Count */
            overdue_count: number;
            /** Pending Payment Count */
            pending_payment_count: number;
        };
        /** UnreadCount */
        UnreadCount: {
            /** Unread Count */
            unread_count: number;
        };
        /**
         * UpdateProfileRequest
         * @description Champs modifiables. Un champ absent n'est pas modifié ; `"email": null` retire l'e-mail.
         */
        UpdateProfileRequest: {
            /**
             * Email
             * @example grace.ngoma@example.com
             */
            email?: string | null;
            /**
             * Full Name
             * @example Grâce Ngoma
             */
            full_name?: string | null;
        };
        /**
         * UserKind
         * @description Filtres de l'écran A2.
         * @enum {string}
         */
        UserKind: "client" | "delegated_payer" | "team";
        /**
         * UserPublic
         * @description Profil renvoyé par l'API. Jamais d'empreinte de mot de passe.
         */
        UserPublic: {
            /**
             * Created At
             * Format: date-time
             */
            created_at: string;
            /** Email */
            email: string | null;
            /**
             * Email Verified At
             * @description NULL : adresse pas encore vérifiée (aucun reçu par e-mail)
             */
            email_verified_at?: string | null;
            /** Full Name */
            full_name: string;
            /** Id */
            id: number;
            /** Is Active */
            is_active: boolean;
            /** Last Login At */
            last_login_at: string | null;
            /** Phone */
            phone: string;
            role: components["schemas"]["UserRole"];
        };
        /**
         * UserRole
         * @description Rôle du COMPTE. « Payeur délégué » n'en fait pas partie : c'est un rôle dans un foyer.
         * @enum {string}
         */
        UserRole: "client" | "support" | "admin" | "super_admin";
        /** VerificationConfirm */
        VerificationConfirm: {
            /**
             * Code
             * @example 048213
             */
            code: string;
        };
        /** VerificationSent */
        VerificationSent: {
            /**
             * Demo Code
             * @description Mode démo seulement (aucun e-mail réel ne part) : le code envoyé
             */
            demo_code: string | null;
            /**
             * Expires At
             * Format: date-time
             */
            expires_at: string;
            /**
             * Sent To
             * @description Adresse masquée
             * @example g***@example.com
             */
            sent_to: string;
        };
        /**
         * WatchItem
         * @description Un point « À surveiller », avec de quoi ouvrir le bon écran.
         */
        WatchItem: {
            /** Detail */
            detail: string;
            /** Entity Id */
            entity_id: number | null;
            /**
             * Entity Type
             * @example payment_transaction
             * @example user
             * @example meter
             * @example bill
             */
            entity_type: string | null;
            /**
             * Kind
             * @description stuck_payment, repeated_failures, reading_anomalies, long_overdue, unissued_bills, failed_emails
             */
            kind: string;
            /** Title */
            title: string;
        };
        /**
         * WebSessionResponse
         * @description Réponse du back-office : les jetons sont dans des cookies httpOnly, jamais dans le JSON.
         */
        WebSessionResponse: {
            /**
             * Access Expires At
             * Format: date-time
             */
            access_expires_at: string;
            /**
             * Refresh Expires At
             * Format: date-time
             */
            refresh_expires_at: string;
            user: components["schemas"]["UserPublic"];
        };
        /**
         * WebhookAck
         * @description Réponse au prestataire : la notification est reçue et traitée.
         */
        WebhookAck: {
            /**
             * Outcome
             * @description unchanged, pin_entered, succeeded, failed, amount_mismatch, conflict
             * @example succeeded
             */
            outcome: string;
            /**
             * Received
             * @default true
             */
            received: boolean;
            transaction_status: components["schemas"]["TransactionStatus"];
        };
        /** HouseholdBrief */
        app__modules__admin__meters_schemas__HouseholdBrief: {
            /** City */
            city: string;
            /** District */
            district: string | null;
            /** Id */
            id: number;
            /** Name */
            name: string;
            /** Owner Id */
            owner_id: number;
            /** Owner Name */
            owner_name: string;
        };
        /**
         * Comparison
         * @description Une ligne « ElecPay ↔ opérateur » (maquette A8).
         */
        app__modules__admin__transactions_schemas__Comparison: {
            /** Elecpay */
            elecpay: string | null;
            /**
             * Field
             * @example amount
             * @example provider_ref
             * @example status
             */
            field: string;
            /** Label */
            label: string;
            /**
             * Matches
             * @description None : l'opérateur ne l'a pas indiqué
             */
            matches: boolean | null;
            /** Operator */
            operator: string | null;
        };
        /**
         * Comparison
         * @enum {string}
         */
        app__modules__consumption__schemas__Comparison: "previous" | "last_year";
        /** HouseholdBrief */
        app__modules__households__schemas__HouseholdBrief: {
            /** City */
            city: string;
            /** Id */
            id: number;
            /** Name */
            name: string;
        };
    };
    responses: never;
    parameters: never;
    requestBodies: never;
    headers: never;
    pathItems: never;
}
export type $defs = Record<string, never>;
export interface operations {
    get_alert_settings_api_v1_admin_alert_settings_get: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AlertSettingsPublic"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    update_alert_settings_api_v1_admin_alert_settings_put: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["AlertSettingsUpdate"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AlertSettingsPublic"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    list_announcements_api_v1_admin_announcements_get: {
        parameters: {
            query?: {
                /** @description Numéro de page (à partir de 1) */
                page?: number;
                /** @description Éléments par page */
                size?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AnnouncementList"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    create_announcement_api_v1_admin_announcements_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["AnnouncementCreate"];
            };
        };
        responses: {
            /** @description Successful Response */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AnnouncementRow"];
                };
            };
            /** @description Action impossible sur cette annonce */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Cible ou programmation refusée */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    preview_audience_api_v1_admin_announcements_audience_get: {
        parameters: {
            query: {
                audience: components["schemas"]["Audience"];
                district?: string | null;
                user_id?: number | null;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AudiencePreview"];
                };
            };
            /** @description Action impossible sur cette annonce */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Cible ou programmation refusée */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    list_districts_api_v1_admin_announcements_districts_get: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["DistrictLine"][];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    cancel_announcement_api_v1_admin_announcements__announcement_id__cancel_post: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                announcement_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AnnouncementRow"];
                };
            };
            /** @description Annonce introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Action impossible sur cette annonce */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Cible ou programmation refusée */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    list_journal_api_v1_admin_audit_logs_get: {
        parameters: {
            query?: {
                domain?: string | null;
                action?: string | null;
                actor?: components["schemas"]["ActorKind"] | null;
                actor_id?: number | null;
                entity_type?: string | null;
                entity_id?: number | null;
                from?: string | null;
                to?: string | null;
                /** @description Numéro de page (à partir de 1) */
                page?: number;
                /** @description Éléments par page */
                size?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["JournalPage"];
                };
            };
            /** @description Filtres invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    list_domains_api_v1_admin_audit_logs_domains_get: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["DomainCount"][];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    list_bills_api_v1_admin_bills_get: {
        parameters: {
            query?: {
                /** @description Numéro de page (à partir de 1) */
                page?: number;
                /** @description Éléments par page */
                size?: number;
                /** @description N° de facture, compteur, N° client, foyer, nom */
                q?: string | null;
                status?: components["schemas"]["AdminBillFilter"] | null;
                /** @description Mois d'émission AAAA-MM */
                month?: string | null;
                meter_id?: number | null;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AdminBillList"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    export_bills_api_v1_admin_bills_export_csv_get: {
        parameters: {
            query?: {
                /** @description N° de facture, compteur, N° client, foyer, nom */
                q?: string | null;
                status?: components["schemas"]["AdminBillFilter"] | null;
                /** @description Mois d'émission AAAA-MM */
                month?: string | null;
                meter_id?: number | null;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Le fichier CSV */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "text/csv": unknown;
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    bill_detail_api_v1_admin_bills__bill_id__get: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                bill_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AdminBillDetail"];
                };
            };
            /** @description Facture introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    cancel_bill_api_v1_admin_bills__bill_id__cancel_post: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                bill_id: number;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["CancelRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["BillCancelled"];
                };
            };
            /** @description Facture introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Action impossible sur cette facture */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    reissue_bill_api_v1_admin_bills__bill_id__reissue_post: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                bill_id: number;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["ReissueRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["BillReissued"];
                };
            };
            /** @description Facture introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Action impossible sur cette facture */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    integrations_api_v1_admin_integrations_get: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["IntegrationsStatus"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    list_meters_api_v1_admin_meters_get: {
        parameters: {
            query?: {
                q?: string | null;
                today?: components["schemas"]["TodayStatus"] | null;
                attached?: boolean | null;
                /** @description Numéro de page (à partir de 1) */
                page?: number;
                /** @description Éléments par page */
                size?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AdminMeterList"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    meter_detail_api_v1_admin_meters__meter_id__get: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                meter_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AdminMeterDetail"];
                };
            };
            /** @description Compteur, relevé ou foyer introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    request_control_api_v1_admin_meters__meter_id__anomalies__reading_id__control_post: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                meter_id: number;
                reading_id: number;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["ControlRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AnomalyHandled"];
                };
            };
            /** @description Compteur, relevé ou foyer introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Action impossible sur ce compteur */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    dismiss_anomaly_api_v1_admin_meters__meter_id__anomalies__reading_id__dismiss_post: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                meter_id: number;
                reading_id: number;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["DismissRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AnomalyHandled"];
                };
            };
            /** @description Compteur, relevé ou foyer introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Action impossible sur ce compteur */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    attach_meter_api_v1_admin_meters__meter_id__attach_post: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                meter_id: number;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["AttachRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["MeterLink"];
                };
            };
            /** @description Compteur, relevé ou foyer introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Action impossible sur ce compteur */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    detach_meter_api_v1_admin_meters__meter_id__detach_post: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                meter_id: number;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["DetachRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["MeterLink"];
                };
            };
            /** @description Compteur, relevé ou foyer introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Action impossible sur ce compteur */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    my_permissions_api_v1_admin_permissions_get: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["MyPermissions"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    admin_stats_api_v1_admin_stats_get: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AdminStats"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    list_tariffs_api_v1_admin_tariffs_get: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["TariffRow"][];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    create_tariff_api_v1_admin_tariffs_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["TariffCreate"];
            };
        };
        responses: {
            /** @description Successful Response */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["TariffRow"][];
                };
            };
            /** @description Tarif refusé */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    list_team_api_v1_admin_team_get: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["TeamMember"][];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    invite_member_api_v1_admin_team_invite_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["TeamInvite"];
            };
        };
        responses: {
            /** @description Successful Response */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["TeamInvited"];
                };
            };
            /** @description Action refusée */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    reset_two_factor_api_v1_admin_team__member_id__2fa_reset_post: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                member_id: number;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["TwoFactorReset"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["TeamMember"];
                };
            };
            /** @description Membre introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Action refusée */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    change_role_api_v1_admin_team__member_id__role_put: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                member_id: number;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["RoleChange"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["TeamMember"];
                };
            };
            /** @description Membre introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Action refusée */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    list_transactions_api_v1_admin_transactions_get: {
        parameters: {
            query?: {
                q?: string | null;
                status?: components["schemas"]["TransactionFilter"] | null;
                operator?: components["schemas"]["MobileOperator"] | null;
                day?: string | null;
                /** @description Numéro de page (à partir de 1) */
                page?: number;
                /** @description Éléments par page */
                size?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AdminTransactionList"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    transaction_detail_api_v1_admin_transactions__transaction_id__get: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                transaction_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AdminTransactionDetail"];
                };
            };
            /** @description Transaction ou litige introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    open_dispute_api_v1_admin_transactions__transaction_id__disputes_post: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                transaction_id: number;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["DisputeOpenRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["DisputePublic"];
                };
            };
            /** @description Transaction ou litige introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Action impossible */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    close_dispute_api_v1_admin_transactions__transaction_id__disputes__dispute_id__close_post: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                transaction_id: number;
                dispute_id: number;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["DisputeCloseRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["DisputePublic"];
                };
            };
            /** @description Transaction ou litige introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Action impossible */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    recheck_transaction_api_v1_admin_transactions__transaction_id__recheck_post: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                transaction_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["RecheckResult"];
                };
            };
            /** @description Transaction ou litige introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Action impossible */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Opérateur */
            503: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    list_users_api_v1_admin_users_get: {
        parameters: {
            query?: {
                /** @description Numéro de page (à partir de 1) */
                page?: number;
                /** @description Éléments par page */
                size?: number;
                /** @description Nom ou numéro */
                q?: string | null;
                /** @description client, delegated_payer, team */
                kind?: components["schemas"]["UserKind"] | null;
                status?: components["schemas"]["AccountStatus"] | null;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AdminUserList"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    export_users_api_v1_admin_users_export_csv_get: {
        parameters: {
            query?: {
                /** @description Nom ou numéro */
                q?: string | null;
                /** @description client, delegated_payer, team */
                kind?: components["schemas"]["UserKind"] | null;
                status?: components["schemas"]["AccountStatus"] | null;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Le fichier CSV */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "text/csv": unknown;
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    user_detail_api_v1_admin_users__user_id__get: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                user_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AdminUserDetail"];
                };
            };
            /** @description Utilisateur introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    deactivate_api_v1_admin_users__user_id__deactivate_post: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                user_id: number;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["DeactivateRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AccountChange"];
                };
            };
            /** @description Utilisateur introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Action impossible sur ce compte */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    reactivate_api_v1_admin_users__user_id__reactivate_post: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                user_id: number;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["ReactivateRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AccountChange"];
                };
            };
            /** @description Utilisateur introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Action impossible sur ce compte */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    send_reset_code_api_v1_admin_users__user_id__reset_code_post: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                user_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ResetCodeSent"];
                };
            };
            /** @description Utilisateur introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Action impossible sur ce compte */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    login_api_v1_auth_login_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["LoginRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["TokenResponse"] | components["schemas"]["TwoFactorChallenge"];
                };
            };
            /** @description Numéro ou mot de passe incorrect */
            401: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Compte désactivé */
            403: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Trop de tentatives (en-tête Retry-After) */
            429: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    login_two_factor_api_v1_auth_login_2fa_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["TwoFactorLoginRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["TokenResponse"];
                };
            };
            /** @description Code incorrect ou étape expirée */
            401: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Trop de tentatives (en-tête Retry-After) */
            429: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    logout_api_v1_auth_logout_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["RefreshRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            204: {
                headers: {
                    [name: string]: unknown;
                };
                content?: never;
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    logout_all_api_v1_auth_logout_all_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["LogoutAllResponse"];
                };
            };
            /** @description Non connecté */
            401: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    forgot_password_api_v1_auth_password_forgot_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["ForgotPasswordRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ForgotPasswordResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Trop de tentatives (en-tête Retry-After) */
            429: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    reset_password_api_v1_auth_password_reset_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["ResetPasswordRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            204: {
                headers: {
                    [name: string]: unknown;
                };
                content?: never;
            };
            /** @description Code invalide ou expiré */
            400: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Trop de tentatives (en-tête Retry-After) */
            429: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    refresh_api_v1_auth_refresh_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["RefreshRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["TokenResponse"];
                };
            };
            /** @description Jeton inconnu, expiré, ou déjà utilisé (REFRESH_TOKEN_REUSED : toutes les sessions de cette connexion sont fermées par sécurité) */
            401: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Compte désactivé */
            403: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    register_api_v1_auth_register_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["RegisterRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["TokenResponse"];
                };
            };
            /** @description Numéro ou e-mail déjà utilisé */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Trop de tentatives (en-tête Retry-After) */
            429: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    web_login_api_v1_auth_web_login_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["LoginRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["WebSessionResponse"] | components["schemas"]["TwoFactorChallenge"];
                };
            };
            /** @description Numéro ou mot de passe incorrect */
            401: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Compte désactivé, ou réservé à l'équipe */
            403: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Trop de tentatives (en-tête Retry-After) */
            429: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    web_login_two_factor_api_v1_auth_web_login_2fa_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["TwoFactorLoginRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["WebSessionResponse"];
                };
            };
            /** @description Code incorrect ou étape expirée */
            401: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Compte désactivé */
            403: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Trop de tentatives (en-tête Retry-After) */
            429: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    web_logout_api_v1_auth_web_logout_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            204: {
                headers: {
                    [name: string]: unknown;
                };
                content?: never;
            };
            /** @description Jeton CSRF invalide */
            403: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    web_refresh_api_v1_auth_web_refresh_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["WebSessionResponse"];
                };
            };
            /** @description Session absente, expirée ou révoquée */
            401: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Jeton CSRF invalide ou compte désactivé */
            403: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    list_bills_api_v1_bills_get: {
        parameters: {
            query?: {
                /** @description Filtre de l'écran */
                status?: components["schemas"]["BillFilter"] | null;
                meter_id?: number | null;
                household_id?: number | null;
                /** @description Année du début de la période */
                year?: number | null;
                /** @description Numéro de page (à partir de 1) */
                page?: number;
                /** @description Éléments par page */
                size?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["BillList"];
                };
            };
            /** @description Foyer ou compteur introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    bill_detail_api_v1_bills__bill_id__get: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                bill_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["BillDetail"];
                };
            };
            /** @description Facture introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    bill_pdf_api_v1_bills__bill_id__pdf_get: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                bill_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Le fichier PDF */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/pdf": unknown;
                };
            };
            /** @description Facture introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    health_api_v1_health_get: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HealthResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Base de données injoignable */
            503: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HealthResponse"];
                };
            };
        };
    };
    list_households_api_v1_households_get: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HouseholdSummary"][];
                };
            };
            /** @description Non connecté */
            401: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    create_household_api_v1_households_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["HouseholdCreate"];
            };
        };
        responses: {
            /** @description Successful Response */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HouseholdDetail"];
                };
            };
            /** @description Non connecté */
            401: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Réservé aux comptes clients */
            403: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Nombre maximal de foyers atteint */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    read_household_api_v1_households__household_id__get: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                household_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HouseholdDetail"];
                };
            };
            /** @description Non connecté */
            401: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Foyer introuvable (ou auquel vous n'avez pas accès : même réponse) */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    update_household_api_v1_households__household_id__patch: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                household_id: number;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["HouseholdUpdate"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HouseholdDetail"];
                };
            };
            /** @description Non connecté */
            401: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Réservé au propriétaire du foyer */
            403: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Foyer introuvable (ou auquel vous n'avez pas accès : même réponse) */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    leave_household_api_v1_households__household_id__leave_post: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                household_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            204: {
                headers: {
                    [name: string]: unknown;
                };
                content?: never;
            };
            /** @description Le propriétaire ne quitte pas son foyer */
            400: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Non connecté */
            401: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Foyer introuvable (ou auquel vous n'avez pas accès : même réponse) */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    list_members_api_v1_households__household_id__members_get: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                household_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["MemberPublic"][];
                };
            };
            /** @description Non connecté */
            401: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Foyer introuvable (ou auquel vous n'avez pas accès : même réponse) */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    invite_member_api_v1_households__household_id__members_post: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                household_id: number;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["InviteRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["MemberPublic"];
                };
            };
            /** @description Personne qui ne peut pas être invitée */
            400: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Non connecté */
            401: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Réservé au propriétaire du foyer */
            403: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Foyer introuvable (ou auquel vous n'avez pas accès : même réponse) */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Déjà membre, ou limite de membres atteinte */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Trop d'invitations envoyées aujourd'hui */
            429: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    remove_member_api_v1_households__household_id__members__member_id__delete: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                household_id: number;
                member_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            204: {
                headers: {
                    [name: string]: unknown;
                };
                content?: never;
            };
            /** @description Non connecté */
            401: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Réservé au propriétaire du foyer */
            403: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Foyer introuvable (ou auquel vous n'avez pas accès : même réponse) */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    list_meters_api_v1_households__household_id__meters_get: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                household_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["MeterDetail"][];
                };
            };
            /** @description Foyer ou compteur introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    add_meter_api_v1_households__household_id__meters_post: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                household_id: number;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["MeterAddRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["MeterAddResponse"];
                };
            };
            /** @description Réservé au propriétaire du foyer */
            403: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Foyer ou compteur introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Déjà rattaché, ou limite atteinte */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Trop d'ajouts en peu de temps */
            429: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    my_invitations_api_v1_invitations_get: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["InvitationPublic"][];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    accept_invitation_api_v1_invitations__invitation_id__accept_post: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                invitation_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["HouseholdDetail"];
                };
            };
            /** @description Invitation introuvable ou déjà traitée */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    decline_invitation_api_v1_invitations__invitation_id__decline_post: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                invitation_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            204: {
                headers: {
                    [name: string]: unknown;
                };
                content?: never;
            };
            /** @description Invitation introuvable ou déjà traitée */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    read_me_api_v1_me_get: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["UserPublic"];
                };
            };
            /** @description Jeton absent, expiré ou invalide */
            401: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Compte désactivé */
            403: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    update_me_api_v1_me_patch: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["UpdateProfileRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["UserPublic"];
                };
            };
            /** @description Jeton absent, expiré ou invalide */
            401: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Compte désactivé */
            403: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description E-mail déjà utilisé */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    my_two_factor_api_v1_me_2fa_get: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["TwoFactorStatus"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    regenerate_backup_codes_api_v1_me_2fa_backup_codes_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["TwoFactorCodeRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["BackupCodesResponse"];
                };
            };
            /** @description Code incorrect */
            401: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description État incompatible (déjà active, pas active…) */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    disable_api_v1_me_2fa_disable_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["TwoFactorDisableRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            204: {
                headers: {
                    [name: string]: unknown;
                };
                content?: never;
            };
            /** @description Code incorrect */
            401: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Obligatoire pour mon rôle */
            403: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description État incompatible (déjà active, pas active…) */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    enable_api_v1_me_2fa_enable_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["TwoFactorCodeRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["BackupCodesResponse"];
                };
            };
            /** @description Code incorrect */
            401: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description État incompatible (déjà active, pas active…) */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    start_setup_api_v1_me_2fa_setup_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["TwoFactorSetupResponse"];
                };
            };
            /** @description État incompatible (déjà active, pas active…) */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    request_verification_api_v1_me_email_verification_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["VerificationSent"];
                };
            };
            /** @description Pas d'e-mail, ou déjà vérifié */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Trop de demandes */
            429: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Envoi d'e-mails indisponible */
            503: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    confirm_verification_api_v1_me_email_verification_confirm_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["VerificationConfirm"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["UserPublic"];
                };
            };
            /** @description Code invalide ou expiré */
            400: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Déjà vérifiée */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    my_preferences_api_v1_me_notification_preferences_get: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["NotificationPreferences"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    change_preferences_api_v1_me_notification_preferences_patch: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["PreferencesUpdate"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["NotificationPreferences"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    change_my_password_api_v1_me_password_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["ChangePasswordRequest"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["TokenResponse"];
                };
            };
            /** @description Mot de passe actuel incorrect */
            400: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Jeton absent, expiré ou invalide */
            401: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Compte désactivé */
            403: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    read_meter_api_v1_meters__meter_id__get: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                meter_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["MeterDetail"];
                };
            };
            /** @description Foyer ou compteur introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    rename_meter_api_v1_meters__meter_id__patch: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                meter_id: number;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["MeterUpdate"];
            };
        };
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["MeterDetail"];
                };
            };
            /** @description Réservé au propriétaire du foyer */
            403: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Foyer ou compteur introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    consumption_series_api_v1_meters__meter_id__consumption_get: {
        parameters: {
            query?: {
                granularity?: components["schemas"]["Granularity"];
                /** @description Premier jour (inclus) */
                from?: string | null;
                /** @description Dernier jour (inclus) */
                to?: string | null;
                compare?: components["schemas"]["Comparison-Input"] | null;
            };
            header?: never;
            path: {
                meter_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ConsumptionSeries"];
                };
            };
            /** @description Plage de dates invalide ou trop longue */
            400: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Compteur introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    consumption_day_api_v1_meters__meter_id__consumption_days__day__get: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                meter_id: number;
                day: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["DayDetail"];
                };
            };
            /** @description Compteur introuvable ou journée non relevée */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    consumption_summary_api_v1_meters__meter_id__consumption_summary_get: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                meter_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ConsumptionSummary"];
                };
            };
            /** @description Compteur introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    meter_readings_api_v1_meters__meter_id__readings_get: {
        parameters: {
            query?: {
                from?: string | null;
                to?: string | null;
                /** @description Numéro de page (à partir de 1) */
                page?: number;
                /** @description Éléments par page */
                size?: number;
            };
            header?: never;
            path: {
                meter_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["Page_ReadingPublic_"];
                };
            };
            /** @description Plage de dates invalide */
            400: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Compteur introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    list_notifications_api_v1_notifications_get: {
        parameters: {
            query?: {
                /** @description Seulement les non lues */
                unread_only?: boolean;
                /** @description Numéro de page (à partir de 1) */
                page?: number;
                /** @description Éléments par page */
                size?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["NotificationList"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    read_all_api_v1_notifications_read_all_post: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ReadAllResult"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    unread_count_api_v1_notifications_unread_count_get: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["UnreadCount"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    read_one_api_v1_notifications__notification_id__read_post: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                notification_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["NotificationPublic"];
                };
            };
            /** @description Notification introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    list_payments_api_v1_payments_get: {
        parameters: {
            query?: {
                status?: components["schemas"]["TransactionStatus"] | null;
                bill_id?: number | null;
                household_id?: number | null;
                /** @description AAAA-MM */
                month?: string | null;
                /** @description Numéro de page (à partir de 1) */
                page?: number;
                /** @description Éléments par page */
                size?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["Page_PaymentPublic_"];
                };
            };
            /** @description Foyer ou facture introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    create_payment_api_v1_payments_post: {
        parameters: {
            query?: never;
            header: {
                /** @description Une clé par tentative */
                "Idempotency-Key": string;
            };
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["PaymentCreate"];
            };
        };
        responses: {
            /** @description Même demande déjà reçue (même clé) */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["PaymentPublic"];
                };
            };
            /** @description Successful Response */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["PaymentPublic"];
                };
            };
            /** @description Lecteur du foyer : ne peut pas payer */
            403: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Facture introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Facture payée ou annulée, paiement déjà en cours, clé déjà utilisée */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Numéro, opérateur ou clé invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Trop de demandes de paiement */
            429: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    get_payment_api_v1_payments__payment_id__get: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                payment_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["PaymentPublic"];
                };
            };
            /** @description Paiement introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    list_receipts_api_v1_receipts_get: {
        parameters: {
            query?: {
                household_id?: number | null;
                year?: number | null;
                /** @description Numéro de page (à partir de 1) */
                page?: number;
                /** @description Éléments par page */
                size?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["Page_ReceiptPublic_"];
                };
            };
            /** @description Foyer introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    verify_api_v1_receipts_verify__code__get: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                code: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ReceiptVerification"];
                };
            };
            /** @description Aucun reçu ne porte ce code */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Trop de vérifications */
            429: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    get_receipt_api_v1_receipts__receipt_id__get: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                receipt_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ReceiptPublic"];
                };
            };
            /** @description Reçu introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    receipt_pdf_api_v1_receipts__receipt_id__pdf_get: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                receipt_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Le fichier PDF */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/pdf": unknown;
                };
            };
            /** @description Reçu introuvable */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    payment_webhook_api_v1_webhooks_payments__provider__post: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                provider: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Successful Response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["WebhookAck"];
                };
            };
            /** @description Contenu invalide */
            400: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Signature absente, fausse ou trop ancienne */
            401: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Prestataire ou transaction inconnus */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Données invalides */
            422: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            /** @description Erreur interne */
            500: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
}
