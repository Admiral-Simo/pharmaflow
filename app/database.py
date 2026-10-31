"""
Module d'accès aux données MySQL 8.0+ pour PharmaFlow BDR (INPT).
Utilise exclusivement mysql-connector-python et des requêtes paramétrées (%s)
sans aucun ORM afin de mettre en valeur l'architecture SQL native.
"""

import os
from typing import Any, Dict, List, Optional, Tuple
import mysql.connector
from mysql.connector import Error as MySQLError
import pandas as pd


class DatabaseManager:
    """Gère les connexions et l'exécution sécurisée des requêtes sur MySQL."""

    def __init__(
        self,
        host: str = os.getenv("DB_HOST", "localhost"),
        port: int = int(os.getenv("DB_PORT", "3306")),
        user: str = os.getenv("DB_USER", "root"),
        password: str = os.getenv("DB_PASSWORD", ""),
        database: str = os.getenv("DB_NAME", "pharmaflow_bdr"),
    ) -> None:
        self.config: Dict[str, Any] = {
            "host": host,
            "port": port,
            "user": user,
            "password": password,
            "database": database,
            "charset": "utf8mb4",
            "use_unicode": True,
            "autocommit": False,
        }

    def get_connection(self) -> mysql.connector.MySQLConnection:
        """Ouvre et retourne une connexion active au serveur MySQL."""
        return mysql.connector.connect(**self.config)

    def test_connection(self) -> Tuple[bool, str]:
        """Vérifie la connectivité à la base MySQL et retourne la version du serveur."""
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            cursor.execute("SELECT VERSION(), DATABASE();")
            version, db_name = cursor.fetchone()
            cursor.close()
            conn.close()
            return True, f"Connecté à MySQL {version} (Base : {db_name})"
        except MySQLError as err:
            return False, f"Erreur de connexion MySQL : {err.msg}"

    def fetch_dataframe(
        self, query: str, params: Optional[Tuple[Any, ...]] = None
    ) -> pd.DataFrame:
        """Exécute une requête SELECT paramétrée et retourne un DataFrame Pandas."""
        conn = self.get_connection()
        try:
            cursor = conn.cursor(dictionary=True)
            cursor.execute(query, params or ())
            rows = cursor.fetchall()
            return pd.DataFrame(rows) if rows else pd.DataFrame()
        finally:
            cursor.close()
            conn.close()

    def fetch_one(
        self, query: str, params: Optional[Tuple[Any, ...]] = None
    ) -> Optional[Dict[str, Any]]:
        """Exécute une requête SELECT et retourne une seule ligne sous forme de dictionnaire."""
        conn = self.get_connection()
        try:
            cursor = conn.cursor(dictionary=True)
            cursor.execute(query, params or ())
            return cursor.fetchone()
        finally:
            cursor.close()
            conn.close()

    def execute_dml(
        self, query: str, params: Optional[Tuple[Any, ...]] = None
    ) -> Tuple[bool, str, int]:
        """
        Exécute une instruction INSERT, UPDATE ou DELETE au sein d'une transaction explicite.
        Retourne (succès, message, lastrowid_ou_rowcount).
        """
        conn = self.get_connection()
        cursor = conn.cursor()
        try:
            cursor.execute(query, params or ())
            conn.commit()
            affected = cursor.lastrowid if cursor.lastrowid else cursor.rowcount
            return True, "Opération enregistrée avec succès dans MySQL.", affected
        except MySQLError as err:
            conn.rollback()
            return False, f"Erreur MySQL [{err.errno}] : {err.msg}", 0
        finally:
            cursor.close()
            conn.close()

    def dispenser_ordonnance_fefo(
        self,
        reference_ord: str,
        id_patient: int,
        id_medecin: int,
        id_medicament: int,
        quantite: int,
        posologie: str,
        notes: str,
    ) -> Tuple[bool, str]:
        """
        Crée une ordonnance et invoque la procédure stockée transactionnelle
        sp_dispenser_medicament_fefo pour allouer les lots selon la règle FEFO.
        """
        conn = self.get_connection()
        cursor = conn.cursor()
        try:
            # 1. Insertion de l'en-tête d'ordonnance
            sql_ord = """
                INSERT INTO ordonnance (
                    reference_ordonnance, id_patient, id_medecin,
                    date_prescription, statut_ordonnance, notes_cliniques
                ) VALUES (%s, %s, %s, CURDATE(), 'SERVIE', %s)
            """
            cursor.execute(sql_ord, (reference_ord, id_patient, id_medecin, notes))
            id_ordonnance = cursor.lastrowid

            # 2. Appel de la procédure stockée FEFO (qui gère les lots et les triggers)
            cursor.callproc(
                "sp_dispenser_medicament_fefo",
                (id_ordonnance, id_medicament, quantite, posologie),
            )
            conn.commit()
            return (
                True,
                f"Ordonnance {reference_ord} (ID #{id_ordonnance}) dispensée avec succès selon la règle FEFO.",
            )
        except MySQLError as err:
            conn.rollback()
            return False, f"Transaction annulée (ROLLBACK) — {err.msg}"
        finally:
            cursor.close()
            conn.close()
