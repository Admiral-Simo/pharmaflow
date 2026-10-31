"""
Main Streamlit User Interface — PharmaFlow DB (Master in Data & AI - INPT)
Style : Classic / Vintage Apothecary Ledger (Zero Emojis)
Run   : streamlit run app/main.py
"""

import datetime
import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from database import DatabaseManager

# Page Configuration (No emojis)
st.set_page_config(
    page_title="PHARMAFLOW DB - Apothecary Ledger & FEFO Batch Management",
    layout="wide",
    initial_sidebar_state="expanded",
)

# Classic Color Palette for Plotly Charts (Apothecary Green, Ochre, Burgundy, Slate)
RETRO_PALETTE = ["#1B4332", "#8C5A2B", "#7B2D26", "#2C4251", "#5C6B5E", "#A47E3B"]

# Classic / Retro CSS Stylesheet (Parchment ledger paper, Serif & Monospace typography, sharp borders)
st.markdown(
    """
    <style>
    .stApp {
        background-color: #F4EFE6;
        color: #1F2421;
        font-family: "Georgia", "Times New Roman", serif;
    }

    section[data-testid="stSidebar"] {
        background-color: #EAE2D3;
        border-right: 2px solid #2C3531;
    }

    h1 {
        font-family: "Georgia", "Garamond", serif !important;
        color: #1B4332 !important;
        text-transform: uppercase;
        letter-spacing: 1.5px;
        border-bottom: 3px double #1B4332;
        padding-bottom: 10px;
        margin-bottom: 8px;
        font-weight: 700 !important;
    }

    h2, h3, h4 {
        font-family: "Georgia", "Garamond", serif !important;
        color: #1F2421 !important;
        letter-spacing: 0.6px;
        border-bottom: 1px solid #B8B0A0;
        padding-bottom: 4px;
    }

    div[data-testid="stMetric"] {
        background-color: #EAE2D3;
        border: 1px solid #2C3531;
        border-top: 4px solid #1B4332;
        border-radius: 0px;
        padding: 14px 16px;
        box-shadow: 3px 3px 0px #C8BFA8;
    }

    div[data-testid="stMetricLabel"] {
        font-family: "Courier New", Courier, monospace !important;
        font-size: 0.82rem !important;
        text-transform: uppercase;
        letter-spacing: 0.8px;
        color: #3D4440 !important;
        font-weight: bold;
    }

    div[data-testid="stMetricValue"] {
        font-family: "Courier New", Courier, monospace !important;
        color: #1B4332 !important;
        font-weight: 700 !important;
    }

    .stButton > button, div[data-testid="stFormSubmitButton"] > button {
        background-color: #1B4332 !important;
        color: #F4EFE6 !important;
        border: 1px solid #0F291E !important;
        border-radius: 0px !important;
        font-family: "Courier New", Courier, monospace !important;
        text-transform: uppercase;
        letter-spacing: 1px;
        font-weight: bold;
        padding: 0.45rem 1.1rem;
        box-shadow: 2px 2px 0px #2C3531;
        transition: all 0.1s ease-in-out;
    }

    .stButton > button:hover, div[data-testid="stFormSubmitButton"] > button:hover {
        background-color: #2D6A4F !important;
        color: #FFFFFF !important;
    }

    div[data-testid="stForm"] {
        background-color: #EAE2D3;
        border: 1px solid #2C3531;
        border-radius: 0px;
        padding: 18px;
        box-shadow: 3px 3px 0px #C8BFA8;
    }

    button[data-baseweb="tab"] {
        font-family: "Courier New", Courier, monospace !important;
        text-transform: uppercase;
        font-weight: bold;
        letter-spacing: 0.7px;
        border-radius: 0px !important;
    }

    input, select, textarea, div[data-baseweb="select"] > div {
        border-radius: 0px !important;
        border-color: #6C665A !important;
        background-color: #FAF7F0 !important;
    }

    .block-container {
        padding-top: 1.5rem;
        padding-bottom: 2rem;
    }
    </style>
    """,
    unsafe_allow_html=True,
)


