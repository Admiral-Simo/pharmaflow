# PharmaFlow DB — Hospital Pharmacy, FEFO Batch Tracking & Prescription Dispensing System

## 1. Project Overview & Business Context
**PharmaFlow DB** is a relational database and inventory management application built with **MySQL 8.0+** and **Python (Streamlit)**[cite: 1, 2]. In pharmaceutical supply chains, products cannot be tracked as a single aggregate quantity per medication: they arrive from multiple contracted suppliers as physical **stock batches (`stock_batch`)** with strict manufacturing dates, expiration dates, and cold-chain storage requirements.

### Core Business Rules Enforced by MySQL
1. **3NF Relational Integrity & M:N Junctions:** Separates master medication definitions (`medication`) from physical lots (`stock_batch`), supplier pricing contracts (`supplier_catalog`), and prescription line items (`dispensing_item`).
2. **Cold-Chain Storage Enforcement (`trg_before_insert_batch_validation`):** Thermolabile medications (`requires_cold_chain = TRUE`, such as Insulins and Vaccines) are rejected via `SIGNAL SQLSTATE '45000'` if assigned to a non-refrigerated storage zone[cite: 1].
3. **Anti-Expiration & Quarantine Shield (`trg_before_insert_dispensing_item`):** Strictly blocks dispensing from any batch that is expired (`expiration_date < CURDATE()`) or locked in `'QUARANTINED'` status[cite: 1].
4. **Automated FEFO Transaction (`sp_dispense_medication_fefo`):** Locks available batches (`SELECT ... FOR UPDATE`) and automatically allocates requested prescription quantities starting from the earliest-expiring non-expired batch (**First-Expired, First-Out**), rolling back atomically if total valid stock is insufficient.
5. **Immutable Audit Ledger (`trg_after_insert_batch_audit` & `trg_after_update_batch_audit`):** Every initial receipt, prescription deduction, manual stock adjustment, or quarantine lock is automatically recorded in `stock_movement_log`[cite: 1].

---

## 2. Project Structure
```text
project/
├── .streamlit/
│   └── config.toml                     # Classic parchment ledger theme configuration
├── database/
│   ├── 01_schema_and_triggers.sql      # DDL: 11 tables (3NF), constraints, 5 triggers, FEFO procedure, 2 views
│   ├── 02_sample_data.sql              # DML: Realistic dataset + edge cases for triggers and FEFO
│   └── 03_queries_and_optimization.sql # Analytical SQL (Joins, Group By, Subquery, CTE, Window) + Indexes & EXPLAIN
├── app/
│   ├── database.py                     # MySQL 8.0+ connection & parameterized query/transaction manager
│   └── main.py                         # Classic apothecary ledger Streamlit interface (Zero emojis)
├── requirements.txt                    # Python dependencies
└── README.md                           # Documentation & execution guide
