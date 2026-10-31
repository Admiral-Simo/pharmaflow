"""
Interface Utilisateur Principale Streamlit — PharmaFlow BDR (Master Data & IA - INPT)
Style : Classique / Registre Officinal Retro (Sans Emojis)
Execution : streamlit run app/main.py
"""

import datetime
import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from database import DatabaseManager

# Configuration de la page Streamlit (Sans icône emoji)
st.set_page_config(
    page_title="PHARMAFLOW BDR - Registre Officinal & Gestion des Lots",
    layout="wide",
    initial_sidebar_state="expanded",
)

# Palette Classique pour les graphiques Plotly (Vert Officinal, Ocre, Bordeaux, Ardoise)
RETRO_PALETTE = ["#1B4332", "#8C5A2B", "#7B2D26", "#2C4251", "#5C6B5E", "#A47E3B"]

# Feuille de style CSS Classique / Retro (Papier registre, typographie Serif & Monospace, bordures franches)
st.markdown(
    """
    <style>
    /* Fond général papier registre et typographie classique */
    .stApp {
        background-color: #F4EFE6;
        color: #1F2421;
        font-family: "Georgia", "Times New Roman", serif;
    }

    /* Barre latérale style dossier d'archives */
    section[data-testid="stSidebar"] {
        background-color: #EAE2D3;
        border-right: 2px solid #2C3531;
    }

    /* En-têtes typographiques classiques avec filets */
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

    /* Cartes d'indicateurs (KPI) style étiquettes de registre comptable */
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

    /* Boutons classiques à angles droits et ombre franche */
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

    /* Conteneurs de formulaires encadrés */
    div[data-testid="stForm"] {
        background-color: #EAE2D3;
        border: 1px solid #2C3531;
        border-radius: 0px;
        padding: 18px;
        box-shadow: 3px 3px 0px #C8BFA8;
    }

    /* Onglets de navigation style intercalaires d'index */
    button[data-baseweb="tab"] {
        font-family: "Courier New", Courier, monospace !important;
        text-transform: uppercase;
        font-weight: bold;
        letter-spacing: 0.7px;
        border-radius: 0px !important;
    }

    /* Champs de saisie à angles droits */
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
    """Applique une mise en forme sobre et classique (papier registre & police serif) aux graphiques Plotly."""
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
    """Affiche les paramètres de connexion MySQL dans la barre latérale."""
    st.sidebar.markdown("### PHARMAFLOW BDR")
    st.sidebar.caption("INSTITUT NATIONAL DES POSTES ET TELECOMMUNICATIONS (INPT) — MASTER DATA & IA")
    st.sidebar.markdown("---")
    st.sidebar.markdown("#### CONFIGURATION SERVEUR MYSQL")

    host = st.sidebar.text_input("Hote MySQL", value="localhost")
    port = st.sidebar.number_input("Port TCP", value=3306, step=1)
    user = st.sidebar.text_input("Utilisateur", value="root")
    password = st.sidebar.text_input("Mot de passe", value="", type="password")
    database = st.sidebar.text_input("Schema de base de donnees", value="pharmaflow_bdr")

    db = DatabaseManager(
        host=host, port=int(port), user=user, password=password, database=database
    )
    ok, msg = db.test_connection()
    if ok:
        st.sidebar.success(f"[STATUT : CONNECTE] {msg}")
    else:
        st.sidebar.error(f"[STATUT : ECHEC] {msg}")
        st.stop()
    return db


def render_dashboard_tab(db: DatabaseManager) -> None:
    """Section I : Tableau de bord exécutif, KPIs temps réel et graphiques classiques."""
    st.subheader("SECTION I. TABLEAU DE BORD & INDICATEURS D'EXPLOITATION")

    # 1. Récupération des KPIs depuis MySQL
    kpi_stock = db.fetch_one(
        """
        SELECT
            COALESCE(SUM(CASE WHEN statut_lot = 'DISPONIBLE' AND date_peremption >= CURDATE()
                              THEN quantite_actuelle * prix_achat_unitaire ELSE 0 END), 0) AS valeur_stock_valide,
            COUNT(CASE WHEN statut_lot = 'DISPONIBLE' AND date_peremption BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY)
                       AND quantite_actuelle > 0 THEN 1 END) AS lots_critiques_30j,
            COUNT(CASE WHEN (date_peremption < CURDATE() OR statut_lot = 'PERIME') AND quantite_actuelle > 0
                       THEN 1 END) AS lots_perimes
        FROM lot_stock;
        """
    )

    kpi_alerte = db.fetch_one(
        """
        SELECT COUNT(*) AS nb_meds_alerte
        FROM vw_etat_stock_medicaments
        WHERE statut_approvisionnement <> 'STOCK NORMAL';
        """
    )

    kpi_ca = db.fetch_one(
        """
        SELECT COALESCE(SUM(quantite_delivree * prix_unitaire_facture), 0) AS ca_total
        FROM ligne_dispensation;
        """
    )

    c1, c2, c3, c4, c5 = st.columns(5)
    c1.metric(
        "VALEUR STOCK VALIDE",
        f"{float(kpi_stock['valeur_stock_valide']):,.2f} MAD",
    )
    c2.metric(
        "CHIFFRE D'AFFAIRES",
        f"{float(kpi_ca['ca_total']):,.2f} MAD",
    )
    c3.metric(
        "REFERENCES SOUS SEUIL",
        f"{int(kpi_alerte['nb_meds_alerte'])}",
        delta="REAPPRO. REQUIS" if int(kpi_alerte["nb_meds_alerte"]) > 0 else "CONFORME",
        delta_color="inverse",
    )
    c4.metric(
        "LOTS CRITIQUES (< 30J)",
        f"{int(kpi_stock['lots_critiques_30j'])} LOTS",
        delta="PRIORITE FEFO",
        delta_color="off",
    )
    c5.metric(
        "LOTS PERIMES BLOQUES",
        f"{int(kpi_stock['lots_perimes'])} LOT(S)",
        delta="ISOLES PAR TRIGGER",
        delta_color="inverse",
    )

    st.markdown("---")

    # 2. Graphiques interactifs Plotly (Style classique)
    col_chart1, col_chart2 = st.columns(2)

    with col_chart1:
        df_pareto = db.fetch_dataframe(
            """
            WITH cte_perf AS (
                SELECT
                    m.nom_commercial,
                    c.nom_categorie,
                    ROUND(SUM(ld.quantite_delivree * ld.prix_unitaire_facture), 2) AS ca_mad,
                    ROUND(SUM(ld.quantite_delivree * (ld.prix_unitaire_facture - l.prix_achat_unitaire)), 2) AS marge_mad
                FROM ligne_dispensation ld
                INNER JOIN lot_stock l ON ld.id_lot = l.id_lot
                INNER JOIN medicament m ON l.id_medicament = m.id_medicament
                INNER JOIN categorie_therapeutique c ON m.id_categorie = c.id_categorie
                GROUP BY m.id_medicament, m.nom_commercial, c.nom_categorie
            )
            SELECT
                DENSE_RANK() OVER (ORDER BY ca_mad DESC) AS rang,
                nom_commercial,
                nom_categorie,
                ca_mad,
                marge_mad,
                ROUND(100.0 * SUM(ca_mad) OVER (ORDER BY ca_mad DESC) / SUM(ca_mad) OVER (), 1) AS pct_cumule
            FROM cte_perf
            ORDER BY rang;
            """
        )
        if not df_pareto.empty:
            fig_ca = px.bar(
                df_pareto,
                x="nom_commercial",
                y=["ca_mad", "marge_mad"],
                barmode="group",
                color_discrete_sequence=["#1B4332", "#8C5A2B"],
                labels={"value": "Montant (MAD)", "nom_commercial": "Medicament", "variable": "Indicateur"},
            )
            fig_ca = apply_classic_chart_layout(
                fig_ca, "Chiffre d'Affaires & Marge Brute par Medicament (CTE + Window)"
            )
            st.plotly_chart(fig_ca, use_container_width=True)

    with col_chart2:
        df_risque = db.fetch_dataframe(
            """
            SELECT niveau_risque_peremption, SUM(valeur_stock_risque_mad) AS valeur_mad, COUNT(*) AS nb_lots
            FROM vw_radar_peremption_lots
            GROUP BY niveau_risque_peremption
            ORDER BY niveau_risque_peremption;
            """
        )
        if not df_risque.empty:
            fig_risque = px.bar(
                df_risque,
                x="niveau_risque_peremption",
                y="valeur_mad",
                text="nb_lots",
                color="niveau_risque_peremption",
                color_discrete_sequence=RETRO_PALETTE,
                labels={
                    "niveau_risque_peremption": "Categorie de Risque FEFO",
                    "valeur_mad": "Valeur Immobilisee (MAD)",
                },
            )
            fig_risque = apply_classic_chart_layout(
                fig_risque, "Valeur du Stock par Horizon de Peremption (MAD)"
            )
            fig_risque.update_layout(showlegend=False)
            st.plotly_chart(fig_risque, use_container_width=True)

    # 3. Vue consolidée des stocks
    st.subheader("ETAT CONSOLIDE DES STOCKS & SEUILS DE REAPPROVISIONNEMENT (VUE : vw_etat_stock_medicaments)")
    df_etat = db.fetch_dataframe(
        "SELECT * FROM vw_etat_stock_medicaments ORDER BY stock_valide_disponible ASC;"
    )
    st.dataframe(df_etat, use_container_width=True, hide_index=True)


def render_lots_and_crud_tab(db: DatabaseManager) -> None:
    """Section II : Gestion des lots, Radar de péremption et Réception de nouveaux lots."""
    st.subheader("SECTION II. REGISTRE DES LOTS EN STOCK, PEREMPTION & RECEPTION")

    col_filter1, col_filter2 = st.columns([2, 2])
    with col_filter1:
        filtre_risque = st.selectbox(
            "Filtrer par niveau de risque sanitaire :",
            [
                "TOUS LES LOTS",
                "1. PERIME (A DETRUIRE)",
                "2. CRITIQUE (< 30 JOURS)",
                "3. SURVEILLANCE (31-90 JOURS)",
                "4. CONFORME (> 90 JOURS)",
            ],
        )
    with col_filter2:
        search_med = st.text_input("Rechercher par nom commercial ou numero de lot :", "")

    sql_radar = "SELECT * FROM vw_radar_peremption_lots WHERE 1=1"
    params = []
    if filtre_risque != "TOUS LES LOTS":
        sql_radar += " AND niveau_risque_peremption = %s"
        params.append(filtre_risque)
    if search_med.strip():
        sql_radar += " AND (nom_commercial LIKE %s OR numero_lot_fabricant LIKE %s)"
        params.extend([f"%{search_med.strip()}%", f"%{search_med.strip()}%"])
    sql_radar += " ORDER BY date_peremption ASC;"

    df_lots = db.fetch_dataframe(sql_radar, tuple(params))
    st.dataframe(df_lots, use_container_width=True, hide_index=True)

    st.markdown("---")
    col_form_add, col_form_upd = st.columns(2)

    # Formulaire INSERT : Réception d'un nouveau lot (Teste le Trigger de chaîne du froid)
    with col_form_add:
        st.markdown("#### [OPERATION INSERT] BORDEREAU DE RECEPTION D'UN NOUVEAU LOT")
        df_meds = db.fetch_dataframe(
            "SELECT id_medicament, nom_commercial, dosage, conservation_froid FROM medicament ORDER BY nom_commercial;"
        )
        df_fourn = db.fetch_dataframe(
            "SELECT id_fournisseur, raison_sociale FROM fournisseur WHERE statut_actif = TRUE ORDER BY raison_sociale;"
        )
        df_zones = db.fetch_dataframe(
            "SELECT id_zone, code_zone, nom_zone, est_refrigere FROM zone_stockage ORDER BY code_zone;"
        )

        with st.form("form_reception_lot"):
            num_lot = st.text_input("Numero de lot fabricant", placeholder="Ex: LOT-2026-X99")
            med_choice = st.selectbox(
                "Medicament",
                options=df_meds.to_dict("records"),
                format_func=lambda r: f"{r['nom_commercial']} ({r['dosage']}) {'[CHAINE DU FROID REQUISE]' if r['conservation_froid'] else '[AMBIANT]'}",
            )
            fourn_choice = st.selectbox(
                "Fournisseur agree",
                options=df_fourn.to_dict("records"),
                format_func=lambda r: r["raison_sociale"],
            )
            zone_choice = st.selectbox(
                "Zone d'entreposage",
                options=df_zones.to_dict("records"),
                format_func=lambda r: f"{r['code_zone']} - {r['nom_zone']} {'[REFRIGERE 2-8C]' if r['est_refrigere'] else '[AMBIANT 15-25C]'}",
            )
            c_d1, c_d2 = st.columns(2)
            date_fab = c_d1.date_input(
                "Date de fabrication", value=datetime.date.today() - datetime.timedelta(days=30)
            )
            date_exp = c_d2.date_input(
                "Date de peremption", value=datetime.date.today() + datetime.timedelta(days=365)
            )
            c_q1, c_q2 = st.columns(2)
            qte_recue = c_q1.number_input("Quantite recue (unites)", min_value=1, max_value=5000, value=50)
            prix_achat = c_q2.number_input("Prix d'achat unitaire (MAD)", min_value=1.0, value=45.0, step=0.5)

            submitted_lot = st.form_submit_button("Enregistrer la Reception du Lot")
            if submitted_lot:
                if not num_lot.strip():
                    st.error("[ERREUR DE VALIDATION] Veuillez saisir un numero de lot fabricant.")
                else:
                    ok, msg, _ = db.execute_dml(
                        """
                        INSERT INTO lot_stock (
                            numero_lot_fabricant, id_medicament, id_fournisseur, id_zone,
                            date_fabrication, date_peremption, date_reception,
                            quantite_initiale, quantite_actuelle, prix_achat_unitaire
                        ) VALUES (%s, %s, %s, %s, %s, %s, CURDATE(), %s, %s, %s);
                        """,
                        (
                            num_lot.strip(),
                            med_choice["id_medicament"],
                            fourn_choice["id_fournisseur"],
                            zone_choice["id_zone"],
                            date_fab,
                            date_exp,
                            int(qte_recue),
                            int(qte_recue),
                            float(prix_achat),
                        ),
                    )
                    if ok:
                        st.success(f"[SUCCES] {msg} (Ecriture automatique dans journal_mouvements_stock)")
                        st.rerun()
                    else:
                        st.error(f"[REJET PAR TRIGGER MYSQL] {msg}")

    # Formulaire UPDATE : Mise en quarantaine ou ajustement d'inventaire
    with col_form_upd:
        st.markdown("#### [OPERATION UPDATE] RECTIFICATION D'INVENTAIRE / QUARANTAINE")
        df_all_lots = db.fetch_dataframe(
            """
            SELECT l.id_lot, l.numero_lot_fabricant, m.nom_commercial, l.quantite_actuelle, l.statut_lot
            FROM lot_stock l
            INNER JOIN medicament m ON l.id_medicament = m.id_medicament
            ORDER BY l.id_lot DESC;
            """
        )
        with st.form("form_update_lot"):
            lot_sel = st.selectbox(
                "Selectionner le lot au registre",
                options=df_all_lots.to_dict("records"),
                format_func=lambda r: f"ID #{r['id_lot']} | {r['numero_lot_fabricant']} - {r['nom_commercial']} (Qte: {r['quantite_actuelle']} | Statut: {r['statut_lot']})",
            )
            new_statut = st.selectbox(
                "Nouveau statut sanitaire",
                options=["DISPONIBLE", "QUARANTAINE", "PERIME"],
            )
            new_qte = st.number_input(
                "Nouvelle quantite physique en stock",
                min_value=0,
                max_value=5000,
                value=int(lot_sel["quantite_actuelle"]) if lot_sel else 0,
            )
            btn_upd = st.form_submit_button("Valider la Rectification")
            if btn_upd and lot_sel:
                ok, msg, _ = db.execute_dml(
                    "UPDATE lot_stock SET statut_lot = %s, quantite_actuelle = %s WHERE id_lot = %s;",
                    (new_statut, int(new_qte), int(lot_sel["id_lot"])),
                )
                if ok:
                    st.success(f"[SUCCES] {msg} — Mouvement consigne dans le journal d'audit.")
                    st.rerun()
                else:
                    st.error(f"[ERREUR] {msg}")


def render_dispensation_and_triggers_tab(db: DatabaseManager) -> None:
    """Section III : Dispensation transactionnelle FEFO et Démonstration des Triggers."""
    st.subheader("SECTION III. DISPENSATION SUR ORDONNANCE (TRANSACTION ACID & ALGORITHME FEFO)")

    col_left, col_right = st.columns([3, 2])

    with col_left:
        st.markdown("#### 1. BORDEREAU DE DISPENSATION FEFO (PROCEDURE : sp_dispenser_medicament_fefo)")
        st.info(
            "NOTE TECHNIQUE : La procedure stockee verrouille les lots actifs (SELECT ... FOR UPDATE), "
            "alloue prioritairement les lots dont la date de peremption est la plus proche (FEFO), "
            "scinde automatiquement le prelevement sur plusieurs lots si necessaire, et execute un ROLLBACK "
            "integral si le stock total non-perime est insuffisant."
        )

        df_patients = db.fetch_dataframe("SELECT id_patient, cin, nom, prenom, organisme_assurance FROM patient;")
        df_medecins = db.fetch_dataframe("SELECT id_medecin, nom_complet, specialite FROM medecin;")
        df_meds_stock = db.fetch_dataframe(
            "SELECT id_medicament, nom_commercial, dosage, stock_valide_disponible FROM vw_etat_stock_medicaments;"
        )

        with st.form("form_fefo_dispense"):
            ref_ord = st.text_input(
                "Reference Ordonnance",
                value=f"ORD-2026-{datetime.datetime.now().strftime('%H%M%S')}",
            )
            pat = st.selectbox(
                "Patient beneficiaire",
                options=df_patients.to_dict("records"),
                format_func=lambda p: f"{p['nom']} {p['prenom']} [CIN: {p['cin']} | Assurance: {p['organisme_assurance']}]",
            )
            doc = st.selectbox(
                "Medecin prescripteur",
                options=df_medecins.to_dict("records"),
                format_func=lambda d: f"{d['nom_complet']} ({d['specialite']})",
            )
            med = st.selectbox(
                "Medicament prescrit",
                options=df_meds_stock.to_dict("records"),
                format_func=lambda m: f"{m['nom_commercial']} {m['dosage']} [Stock valide disponible : {m['stock_valide_disponible']} boites]",
            )
            qte_dem = st.number_input("Quantite a delivrer (boites)", min_value=1, max_value=500, value=5)
            posologie = st.text_input("Posologie indiquee", value="1 comprime matin et soir pendant 10 jours")
            notes = st.text_input("Observations cliniques", value="Dispensation conforme FEFO")

            btn_fefo = st.form_submit_button("Executer la Transaction FEFO")
            if btn_fefo:
                ok, msg = db.dispenser_ordonnance_fefo(
                    reference_ord=ref_ord.strip(),
                    id_patient=int(pat["id_patient"]),
                    id_medecin=int(doc["id_medecin"]),
                    id_medicament=int(med["id_medicament"]),
                    quantite=int(qte_dem),
                    posologie=posologie,
                    notes=notes,
                )
                if ok:
                    st.success(f"[TRANSACTION VALIDEE - COMMIT] {msg}")
                else:
                    st.error(f"[TRANSACTION ANNULEE - ROLLBACK] {msg}")

    with col_right:
        st.markdown("#### 2. BANC D'ESSAI DU TRIGGER SANITAIRE (ANTI-PEREMPTION)")
        st.warning(
            "PROTOCOLE DE TEST : Selectionnez ci-dessous un lot PERIME (ex: LOT-AML-OLD) ou en QUARANTAINE "
            "(ex: LOT-MOP-QUAR) et tentez de forcer une insertion directe dans ligne_dispensation. "
            "Le trigger MySQL trg_before_insert_dispensation interceptera et rejettera la requete via SIGNAL SQLSTATE '45000'."
        )
        df_bad_lots = db.fetch_dataframe(
            """
            SELECT l.id_lot, l.numero_lot_fabricant, m.nom_commercial, l.statut_lot, l.date_peremption, l.quantite_actuelle
            FROM lot_stock l
            INNER JOIN medicament m ON l.id_medicament = m.id_medicament
            WHERE l.statut_lot IN ('PERIME', 'QUARANTAINE') OR l.date_peremption < CURDATE();
            """
        )
        with st.form("form_test_trigger"):
            bad_lot = st.selectbox(
                "Lot non conforme (Perime ou Quarantaine)",
                options=df_bad_lots.to_dict("records"),
                format_func=lambda b: f"{b['numero_lot_fabricant']} ({b['nom_commercial']}) — Statut: {b['statut_lot']} | Exp: {b['date_peremption']}",
            )
            btn_trigger = st.form_submit_button("Simuler une Delivrance Non Conforme")
            if btn_trigger and bad_lot:
                ok, msg, _ = db.execute_dml(
                    """
                    INSERT INTO ligne_dispensation (id_ordonnance, id_lot, quantite_delivree, prix_unitaire_facture, posologie)
                    VALUES (1, %s, 1, 50.00, 'Test de violation regle sanitaire');
                    """,
                    (int(bad_lot["id_lot"]),),
                )
                if not ok:
                    st.error(f"[BLOCAGE TRIGGER ACTIF] {msg}")
                else:
                    st.success(msg)

    st.markdown("---")
    st.subheader("REGISTRE HISTORIQUE DES LIGNES DE DISPENSATION (JOINTURE SUR 6 TABLES)")
    df_hist_disp = db.fetch_dataframe(
        """
        SELECT
            o.reference_ordonnance,
            o.date_dispensation,
            CONCAT(p.nom, ' ', p.prenom) AS patient,
            med_doc.nom_complet AS medecin,
            m.nom_commercial AS medicament,
            l.numero_lot_fabricant AS lot_preleve_fefo,
            l.date_peremption AS expiration_lot,
            ld.quantite_delivree,
            ld.prix_unitaire_facture,
            ROUND(ld.quantite_delivree * ld.prix_unitaire_facture, 2) AS total_ligne_mad
        FROM ligne_dispensation ld
        INNER JOIN ordonnance o ON ld.id_ordonnance = o.id_ordonnance
        INNER JOIN patient p ON o.id_patient = p.id_patient
        INNER JOIN medecin med_doc ON o.id_medecin = med_doc.id_medecin
        INNER JOIN lot_stock l ON ld.id_lot = l.id_lot
        INNER JOIN medicament m ON l.id_medicament = m.id_medicament
        ORDER BY o.date_dispensation DESC, o.id_ordonnance DESC;
        """
    )
    st.dataframe(df_hist_disp, use_container_width=True, hide_index=True)


def render_audit_and_explain_tab(db: DatabaseManager) -> None:
    """Section IV : Journal d'audit des triggers et plan d'exécution EXPLAIN des index."""
    st.subheader("SECTION IV. GRAND LIVRE D'AUDIT DES MOUVEMENTS & OPTIMISATION EXPLAIN")

    df_audit = db.fetch_dataframe(
        """
        SELECT
            j.id_mouvement,
            j.date_mouvement,
            l.numero_lot_fabricant,
            m.nom_commercial,
            j.type_mouvement,
            j.quantite_avant,
            j.quantite_apres,
            j.delta_quantite,
            j.operateur,
            j.commentaire
        FROM journal_mouvements_stock j
        INNER JOIN lot_stock l ON j.id_lot = l.id_lot
        INNER JOIN medicament m ON l.id_medicament = m.id_medicament
        ORDER BY j.id_mouvement DESC;
        """
    )
    st.dataframe(df_audit, use_container_width=True, hide_index=True)

    st.markdown("---")
    st.subheader("ANALYSE DU PLAN D'EXECUTION MYSQL (COMMANDE EXPLAIN — ETAPE 9 DU BAREME)")

    col_exp1, col_exp2 = st.columns(2)
    with col_exp1:
        st.markdown("**1. Plan EXPLAIN sur la recherche FEFO (Index : idx_lot_fefo_lookup)**")
        df_exp1 = db.fetch_dataframe(
            """
            EXPLAIN
            SELECT id_lot, numero_lot_fabricant, quantite_actuelle, date_peremption
            FROM lot_stock
            WHERE id_medicament = 1
              AND statut_lot = 'DISPONIBLE'
              AND date_peremption >= CURDATE()
            ORDER BY date_peremption ASC;
            """
        )
        st.dataframe(df_exp1, use_container_width=True, hide_index=True)

    with col_exp2:
        st.markdown("**2. Plan EXPLAIN sur le Journal des Mouvements (Index : idx_journal_type_date)**")
        df_exp2 = db.fetch_dataframe(
            """
            EXPLAIN
            SELECT id_mouvement, id_lot, type_mouvement, delta_quantite, date_mouvement
            FROM journal_mouvements_stock
            WHERE type_mouvement = 'DISPENSATION'
            ORDER BY date_mouvement DESC;
            """
        )
        st.dataframe(df_exp2, use_container_width=True, hide_index=True)


def main() -> None:
    db = init_db_sidebar()
    st.title("PHARMAFLOW — REGISTRE OFFICINAL & GESTION DES LOTS (FEFO)")
    st.caption(
        "ARCHITECTURE RELATIONNELLE MYSQL 8.0+ (3NF, TRIGGERS SANITAIRES, PROCEDURES STOCKEES ACID, CTE, FONCTIONS DE FENETRAGE & INDEX B-TREE)"
    )

    tab1, tab2, tab3, tab4 = st.tabs(
        [
            "I. TABLEAU DE BORD & ANALYTIQUE",
            "II. LOTS, PEREMPTION & RECEPTION",
            "III. DISPENSATION FEFO & TRIGGERS",
            "IV. LIVRE D'AUDIT & EXPLAIN",
        ]
    )

    with tab1:
        render_dashboard_tab(db)
    with tab2:
        render_lots_and_crud_tab(db)
    with tab3:
        render_dispensation_and_triggers_tab(db)
    with tab4:
        render_audit_and_explain_tab(db)


if __name__ == "__main__":
    main()