def apply_classic_chart_layout(fig: go.Figure, title: str) -> go.Figure:
    """Applies a classic ledger styling (parchment background & serif/monospace fonts) to Plotly figures."""
    fig.update_layout(
        title={
            "text": title.upper(),
            "font": {"family": "Georgia, serif", "size": 14, "color": "#1F2421"},
        },
        paper_bgcolor="#EAE2D3",
        plot_bgcolor="#FAF7F0",
        font={"family": "Courier New, monospace", "color": "#1F2421", "size": 12},
        margin={"l": 35, "r": 25, "t": 50, "b": 35},
        legend={
            "bgcolor": "#F4EFE6",
            "bordercolor": "#2C3531",
            "borderwidth": 1,
        },
    )
    fig.update_xaxes(showgrid=True, gridcolor="#D6CFC0", linecolor="#2C3531", mirror=True)
    fig.update_yaxes(showgrid=True, gridcolor="#D6CFC0", linecolor="#2C3531", mirror=True)
    return fig


def init_db_sidebar() -> DatabaseManager:
    """Renders the MySQL connection configuration panel in the sidebar."""
    st.sidebar.markdown("### PHARMAFLOW DB")
    st.sidebar.caption("NATIONAL INSTITUTE OF POSTS AND TELECOMMUNICATIONS (INPT) — MASTER IN DATA & AI")
    st.sidebar.markdown("---")
    st.sidebar.markdown("#### MYSQL SERVER CONFIGURATION")

    host = st.sidebar.text_input("MySQL Host", value="localhost")
    port = st.sidebar.number_input("TCP Port", value=3306, step=1)
    user = st.sidebar.text_input("Database User", value="root")
    password = st.sidebar.text_input("Password", value="", type="password")
    database = st.sidebar.text_input("Database Schema", value="pharmaflow_db")

    db = DatabaseManager(
        host=host, port=int(port), user=user, password=password, database=database
    )
    ok, msg = db.test_connection()
    if ok:
        st.sidebar.success(f"[STATUS: CONNECTED] {msg}")
    else:
        st.sidebar.error(f"[STATUS: DISCONNECTED] {msg}")
        st.stop()
    return db


