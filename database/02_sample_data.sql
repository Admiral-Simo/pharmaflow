-- ============================================================================
-- RELATIONAL DATABASE PROJECT - MASTER IN DATA & AI (INPT)
-- File : 02_sample_data.sql
-- Realistic dataset (> 5 records per main table + edge cases for triggers/FEFO)
-- ============================================================================

USE pharmaflow_db;

-- 1. Therapeutic Categories (7 records)
INSERT INTO therapeutic_category (atc_code, category_name, category_description) VALUES
('J01', 'Systemic Antibiotics', 'Treatment of severe and community-acquired bacterial infections'),
('N02', 'Analgesics and Antipyretics', 'Acute or chronic pain management and fever reduction'),
('A10', 'Antidiabetics and Insulins', 'Blood glucose regulation for Type 1 and Type 2 diabetes'),
('C09', 'Cardiology and Antihypertensives', 'Management of arterial hypertension and heart failure'),
('R03', 'Pulmonology and Antiasthmatics', 'Inhaled bronchodilators and respiratory corticosteroids'),
('A02', 'Gastroenterology and Antiulcerants', 'Proton pump inhibitors and gastric mucosal protectants'),
('J07', 'Vaccines and Immunology', 'Thermolabile immunological biologics requiring strict cold-chain');

-- 2. Pharmaceutical Suppliers (6 records)
INSERT INTO supplier (company_name, tax_registration_id, phone_number, email, city, reliability_score, is_active) VALUES
('Cooper Pharma Distribution', '001524896000084', '+212-522-354000', 'orders@cooperpharma.ma', 'Casablanca', 4.85, TRUE),
('Sothema Laboratories', '001639841000021', '+212-522-970600', 'supplychain@sothema.ma', 'Bouskoura', 4.90, TRUE),
('Laprophan Logistics', '001412365000059', '+212-522-618181', 'logistics@laprophan.ma', 'Casablanca', 4.65, TRUE),
('Pharma 5 Industries', '001789654000033', '+212-522-780101', 'procurement@pharma5.ma', 'Casablanca', 4.70, TRUE),
('Galenica Laboratories', '001852963000077', '+212-522-335252', 'sales@galenica.ma', 'Casablanca', 4.40, TRUE),
('Promopharm Healthcare', '001951753000012', '+212-523-321010', 'support@promopharm.ma', 'Berrechid', 4.55, TRUE);

-- 3. Storage Zones (5 records)
INSERT INTO storage_zone (zone_code, zone_name, min_temperature_c, max_temperature_c, is_refrigerated, max_capacity) VALUES
('RACK-A1', 'Central Shelving Bay A1 - Fast-Moving Stock', 15.0, 25.0, FALSE, 2500),
('RACK-B2', 'Shelving Bay B2 - Antibiotics & Cardiology', 15.0, 25.0, FALSE, 1800),
('COLD-01', 'Primary Walk-In Cold Room #1 (Insulins/Vaccines)', 2.0, 8.0, TRUE, 600),
('COLD-02', 'Backup Refrigerated Medical Cabinet #2', 2.0, 8.0, TRUE, 400),
('VAULT-S1', 'High-Security Quarantine & Controlled Vault', 15.0, 22.0, FALSE, 500);

-- 4. Medications (10 records)
INSERT INTO medication (national_drug_code, brand_name, active_ingredient, dosage_form, strength, unit_selling_price, reorder_threshold, requires_prescription, requires_cold_chain, category_id) VALUES
('340093001', 'Augmentin Adult', 'Amoxicillin / Clavulanic Acid', 'Tablet', '1g / 125mg', 98.50, 40, TRUE, FALSE, 1),
('340093002', 'Zinnat', 'Cefuroxime', 'Tablet', '500mg', 132.00, 30, TRUE, FALSE, 1),
('340093003', 'Doliprane', 'Paracetamol', 'Tablet', '1000mg', 15.60, 80, FALSE, FALSE, 2),
('340093004', 'Lantus Solostar', 'Insulin Glargine', 'Injectable', '100 IU/ml', 365.00, 25, TRUE, TRUE, 3),
('340093005', 'Glucophage', 'Metformin', 'Tablet', '850mg', 38.00, 50, TRUE, FALSE, 3),
('340093006', 'Amlor', 'Amlodipine', 'Capsule', '5mg', 64.00, 35, TRUE, FALSE, 4),
('340093007', 'Cozaar', 'Losartan', 'Tablet', '50mg', 110.00, 30, TRUE, FALSE, 4),
('340093008', 'Ventolin', 'Salbutamol', 'Inhaler', '100 mcg/dose', 49.50, 45, TRUE, FALSE, 5),
('340093009', 'Mopral', 'Omeprazole', 'Capsule', '20mg', 54.00, 40, FALSE, FALSE, 6),
('340093010', 'Vaxigrip Tetra', 'Quadrivalent Influenza Vaccine', 'Injectable', '0.5 ml', 128.00, 20, TRUE, TRUE, 7);

