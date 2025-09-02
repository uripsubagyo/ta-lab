#!/usr/bin/env python3
"""Standalone database connection test"""

import logging
import sys
import os

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def main():
    """Test database connection"""
    try:
        print("🔍 Testing database connection...")
        
        # Import local modules
        import db_utils
        
        # Get database manager
        db = db_utils.get_db_manager()
        print("✅ Database manager created")
        
        # Test connection
        if db.test_connection():
            print("✅ Database connection test successful")
            logging.info("✅ Database connection test successful")
            return True
        else:
            print("❌ Database connection failed")
            return False
            
    except Exception as e:
        print(f"❌ Database connection error: {e}")
        logging.error(f"❌ Database connection error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 