-- ============================================================================
-- PROJET BDR - MASTER DATA & IA (INPT)
-- Fichier : 03_queries_and_optimization.sql
-- Etapes 8 & 9 du descriptif : Interrogation avancée, Indexation & EXPLAIN
-- ============================================================================

USE pharmaflow_bdr;

-- ============================================================================
-- PARTIE A : INTERROGATION DE LA BASE DE DONNEES (Etape 8 du barème)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- REQUETE 1 : Sélection, Filtrage Temporel et Jointures Multiples (INNER JOIN)
-- Objectif  : Lister les lots actifs qui vont périmer dans les 90 prochains
--             jours, avec le nom du médicament, le fournisseur et la zone.
-- ----------------------------------------------------------------------------
SELECT
    l.numero_lot_fabricant,
    m.nom_commercial AS medicament,
    c.nom_categorie AS categorie,
    f.raison_sociale AS fournisseur,
    z.nom_zone AS emplacement,
    l.quantite_actuelle,
    l.date_peremption,
    DATEDIFF(l.date_peremption, CURDATE()) AS jours_restants,
    ROUND(l.quantite_actuelle * l.prix_achat_unitaire, 2) AS valeur_immobilisee_mad
FROM lot_stock l
INNER JOIN medicament m ON l.id_medicament = m.id_medicament
INNER JOIN categorie_therapeutique c ON m.id_categorie = c.id_categorie
INNER JOIN fournisseur f ON l.id_fournisseur = f.id_fournisseur
INNER JOIN zone_stockage z ON l.id_zone = z.id_zone
WHERE l.statut_lot = 'DISPONIBLE'
  AND l.quantite_actuelle > 0
  AND l.date_peremption BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 90 DAY)
ORDER BY l.date_peremption ASC;

-- ----------------------------------------------------------------------------
-- REQUETE 2 : Jointure Externe (LEFT JOIN), Agrégation (GROUP BY) et HAVING
-- Objectif  : Identifier les médicaments dont le stock valide total est
--             inférieur au seuil d'alerte (incluant ceux à 0 lot via LEFT JOIN).
-- ----------------------------------------------------------------------------
SELECT
    m.code_cip,
    m.nom_commercial,
    m.seuil_alerte_stock,
    COALESCE(SUM(CASE WHEN l.statut_lot = 'DISPONIBLE' AND l.date_peremption >= CURDATE()
                      THEN l.quantite_actuelle ELSE 0 END), 0) AS stock_valide_actuel,
    m.seuil_alerte_stock - COALESCE(SUM(CASE WHEN l.statut_lot = 'DISPONIBLE' AND l.date_peremption >= CURDATE()
                                             THEN l.quantite_actuelle ELSE 0 END), 0) AS deficit_unites
FROM medicament m
LEFT JOIN lot_stock l ON m.id_medicament = l.id_medicament
GROUP BY m.id_medicament, m.code_cip, m.nom_commercial, m.seuil_alerte_stock
HAVING stock_valide_actuel < m.seuil_alerte_stock
ORDER BY deficit_unites DESC;

-- ----------------------------------------------------------------------------
-- REQUETE 3 : Sous-requête Corrélée (Correlated Subquery)
-- Objectif  : Pour chaque médicament en alerte de stock, trouver automatiquement
--             le fournisseur agréé offrant le prix d'achat le plus bas.
-- ----------------------------------------------------------------------------
SELECT
    m.nom_commercial AS medicament,
    f.raison_sociale AS meilleur_fournisseur,
    cf.prix_achat_catalogue AS meilleur_prix_mad,
    cf.delai_livraison_jours,
    cf.quantite_min_commande
FROM catalogue_fournisseur cf
INNER JOIN medicament m ON cf.id_medicament = m.id_medicament
INNER JOIN fournisseur f ON cf.id_fournisseur = f.id_fournisseur
WHERE f.statut_actif = TRUE
  AND cf.prix_achat_catalogue = (
      -- Sous-requête corrélée sur le médicament courant
      SELECT MIN(cf2.prix_achat_catalogue)
      FROM catalogue_fournisseur cf2
      INNER JOIN fournisseur f2 ON cf2.id_fournisseur = f2.id_fournisseur
      WHERE cf2.id_medicament = cf.id_medicament
        AND f2.statut_actif = TRUE
  )
ORDER BY m.nom_commercial;

-- ----------------------------------------------------------------------------
-- REQUETE 4 : Requête Elaborée avec CTE (WITH) + Fonctions de Fenêtrage (Window)
-- Objectif  : Analyse financière ABC (Loi de Pareto) du chiffre d'affaires et
--             de la marge brute générés par chaque médicament dispensé, avec
--             classement DENSE_RANK() et pourcentage cumulé SUM() OVER().
-- ----------------------------------------------------------------------------
WITH cte_performance_medicaments AS (
    SELECT
        m.id_medicament,
        m.nom_commercial,
        c.nom_categorie,
        SUM(ld.quantite_delivree) AS total_unites_vendues,
        ROUND(SUM(ld.quantite_delivree * ld.prix_unitaire_facture), 2) AS chiffre_affaires_mad,
        ROUND(SUM(ld.quantite_delivree * (ld.prix_unitaire_facture - l.prix_achat_unitaire)), 2) AS marge_brute_mad
    FROM ligne_dispensation ld
    INNER JOIN lot_stock l ON ld.id_lot = l.id_lot
    INNER JOIN medicament m ON l.id_medicament = m.id_medicament
    INNER JOIN categorie_therapeutique c ON m.id_categorie = c.id_categorie
    GROUP BY m.id_medicament, m.nom_commercial, c.nom_categorie
)
SELECT
    DENSE_RANK() OVER (ORDER BY chiffre_affaires_mad DESC) AS rang_ca,
    nom_commercial,
    nom_categorie,
    total_unites_vendues,
    chiffre_affaires_mad,
    marge_brute_mad,
    ROUND(
        100.0 * SUM(chiffre_affaires_mad) OVER (ORDER BY chiffre_affaires_mad DESC)
        / SUM(chiffre_affaires_mad) OVER (),
        2
    ) AS pct_ca_cumule,
    CASE
        WHEN SUM(chiffre_affaires_mad) OVER (ORDER BY chiffre_affaires_mad DESC)
             / SUM(chiffre_affaires_mad) OVER () <= 0.70 THEN 'Classe A (Coeur CA)'
        WHEN SUM(chiffre_affaires_mad) OVER (ORDER BY chiffre_affaires_mad DESC)
             / SUM(chiffre_affaires_mad) OVER () <= 0.90 THEN 'Classe B (Intermediaire)'
        ELSE 'Classe C (Rotation lente)'
    END AS classification_pareto_abc
