-- ============================================================================
-- PROJET BDR - MASTER DATA & IA (INPT)
-- Système : PharmaFlow - Gestion de Pharmacie, Lots FEFO & Dispensation
-- SGBD    : MySQL 8.0+
-- Fichier : 01_schema_and_triggers.sql
-- ============================================================================

DROP DATABASE IF EXISTS pharmaflow_bdr;
CREATE DATABASE pharmaflow_bdr
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE pharmaflow_bdr;

-- ============================================================================
-- 1. CREATION DES TABLES (MLD en 3NF)
-- ============================================================================

-- 1.1 Table des catégories thérapeutiques (Classification ATC)
CREATE TABLE categorie_therapeutique (
    id_categorie INT AUTO_INCREMENT,
    code_atc VARCHAR(10) NOT NULL,
    nom_categorie VARCHAR(100) NOT NULL,
    description_cat VARCHAR(255) NOT NULL,
    CONSTRAINT pk_categorie PRIMARY KEY (id_categorie),
    CONSTRAINT uq_categorie_code_atc UNIQUE (code_atc),
    CONSTRAINT uq_categorie_nom UNIQUE (nom_categorie)
) ENGINE=InnoDB;

-- 1.2 Table des fournisseurs pharmaceutiques
CREATE TABLE fournisseur (
    id_fournisseur INT AUTO_INCREMENT,
    raison_sociale VARCHAR(120) NOT NULL,
    ice_fiscal VARCHAR(20) NOT NULL,
    telephone VARCHAR(25) NOT NULL,
    email VARCHAR(120) NOT NULL,
    ville VARCHAR(60) NOT NULL,
    note_fiabilite DECIMAL(3,2) NOT NULL DEFAULT 4.50,
    statut_actif BOOLEAN NOT NULL DEFAULT TRUE,
    date_creation TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_fournisseur PRIMARY KEY (id_fournisseur),
    CONSTRAINT uq_fournisseur_raison UNIQUE (raison_sociale),
    CONSTRAINT uq_fournisseur_ice UNIQUE (ice_fiscal),
    CONSTRAINT uq_fournisseur_email UNIQUE (email),
    CONSTRAINT chk_fournisseur_note CHECK (note_fiabilite BETWEEN 1.00 AND 5.00)
) ENGINE=InnoDB;

-- 1.3 Table des zones de stockage (Chambre froide, Rayonnage, Coffre sécurisé)
CREATE TABLE zone_stockage (
    id_zone INT AUTO_INCREMENT,
    code_zone VARCHAR(20) NOT NULL,
    nom_zone VARCHAR(100) NOT NULL,
    temperature_min DECIMAL(4,1) NOT NULL,
    temperature_max DECIMAL(4,1) NOT NULL,
    est_refrigere BOOLEAN NOT NULL DEFAULT FALSE,
    capacite_max INT NOT NULL DEFAULT 1000,
    CONSTRAINT pk_zone PRIMARY KEY (id_zone),
    CONSTRAINT uq_zone_code UNIQUE (code_zone),
    CONSTRAINT chk_zone_temp CHECK (temperature_max >= temperature_min),
    CONSTRAINT chk_zone_capacite CHECK (capacite_max > 0)
) ENGINE=InnoDB;

-- 1.4 Table des médicaments
CREATE TABLE medicament (
    id_medicament INT AUTO_INCREMENT,
    code_cip VARCHAR(20) NOT NULL,
    nom_commercial VARCHAR(120) NOT NULL,
    dci VARCHAR(120) NOT NULL,
    forme_galenique ENUM('Comprime', 'Gelule', 'Sirop', 'Injectable', 'Pommade', 'Collyre', ' Inhalateur') NOT NULL,
    dosage VARCHAR(50) NOT NULL,
    prix_vente_unitaire DECIMAL(10,2) NOT NULL,
    seuil_alerte_stock INT NOT NULL DEFAULT 30,
    necessite_ordonnance BOOLEAN NOT NULL DEFAULT TRUE,
    conservation_froid BOOLEAN NOT NULL DEFAULT FALSE,
    id_categorie INT NOT NULL,
    CONSTRAINT pk_medicament PRIMARY KEY (id_medicament),
    CONSTRAINT uq_medicament_cip UNIQUE (code_cip),
    CONSTRAINT fk_medicament_categorie FOREIGN KEY (id_categorie)
        REFERENCES categorie_therapeutique(id_categorie)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_medicament_prix CHECK (prix_vente_unitaire > 0),
    CONSTRAINT chk_medicament_seuil CHECK (seuil_alerte_stock >= 0)
) ENGINE=InnoDB;

