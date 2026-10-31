"""
MySQL 8.0+ Data Access Layer for PharmaFlow (INPT Master in Data & AI).
Uses mysql-connector-python and parameterized SQL queries (%s) without an ORM
to showcase native relational database engineering.
"""

import os
from typing import Any, Dict, Optional, Tuple
import mysql.connector
from mysql.connector import Error as MySQLError
import pandas as pd


class DatabaseManager:
    """Manages MySQL connections, parameterized queries, and ACID transactions."""

    def __init__(
        self,
        host: str = os.getenv("DB_HOST", "localhost"),
        port: int = int(os.getenv("DB_PORT", "3306")),
        user: str = os.getenv("DB_USER", "root"),
        password: str = os.getenv("DB_PASSWORD", ""),
        database: str = os.getenv("DB_NAME", "pharmaflow_db"),
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
        """Opens and returns an active MySQL server connection."""
        return mysql.connector.connect(**self.config)

    def test_connection(self) -> Tuple[bool, str]:
        """Verifies connectivity to the MySQL server and returns server version details."""
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            cursor.execute("SELECT VERSION(), DATABASE();")
            version, db_name = cursor.fetchone()
            cursor.close()
            conn.close()
            return True, f"Connected to MySQL {version} (Schema: {db_name})"
        except MySQLError as err:
            return False, f"MySQL Connection Error: {err.msg}"

    def fetch_dataframe(
        self, query: str, params: Optional[Tuple[Any, ...]] = None
    ) -> pd.DataFrame:
        """Executes a parameterized SELECT query and returns a Pandas DataFrame."""
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
        """Executes a parameterized SELECT query and returns a single row as a dictionary."""
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
        Executes an INSERT, UPDATE, or DELETE statement inside an explicit transaction.
        Returns (success_flag, status_message, lastrowid_or_rowcount).
        """
        conn = self.get_connection()
        cursor = conn.cursor()
        try:
            cursor.execute(query, params or ())
            conn.commit()
            affected = cursor.lastrowid if cursor.lastrowid else cursor.rowcount
            return True, "Database operation committed successfully.", affected
        except MySQLError as err:
            conn.rollback()
            return False, f"MySQL Error [{err.errno}]: {err.msg}", 0
        finally:
            cursor.close()
            conn.close()

    def dispense_prescription_fefo(
        self,
        prescription_ref: str,
        patient_id: int,
        physician_id: int,
        medication_id: int,
        quantity: int,
        dosage_instructions: str,
        clinical_notes: str,
    ) -> Tuple[bool, str]:
        """
        Creates a prescription header and invokes the transactional stored procedure
        sp_dispense_medication_fefo to allocate inventory batches using FEFO rules.
        """
        conn = self.get_connection()
        cursor = conn.cursor()
        try:
            # 1. Insert the prescription header record
            sql_prescription = """
                INSERT INTO prescription (
                    prescription_reference, patient_id, physician_id,
                    prescription_date, prescription_status, clinical_notes
                ) VALUES (%s, %s, %s, CURDATE(), 'DISPENSED', %s)
            """
            cursor.execute(
                sql_prescription,
                (prescription_ref, patient_id, physician_id, clinical_notes),
            )
            prescription_id = cursor.lastrowid

            # 2. Invoke the FEFO stored procedure (allocates batches and triggers audit logs)
            cursor.callproc(
                "sp_dispense_medication_fefo",
                (prescription_id, medication_id, quantity, dosage_instructions),
            )
            conn.commit()
            return (
                True,
                f"Prescription {prescription_ref} (ID #{prescription_id}) dispensed successfully using FEFO allocation.",
            )
        except MySQLError as err:
            conn.rollback()
            return False, f"Transaction Aborted (ROLLBACK) — {err.msg}"
        finally:
            cursor.close()
            conn.close()