-- 5. Supplier Catalog (M:N Junction Table - 15 records)
INSERT INTO supplier_catalog (supplier_id, medication_id, contract_unit_cost, lead_time_days, min_order_quantity, is_preferred_supplier) VALUES
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

-- 6. Stock Batches (15 records with dynamic dates relative to CURDATE())
-- Includes: Multi-batch FEFO candidates, Near-expiry (< 25 days), Expired batch, Quarantined batch, Cold-chain
INSERT INTO stock_batch (
    manufacturer_batch_number, medication_id, supplier_id, zone_id,
    manufacturing_date, expiration_date, received_date,
    initial_quantity, current_quantity, unit_purchase_cost, batch_status
) VALUES
-- Augmentin Adult (2 valid batches to demonstrate FEFO deduction from the batch expiring in 20 days first)
('BATCH-AUG-2025A', 1, 1, 2, DATE_SUB(CURDATE(), INTERVAL 300 DAY), DATE_ADD(CURDATE(), INTERVAL 20 DAY), DATE_SUB(CURDATE(), INTERVAL 250 DAY), 40, 15, 74.00, 'AVAILABLE'),
('BATCH-AUG-2026B', 1, 3, 2, DATE_SUB(CURDATE(), INTERVAL 60 DAY),  DATE_ADD(CURDATE(), INTERVAL 280 DAY), DATE_SUB(CURDATE(), INTERVAL 45 DAY), 80, 60, 76.50, 'AVAILABLE'),

-- Zinnat (Low stock: 12 units < reorder threshold of 30 -> triggers low-stock alert)
('BATCH-ZIN-104',   2, 1, 2, DATE_SUB(CURDATE(), INTERVAL 180 DAY), DATE_ADD(CURDATE(), INTERVAL 150 DAY), DATE_SUB(CURDATE(), INTERVAL 160 DAY), 50, 12, 99.00, 'AVAILABLE'),

-- Doliprane (2 healthy batches)
('BATCH-DOL-881',   3, 2, 1, DATE_SUB(CURDATE(), INTERVAL 200 DAY), DATE_ADD(CURDATE(), INTERVAL 75 DAY),  DATE_SUB(CURDATE(), INTERVAL 180 DAY), 120, 45, 10.50, 'AVAILABLE'),
('BATCH-DOL-992',   3, 4, 1, DATE_SUB(CURDATE(), INTERVAL 40 DAY),  DATE_ADD(CURDATE(), INTERVAL 420 DAY), DATE_SUB(CURDATE(), INTERVAL 30 DAY),  150, 110, 11.00, 'AVAILABLE'),

-- Lantus Solostar Insulin (Mandatory Cold-Chain COLD-01, zone_id=3)
('BATCH-LAN-COLD1', 4, 2, 3, DATE_SUB(CURDATE(), INTERVAL 120 DAY), DATE_ADD(CURDATE(), INTERVAL 24 DAY),  DATE_SUB(CURDATE(), INTERVAL 100 DAY), 30, 10, 290.00, 'AVAILABLE'),
('BATCH-LAN-COLD2', 4, 2, 3, DATE_SUB(CURDATE(), INTERVAL 30 DAY),  DATE_ADD(CURDATE(), INTERVAL 210 DAY), DATE_SUB(CURDATE(), INTERVAL 20 DAY),  40, 32, 290.00, 'AVAILABLE'),

