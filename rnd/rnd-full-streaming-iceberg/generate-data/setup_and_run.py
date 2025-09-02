#!/usr/bin/env python3
"""Setup database schema and run data generation"""

import logging
import sys
import os
import subprocess
from datetime import datetime

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def run_command(command, description):
    """Run a shell command with error handling"""
    try:
        print(f"🔧 {description}...")
        result = subprocess.run(command, shell=True, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"❌ Failed to {description.lower()}")
            print(f"Error: {result.stderr}")
            return False
        print(f"✅ {description} completed")
        if result.stdout.strip():
            print(f"Output: {result.stdout.strip()}")
        return True
    except Exception as e:
        print(f"❌ Error in {description.lower()}: {e}")
        return False

def wait_for_postgres():
    """Wait for PostgreSQL to be ready"""
    import time
    max_retries = 30
    retry_count = 0
    
    while retry_count < max_retries:
        try:
            import db_utils
            db = db_utils.get_db_manager()
            if db.test_connection():
                print("✅ PostgreSQL is ready")
                return True
        except Exception as e:
            print(f"⏳ Waiting for PostgreSQL... ({retry_count + 1}/{max_retries})")
            time.sleep(2)
            retry_count += 1
    
    print("❌ PostgreSQL not ready after waiting")
    return False

def setup_database_schema():
    """Setup the university database schema"""
    try:
        print("🗄️ Setting up database schema...")
        
        # Wait for PostgreSQL
        if not wait_for_postgres():
            return False
        
        # Execute the university schema
        import db_utils
        db = db_utils.get_db_manager()
        
        schema_file = os.path.join(os.path.dirname(__file__), 'university_tables.sql')
        if os.path.exists(schema_file):
            db.create_tables_from_sql_file(schema_file)
            print("✅ University schema created successfully")
            return True
        else:
            print(f"❌ Schema file not found: {schema_file}")
            return False
            
    except Exception as e:
        print(f"❌ Error setting up database schema: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """Main setup and run function"""
    try:
        print("🚀 Starting university data generation setup")
        
        # Step 1: Setup database schema
        if not setup_database_schema():
            print("❌ Database schema setup failed")
            return False
        
        # Step 2: Run the complete generation
        print("\n🎯 Starting data generation...")
        
        import run_complete_generation
        success = run_complete_generation.main(
            academic_year=None,  # Use current year
            student_count=500,   # Smaller count for initial setup
            skip_existing=True
        )
        
        if success:
            print("\n🎉 Complete setup and data generation finished successfully!")
            return True
        else:
            print("\n❌ Data generation failed")
            return False
        
    except Exception as e:
        print(f"❌ Setup error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 