def render_dashboard_tab(db: DatabaseManager) -> None:
    """Section I: Executive Dashboard, Real-Time KPIs, and Analytical Charts."""
    st.subheader("SECTION I. EXECUTIVE DASHBOARD & OPERATIONAL KPIS")

    # 1. Fetch real-time KPIs from MySQL
    kpi_stock = db.fetch_one(
        """
        SELECT
            COALESCE(SUM(CASE WHEN batch_status = 'AVAILABLE' AND expiration_date >= CURDATE()
                              THEN current_quantity * unit_purchase_cost ELSE 0 END), 0) AS valid_stock_value,
            COUNT(CASE WHEN batch_status = 'AVAILABLE' AND expiration_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY)
                       AND current_quantity > 0 THEN 1 END) AS critical_batches_30d,
            COUNT(CASE WHEN (expiration_date < CURDATE() OR batch_status = 'EXPIRED') AND current_quantity > 0
                       THEN 1 END) AS expired_batches
        FROM stock_batch;
        """
    )

    kpi_alert = db.fetch_one(
        """
        SELECT COUNT(*) AS low_stock_meds
        FROM vw_medication_stock_status
        WHERE replenishment_status <> 'OPTIMAL STOCK';
        """
    )

    kpi_revenue = db.fetch_one(
        """
        SELECT COALESCE(SUM(dispensed_quantity * billed_unit_price), 0) AS total_revenue
        FROM dispensing_item;
        """
    )

    c1, c2, c3, c4, c5 = st.columns(5)
    c1.metric(
        "VALID INVENTORY VALUE",
        f"{float(kpi_stock['valid_stock_value']):,.2f} MAD",
    )
    c2.metric(
        "TOTAL DISPENSED REVENUE",
        f"{float(kpi_revenue['total_revenue']):,.2f} MAD",
    )
    c3.metric(
        "LOW STOCK ALERTS",
        f"{int(kpi_alert['low_stock_meds'])}",
        delta="REORDER NEEDED" if int(kpi_alert["low_stock_meds"]) > 0 else "OPTIMAL",
        delta_color="inverse",
    )
    c4.metric(
        "CRITICAL BATCHES (< 30D)",
        f"{int(kpi_stock['critical_batches_30d'])} BATCHES",
        delta="FEFO PRIORITY",
        delta_color="off",
    )
    c5.metric(
        "LOCKED EXPIRED BATCHES",
        f"{int(kpi_stock['expired_batches'])} BATCH(ES)",
        delta="BLOCKED BY TRIGGER",
        delta_color="inverse",
    )

    st.markdown("---")

    # 2. Interactive Plotly Charts
    col_chart1, col_chart2 = st.columns(2)

    with col_chart1:
        df_pareto = db.fetch_dataframe(
            """
            WITH cte_perf AS (
                SELECT
                    m.brand_name,
                    c.category_name,
                    ROUND(SUM(di.dispensed_quantity * di.billed_unit_price), 2) AS revenue_mad,
                    ROUND(SUM(di.dispensed_quantity * (di.billed_unit_price - b.unit_purchase_cost)), 2) AS gross_margin_mad
                FROM dispensing_item di
                INNER JOIN stock_batch b ON di.batch_id = b.batch_id
                INNER JOIN medication m ON b.medication_id = m.medication_id
                INNER JOIN therapeutic_category c ON m.category_id = c.category_id
                GROUP BY m.medication_id, m.brand_name, c.category_name
            )
            SELECT
                DENSE_RANK() OVER (ORDER BY revenue_mad DESC) AS rank_num,
                brand_name,
                category_name,
                revenue_mad,
                gross_margin_mad,
                ROUND(100.0 * SUM(revenue_mad) OVER (ORDER BY revenue_mad DESC) / SUM(revenue_mad) OVER (), 1) AS cumulative_pct
            FROM cte_perf
            ORDER BY rank_num;
            """
        )
        if not df_pareto.empty:
            fig_rev = px.bar(
                df_pareto,
                x="brand_name",
                y=["revenue_mad", "gross_margin_mad"],
                barmode="group",
                color_discrete_sequence=["#1B4332", "#8C5A2B"],
                labels={
                    "value": "Amount (MAD)",
                    "brand_name": "Medication",
                    "variable": "Metric",
                },
            )
            fig_rev = apply_classic_chart_layout(
                fig_rev, "Best-Selling Products: Revenue & Gross Margin (CTE + Window)"
            )
            st.plotly_chart(fig_rev, use_container_width=True)

    with col_chart2:
        df_risk = db.fetch_dataframe(
            """
            SELECT expiration_risk_tier, SUM(stock_value_at_risk_mad) AS value_mad, COUNT(*) AS batch_count
            FROM vw_batch_expiration_radar
            GROUP BY expiration_risk_tier
            ORDER BY expiration_risk_tier;
            """
        )
        if not df_risk.empty:
            fig_risk = px.bar(
                df_risk,
                x="expiration_risk_tier",
                y="value_mad",
                text="batch_count",
                color="expiration_risk_tier",
                color_discrete_sequence=RETRO_PALETTE,
                labels={
                    "expiration_risk_tier": "FEFO Expiration Risk Tier",
                    "value_mad": "Inventory Value (MAD)",
                },
            )
            fig_risk = apply_classic_chart_layout(
                fig_risk, "Inventory Capital Exposure by Expiration Horizon (MAD)"
            )
            fig_risk.update_layout(showlegend=False)
            st.plotly_chart(fig_risk, use_container_width=True)

    # 3. Consolidated Stock Status View
    st.subheader("CONSOLIDATED MEDICATION INVENTORY & LOW STOCK ALERTS (VIEW: vw_medication_stock_status)")
    df_status = db.fetch_dataframe(
        "SELECT * FROM vw_medication_stock_status ORDER BY valid_available_stock ASC;"
    )
    st.dataframe(df_status, use_container_width=True, hide_index=True)


