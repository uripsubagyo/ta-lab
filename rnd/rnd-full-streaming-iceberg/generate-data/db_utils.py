# include/utils/db_utils.py
import logging
import os
from typing import List, Tuple, Any

# Try to import psycopg2, with fallback options
try:
    import psycopg2
    from psycopg2.extras import execute_batch
    PSYCOPG2_AVAILABLE = True
    logging.info("✅ psycopg2 imported successfully")
except ImportError:
    try:
        import psycopg2cffi as psycopg2
        from psycopg2cffi.extras import execute_batch
        PSYCOPG2_AVAILABLE = True
        logging.info("✅ psycopg2cffi imported as fallback")
    except ImportError:
        PSYCOPG2_AVAILABLE = False
        logging.warning("⚠️ Neither psycopg2 nor psycopg2cffi is available")

# Database configuration from environment with defaults for Docker setup
DB_HOST = os.getenv("DB_HOST", "localhost")  # localhost for external connection
DB_PORT = os.getenv("DB_PORT", "5433")  # 5433 to avoid conflict with local postgres
DB_NAME = os.getenv("DB_NAME", "sourcedb")  # sourcedb as per docker-compose
DB_USER = os.getenv("DB_USER", "postgres")  # postgres user as per docker-compose
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")  # postgres password as per docker-compose

# Alternative container connection settings
CONTAINER_HOST = os.getenv("CONTAINER_HOST", "rnd-full-streaming-iceberg-postgres-1")