-- 1.5 Table de jonction M:N : Catalogue Fournisseur <-> Médicament (Clé composée)
CREATE TABLE catalogue_fournisseur (
    id_fournisseur INT NOT NULL,
    id_medicament INT NOT NULL,
    prix_achat_catalogue DECIMAL(10,2) NOT NULL,
    delai_livraison_jours INT NOT NULL DEFAULT 3,
    quantite_min_commande INT NOT NULL DEFAULT 10,
    est_fournisseur_prefere BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_catalogue_fournisseur PRIMARY KEY (id_fournisseur, id_medicament),
    CONSTRAINT fk_cat_fournisseur FOREIGN KEY (id_fournisseur)
        REFERENCES fournisseur(id_fournisseur)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_cat_medicament FOREIGN KEY (id_medicament)
        REFERENCES medicament(id_medicament)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_cat_prix CHECK (prix_achat_catalogue > 0),
    CONSTRAINT chk_cat_delai CHECK (delai_livraison_jours >= 1),
    CONSTRAINT chk_cat_qte_min CHECK (quantite_min_commande >= 1)
) ENGINE=InnoDB;

-- 1.6 Table des lots physiques en stock (Entité centrale FEFO)
CREATE TABLE lot_stock (
    id_lot INT AUTO_INCREMENT,
    numero_lot_fabricant VARCHAR(40) NOT NULL,
    id_medicament INT NOT NULL,
    id_fournisseur INT NOT NULL,
    id_zone INT NOT NULL,
    date_fabrication DATE NOT NULL,
    date_peremption DATE NOT NULL,
    date_reception DATE NOT NULL,
    quantite_initiale INT NOT NULL,
    quantite_actuelle INT NOT NULL,
    prix_achat_unitaire DECIMAL(10,2) NOT NULL,
    statut_lot ENUM('DISPONIBLE', 'EPUISE', 'PERIME', 'QUARANTAINE') NOT NULL DEFAULT 'DISPONIBLE',
    CONSTRAINT pk_lot_stock PRIMARY KEY (id_lot),
    CONSTRAINT uq_lot_fabricant_med UNIQUE (numero_lot_fabricant, id_medicament),
    CONSTRAINT fk_lot_medicament FOREIGN KEY (id_medicament)
        REFERENCES medicament(id_medicament)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_lot_fournisseur FOREIGN KEY (id_fournisseur)
        REFERENCES fournisseur(id_fournisseur)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_lot_zone FOREIGN KEY (id_zone)
        REFERENCES zone_stockage(id_zone)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_lot_dates CHECK (date_peremption > date_fabrication),
    CONSTRAINT chk_lot_qte_init CHECK (quantite_initiale > 0),
    CONSTRAINT chk_lot_qte_actuelle CHECK (quantite_actuelle >= 0 AND quantite_actuelle <= quantite_initiale),
    CONSTRAINT chk_lot_prix_achat CHECK (prix_achat_unitaire > 0)
) ENGINE=InnoDB;

-- 1.7 Table des patients
CREATE TABLE patient (
    id_patient INT AUTO_INCREMENT,
    cin VARCHAR(15) NOT NULL,
    nom VARCHAR(60) NOT NULL,
    prenom VARCHAR(60) NOT NULL,
    date_naissance DATE NOT NULL,
    sexe ENUM('M', 'F') NOT NULL,
    telephone VARCHAR(25) NOT NULL,
    organisme_assurance VARCHAR(60) NOT NULL DEFAULT 'CNOPS',
    CONSTRAINT pk_patient PRIMARY KEY (id_patient),
    CONSTRAINT uq_patient_cin UNIQUE (cin)
) ENGINE=InnoDB;

-- 1.8 Table des médecins prescripteurs
CREATE TABLE medecin (
    id_medecin INT AUTO_INCREMENT,
    numero_inpe VARCHAR(20) NOT NULL,
    nom_complet VARCHAR(120) NOT NULL,
    specialite VARCHAR(80) NOT NULL,
    etablissement VARCHAR(120) NOT NULL,
    telephone VARCHAR(25) NOT NULL,
    CONSTRAINT pk_medecin PRIMARY KEY (id_medecin),
    CONSTRAINT uq_medecin_inpe UNIQUE (numero_inpe)
) ENGINE=InnoDB;