def render_batches_and_crud_tab(db: DatabaseManager) -> None:
    """Section II: Batch Inventory Management, Expiration Radar, and Supplier Receipts."""
    st.subheader("SECTION II. INVENTORY MANAGEMENT, EXPIRATION RADAR & BATCH RECEIPTS")

    col_filter1, col_filter2 = st.columns([2, 2])
    with col_filter1:
        risk_filter = st.selectbox(
            "Filter by FEFO Expiration Risk Tier:",
            [
                "ALL BATCHES",
                "1. EXPIRED (DO NOT DISPENSE)",
                "2. CRITICAL (< 30 DAYS)",
                "3. WATCHLIST (31-90 DAYS)",
                "4. COMPLIANT (> 90 DAYS)",
            ],
        )
    with col_filter2:
        search_term = st.text_input("Search by Medication Brand Name or Batch Number:", "")

    sql_radar = "SELECT * FROM vw_batch_expiration_radar WHERE 1=1"
    params = []
    if risk_filter != "ALL BATCHES":
        sql_radar += " AND expiration_risk_tier = %s"
        params.append(risk_filter)
    if search_term.strip():
        sql_radar += " AND (brand_name LIKE %s OR manufacturer_batch_number LIKE %s)"
        params.extend([f"%{search_term.strip()}%", f"%{search_term.strip()}%"])
    sql_radar += " ORDER BY expiration_date ASC;"

    df_batches = db.fetch_dataframe(sql_radar, tuple(params))
    st.dataframe(df_batches, use_container_width=True, hide_index=True)

    st.markdown("---")
    col_form_add, col_form_upd = st.columns(2)

    # INSERT Form: Receive a new inventory batch (Tests Cold-Chain Trigger)
    with col_form_add:
        st.markdown("#### [INSERT OPERATION] RECEIVE NEW SUPPLIER STOCK BATCH")
        df_meds = db.fetch_dataframe(
            "SELECT medication_id, brand_name, strength, requires_cold_chain FROM medication ORDER BY brand_name;"
        )
        df_suppliers = db.fetch_dataframe(
            "SELECT supplier_id, company_name FROM supplier WHERE is_active = TRUE ORDER BY company_name;"
        )
        df_zones = db.fetch_dataframe(
            "SELECT zone_id, zone_code, zone_name, is_refrigerated FROM storage_zone ORDER BY zone_code;"
        )

        with st.form("form_receive_batch"):
            batch_number = st.text_input(
                "Manufacturer Batch Number",
                placeholder="e.g. BATCH-2026-X99",
                help="Unique lot identifier printed by the manufacturer.",
            )
            med_choice = st.selectbox(
                "Product / Medication",
                options=df_meds.to_dict("records"),
                format_func=lambda r: f"{r['brand_name']} ({r['strength']}) {'[COLD-CHAIN REQUIRED]' if r['requires_cold_chain'] else '[AMBIENT]'}",
            )
            supplier_choice = st.selectbox(
                "Approved Supplier",
                options=df_suppliers.to_dict("records"),
                format_func=lambda r: r["company_name"],
            )
            zone_choice = st.selectbox(
                "Target Storage Zone",
                options=df_zones.to_dict("records"),
                format_func=lambda r: f"{r['zone_code']} - {r['zone_name']} {'[REFRIGERATED 2-8C]' if r['is_refrigerated'] else '[AMBIENT 15-25C]'}",
            )
            c_d1, c_d2 = st.columns(2)
            mfg_date = c_d1.date_input(
                "Manufacturing Date", value=datetime.date.today() - datetime.timedelta(days=30)
            )
            exp_date = c_d2.date_input(
                "Expiration Date", value=datetime.date.today() + datetime.timedelta(days=365)
            )
            c_q1, c_q2 = st.columns(2)
            received_qty = c_q1.number_input("Received Quantity (Units)", min_value=1, max_value=5000, value=50)
            purchase_cost = c_q2.number_input("Unit Purchase Cost (MAD)", min_value=1.0, value=45.0, step=0.5)

            submitted_batch = st.form_submit_button("Record Batch Receipt in MySQL")
            if submitted_batch:
                if not batch_number.strip():
                    st.error("[VALIDATION ERROR] Please provide a valid manufacturer batch number.")
                else:
                    ok, msg, _ = db.execute_dml(
                        """
                        INSERT INTO stock_batch (
                            manufacturer_batch_number, medication_id, supplier_id, zone_id,
                            manufacturing_date, expiration_date, received_date,
                            initial_quantity, current_quantity, unit_purchase_cost
                        ) VALUES (%s, %s, %s, %s, %s, %s, CURDATE(), %s, %s, %s);
                        """,
                        (
                            batch_number.strip(),
                            med_choice["medication_id"],
                            supplier_choice["supplier_id"],
                            zone_choice["zone_id"],
                            mfg_date,
                            exp_date,
                            int(received_qty),
                            int(received_qty),
                            float(purchase_cost),
                        ),
                    )
                    if ok:
                        st.success(f"[SUCCESS] {msg} (Audit entry automatically written to stock_movement_log)")
                        st.rerun()
                    else:
                        st.error(f"[REJECTED BY MYSQL TRIGGER] {msg}")

    # UPDATE Form: Stock Adjustment or Quarantine Lock
    with col_form_upd:
        st.markdown("#### [UPDATE OPERATION] INVENTORY ADJUSTMENT / QUARANTINE LOCK")
        df_all_batches = db.fetch_dataframe(
            """
            SELECT b.batch_id, b.manufacturer_batch_number, m.brand_name, b.current_quantity, b.batch_status
            FROM stock_batch b
            INNER JOIN medication m ON b.medication_id = m.medication_id
            ORDER BY b.batch_id DESC;
            """
        )
        with st.form("form_update_batch"):
            batch_sel = st.selectbox(
                "Select Batch Record",
                options=df_all_batches.to_dict("records"),
                format_func=lambda r: f"ID #{r['batch_id']} | {r['manufacturer_batch_number']} - {r['brand_name']} (Qty: {r['current_quantity']} | Status: {r['batch_status']})",
            )
            new_status = st.selectbox(
                "Updated Batch Status",
                options=["AVAILABLE", "QUARANTINED", "EXPIRED"],
            )
            new_qty = st.number_input(
                "Updated Physical Stock Quantity",
                min_value=0,
                max_value=5000,
                value=int(batch_sel["current_quantity"]) if batch_sel else 0,
            )
            btn_upd = st.form_submit_button("Commit Batch Update")
            if btn_upd and batch_sel:
                ok, msg, _ = db.execute_dml(
                    "UPDATE stock_batch SET batch_status = %s, current_quantity = %s WHERE batch_id = %s;",
                    (new_status, int(new_qty), int(batch_sel["batch_id"])),
                )
                if ok:
                    st.success(f"[SUCCESS] {msg} — Stock movement recorded in audit log.")
                    st.rerun()
                else:
                    st.error(f"[ERROR] {msg}")