-- Glucophage
('BATCH-GLU-501',   5, 4, 1, DATE_SUB(CURDATE(), INTERVAL 150 DAY), DATE_ADD(CURDATE(), INTERVAL 310 DAY), DATE_SUB(CURDATE(), INTERVAL 130 DAY), 100, 72, 26.50, 'AVAILABLE'),

-- Amlor (1 expired batch + 1 valid batch to test trigger blocking)
('BATCH-AML-OLD',   6, 5, 2, DATE_SUB(CURDATE(), INTERVAL 500 DAY), DATE_SUB(CURDATE(), INTERVAL 15 DAY),  DATE_SUB(CURDATE(), INTERVAL 460 DAY), 40, 14, 46.00, 'EXPIRED'),
('BATCH-AML-NEW',   6, 5, 2, DATE_SUB(CURDATE(), INTERVAL 90 DAY),  DATE_ADD(CURDATE(), INTERVAL 260 DAY), DATE_SUB(CURDATE(), INTERVAL 75 DAY),  60, 48, 46.00, 'AVAILABLE'),

-- Cozaar (Below reorder threshold: 18 < 30)
('BATCH-COZ-302',   7, 5, 2, DATE_SUB(CURDATE(), INTERVAL 110 DAY), DATE_ADD(CURDATE(), INTERVAL 60 DAY),  DATE_SUB(CURDATE(), INTERVAL 95 DAY),  50, 18, 82.00, 'AVAILABLE'),

-- Ventolin
('BATCH-VEN-771',   8, 3, 1, DATE_SUB(CURDATE(), INTERVAL 80 DAY),  DATE_ADD(CURDATE(), INTERVAL 190 DAY), DATE_SUB(CURDATE(), INTERVAL 65 DAY),  90, 64, 35.00, 'AVAILABLE'),

-- Mopral (1 batch locked in QUARANTINED status in VAULT-S1 + 1 available batch)
('BATCH-MOP-QUAR',  9, 4, 5, DATE_SUB(CURDATE(), INTERVAL 140 DAY), DATE_ADD(CURDATE(), INTERVAL 120 DAY), DATE_SUB(CURDATE(), INTERVAL 125 DAY), 50, 25, 38.00, 'QUARANTINED'),
('BATCH-MOP-OK',    9, 4, 1, DATE_SUB(CURDATE(), INTERVAL 50 DAY),  DATE_ADD(CURDATE(), INTERVAL 300 DAY), DATE_SUB(CURDATE(), INTERVAL 40 DAY),  80, 55, 38.00, 'AVAILABLE'),

-- Vaxigrip Tetra (Cold-Chain COLD-02, zone_id=4 - Below threshold: 9 < 20)
('BATCH-VAX-2026',  10, 2, 4, DATE_SUB(CURDATE(), INTERVAL 45 DAY), DATE_ADD(CURDATE(), INTERVAL 18 DAY),  DATE_SUB(CURDATE(), INTERVAL 35 DAY),  30, 9,  96.00, 'AVAILABLE');

-- 7. Patients (7 records)
INSERT INTO patient (national_id, last_name, first_name, date_of_birth, gender, phone_number, insurance_provider) VALUES
('AA104521', 'El Amrani', 'Youssef', '1978-04-12', 'M', '+212-661-123456', 'CNOPS'),
('BE883920', 'Bennani', 'Salma', '1992-09-25', 'F', '+212-662-987654', 'CNSS'),
('CD441209', 'Tazi', 'Abdelkader', '1959-11-03', 'M', '+212-663-456789', 'CNOPS'),
('AB774123', 'Chraibi', 'Nadia', '1985-02-19', 'F', '+212-664-321654', 'AXA Healthcare'),
('GA339012', 'Mansouri', 'Karim', '2001-07-08', 'M', '+212-665-789123', 'Student AMO'),
('EE552190', 'Idrissi', 'Fatima Zahra', '1967-12-30', 'F', '+212-668-147258', 'CNSS'),
('JK908172', 'Ouali', 'Hassan', '1973-06-15', 'M', '+212-661-852963', 'RMA Insurance');