FROM cte_performance_medicaments
ORDER BY rang_ca;

-- ----------------------------------------------------------------------------
-- REQUETE 5 : Analyse de fidélité et dépense des patients par organisme (GROUP BY)
-- ----------------------------------------------------------------------------
SELECT
    p.organisme_assurance,
    COUNT(DISTINCT p.id_patient) AS nb_patients,
    COUNT(DISTINCT o.id_ordonnance) AS nb_ordonnances,
    SUM(ld.quantite_delivree) AS total_boites_delivrees,
    ROUND(SUM(ld.quantite_delivree * ld.prix_unitaire_facture), 2) AS montant_total_facture_mad
FROM patient p
INNER JOIN ordonnance o ON p.id_patient = o.id_patient
INNER JOIN ligne_dispensation ld ON o.id_ordonnance = ld.id_ordonnance
WHERE o.statut_ordonnance = 'SERVIE'
GROUP BY p.organisme_assurance
ORDER BY montant_total_facture_mad DESC;


-- ============================================================================
-- PARTIE B : INDEXATION ET OPTIMISATION AVEC EXPLAIN (Etape 9 du barème)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. AVANT CREATION DES INDEX : Tester le plan d'exécution avec EXPLAIN
-- ----------------------------------------------------------------------------
-- Requête cible A : Recherche FEFO des lots disponibles d'un médicament triés par date de péremption
EXPLAIN
SELECT id_lot, numero_lot_fabricant, quantite_actuelle, date_peremption
FROM lot_stock
WHERE id_medicament = 1
  AND statut_lot = 'DISPONIBLE'
  AND date_peremption >= CURDATE()
ORDER BY date_peremption ASC;

-- Requête cible B : Historique des mouvements d'audit filtré par type et trié par date
EXPLAIN
SELECT id_mouvement, id_lot, type_mouvement, delta_quantite, date_mouvement
FROM journal_mouvements_stock
WHERE type_mouvement = 'DISPENSATION'
ORDER BY date_mouvement DESC;

-- ----------------------------------------------------------------------------
-- 2. CREATION DES INDEX PERTINENTS (Justification métier & technique)
-- ----------------------------------------------------------------------------

-- INDEX 1 : Index composite couvrant la recherche FEFO dans lot_stock
-- Justification : La procédure stockée sp_dispenser_medicament_fefo et le radar
-- de péremption filtrent systématiquement sur (id_medicament, statut_lot, date_peremption).
-- Cet index B-Tree élimine le tri coûteux ("Using filesort") et permet un Index Range Scan direct.
CREATE INDEX idx_lot_fefo_lookup
ON lot_stock (id_medicament, statut_lot, date_peremption, quantite_actuelle);

-- INDEX 2 : Index composite sur le journal d'audit des mouvements de stock
-- Justification : La table journal_mouvements_stock croît à chaque opération (table la plus
-- volumineuse en production). Filtrer par type_mouvement et trier par date_mouvement sans
-- index provoque un Full Table Scan (type = ALL + Using filesort).
CREATE INDEX idx_journal_type_date
ON journal_mouvements_stock (type_mouvement, date_mouvement DESC);

-- INDEX 3 : Index sur date_prescription et statut_ordonnance
-- Justification : Accélère le filtrage temporel du tableau de bord des ordonnances.
CREATE INDEX idx_ordonnance_date_statut
ON ordonnance (date_prescription, statut_ordonnance);

-- ----------------------------------------------------------------------------
-- 3. APRES CREATION DES INDEX : Comparaison du plan d'exécution avec EXPLAIN
-- ----------------------------------------------------------------------------
-- Résultat attendu sur Requête A :
-- AVANT : key = fk_lot_medicament, Extra = "Using where; Using filesort"
-- APRES : key = idx_lot_fefo_lookup, Extra = "Using where; Using index" (Covering Index, 0 filesort !)
EXPLAIN
SELECT id_lot, numero_lot_fabricant, quantite_actuelle, date_peremption
FROM lot_stock
WHERE id_medicament = 1
  AND statut_lot = 'DISPONIBLE'
  AND date_peremption >= CURDATE()
ORDER BY date_peremption ASC;

-- Résultat attendu sur Requête B :
-- AVANT : type = ALL (Full Table Scan), key = NULL, Extra = "Using where; Using filesort"
-- APRES : type = ref, key = idx_journal_type_date, Extra = "Using where" (Scan indexé ordonné !)
EXPLAIN
SELECT id_mouvement, id_lot, type_mouvement, delta_quantite, date_mouvement
FROM journal_mouvements_stock
WHERE type_mouvement = 'DISPENSATION'
ORDER BY date_mouvement DESC;