def render_dispensing_and_triggers_tab(db: DatabaseManager) -> None:
    """Section III: Transactional FEFO Dispensing and Safety Trigger Verification."""
    st.subheader("SECTION III. PRESCRIPTION DISPENSING (ACID TRANSACTION & FEFO ALLOCATION)")

    col_left, col_right = st.columns([3, 2])

    with col_left:
        st.markdown("#### 1. FEFO PRESCRIPTION DISPENSING ORDER (PROCEDURE: sp_dispense_medication_fefo)")
        st.info(
            "TECHNICAL NOTE: The stored procedure locks active batches (SELECT ... FOR UPDATE), "
            "allocates stock from the earliest-expiring valid batch first (FEFO), splits allocation across "
            "multiple batches if required, and executes a full ROLLBACK if total non-expired stock is insufficient."
        )

        df_patients = db.fetch_dataframe(
            "SELECT patient_id, national_id, last_name, first_name, insurance_provider FROM patient;"
        )
        df_physicians = db.fetch_dataframe(
            "SELECT physician_id, full_name, specialty FROM physician;"
        )
        df_meds_stock = db.fetch_dataframe(
            "SELECT medication_id, brand_name, strength, valid_available_stock FROM vw_medication_stock_status;"
        )

        with st.form("form_fefo_dispense"):
            rx_ref = st.text_input(
                "Prescription Reference",
                value=f"RX-2026-{datetime.datetime.now().strftime('%H%M%S')}",
            )
            pat = st.selectbox(
                "Patient",
                options=df_patients.to_dict("records"),
                format_func=lambda p: f"{p['last_name']} {p['first_name']} [ID: {p['national_id']} | Insurance: {p['insurance_provider']}]",
            )
            doc = st.selectbox(
                "Prescribing Physician",
                options=df_physicians.to_dict("records"),
                format_func=lambda d: f"{d['full_name']} ({d['specialty']})",
            )
            med = st.selectbox(
                "Prescribed Medication",
                options=df_meds_stock.to_dict("records"),
                format_func=lambda m: f"{m['brand_name']} {m['strength']} [Valid Available Stock: {m['valid_available_stock']} packs]",
            )
            req_qty = st.number_input("Quantity to Dispense (Packs)", min_value=1, max_value=500, value=5)
            dosage = st.text_input("Dosage Instructions", value="1 tablet morning and evening for 10 days")
            notes = st.text_input("Clinical Notes", value="Standard FEFO-compliant dispensing")

            btn_fefo = st.form_submit_button("Execute FEFO Dispensing Transaction")
            if btn_fefo:
                ok, msg = db.dispense_prescription_fefo(
                    prescription_ref=rx_ref.strip(),
                    patient_id=int(pat["patient_id"]),
                    physician_id=int(doc["physician_id"]),
                    medication_id=int(med["medication_id"]),
                    quantity=int(req_qty),
                    dosage_instructions=dosage,
                    clinical_notes=notes,
                )
                if ok:
                    st.success(f"[TRANSACTION COMMITTED] {msg}")
                else:
                    st.error(f"[TRANSACTION ROLLED BACK] {msg}")

    with col_right:
        st.markdown("#### 2. SAFETY TRIGGER TESTBENCH (ANTI-EXPIRATION SHIELD)")
        st.warning(
            "TEST PROTOCOL: Select an EXPIRED batch (e.g. BATCH-AML-OLD) or QUARANTINED batch "
            "(e.g. BATCH-MOP-QUAR) below and attempt a direct insertion into dispensing_item. "
            "The MySQL trigger trg_before_insert_dispensing_item will intercept and block the operation via SIGNAL SQLSTATE '45000'."
        )
        df_bad_batches = db.fetch_dataframe(
            """
            SELECT b.batch_id, b.manufacturer_batch_number, m.brand_name, b.batch_status, b.expiration_date, b.current_quantity
            FROM stock_batch b
            INNER JOIN medication m ON b.medication_id = m.medication_id
            WHERE b.batch_status IN ('EXPIRED', 'QUARANTINED') OR b.expiration_date < CURDATE();
            """
        )
        with st.form("form_test_trigger"):
            bad_batch = st.selectbox(
                "Non-Compliant Batch (Expired or Quarantined)",
                options=df_bad_batches.to_dict("records"),
                format_func=lambda b: f"{b['manufacturer_batch_number']} ({b['brand_name']}) — Status: {b['batch_status']} | Exp: {b['expiration_date']}",
            )
            btn_trigger = st.form_submit_button("Simulate Unauthorized Dispensing")
            if btn_trigger and bad_batch:
                ok, msg, _ = db.execute_dml(
                    """
                    INSERT INTO dispensing_item (prescription_id, batch_id, dispensed_quantity, billed_unit_price, dosage_instructions)
                    VALUES (1, %s, 1, 50.00, 'Trigger safety violation test');
                    """,
                    (int(bad_batch["batch_id"]),),
                )
                if not ok:
                    st.error(f"[MYSQL TRIGGER SHIELD ACTIVATED] {msg}")
                else:
                    st.success(msg)

    st.markdown("---")
    st.subheader("HISTORICAL DISPENSING LEDGER (6-TABLE RELATIONAL JOIN)")
    df_hist_disp = db.fetch_dataframe(
        """
        SELECT
            rx.prescription_reference,
            rx.dispensed_at,
            CONCAT(p.last_name, ' ', p.first_name) AS patient_name,
            doc.full_name AS prescribing_physician,
            m.brand_name AS medication_name,
            b.manufacturer_batch_number AS allocated_fefo_batch,
            b.expiration_date AS batch_expiration,
            di.dispensed_quantity,
            di.billed_unit_price,
            ROUND(di.dispensed_quantity * di.billed_unit_price, 2) AS line_total_mad
        FROM dispensing_item di
        INNER JOIN prescription rx ON di.prescription_id = rx.prescription_id
        INNER JOIN patient p ON rx.patient_id = p.patient_id
        INNER JOIN physician doc ON rx.physician_id = doc.physician_id
        INNER JOIN stock_batch b ON di.batch_id = b.batch_id
        INNER JOIN medication m ON b.medication_id = m.medication_id
        ORDER BY rx.dispensed_at DESC, rx.prescription_id DESC;
        """
    )
    st.dataframe(df_hist_disp, use_container_width=True, hide_index=True)


