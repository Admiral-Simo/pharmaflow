-- ============================================================================
-- RELATIONAL DATABASE PROJECT - MASTER IN DATA & AI (INPT)
-- System  : PharmaFlow - Hospital Pharmacy, FEFO Batch & Prescription Management
-- DBMS    : MySQL 8.0+
-- File    : 01_schema_and_triggers.sql
-- ============================================================================

DROP DATABASE IF EXISTS pharmaflow_db;
CREATE DATABASE pharmaflow_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE pharmaflow_db;

-- ============================================================================
-- 1. TABLE DEFINITIONS (3NF Relational Schema)
-- ============================================================================

-- 1.1 Therapeutic Categories (ATC Classification)
CREATE TABLE therapeutic_category (
    category_id INT AUTO_INCREMENT,
    atc_code VARCHAR(10) NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    category_description VARCHAR(255) NOT NULL,
    CONSTRAINT pk_therapeutic_category PRIMARY KEY (category_id),
    CONSTRAINT uq_category_atc_code UNIQUE (atc_code),
    CONSTRAINT uq_category_name UNIQUE (category_name)
) ENGINE=InnoDB;

-- 1.2 Pharmaceutical Suppliers
CREATE TABLE supplier (
    supplier_id INT AUTO_INCREMENT,
    company_name VARCHAR(120) NOT NULL,
    tax_registration_id VARCHAR(20) NOT NULL,
    phone_number VARCHAR(25) NOT NULL,
    email VARCHAR(120) NOT NULL,
    city VARCHAR(60) NOT NULL,
    reliability_score DECIMAL(3,2) NOT NULL DEFAULT 4.50,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_supplier PRIMARY KEY (supplier_id),
    CONSTRAINT uq_supplier_company_name UNIQUE (company_name),
    CONSTRAINT uq_supplier_tax_id UNIQUE (tax_registration_id),
    CONSTRAINT uq_supplier_email UNIQUE (email),
    CONSTRAINT chk_supplier_reliability CHECK (reliability_score BETWEEN 1.00 AND 5.00)
) ENGINE=InnoDB;

-- 1.3 Storage Zones (Cold Rooms, Standard Shelving, Quarantine Vaults)
CREATE TABLE storage_zone (
    zone_id INT AUTO_INCREMENT,
    zone_code VARCHAR(20) NOT NULL,
    zone_name VARCHAR(100) NOT NULL,
    min_temperature_c DECIMAL(4,1) NOT NULL,
    max_temperature_c DECIMAL(4,1) NOT NULL,
    is_refrigerated BOOLEAN NOT NULL DEFAULT FALSE,
    max_capacity INT NOT NULL DEFAULT 1000,
    CONSTRAINT pk_storage_zone PRIMARY KEY (zone_id),
    CONSTRAINT uq_storage_zone_code UNIQUE (zone_code),
    CONSTRAINT chk_zone_temperature CHECK (max_temperature_c >= min_temperature_c),
    CONSTRAINT chk_zone_capacity CHECK (max_capacity > 0)
) ENGINE=InnoDB;

