#!/usr/bin/env python3
"""Standalone master data setup"""

import logging
import sys
import os

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def main():
    """Setup master data"""
    try:
        print("🏗️ Setting up master data...")
        
        # Import local modules
        import master_data_generator
        
        # Get generator
        generator = master_data_generator.get_master_data_generator()
        
        # Setup master data
        success = generator.setup_master_data()
        
        if success:
            print("✅ Master data setup completed!")
            return True
        else:
            print("❌ Master data setup failed")
            return False
            
    except Exception as e:
        print(f"❌ Master data setup error: {e}")
        logging.error(f"❌ Master data setup error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 