def render_audit_and_explain_tab(db: DatabaseManager) -> None:
    """Section IV: Immutable Stock Movement Audit Ledger and EXPLAIN Execution Plans."""
    st.subheader("SECTION IV. STOCK MOVEMENTS AUDIT LEDGER & EXPLAIN QUERY OPTIMIZATION")

    df_audit = db.fetch_dataframe(
        """
        SELECT
            sml.movement_id,
            sml.movement_timestamp,
            b.manufacturer_batch_number,
            m.brand_name AS medication_name,
            sml.movement_type,
            sml.quantity_before,
            sml.quantity_after,
            sml.quantity_delta,
            sml.operator_name,
            sml.audit_comment
        FROM stock_movement_log sml
        INNER JOIN stock_batch b ON sml.batch_id = b.batch_id
        INNER JOIN medication m ON b.medication_id = m.medication_id
        ORDER BY sml.movement_id DESC;
        """
    )
    st.dataframe(df_audit, use_container_width=True, hide_index=True)

    st.markdown("---")
    st.subheader("MYSQL EXECUTION PLAN VERIFICATION (EXPLAIN COMMAND — STEP 9)")

    col_exp1, col_exp2 = st.columns(2)
    with col_exp1:
        st.markdown("**1. EXPLAIN Plan for FEFO Batch Lookup (Index: idx_batch_fefo_lookup)**")
        df_exp1 = db.fetch_dataframe(
            """
            EXPLAIN
            SELECT batch_id, manufacturer_batch_number, current_quantity, expiration_date
            FROM stock_batch
            WHERE medication_id = 1
              AND batch_status = 'AVAILABLE'
              AND expiration_date >= CURDATE()
            ORDER BY expiration_date ASC;
            """
        )
        st.dataframe(df_exp1, use_container_width=True, hide_index=True)

    with col_exp2:
        st.markdown("**2. EXPLAIN Plan for Stock Movements Ledger (Index: idx_movement_type_date)**")
        df_exp2 = db.fetch_dataframe(
            """
            EXPLAIN
            SELECT movement_id, batch_id, movement_type, quantity_delta, movement_timestamp
            FROM stock_movement_log
            WHERE movement_type = 'DISPENSING'
            ORDER BY movement_timestamp DESC;
            """
        )
        st.dataframe(df_exp2, use_container_width=True, hide_index=True)


def main() -> None:
    db = init_db_sidebar()
    st.title("PHARMAFLOW — APOTHECARY LEDGER & FEFO BATCH MANAGEMENT")
    st.caption(
        "RELATIONAL DATABASE ARCHITECTURE IN MYSQL 8.0+ (3NF SCHEMA, SAFETY TRIGGERS, ACID STORED PROCEDURES, CTES, WINDOW FUNCTIONS & B-TREE INDEXING)"
    )

    tab1, tab2, tab3, tab4 = st.tabs(
        [
            "I. EXECUTIVE DASHBOARD & ANALYTICS",
            "II. INVENTORY BATCHES & RECEIPTS",
            "III. FEFO DISPENSING & TRIGGERS",
            "IV. STOCK MOVEMENTS & EXPLAIN",
        ]
    )

    with tab1:
        render_dashboard_tab(db)
    with tab2:
        render_batches_and_crud_tab(db)
    with tab3:
        render_dispensing_and_triggers_tab(db)
    with tab4:
        render_audit_and_explain_tab(db)


if __name__ == "__main__":
    main()
