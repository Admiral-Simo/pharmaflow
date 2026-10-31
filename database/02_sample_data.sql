-- ============================================================================
-- PROJET BDR - MASTER DATA & IA (INPT)
-- Fichier : 02_sample_data.sql
-- Peuplement réaliste (> 5 enregistrements par table principale + cas limites)
-- ============================================================================

USE pharmaflow_bdr;

-- 1. Catégories Thérapeutiques (7 enregistrements)
INSERT INTO categorie_therapeutique (code_atc, nom_categorie, description_cat) VALUES
('J01', 'Antibiotiques systémiques', 'Traitement des infections bactériennes sévères et communautaires'),
('N02', 'Analgésiques et Antipyrétiques', 'Traitement de la douleur aiguë ou chronique et de la fièvre'),
('A10', 'Antidiabétiques et Insulines', 'Régulation de la glycémie pour diabète de type 1 et 2'),
('C09', 'Cardiologie et Antihypertenseurs', 'Traitement de l hypertension artérielle et insuffisance cardiaque'),
('R03', 'Pneumologie et Antiasthmatiques', 'Bronchodilatateurs et corticoïdes inhalés'),
('A02', 'Gastro-entérologie et Antiulcéreux', 'Inhibiteurs de la pompe à protons et protecteurs gastriques'),
('J07', 'Vaccins et Immunologie', 'Prévention immunitaire thermolabile sous chaîne du froid');

-- 2. Fournisseurs Pharmaceutiques au Maroc (6 enregistrements)
INSERT INTO fournisseur (raison_sociale, ice_fiscal, telephone, email, ville, note_fiabilite, statut_actif) VALUES
('Cooper Pharma Maroc', '001524896000084', '+212-522-354000', 'commandes@cooperpharma.ma', 'Casablanca', 4.85, TRUE),
('Laboratoires Sothema', '001639841000021', '+212-522-970600', 'distribution@sothema.ma', 'Bouskoura', 4.90, TRUE),
('Laprophan Distribution', '001412365000059', '+212-522-618181', 'logistique@laprophan.ma', 'Casablanca', 4.65, TRUE),
('Pharma 5 Industries', '001789654000033', '+212-522-780101', 'supply@pharma5.ma', 'Casablanca', 4.70, TRUE),
('Galenica Laboratoires', '001852963000077', '+212-522-335252', 'contact@galenica.ma', 'Casablanca', 4.40, TRUE),
('Promopharm S.A.', '001951753000012', '+212-523-321010', 'service.client@promopharm.ma', 'Berrechid', 4.55, TRUE);

-- 3. Zones de Stockage (5 enregistrements)
INSERT INTO zone_stockage (code_zone, nom_zone, temperature_min, temperature_max, est_refrigere, capacite_max) VALUES
('RAY-A1', 'Rayonnage Central A1 - Courants', 15.0, 25.0, FALSE, 2500),
('RAY-B2', 'Rayonnage B2 - Antibiotiques & Cardio', 15.0, 25.0, FALSE, 1800),
('FRIGO-01', 'Chambre Froide Positive N°1 (Insulines/Vaccins)', 2.0, 8.0, TRUE, 600),
('FRIGO-02', 'Armoire Réfrigérée Secours N°2', 2.0, 8.0, TRUE, 400),
('COFFRE-S1', 'Armoire Sécurisée Quarantaine & Contrôlés', 15.0, 22.0, FALSE, 500);

-- 4. Médicaments (10 enregistrements)
INSERT INTO medicament (code_cip, nom_commercial, dci, forme_galenique, dosage, prix_vente_unitaire, seuil_alerte_stock, necessite_ordonnance, conservation_froid, id_categorie) VALUES
('340093001', 'Augmentin Adulte', 'Amoxicilline / Acide clavulanique', 'Comprime', '1g / 125mg', 98.50, 40, TRUE, FALSE, 1),
('340093002', 'Zinnat', 'Céfuroxime', 'Comprime', '500mg', 132.00, 30, TRUE, FALSE, 1),
('340093003', 'Doliprane', 'Paracétamol', 'Comprime', '1000mg', 15.60, 80, FALSE, FALSE, 2),
('340093004', 'Lantus Solostar', 'Insuline Glargine', 'Injectable', '100 UI/ml', 365.00, 25, TRUE, TRUE, 3),
('340093005', 'Glucophage', 'Metformine', 'Comprime', '850mg', 38.00, 50, TRUE, FALSE, 3),
('340093006', 'Amlor', 'Amlodipine', 'Gelule', '5mg', 64.00, 35, TRUE, FALSE, 4),
('340093007', 'Cozaar', 'Losartan', 'Comprime', '50mg', 110.00, 30, TRUE, FALSE, 4),
('340093008', 'Ventoline', 'Salbutamol', ' Inhalateur', '100 mcg/dose', 49.50, 45, TRUE, FALSE, 5),
('340093009', 'Mopral', 'Oméprazole', 'Gelule', '20mg', 54.00, 40, FALSE, FALSE, 6),
('340093010', 'Vaxigrip Tetra', 'Vaccin Grippal Quadrivalent', 'Injectable', '0.5 ml', 128.00, 20, TRUE, TRUE, 7);