-- 1.4 Medications Master Catalog
CREATE TABLE medication (
    medication_id INT AUTO_INCREMENT,
    national_drug_code VARCHAR(20) NOT NULL,
    brand_name VARCHAR(120) NOT NULL,
    active_ingredient VARCHAR(120) NOT NULL,
    dosage_form ENUM('Tablet', 'Capsule', 'Syrup', 'Injectable', 'Ointment', 'Eye_Drops', 'Inhaler') NOT NULL,
    strength VARCHAR(50) NOT NULL,
    unit_selling_price DECIMAL(10,2) NOT NULL,
    reorder_threshold INT NOT NULL DEFAULT 30,
    requires_prescription BOOLEAN NOT NULL DEFAULT TRUE,
    requires_cold_chain BOOLEAN NOT NULL DEFAULT FALSE,
    category_id INT NOT NULL,
    CONSTRAINT pk_medication PRIMARY KEY (medication_id),
    CONSTRAINT uq_medication_ndc UNIQUE (national_drug_code),
    CONSTRAINT fk_medication_category FOREIGN KEY (category_id)
        REFERENCES therapeutic_category(category_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_medication_selling_price CHECK (unit_selling_price > 0),
    CONSTRAINT chk_medication_reorder_threshold CHECK (reorder_threshold >= 0)
) ENGINE=InnoDB;

-- 1.5 M:N Junction Table: Supplier Catalog (Composite Primary Key)
CREATE TABLE supplier_catalog (
    supplier_id INT NOT NULL,
    medication_id INT NOT NULL,
    contract_unit_cost DECIMAL(10,2) NOT NULL,
    lead_time_days INT NOT NULL DEFAULT 3,
    min_order_quantity INT NOT NULL DEFAULT 10,
    is_preferred_supplier BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_supplier_catalog PRIMARY KEY (supplier_id, medication_id),
    CONSTRAINT fk_catalog_supplier FOREIGN KEY (supplier_id)
        REFERENCES supplier(supplier_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_catalog_medication FOREIGN KEY (medication_id)
        REFERENCES medication(medication_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_catalog_unit_cost CHECK (contract_unit_cost > 0),
    CONSTRAINT chk_catalog_lead_time CHECK (lead_time_days >= 1),
    CONSTRAINT chk_catalog_min_order_qty CHECK (min_order_quantity >= 1)
) ENGINE=InnoDB;

-- 1.6 Physical Inventory Batches (Core FEFO Entity)
CREATE TABLE stock_batch (
    batch_id INT AUTO_INCREMENT,
    manufacturer_batch_number VARCHAR(40) NOT NULL,
    medication_id INT NOT NULL,
    supplier_id INT NOT NULL,
    zone_id INT NOT NULL,
    manufacturing_date DATE NOT NULL,
    expiration_date DATE NOT NULL,
    received_date DATE NOT NULL,
    initial_quantity INT NOT NULL,
    current_quantity INT NOT NULL,
    unit_purchase_cost DECIMAL(10,2) NOT NULL,
    batch_status ENUM('AVAILABLE', 'DEPLETED', 'EXPIRED', 'QUARANTINED') NOT NULL DEFAULT 'AVAILABLE',
    CONSTRAINT pk_stock_batch PRIMARY KEY (batch_id),
    CONSTRAINT uq_batch_manufacturer_med UNIQUE (manufacturer_batch_number, medication_id),
    CONSTRAINT fk_batch_medication FOREIGN KEY (medication_id)
        REFERENCES medication(medication_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_batch_supplier FOREIGN KEY (supplier_id)
        REFERENCES supplier(supplier_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_batch_zone FOREIGN KEY (zone_id)
        REFERENCES storage_zone(zone_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_batch_dates CHECK (expiration_date > manufacturing_date),
    CONSTRAINT chk_batch_initial_qty CHECK (initial_quantity > 0),
    CONSTRAINT chk_batch_current_qty CHECK (current_quantity >= 0 AND current_quantity <= initial_quantity),
    CONSTRAINT chk_batch_purchase_cost CHECK (unit_purchase_cost > 0)
) ENGINE=InnoDB;

-- 1.7 Patients
CREATE TABLE patient (
    patient_id INT AUTO_INCREMENT,
    national_id VARCHAR(15) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    first_name VARCHAR(60) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('M', 'F') NOT NULL,
    phone_number VARCHAR(25) NOT NULL,
    insurance_provider VARCHAR(60) NOT NULL DEFAULT 'CNOPS',
    CONSTRAINT pk_patient PRIMARY KEY (patient_id),
    CONSTRAINT uq_patient_national_id UNIQUE (national_id)
) ENGINE=InnoDB;

-- 1.8 Prescribing Physicians
CREATE TABLE physician (
    physician_id INT AUTO_INCREMENT,
    license_number VARCHAR(20) NOT NULL,
    full_name VARCHAR(120) NOT NULL,
    specialty VARCHAR(80) NOT NULL,
    medical_facility VARCHAR(120) NOT NULL,
    phone_number VARCHAR(25) NOT NULL,
    CONSTRAINT pk_physician PRIMARY KEY (physician_id),
    CONSTRAINT uq_physician_license UNIQUE (license_number)
) ENGINE=InnoDB;

-- 1.9 Medical Prescriptions
CREATE TABLE prescription (
    prescription_id INT AUTO_INCREMENT,
    prescription_reference VARCHAR(30) NOT NULL,
    patient_id INT NOT NULL,
    physician_id INT NOT NULL,
    prescription_date DATE NOT NULL,
    dispensed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    prescription_status ENUM('PENDING', 'DISPENSED', 'CANCELLED') NOT NULL DEFAULT 'DISPENSED',
    clinical_notes VARCHAR(255) DEFAULT NULL,
    CONSTRAINT pk_prescription PRIMARY KEY (prescription_id),
    CONSTRAINT uq_prescription_reference UNIQUE (prescription_reference),
    CONSTRAINT fk_prescription_patient FOREIGN KEY (patient_id)
        REFERENCES patient(patient_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_prescription_physician FOREIGN KEY (physician_id)
        REFERENCES physician(physician_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 1.10 M:N Junction Table: Dispensing Line Items (Prescription <-> Stock_Batch)
CREATE TABLE dispensing_item (
    prescription_id INT NOT NULL,
    batch_id INT NOT NULL,
    dispensed_quantity INT NOT NULL,
    billed_unit_price DECIMAL(10,2) NOT NULL,
    dosage_instructions VARCHAR(150) NOT NULL,
    CONSTRAINT pk_dispensing_item PRIMARY KEY (prescription_id, batch_id),
    CONSTRAINT fk_dispensing_prescription FOREIGN KEY (prescription_id)
        REFERENCES prescription(prescription_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_dispensing_batch FOREIGN KEY (batch_id)
        REFERENCES stock_batch(batch_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_dispensing_qty CHECK (dispensed_quantity > 0),
    CONSTRAINT chk_dispensing_price CHECK (billed_unit_price > 0)
) ENGINE=InnoDB;

-- 1.11 Immutable Stock Movement Audit Ledger
CREATE TABLE stock_movement_log (
    movement_id INT AUTO_INCREMENT,
    batch_id INT NOT NULL,
    movement_type ENUM('INITIAL_RECEIPT', 'DISPENSING', 'POSITIVE_ADJUSTMENT', 'NEGATIVE_ADJUSTMENT', 'QUARANTINE_LOCK') NOT NULL,
    quantity_before INT NOT NULL,
    quantity_after INT NOT NULL,
    quantity_delta INT NOT NULL,
    movement_timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    operator_name VARCHAR(80) NOT NULL DEFAULT 'SYSTEM_TRIGGER',
    audit_comment VARCHAR(255) NOT NULL,
    CONSTRAINT pk_stock_movement_log PRIMARY KEY (movement_id),
    CONSTRAINT fk_movement_batch FOREIGN KEY (batch_id)
        REFERENCES stock_batch(batch_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================================
-- 2. BUSINESS LOGIC TRIGGERS (Requirement #7)
-- ============================================================================

DELIMITER $$

-- TRIGGER 1: Enforce Cold-Chain Compliance and Synchronize Batch Status on INSERT
CREATE TRIGGER trg_before_insert_batch_validation
BEFORE INSERT ON stock_batch
FOR EACH ROW
BEGIN
    DECLARE v_cold_chain_required BOOLEAN;
    DECLARE v_zone_is_refrigerated BOOLEAN;

    SELECT requires_cold_chain INTO v_cold_chain_required
    FROM medication WHERE medication_id = NEW.medication_id;

    SELECT is_refrigerated INTO v_zone_is_refrigerated
    FROM storage_zone WHERE zone_id = NEW.zone_id;

    -- Business Rule: Thermolabile medications (e.g. Insulin, Vaccines) MUST be placed in a refrigerated zone
    IF v_cold_chain_required = TRUE AND v_zone_is_refrigerated = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'BUSINESS RULE VIOLATION [Cold-Chain]: This thermolabile medication requires a refrigerated storage zone.';
    END IF;

    -- Automatically flag status if inserted batch is already expired or empty
    IF NEW.expiration_date < CURDATE() THEN
        SET NEW.batch_status = 'EXPIRED';
    ELSEIF NEW.current_quantity = 0 THEN
        SET NEW.batch_status = 'DEPLETED';
    END IF;
END$$

-- TRIGGER 2: Automatically Log Initial Batch Receipt in the Audit Ledger
CREATE TRIGGER trg_after_insert_batch_audit
AFTER INSERT ON stock_batch
FOR EACH ROW
BEGIN
    INSERT INTO stock_movement_log (
        batch_id, movement_type, quantity_before, quantity_after, quantity_delta, operator_name, audit_comment
    ) VALUES (
        NEW.batch_id,
        'INITIAL_RECEIPT',
        0,
        NEW.current_quantity,
        NEW.current_quantity,
        CURRENT_USER(),
        CONCAT('Initial stock receipt for batch ', NEW.manufacturer_batch_number)
    );
END$$

-- TRIGGER 3: Guard Dispensing Against Expired/Quarantined Batches and Deduct Stock Automatically
CREATE TRIGGER trg_before_insert_dispensing_item
BEFORE INSERT ON dispensing_item
FOR EACH ROW
BEGIN
    DECLARE v_available_qty INT;
    DECLARE v_exp_date DATE;
    DECLARE v_status VARCHAR(20);
    DECLARE v_batch_num VARCHAR(40);

    -- Lock and read the target batch state
    SELECT current_quantity, expiration_date, batch_status, manufacturer_batch_number
    INTO v_available_qty, v_exp_date, v_status, v_batch_num
    FROM stock_batch
    WHERE batch_id = NEW.batch_id
    FOR UPDATE;

    -- Safety Rule 1: Strictly prohibit dispensing from an expired batch
    IF v_exp_date < CURDATE() OR v_status = 'EXPIRED' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'SAFETY ALERT: Dispensing rejected because the selected batch is EXPIRED.';
    END IF;

    -- Safety Rule 2: Strictly prohibit dispensing from a quarantined batch
    IF v_status = 'QUARANTINED' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'SAFETY ALERT: Dispensing rejected because the selected batch is QUARANTINED.';
    END IF;

    -- Safety Rule 3: Verify sufficient available units in the batch
    IF v_available_qty < NEW.dispensed_quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'INVENTORY ERROR: Insufficient stock quantity in this batch to fulfill the dispensing request.';
    END IF;

    -- Deduct dispensed units from the batch (which in turn fires the stock_batch update triggers)
    UPDATE stock_batch
    SET current_quantity = current_quantity - NEW.dispensed_quantity
    WHERE batch_id = NEW.batch_id;
END$$

-- TRIGGER 4: Automatically Transition Batch Status ('DEPLETED' at 0) Before UPDATE
CREATE TRIGGER trg_before_update_batch_status
BEFORE UPDATE ON stock_batch
FOR EACH ROW
BEGIN
    IF NEW.current_quantity = 0 AND NEW.batch_status = 'AVAILABLE' THEN
        SET NEW.batch_status = 'DEPLETED';
    ELSEIF NEW.current_quantity > 0 AND OLD.batch_status = 'DEPLETED' AND NEW.expiration_date >= CURDATE() THEN
        SET NEW.batch_status = 'AVAILABLE';
    END IF;
END$$

-- TRIGGER 5: Record Every Stock Quantity or Quarantine Change in the Immutable Audit Ledger
CREATE TRIGGER trg_after_update_batch_audit
AFTER UPDATE ON stock_batch
FOR EACH ROW
BEGIN
    DECLARE v_mvt_type VARCHAR(30);
    DECLARE v_comment VARCHAR(255);

    IF OLD.current_quantity <> NEW.current_quantity THEN
        IF NEW.current_quantity < OLD.current_quantity THEN
            SET v_mvt_type = 'DISPENSING';
            SET v_comment = CONCAT('Stock deduction (-', OLD.current_quantity - NEW.current_quantity, ' units) from batch ', NEW.manufacturer_batch_number);
        ELSE
            SET v_mvt_type = 'POSITIVE_ADJUSTMENT';
            SET v_comment = CONCAT('Stock addition/adjustment (+', NEW.current_quantity - OLD.current_quantity, ' units) on batch ', NEW.manufacturer_batch_number);
        END IF;

        INSERT INTO stock_movement_log (
            batch_id, movement_type, quantity_before, quantity_after, quantity_delta, operator_name, audit_comment
        ) VALUES (
            NEW.batch_id,
            v_mvt_type,
            OLD.current_quantity,
            NEW.current_quantity,
            NEW.current_quantity - OLD.current_quantity,
            CURRENT_USER(),
            v_comment
        );
    ELSEIF OLD.batch_status <> 'QUARANTINED' AND NEW.batch_status = 'QUARANTINED' THEN
        INSERT INTO stock_movement_log (
            batch_id, movement_type, quantity_before, quantity_after, quantity_delta, operator_name, audit_comment
        ) VALUES (
            NEW.batch_id,
            'QUARANTINE_LOCK',
            OLD.current_quantity,
            NEW.current_quantity,
            0,
            CURRENT_USER(),
            CONCAT('Batch ', NEW.manufacturer_batch_number, ' placed under safety QUARANTINE')
        );
    END IF;
END$$

-- ============================================================================
-- 3. STORED PROCEDURES & ACID TRANSACTIONS
-- ============================================================================

-- PROCEDURE 1: Automated FEFO (First-Expired, First-Out) Prescription Dispensing
-- Allocates requested medication quantity across the earliest-expiring valid batches
-- inside an atomic transaction with row-level locking (SELECT ... FOR UPDATE).
CREATE PROCEDURE sp_dispense_medication_fefo(
    IN p_prescription_id INT,
    IN p_medication_id INT,
    IN p_requested_quantity INT,
    IN p_dosage_instructions VARCHAR(150)
)
BEGIN
    DECLARE v_total_valid_stock INT DEFAULT 0;
    DECLARE v_remaining_to_dispense INT;
    DECLARE v_batch_id INT;
    DECLARE v_batch_qty INT;
    DECLARE v_allocated_qty INT;
    DECLARE v_selling_price DECIMAL(10,2);
    DECLARE done INT DEFAULT FALSE;

    -- FEFO Cursor: Iterates over available, non-expired batches ordered by earliest expiration date
    DECLARE cur_fefo_batches CURSOR FOR
        SELECT batch_id, current_quantity
        FROM stock_batch
        WHERE medication_id = p_medication_id
          AND batch_status = 'AVAILABLE'
          AND expiration_date >= CURDATE()
          AND current_quantity > 0
        ORDER BY expiration_date ASC, batch_id ASC
        FOR UPDATE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Exception Handler: Full ROLLBACK if any constraint or trigger raises an error
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- 1. Validate positive quantity
    IF p_requested_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'VALIDATION ERROR: Requested quantity must be strictly greater than zero.';
    END IF;

    -- 2. Retrieve current unit selling price
    SELECT unit_selling_price INTO v_selling_price
    FROM medication
    WHERE medication_id = p_medication_id;

    -- 3. Verify total non-expired stock across all available batches
    SELECT COALESCE(SUM(current_quantity), 0) INTO v_total_valid_stock
    FROM stock_batch
    WHERE medication_id = p_medication_id
      AND batch_status = 'AVAILABLE'
      AND expiration_date >= CURDATE();

    IF v_total_valid_stock < p_requested_quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'TRANSACTION ABORTED (ROLLBACK): Insufficient non-expired stock across all batches for this medication.';
    END IF;

    -- 4. Multi-batch FEFO allocation loop
    SET v_remaining_to_dispense = p_requested_quantity;

    OPEN cur_fefo_batches;
    fefo_loop: LOOP
        FETCH cur_fefo_batches INTO v_batch_id, v_batch_qty;
        IF done OR v_remaining_to_dispense = 0 THEN
            LEAVE fefo_loop;
        END IF;

        IF v_batch_qty <= v_remaining_to_dispense THEN
            SET v_allocated_qty = v_batch_qty;
        ELSE
            SET v_allocated_qty = v_remaining_to_dispense;
        END IF;

        -- Inserting into dispensing_item automatically fires trg_before_insert_dispensing_item
        INSERT INTO dispensing_item (
            prescription_id, batch_id, dispensed_quantity, billed_unit_price, dosage_instructions
        ) VALUES (
            p_prescription_id, v_batch_id, v_allocated_qty, v_selling_price, p_dosage_instructions
        );

        SET v_remaining_to_dispense = v_remaining_to_dispense - v_allocated_qty;
    END LOOP;
    CLOSE cur_fefo_batches;

    COMMIT;
END$$

DELIMITER ;

-- ============================================================================
-- 4. ANALYTICAL VIEWS
-- ============================================================================

-- VIEW 1: Consolidated Medication Stock Status & Low-Stock Reorder Alerts
CREATE OR REPLACE VIEW vw_medication_stock_status AS
SELECT
    m.medication_id,
    m.national_drug_code,
    m.brand_name,
    m.active_ingredient,
    m.dosage_form,
    m.strength,
    c.category_name,
    m.unit_selling_price,
    m.reorder_threshold,
    m.requires_cold_chain,
    COALESCE(SUM(CASE WHEN b.batch_status = 'AVAILABLE' AND b.expiration_date >= CURDATE() THEN b.current_quantity ELSE 0 END), 0) AS valid_available_stock,
    COALESCE(SUM(CASE WHEN b.expiration_date < CURDATE() OR b.batch_status = 'EXPIRED' THEN b.current_quantity ELSE 0 END), 0) AS expired_locked_stock,
    COUNT(DISTINCT CASE WHEN b.batch_status = 'AVAILABLE' AND b.current_quantity > 0 THEN b.batch_id END) AS active_batch_count,
    MIN(CASE WHEN b.batch_status = 'AVAILABLE' AND b.current_quantity > 0 AND b.expiration_date >= CURDATE() THEN b.expiration_date END) AS earliest_expiration_date,
    CASE
        WHEN COALESCE(SUM(CASE WHEN b.batch_status = 'AVAILABLE' AND b.expiration_date >= CURDATE() THEN b.current_quantity ELSE 0 END), 0) = 0 THEN 'CRITICAL STOCKOUT'
        WHEN COALESCE(SUM(CASE WHEN b.batch_status = 'AVAILABLE' AND b.expiration_date >= CURDATE() THEN b.current_quantity ELSE 0 END), 0) < m.reorder_threshold THEN 'BELOW REORDER THRESHOLD'
        ELSE 'OPTIMAL STOCK'
    END AS replenishment_status
FROM medication m
INNER JOIN therapeutic_category c ON m.category_id = c.category_id
LEFT JOIN stock_batch b ON m.medication_id = b.medication_id
GROUP BY
    m.medication_id, m.national_drug_code, m.brand_name, m.active_ingredient,
    m.dosage_form, m.strength, c.category_name,
    m.unit_selling_price, m.reorder_threshold, m.requires_cold_chain;

-- VIEW 2: FEFO Batch Expiration Risk Radar
CREATE OR REPLACE VIEW vw_batch_expiration_radar AS
SELECT
    b.batch_id,
    b.manufacturer_batch_number,
    m.brand_name,
    m.active_ingredient,
    c.category_name,
    s.company_name AS supplier_name,
    z.zone_name AS storage_zone_name,
    b.current_quantity,
    b.unit_purchase_cost,
    ROUND(b.current_quantity * b.unit_purchase_cost, 2) AS stock_value_at_risk_mad,
    b.expiration_date,
    DATEDIFF(b.expiration_date, CURDATE()) AS days_until_expiration,
    b.batch_status,
    CASE
        WHEN b.expiration_date < CURDATE() OR b.batch_status = 'EXPIRED' THEN '1. EXPIRED (DO NOT DISPENSE)'
        WHEN DATEDIFF(b.expiration_date, CURDATE()) <= 30 THEN '2. CRITICAL (< 30 DAYS)'
        WHEN DATEDIFF(b.expiration_date, CURDATE()) <= 90 THEN '3. WATCHLIST (31-90 DAYS)'
        ELSE '4. COMPLIANT (> 90 DAYS)'
    END AS expiration_risk_tier
FROM stock_batch b
INNER JOIN medication m ON b.medication_id = m.medication_id
INNER JOIN therapeutic_category c ON m.category_id = c.category_id
INNER JOIN supplier s ON b.supplier_id = s.supplier_id
INNER JOIN storage_zone z ON b.zone_id = z.zone_id
WHERE b.current_quantity > 0;