class DatabaseManager:
    def __init__(self):
        self.connection_params = {
            'host': DB_HOST,
            'port': DB_PORT,
            'database': DB_NAME,
            'user': DB_USER,
            'password': DB_PASSWORD
        }
        self.use_airflow_hook = False
        logging.info(f"🔧 Database config: {DB_HOST}:{DB_PORT}/{DB_NAME} as {DB_USER}")
        


    def get_connection(self):
        """Get PostgreSQL connection with fallback to container name"""
        if PSYCOPG2_AVAILABLE:
            # Try localhost connection first
            try:
                logging.info(f"🔄 Attempting to connect to PostgreSQL at {self.connection_params['host']}:{self.connection_params['port']}")
                logging.info(f"📝 Using database: {self.connection_params['database']}, user: {self.connection_params['user']}")
                conn = psycopg2.connect(
                    **self.connection_params,
                    connect_timeout=5
                )
                logging.info("✅ Successfully connected to PostgreSQL via localhost")
                return conn
            except Exception as localhost_error:
                logging.warning(f"⚠️ Localhost connection failed: {localhost_error}")
                
                # Try container name connection as fallback
                try:
                    container_params = self.connection_params.copy()
                    container_params['host'] = CONTAINER_HOST
                    
                    logging.info(f"🔄 Attempting to connect to PostgreSQL container at {CONTAINER_HOST}:{self.connection_params['port']}")
                    conn = psycopg2.connect(
                        **container_params,
                        connect_timeout=5
                    )
                    logging.info("✅ Successfully connected to PostgreSQL via container name")
                    return conn
                except Exception as container_error:
                    logging.error(f"❌ Container connection also failed: {container_error}")
                    raise Exception(f"❌ Both localhost and container connections failed. Localhost: {localhost_error}, Container: {container_error}")
        else:
            raise Exception("❌ psycopg2 not available - please install psycopg2 or psycopg2-binary")
    
    def test_connection(self):
        """Test database connection"""
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            result = cursor.fetchone()
            cursor.close()
            conn.close()
            logging.info("✅ Database connection successful")
            return True
        except Exception as e:
            logging.error(f"❌ Database connection test failed: {e}")
            return False
    
    def bulk_insert_data(self, table_name: str, columns: List[str], data_list: List[Tuple]):
        """Bulk insert data with error handling"""
        if not data_list:
            logging.warning(f"No data to insert into {table_name}")
            return 0
        
        placeholders = ','.join(['%s'] * len(columns))
        columns_str = ','.join(columns)
        sql = f"INSERT INTO {table_name} ({columns_str}) VALUES ({placeholders}) ON CONFLICT DO NOTHING"
        
        conn = None
        cursor = None
        try:
            logging.info(f"🔄 Starting bulk insert into {table_name} with {len(data_list)} records")
            logging.info(f"🔍 SQL Query: {sql}")
            logging.info(f"🔍 Sample data: {data_list[0] if data_list else 'No data'}")
            
            conn = self.get_connection()
            conn.autocommit = False  # Explicitly disable autocommit
            cursor = conn.cursor()
            
            # Log connection details
            logging.info(f"🔍 Connection info: {conn.get_dsn_parameters()}")
            
            # Check current transaction status
            logging.info(f"🔍 Transaction status before insert: {conn.get_transaction_status()}")
            
            # Split data into chunks for better memory management
            chunk_size = 1000
            total_inserted = 0
            
            for i in range(0, len(data_list), chunk_size):
                chunk = data_list[i:i + chunk_size]
                logging.info(f"📦 Processing chunk {i//chunk_size + 1} of {(len(data_list) + chunk_size - 1)//chunk_size}")
                
                if PSYCOPG2_AVAILABLE:
                    # Use psycopg2's execute_batch for better performance
                    execute_batch(cursor, sql, chunk, page_size=chunk_size)
                else:
                    # Fallback to individual inserts
                    for row in chunk:
                        cursor.execute(sql, row)
                
                total_inserted += len(chunk)
                logging.info(f"✅ Executed insert for {len(chunk)} records in current chunk")
                
                # Check transaction status after each chunk
                logging.info(f"🔍 Transaction status after chunk: {conn.get_transaction_status()}")
            
            # EXPLICIT COMMIT with verification
            logging.info("🔄 Committing transaction...")
            conn.commit()
            logging.info("✅ Transaction committed successfully")
            
            # Verify the data was actually inserted
            verify_sql = f"SELECT COUNT(*) FROM {table_name} WHERE {columns[2]} = %s"  # Assuming entry_year is 3rd column
            if len(data_list) > 0 and len(data_list[0]) > 2:
                entry_year = data_list[0][2]  # Get entry_year from first record
                cursor.execute(verify_sql, (entry_year,))
                count_result = cursor.fetchone()
                actual_count = count_result[0] if count_result else 0
                logging.info(f"🔍 Verification: Found {actual_count} records with entry_year {entry_year} in database")
            
            logging.info(f"✅ Successfully inserted {total_inserted} records into {table_name}")
            return total_inserted
            
        except Exception as e:
            logging.error(f"❌ Error inserting into {table_name}: {e}")
            if conn:
                logging.info("🔄 Rolling back transaction...")
                conn.rollback()
                logging.info("✅ Transaction rolled back")
            raise
        finally:
            if cursor:
                cursor.close()
                logging.info("🔍 Cursor closed")
            if conn:
                conn.close()
                logging.info("🔍 Connection closed")
    
    def execute_query(self, query: str, params: tuple = None) -> List[Tuple]:
        """Execute SELECT query and return results"""
        conn = None
        cursor = None
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            
            logging.info(f"🔍 Executing query: {query}")
            if params:
                logging.info(f"📝 With params: {params}")
                cursor.execute(query, params)
            else:
                cursor.execute(query)
                
            results = cursor.fetchall()
            logging.info(f"📊 Query returned {len(results)} rows")
            if results:
                logging.info(f"📋 First row: {results[0]}")
            return results
        except Exception as e:
            logging.error(f"❌ Error executing query: {e}")
            logging.error(f"Query: {query}")
            logging.error(f"Params: {params}")
            raise
        finally:
            if cursor:
                cursor.close()
            if conn:
                conn.close()
    
    def execute_single_query(self, query: str, params: tuple = None):
        """Execute single query (INSERT/UPDATE/DELETE)"""
        conn = None
        cursor = None
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
                
            conn.commit()
            rowcount = cursor.rowcount
            logging.info(f"✅ Query executed successfully - {rowcount} rows affected")
            return rowcount
        except Exception as e:
            if conn:
                conn.rollback()
            logging.error(f"❌ Error executing query: {e}")
            logging.error(f"Query: {query}")
            logging.error(f"Params: {params}")
            raise
        finally:
            if cursor:
                cursor.close()
            if conn:
                conn.close()
    
    def table_exists(self, table_name: str) -> bool:
        """Check if table exists"""
        query = """
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_name = %s
        );
        """
        try:
            result = self.execute_query(query, (table_name,))
            return result[0][0] if result else False
        except Exception as e:
            logging.warning(f"⚠️ Could not check if table {table_name} exists: {e}")
            return False
    
    def get_table_schema(self, table_name: str) -> List[Tuple]:
        """Get table schema information"""
        query = """
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns 
        WHERE table_name = %s
        ORDER BY ordinal_position;
        """
        try:
            return self.execute_query(query, (table_name,))
        except Exception as e:
            logging.error(f"❌ Error getting schema for table {table_name}: {e}")
            return []
    
    def create_tables_from_sql_file(self, sql_file_path: str):
        """Create tables from SQL file"""
        try:
            # Read and execute SQL file
            with open(sql_file_path, 'r') as f:
                sql_commands = f.read()
            
            conn = self.get_connection()
            conn.autocommit = True  # Enable autocommit for DDL statements
            cursor = conn.cursor()
            
            try:
                cursor.execute(sql_commands)
                logging.info(f"✅ Successfully executed SQL file: {sql_file_path}")
            except Exception as e:
                logging.error(f"❌ Error executing SQL file {sql_file_path}: {e}")
                logging.error(f"Query: {sql_commands}")
                raise
            
            cursor.close()
            conn.close()
            
        except Exception as e:
            logging.error(f"❌ Error creating tables from SQL file: {e}")
            raise

# Factory function with error handling
def get_db_manager():
    """Get database manager instance with error handling"""
    try:
        manager = DatabaseManager()
        
        # Test the connection immediately
        if not manager.test_connection():
            logging.error("❌ Database manager created but connection test failed")
        
        return manager
    except Exception as e:
        logging.error(f"❌ Failed to create database manager: {e}")
        raise

# Simple test function
def test_database_setup():
    """Test database setup and connection"""
    try:
        logging.info("🧪 Testing database setup...")
        
        db = get_db_manager()
        
        # Test basic connection
        if db.test_connection():
            logging.info("✅ Database connection test passed")
        else:
            logging.error("❌ Database connection test failed")
            return False
        
        # Test table check
        exists = db.table_exists('information_schema')
        logging.info(f"✅ Table existence check works: {exists}")
        
        # Test simple query
        result = db.execute_query("SELECT current_database(), current_user")
        if result:
            logging.info(f"✅ Connected to database: {result[0][0]} as user: {result[0][1]}")
        
        return True
        
    except Exception as e:
        logging.error(f"❌ Database setup test failed: {e}")
        return False

# Initialize logging
if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    test_database_setup()