-- 5. Catalogue Fournisseur (Table de jonction M:N - 15 enregistrements)
INSERT INTO catalogue_fournisseur (id_fournisseur, id_medicament, prix_achat_catalogue, delai_livraison_jours, quantite_min_commande, est_fournisseur_prefere) VALUES
(1, 1, 74.00, 2, 20, TRUE),
(3, 1, 76.50, 3, 15, FALSE),
(1, 2, 99.00, 2, 10, TRUE),
(2, 3, 10.50, 1, 50, TRUE),
(4, 3, 11.00, 2, 40, FALSE),
(2, 4, 290.00, 2, 10, TRUE),
(6, 4, 298.00, 3, 10, FALSE),
(4, 5, 26.50, 2, 30, TRUE),
(5, 6, 46.00, 3, 20, TRUE),
(1, 6, 48.00, 2, 20, FALSE),
(5, 7, 82.00, 3, 15, TRUE),
(3, 8, 35.00, 2, 25, TRUE),
(4, 9, 38.00, 2, 20, TRUE),
(2, 10, 96.00, 1, 15, TRUE),
(6, 9, 39.50, 4, 15, FALSE);

-- 6. Lots en Stock (14 enregistrements avec dates dynamiques par rapport à CURDATE())
-- Couvre : Multi-lots FEFO, Lot proche péremption (< 25 jours), Lot périmé, Lot en sous-seuil, Lot froid
INSERT INTO lot_stock (
    numero_lot_fabricant, id_medicament, id_fournisseur, id_zone,
    date_fabrication, date_peremption, date_reception,
    quantite_initiale, quantite_actuelle, prix_achat_unitaire, statut_lot
) VALUES
-- Augmentin (2 lots valides pour démontrer le prélèvement FEFO sur le lot expirant dans 20 jours d'abord)
('LOT-AUG-2025A', 1, 1, 2, DATE_SUB(CURDATE(), INTERVAL 300 DAY), DATE_ADD(CURDATE(), INTERVAL 20 DAY), DATE_SUB(CURDATE(), INTERVAL 250 DAY), 40, 15, 74.00, 'DISPONIBLE'),
('LOT-AUG-2026B', 1, 3, 2, DATE_SUB(CURDATE(), INTERVAL 60 DAY),  DATE_ADD(CURDATE(), INTERVAL 280 DAY), DATE_SUB(CURDATE(), INTERVAL 45 DAY), 80, 60, 76.50, 'DISPONIBLE'),

-- Zinnat (Stock faible : 12 unités < seuil de 30 -> déclenche alerte réapprovisionnement)
('LOT-ZIN-104',   2, 1, 2, DATE_SUB(CURDATE(), INTERVAL 180 DAY), DATE_ADD(CURDATE(), INTERVAL 150 DAY), DATE_SUB(CURDATE(), INTERVAL 160 DAY), 50, 12, 99.00, 'DISPONIBLE'),

-- Doliprane (2 lots confortables)
('LOT-DOL-881',   3, 2, 1, DATE_SUB(CURDATE(), INTERVAL 200 DAY), DATE_ADD(CURDATE(), INTERVAL 75 DAY),  DATE_SUB(CURDATE(), INTERVAL 180 DAY), 120, 45, 10.50, 'DISPONIBLE'),
('LOT-DOL-992',   3, 4, 1, DATE_SUB(CURDATE(), INTERVAL 40 DAY),  DATE_ADD(CURDATE(), INTERVAL 420 DAY), DATE_SUB(CURDATE(), INTERVAL 30 DAY),  150, 110, 11.00, 'DISPONIBLE'),

-- Lantus Insuline (Chambre froide obligatoire FRIGO-01, id_zone=3)
('LOT-LAN-COLD1', 4, 2, 3, DATE_SUB(CURDATE(), INTERVAL 120 DAY), DATE_ADD(CURDATE(), INTERVAL 24 DAY),  DATE_SUB(CURDATE(), INTERVAL 100 DAY), 30, 10, 290.00, 'DISPONIBLE'),
('LOT-LAN-COLD2', 4, 2, 3, DATE_SUB(CURDATE(), INTERVAL 30 DAY),  DATE_ADD(CURDATE(), INTERVAL 210 DAY), DATE_SUB(CURDATE(), INTERVAL 20 DAY),  40, 32, 290.00, 'DISPONIBLE'),

-- Glucophage
('LOT-GLU-501',   5, 4, 1, DATE_SUB(CURDATE(), INTERVAL 150 DAY), DATE_ADD(CURDATE(), INTERVAL 310 DAY), DATE_SUB(CURDATE(), INTERVAL 130 DAY), 100, 72, 26.50, 'DISPONIBLE'),

-- Amlor (1 lot valide + 1 lot PERIME pour tester le blocage par Trigger)
('LOT-AML-OLD',   6, 5, 2, DATE_SUB(CURDATE(), INTERVAL 500 DAY), DATE_SUB(CURDATE(), INTERVAL 15 DAY),  DATE_SUB(CURDATE(), INTERVAL 460 DAY), 40, 14, 46.00, 'PERIME'),
('LOT-AML-NEW',   6, 5, 2, DATE_SUB(CURDATE(), INTERVAL 90 DAY),  DATE_ADD(CURDATE(), INTERVAL 260 DAY), DATE_SUB(CURDATE(), INTERVAL 75 DAY),  60, 48, 46.00, 'DISPONIBLE'),

-- Cozaar (Sous le seuil d'alerte : 18 < 30)
('LOT-COZ-302',   7, 5, 2, DATE_SUB(CURDATE(), INTERVAL 110 DAY), DATE_ADD(CURDATE(), INTERVAL 60 DAY),  DATE_SUB(CURDATE(), INTERVAL 95 DAY),  50, 18, 82.00, 'DISPONIBLE'),

-- Ventoline
('LOT-VEN-771',   8, 3, 1, DATE_SUB(CURDATE(), INTERVAL 80 DAY),  DATE_ADD(CURDATE(), INTERVAL 190 DAY), DATE_SUB(CURDATE(), INTERVAL 65 DAY),  90, 64, 35.00, 'DISPONIBLE'),

-- Mopral (Lot en QUARANTAINE dans COFFRE-S1)
('LOT-MOP-QUAR',  9, 4, 5, DATE_SUB(CURDATE(), INTERVAL 140 DAY), DATE_ADD(CURDATE(), INTERVAL 120 DAY), DATE_SUB(CURDATE(), INTERVAL 125 DAY), 50, 25, 38.00, 'QUARANTAINE'),
('LOT-MOP-OK',    9, 4, 1, DATE_SUB(CURDATE(), INTERVAL 50 DAY),  DATE_ADD(CURDATE(), INTERVAL 300 DAY), DATE_SUB(CURDATE(), INTERVAL 40 DAY),  80, 55, 38.00, 'DISPONIBLE'),

-- Vaxigrip Tetra (Chambre froide FRIGO-02, id_zone=4 - Sous le seuil : 9 < 20)
('LOT-VAX-2026',  10, 2, 4, DATE_SUB(CURDATE(), INTERVAL 45 DAY), DATE_ADD(CURDATE(), INTERVAL 18 DAY),  DATE_SUB(CURDATE(), INTERVAL 35 DAY),  30, 9,  96.00, 'DISPONIBLE');

-- 7. Patients (7 enregistrements)
INSERT INTO patient (cin, nom, prenom, date_naissance, sexe, telephone, organisme_assurance) VALUES
('AA104521', 'El Amrani', 'Youssef', '1978-04-12', 'M', '+212-661-123456', 'CNOPS'),
('BE883920', 'Bennani', 'Salma', '1992-09-25', 'F', '+212-662-987654', 'CNSS'),
('CD441209', 'Tazi', 'Abdelkader', '1959-11-03', 'M', '+212-663-456789', 'CNOPS'),
('AB774123', 'Chraibi', 'Nadia', '1985-02-19', 'F', '+212-664-321654', 'AXA Assurance'),
('GA339012', 'Mansouri', 'Karim', '2001-07-08', 'M', '+212-665-789123', 'AMO Etudiant'),
('EE552190', 'Idrissi', 'Fatima Zahra', '1967-12-30', 'F', '+212-668-147258', 'CNSS'),
('JK908172', 'Ouali', 'Hassan', '1973-06-15', 'M', '+212-661-852963', 'RMA Watanya');

-- 8. Médecins Prescripteurs (6 enregistrements)
INSERT INTO medecin (numero_inpe, nom_complet, specialite, etablissement, telephone) VALUES
('INPE-100234', 'Dr. Alaoui Mohammed', 'Maladies Infectieuses', 'CHU Ibn Sina - Rabat', '+212-537-670101'),
('INPE-100589', 'Dr. Berrada Laila', 'Endocrinologie & Diabétologie', 'Clinique Agdal - Rabat', '+212-537-774455'),
('INPE-100812', 'Dr. Kettani Omar', 'Cardiologie', 'Hôpital Cheikh Zaid - Rabat', '+212-537-686868'),
('INPE-100945', 'Dr. Fassi Fihri Amina', 'Pneumologie', 'Cabinet Spécialisé Hassan - Rabat', '+212-537-702030'),
('INPE-101120', 'Dr. Zniber Mehdi', 'Médecine Générale', 'Centre Médical Hay Riad', '+212-537-561212'),
('INPE-101499', 'Dr. Skalli Hind', 'Gastro-entérologie', 'Polyclinique CNSS - Salé', '+212-537-809010');

-- 9. Ordonnances (8 enregistrements)
INSERT INTO ordonnance (reference_ordonnance, id_patient, id_medecin, date_prescription, date_dispensation, statut_ordonnance, notes_cliniques) VALUES
('ORD-2026-0001', 1, 1, DATE_SUB(CURDATE(), INTERVAL 10 DAY), DATE_SUB(NOW(), INTERVAL 10 DAY), 'SERVIE', 'Infection ORL bactérienne aiguë'),
('ORD-2026-0002', 2, 2, DATE_SUB(CURDATE(), INTERVAL 8 DAY),  DATE_SUB(NOW(), INTERVAL 8 DAY),  'SERVIE', 'Suivi diabète type 1 et contrôle glycémique'),
('ORD-2026-0003', 3, 3, DATE_SUB(CURDATE(), INTERVAL 6 DAY),  DATE_SUB(NOW(), INTERVAL 6 DAY),  'SERVIE', 'Hypertension artérielle chronique stabilisée'),
('ORD-2026-0004', 4, 4, DATE_SUB(CURDATE(), INTERVAL 5 DAY),  DATE_SUB(NOW(), INTERVAL 5 DAY),  'SERVIE', 'Asthme persistant modéré'),
('ORD-2026-0005', 5, 5, DATE_SUB(CURDATE(), INTERVAL 3 DAY),  DATE_SUB(NOW(), INTERVAL 3 DAY),  'SERVIE', 'Syndrome grippal et fièvre'),
('ORD-2026-0006', 6, 2, DATE_SUB(CURDATE(), INTERVAL 2 DAY),  DATE_SUB(NOW(), INTERVAL 2 DAY),  'SERVIE', 'Diabète type 2 + protection gastrique'),
('ORD-2026-0007', 7, 3, DATE_SUB(CURDATE(), INTERVAL 1 DAY),  DATE_SUB(NOW(), INTERVAL 1 DAY),  'SERVIE', 'Bithérapie antihypertensive'),
('ORD-2026-0008', 1, 6, CURDATE(),                            NOW(),                            'SERVIE', 'Reflux gastro-oesophagien');

-- 10. Lignes de Dispensation (12 enregistrements)
-- Note : Chaque insertion déclenche automatiquement trg_before_insert_dispensation
-- qui vérifie la validité du lot, déduit le stock et alimente journal_mouvements_stock !
INSERT INTO ligne_dispensation (id_ordonnance, id_lot, quantite_delivree, prix_unitaire_facture, posologie) VALUES
(1, 1, 3,  98.50, '1 comprimé matin et soir pendant 7 jours'),
(1, 4, 2,  15.60, '1 comprimé en cas de douleur ou fièvre (max 3/jour)'),
(2, 6, 4, 365.00, '1 injection sous-cutanée le soir à heure fixe'),
(2, 8, 3,  38.00, '1 comprimé au milieu des repas matin et soir'),
(3, 10, 3, 64.00, '1 gélule par jour le matin'),
(3, 11, 2, 110.00, '1 comprimé par jour'),
(4, 12, 4, 49.50, '1 à 2 bouffées en cas de gêne respiratoire'),
(5, 4, 5,  15.60, '1 comprimé toutes les 6 heures si fièvre'),
(6, 8, 4,  38.00, '1 comprimé matin, midi et soir'),
(6, 14, 2, 54.00, '1 gélule le soir avant le repas'),
(7, 10, 2, 64.00, '1 gélule par jour'),
(8, 14, 3, 54.00, '1 gélule par jour pendant 1 mois');
