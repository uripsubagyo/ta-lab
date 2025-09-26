from pyflink.table import TableEnvironment, EnvironmentSettings
from pyflink.table.expressions import col
from pyflink.table.window import Tumble
import json

class IcebergConnector:
    def __init__(self, table_env: TableEnvironment):
        self.table_env = table_env
        self._setup_iceberg_catalog()

    def _setup_iceberg_catalog(self):
        # Setup Iceberg catalog
        self.table_env.execute_sql("""
            CREATE CATALOG iceberg_catalog WITH (
                'type'='iceberg',
                'catalog-type'='hadoop',
                'warehouse'='s3a://warehouse/iceberg',
                'property-version'='2'
            )
        """)
        
        # Use the catalog
        self.table_env.use_catalog("iceberg_catalog")

    def check_faculty_exists(self, faculty_code: str) -> bool:
        """
        Check if faculty code already exists in Iceberg
        """
        try:
            result = self.table_env.sql_query(f"""
                SELECT COUNT(*) as count 
                FROM faculty_sink 
                WHERE faculty_code = '{faculty_code}'
                AND validation_status = 'VALID'
            """)
            count = result.execute().collect()[0][0]
            return count > 0
        except Exception as e:
            print(f"Error checking faculty existence: {str(e)}")
            return False

    def save_faculty(self, faculty_data: dict) -> bool:
        """
        Save faculty data to Iceberg table
        """
        try:
            # Create temporary table for the input data
            self.table_env.execute_sql("""
                CREATE TEMPORARY TABLE temp_faculty (
                    id INT,
                    faculty_code STRING,
                    faculty_name STRING,
                    created_at BIGINT,
                    source_timestamp TIMESTAMP(3),
                    source_database STRING,
                    source_schema STRING,
                    source_table STRING,
                    ingestion_timestamp TIMESTAMP(3),
                    validation_status STRING,
                    error_message STRING
                ) WITH (
                    'connector' = 'values'
                )
            """)

            # Insert data into temporary table
            self.table_env.execute_sql(f"""
                INSERT INTO temp_faculty VALUES (
                    {faculty_data['id']},
                    '{faculty_data['faculty_code']}',
                    '{faculty_data['faculty_name']}',
                    {faculty_data['created_at']},
                    CAST('{faculty_data['source_timestamp']}' AS TIMESTAMP(3)),
                    '{faculty_data['source_database']}',
                    '{faculty_data['source_schema']}',
                    '{faculty_data['source_table']}',
                    CAST('{faculty_data['ingestion_timestamp']}' AS TIMESTAMP(3)),
                    '{faculty_data['validation_status']}',
                    '{faculty_data.get('error_message', '')}'
                )
            """)

            # Insert from temporary table to Iceberg
            self.table_env.execute_sql("""
                INSERT INTO faculty_sink
                SELECT * FROM temp_faculty
            """)

            return True
        except Exception as e:
            print(f"Error saving faculty data: {str(e)}")
            return False

    def get_faculty_stats(self) -> dict:
        """
        Get statistics about faculty data
        """
        try:
            stats = self.table_env.sql_query("""
                SELECT 
                    validation_status,
                    COUNT(*) as count,
                    MAX(ingestion_timestamp) as last_ingestion
                FROM faculty_sink
                GROUP BY validation_status
            """)
            
            return {
                row[0]: {"count": row[1], "last_ingestion": row[2]}
                for row in stats.execute().collect()
            }
        except Exception as e:
            print(f"Error getting faculty stats: {str(e)}")
            return {} 