-- 8. Prescribing Physicians (6 records)
INSERT INTO physician (license_number, full_name, specialty, medical_facility, phone_number) VALUES
('INPE-100234', 'Dr. Mohammed Alaoui', 'Infectious Diseases', 'Ibn Sina University Hospital - Rabat', '+212-537-670101'),
('INPE-100589', 'Dr. Laila Berrada', 'Endocrinology & Diabetology', 'Agdal Medical Clinic - Rabat', '+212-537-774455'),
('INPE-100812', 'Dr. Omar Kettani', 'Cardiology', 'Cheikh Zaid Foundation Hospital - Rabat', '+212-537-686868'),
('INPE-100945', 'Dr. Amina Fassi Fihri', 'Pulmonology', 'Hassan Respiratory Center - Rabat', '+212-537-702030'),
('INPE-101120', 'Dr. Mehdi Zniber', 'General Practice', 'Hay Riad Medical Center', '+212-537-561212'),
('INPE-101499', 'Dr. Hind Skalli', 'Gastroenterology', 'CNSS Polyclinic - Sale', '+212-537-809010');

-- 9. Medical Prescriptions (8 records)
INSERT INTO prescription (prescription_reference, patient_id, physician_id, prescription_date, dispensed_at, prescription_status, clinical_notes) VALUES
('RX-2026-0001', 1, 1, DATE_SUB(CURDATE(), INTERVAL 10 DAY), DATE_SUB(NOW(), INTERVAL 10 DAY), 'DISPENSED', 'Acute bacterial ENT infection'),
('RX-2026-0002', 2, 2, DATE_SUB(CURDATE(), INTERVAL 8 DAY),  DATE_SUB(NOW(), INTERVAL 8 DAY),  'DISPENSED', 'Type 1 diabetes follow-up and glycemic control'),
('RX-2026-0003', 3, 3, DATE_SUB(CURDATE(), INTERVAL 6 DAY),  DATE_SUB(NOW(), INTERVAL 6 DAY),  'DISPENSED', 'Stabilized chronic arterial hypertension'),
('RX-2026-0004', 4, 4, DATE_SUB(CURDATE(), INTERVAL 5 DAY),  DATE_SUB(NOW(), INTERVAL 5 DAY),  'DISPENSED', 'Moderate persistent bronchial asthma'),
('RX-2026-0005', 5, 5, DATE_SUB(CURDATE(), INTERVAL 3 DAY),  DATE_SUB(NOW(), INTERVAL 3 DAY),  'DISPENSED', 'Viral influenza syndrome and pyrexia'),
('RX-2026-0006', 6, 2, DATE_SUB(CURDATE(), INTERVAL 2 DAY),  DATE_SUB(NOW(), INTERVAL 2 DAY),  'DISPENSED', 'Type 2 diabetes + gastric mucosal protection'),
('RX-2026-0007', 7, 3, DATE_SUB(CURDATE(), INTERVAL 1 DAY),  DATE_SUB(NOW(), INTERVAL 1 DAY),  'DISPENSED', 'Dual antihypertensive therapy'),
('RX-2026-0008', 1, 6, CURDATE(),                            NOW(),                            'DISPENSED', 'Gastroesophageal reflux disease');

-- 10. Dispensing Line Items (12 records)
-- Note: Every INSERT fires trg_before_insert_dispensing_item, which validates the batch,
-- deducts current_quantity, and populates stock_movement_log automatically.
INSERT INTO dispensing_item (prescription_id, batch_id, dispensed_quantity, billed_unit_price, dosage_instructions) VALUES
(1, 1, 3,  98.50, '1 tablet morning and evening for 7 days'),
(1, 4, 2,  15.60, '1 tablet every 6 hours in case of pain or fever (max 3/day)'),
(2, 6, 4, 365.00, '1 subcutaneous injection every evening at a fixed time'),
(2, 8, 3,  38.00, '1 tablet with meals morning and evening'),
(3, 10, 3, 64.00, '1 capsule daily in the morning'),
(3, 11, 2, 110.00, '1 tablet daily'),
(4, 12, 4, 49.50, '1 to 2 puffs as needed for bronchospasm relief'),
(5, 4, 5,  15.60, '1 tablet every 6 hours if fever exceeds 38.5C'),
(6, 8, 4,  38.00, '1 tablet morning, noon, and evening'),
(6, 14, 2, 54.00, '1 capsule in the evening before dinner'),
(7, 10, 2, 64.00, '1 capsule daily'),
(8, 14, 3, 54.00, '1 capsule daily for 30 days');