-- 1.9 Table des ordonnances médicales
CREATE TABLE ordonnance (
    id_ordonnance INT AUTO_INCREMENT,
    reference_ordonnance VARCHAR(30) NOT NULL,
    id_patient INT NOT NULL,
    id_medecin INT NOT NULL,
    date_prescription DATE NOT NULL,
    date_dispensation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    statut_ordonnance ENUM('EN_ATTENTE', 'SERVIE', 'ANNULEE') NOT NULL DEFAULT 'SERVIE',
    notes_cliniques VARCHAR(255) DEFAULT NULL,
    CONSTRAINT pk_ordonnance PRIMARY KEY (id_ordonnance),
    CONSTRAINT uq_ordonnance_ref UNIQUE (reference_ordonnance),
    CONSTRAINT fk_ordonnance_patient FOREIGN KEY (id_patient)
        REFERENCES patient(id_patient)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ordonnance_medecin FOREIGN KEY (id_medecin)
        REFERENCES medecin(id_medecin)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 1.10 Table de jonction M:N : Lignes de dispensation (Ordonnance <-> Lot_Stock)
CREATE TABLE ligne_dispensation (
    id_ordonnance INT NOT NULL,
    id_lot INT NOT NULL,
    quantite_delivree INT NOT NULL,
    prix_unitaire_facture DECIMAL(10,2) NOT NULL,
    posologie VARCHAR(150) NOT NULL,
    CONSTRAINT pk_ligne_dispensation PRIMARY KEY (id_ordonnance, id_lot),
    CONSTRAINT fk_disp_ordonnance FOREIGN KEY (id_ordonnance)
        REFERENCES ordonnance(id_ordonnance)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_disp_lot FOREIGN KEY (id_lot)
        REFERENCES lot_stock(id_lot)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_disp_qte CHECK (quantite_delivree > 0),
    CONSTRAINT chk_disp_prix CHECK (prix_unitaire_facture > 0)
) ENGINE=InnoDB;

-- 1.11 Table d'audit immuable des mouvements de stock
CREATE TABLE journal_mouvements_stock (
    id_mouvement INT AUTO_INCREMENT,
    id_lot INT NOT NULL,
    type_mouvement ENUM('RECEPTION_INITIALE', 'DISPENSATION', 'AJUSTEMENT_POSITIF', 'AJUSTEMENT_NEGATIF', 'MISE_EN_QUARANTAINE') NOT NULL,
    quantite_avant INT NOT NULL,
    quantite_apres INT NOT NULL,
    delta_quantite INT NOT NULL,
    date_mouvement DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    operateur VARCHAR(80) NOT NULL DEFAULT 'SYSTEM_TRIGGER',
    commentaire VARCHAR(255) NOT NULL,
    CONSTRAINT pk_journal_mouvements PRIMARY KEY (id_mouvement),
    CONSTRAINT fk_journal_lot FOREIGN KEY (id_lot)
        REFERENCES lot_stock(id_lot)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================================
-- 2. TRIGGERS METIER (Exigence n°7 du cahier des charges)
-- ============================================================================

DELIMITER $$

-- TRIGGER 1 : Vérifier la chaîne du froid et synchroniser le statut du lot avant insertion
CREATE TRIGGER trg_before_insert_lot_validation
BEFORE INSERT ON lot_stock
FOR EACH ROW
BEGIN
    DECLARE v_froid_requis BOOLEAN;
    DECLARE v_zone_refrigeree BOOLEAN;

    -- Récupérer les exigences de conservation du médicament et les propriétés de la zone
    SELECT conservation_froid INTO v_froid_requis
    FROM medicament WHERE id_medicament = NEW.id_medicament;

    SELECT est_refrigere INTO v_zone_refrigeree
    FROM zone_stockage WHERE id_zone = NEW.id_zone;

    -- Règle Métier : Un médicament thermolabile (ex: Insuline, Vaccin) DOIT être stocké en chambre froide
    IF v_froid_requis = TRUE AND v_zone_refrigeree = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERREUR METIER [Chaine du froid] : Ce medicament thermolabile exige une zone de stockage refrigeree.';
    END IF;

    -- Mise à jour automatique du statut si le lot inséré est déjà périmé ou épuisé
    IF NEW.date_peremption < CURDATE() THEN
        SET NEW.statut_lot = 'PERIME';
    ELSEIF NEW.quantite_actuelle = 0 THEN
        SET NEW.statut_lot = 'EPUISE';
    END IF;
END$$

-- TRIGGER 2 : Journaliser la réception initiale d'un lot dans la table d'audit
CREATE TRIGGER trg_after_insert_lot_audit
AFTER INSERT ON lot_stock
FOR EACH ROW
BEGIN
    INSERT INTO journal_mouvements_stock (
        id_lot, type_mouvement, quantite_avant, quantite_apres, delta_quantite, operateur, commentaire
    ) VALUES (
        NEW.id_lot,
        'RECEPTION_INITIALE',
        0,
        NEW.quantite_actuelle,
        NEW.quantite_actuelle,
        CURRENT_USER(),
        CONCAT('Reception initiale du lot ', NEW.numero_lot_fabricant)
    );
END$$

-- TRIGGER 3 : Sécuriser toute délivrance d'ordonnance (anti-péremption, anti-rupture)
--             et déduire automatiquement le stock du lot correspondant
CREATE TRIGGER trg_before_insert_dispensation
BEFORE INSERT ON ligne_dispensation
FOR EACH ROW
BEGIN
    DECLARE v_qte_dispo INT;
    DECLARE v_date_exp DATE;
    DECLARE v_statut VARCHAR(20);
    DECLARE v_num_lot VARCHAR(40);

    -- Verrouiller et lire l'état actuel du lot
    SELECT quantite_actuelle, date_peremption, statut_lot, numero_lot_fabricant
    INTO v_qte_dispo, v_date_exp, v_statut, v_num_lot
    FROM lot_stock
    WHERE id_lot = NEW.id_lot
    FOR UPDATE;

    -- Règle Métier 1 : Interdiction absolue de délivrer un lot périmé
    IF v_date_exp < CURDATE() OR v_statut = 'PERIME' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERREUR SANITAIRE : Dispensation refusee car le lot selectionne est PERIME.';
    END IF;

    -- Règle Métier 2 : Interdiction de délivrer un lot en quarantaine
    IF v_statut = 'QUARANTAINE' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERREUR SANITAIRE : Dispensation refusee car le lot est en QUARANTAINE.';
    END IF;

    -- Règle Métier 3 : Vérifier la disponibilité suffisante en stock
    IF v_qte_dispo < NEW.quantite_delivree THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERREUR STOCK : Quantite insuffisante sur ce lot pour honorer la dispensation.';
    END IF;

    -- Déduire la quantité du lot (ce qui déclenchera le trigger d'audit sur lot_stock)
    UPDATE lot_stock
    SET quantite_actuelle = quantite_actuelle - NEW.quantite_delivree
    WHERE id_lot = NEW.id_lot;
END$$

-- TRIGGER 4 : Mettre à jour automatiquement le statut du lot ('EPUISE' si 0) avant UPDATE
CREATE TRIGGER trg_before_update_lot_statut
BEFORE UPDATE ON lot_stock
FOR EACH ROW
BEGIN
    IF NEW.quantite_actuelle = 0 AND NEW.statut_lot = 'DISPONIBLE' THEN
        SET NEW.statut_lot = 'EPUISE';
    ELSEIF NEW.quantite_actuelle > 0 AND OLD.statut_lot = 'EPUISE' AND NEW.date_peremption >= CURDATE() THEN
        SET NEW.statut_lot = 'DISPONIBLE';
    END IF;
END$$

-- TRIGGER 5 : Tracer automatiquement chaque variation de quantité dans journal_mouvements_stock
CREATE TRIGGER trg_after_update_lot_audit
AFTER UPDATE ON lot_stock
FOR EACH ROW
BEGIN
    DECLARE v_type_mvt VARCHAR(30);
    DECLARE v_commentaire VARCHAR(255);

    IF OLD.quantite_actuelle <> NEW.quantite_actuelle THEN
        IF NEW.quantite_actuelle < OLD.quantite_actuelle THEN
            SET v_type_mvt = 'DISPENSATION';
            SET v_commentaire = CONCAT('Sortie de stock (-', OLD.quantite_actuelle - NEW.quantite_actuelle, ' unites) sur lot ', NEW.numero_lot_fabricant);
        ELSE
            SET v_type_mvt = 'AJUSTEMENT_POSITIF';
            SET v_commentaire = CONCAT('Entree/Ajustement (+', NEW.quantite_actuelle - OLD.quantite_actuelle, ' unites) sur lot ', NEW.numero_lot_fabricant);
        END IF;

        INSERT INTO journal_mouvements_stock (
            id_lot, type_mouvement, quantite_avant, quantite_apres, delta_quantite, operateur, commentaire
        ) VALUES (
            NEW.id_lot,
            v_type_mvt,
            OLD.quantite_actuelle,
            NEW.quantite_actuelle,
            NEW.quantite_actuelle - OLD.quantite_actuelle,
            CURRENT_USER(),
            v_commentaire
        );
    ELSEIF OLD.statut_lot <> 'QUARANTAINE' AND NEW.statut_lot = 'QUARANTAINE' THEN
        INSERT INTO journal_mouvements_stock (
            id_lot, type_mouvement, quantite_avant, quantite_apres, delta_quantite, operateur, commentaire
        ) VALUES (
            NEW.id_lot,
            'MISE_EN_QUARANTAINE',
            OLD.quantite_actuelle,
            NEW.quantite_actuelle,
            0,
            CURRENT_USER(),
            CONCAT('Lot ', NEW.numero_lot_fabricant, ' place en QUARANTAINE sanitaire')
        );
    END IF;
END$$

-- ============================================================================
-- 3. PROCEDURES STOCKEES & TRANSACTIONS ACID
-- ============================================================================

-- PROCEDURE 1 : Dispensation intelligente FEFO (First-Expired, First-Out)
-- Alloue automatiquement la quantité prescrite en prélevant sur les lots valides
-- ayant la date de péremption la plus proche, au sein d'une transaction atomique.
CREATE PROCEDURE sp_dispenser_medicament_fefo(
    IN p_id_ordonnance INT,
    IN p_id_medicament INT,
    IN p_quantite_demandee INT,
    IN p_posologie VARCHAR(150)
)
BEGIN
    DECLARE v_stock_total_valide INT DEFAULT 0;
    DECLARE v_reste_a_servir INT;
    DECLARE v_lot_id INT;
    DECLARE v_lot_qte INT;
    DECLARE v_qte_prelevee INT;
    DECLARE v_prix_vente DECIMAL(10,2);
    DECLARE done INT DEFAULT FALSE;

    -- Curseur FEFO : Parcourt les lots disponibles non périmés du plus proche d'expiration au plus lointain
    DECLARE cur_lots_fefo CURSOR FOR
        SELECT id_lot, quantite_actuelle
        FROM lot_stock
        WHERE id_medicament = p_id_medicament
          AND statut_lot = 'DISPONIBLE'
          AND date_peremption >= CURDATE()
          AND quantite_actuelle > 0
        ORDER BY date_peremption ASC, id_lot ASC
        FOR UPDATE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Gestionnaire d'exception : ROLLBACK intégral en cas d'erreur SQL ou métier
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- 1. Vérifier que la quantité demandée est strictement positive
    IF p_quantite_demandee <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERREUR : La quantite demandee doit etre superieure a zero.';
    END IF;

    -- 2. Récupérer le prix de vente unitaire du médicament
    SELECT prix_vente_unitaire INTO v_prix_vente
    FROM medicament
    WHERE id_medicament = p_id_medicament;

    -- 3. Calculer le stock total disponible et non périmé tous lots confondus
    SELECT COALESCE(SUM(quantite_actuelle), 0) INTO v_stock_total_valide
    FROM lot_stock
    WHERE id_medicament = p_id_medicament
      AND statut_lot = 'DISPONIBLE'
      AND date_peremption >= CURDATE();

    IF v_stock_total_valide < p_quantite_demandee THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'TRANSACTION ANNULEE (ROLLBACK) : Stock non-perime insuffisant tous lots confondus pour ce medicament.';
    END IF;

    -- 4. Boucle d'allocation FEFO multi-lots
    SET v_reste_a_servir = p_quantite_demandee;

    OPEN cur_lots_fefo;
    fefo_loop: LOOP
        FETCH cur_lots_fefo INTO v_lot_id, v_lot_qte;
        IF done OR v_reste_a_servir = 0 THEN
            LEAVE fefo_loop;
        END IF;

        IF v_lot_qte <= v_reste_a_servir THEN
            SET v_qte_prelevee = v_lot_qte;
        ELSE
            SET v_qte_prelevee = v_reste_a_servir;
        END IF;

        -- L'insertion dans ligne_dispensation déclenchera automatiquement trg_before_insert_dispensation
        INSERT INTO ligne_dispensation (
            id_ordonnance, id_lot, quantite_delivree, prix_unitaire_facture, posologie
        ) VALUES (
            p_id_ordonnance, v_lot_id, v_qte_prelevee, v_prix_vente, p_posologie
        );

        SET v_reste_a_servir = v_reste_a_servir - v_qte_prelevee;
    END LOOP;
    CLOSE cur_lots_fefo;

    COMMIT;
END$$

DELIMITER ;

-- ============================================================================
-- 4. VUES ANALYTIQUES (VIEWS)
-- ============================================================================

-- VUE 1 : État consolidé des stocks et alertes de réapprovisionnement par médicament
CREATE OR REPLACE VIEW vw_etat_stock_medicaments AS
SELECT
    m.id_medicament,
    m.code_cip,
    m.nom_commercial,
    m.dci,
    m.forme_galenique,
    m.dosage,
    c.nom_categorie,
    m.prix_vente_unitaire,
    m.seuil_alerte_stock,
    m.conservation_froid,
    COALESCE(SUM(CASE WHEN l.statut_lot = 'DISPONIBLE' AND l.date_peremption >= CURDATE() THEN l.quantite_actuelle ELSE 0 END), 0) AS stock_valide_disponible,
    COALESCE(SUM(CASE WHEN l.date_peremption < CURDATE() OR l.statut_lot = 'PERIME' THEN l.quantite_actuelle ELSE 0 END), 0) AS stock_perime_immobilise,
    COUNT(DISTINCT CASE WHEN l.statut_lot = 'DISPONIBLE' AND l.quantite_actuelle > 0 THEN l.id_lot END) AS nombre_lots_actifs,
    MIN(CASE WHEN l.statut_lot = 'DISPONIBLE' AND l.quantite_actuelle > 0 AND l.date_peremption >= CURDATE() THEN l.date_peremption END) AS prochaine_date_peremption,
    CASE
        WHEN COALESCE(SUM(CASE WHEN l.statut_lot = 'DISPONIBLE' AND l.date_peremption >= CURDATE() THEN l.quantite_actuelle ELSE 0 END), 0) = 0 THEN 'RUPTURE CRITIQUE'
        WHEN COALESCE(SUM(CASE WHEN l.statut_lot = 'DISPONIBLE' AND l.date_peremption >= CURDATE() THEN l.quantite_actuelle ELSE 0 END), 0) < m.seuil_alerte_stock THEN 'SOUS LE SEUIL D ALERTE'
        ELSE 'STOCK NORMAL'
    END AS statut_approvisionnement
FROM medicament m
INNER JOIN categorie_therapeutique c ON m.id_categorie = c.id_categorie
LEFT JOIN lot_stock l ON m.id_medicament = l.id_medicament
GROUP BY
    m.id_medicament, m.code_cip, m.nom_commercial, m.dci,
    m.forme_galenique, m.dosage, c.nom_categorie,
    m.prix_vente_unitaire, m.seuil_alerte_stock, m.conservation_froid;

-- VUE 2 : Surveillance sanitaire des lots à risque de péremption (FEFO Radar)
CREATE OR REPLACE VIEW vw_radar_peremption_lots AS
SELECT
    l.id_lot,
    l.numero_lot_fabricant,
    m.nom_commercial,
    m.dci,
    c.nom_categorie,
    f.raison_sociale AS fournisseur,
    z.nom_zone AS zone_stockage,
    l.quantite_actuelle,
    l.prix_achat_unitaire,
    ROUND(l.quantite_actuelle * l.prix_achat_unitaire, 2) AS valeur_stock_risque_mad,
    l.date_peremption,
    DATEDIFF(l.date_peremption, CURDATE()) AS jours_avant_peremption,
    l.statut_lot,
    CASE
        WHEN l.date_peremption < CURDATE() OR l.statut_lot = 'PERIME' THEN '1. PERIME (A DETRUIRE)'
        WHEN DATEDIFF(l.date_peremption, CURDATE()) <= 30 THEN '2. CRITIQUE (< 30 JOURS)'
        WHEN DATEDIFF(l.date_peremption, CURDATE()) <= 90 THEN '3. SURVEILLANCE (31-90 JOURS)'
        ELSE '4. CONFORME (> 90 JOURS)'
    END AS niveau_risque_peremption
FROM lot_stock l
INNER JOIN medicament m ON l.id_medicament = m.id_medicament
INNER JOIN categorie_therapeutique c ON m.id_categorie = c.id_categorie
INNER JOIN fournisseur f ON l.id_fournisseur = f.id_fournisseur
INNER JOIN zone_stockage z ON l.id_zone = z.id_zone
WHERE l.quantite_actuelle > 0;
