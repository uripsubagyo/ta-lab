#!/usr/bin/env python3
"""Test script to verify the data generation system"""

import logging
import sys
import os

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def test_imports():
    """Test that all modules can be imported"""
    try:
        print("🧪 Testing module imports...")
        
        import db_utils
        print("✅ db_utils imported")
        
        import static_data
        print("✅ static_data imported")
        
        import master_data_generator
        print("✅ master_data_generator imported")
        
        import student_generator
        print("✅ student_generator imported")
        
        import academic_generator
        print("✅ academic_generator imported")
        
        import enrollment_generator
        print("✅ enrollment_generator imported")
        
        import payment_generator
        print("✅ payment_generator imported")
        
        import attendance_generator
        print("✅ attendance_generator imported")
        
        print("🎉 All modules imported successfully!")
        return True
        
    except Exception as e:
        print(f"❌ Module import failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_database_connection():
    """Test database connectivity"""
    try:
        print("\n🧪 Testing database connection...")
        
        import db_utils
        db = db_utils.get_db_manager()
        
        if db.test_connection():
            print("✅ Database connection successful")
            
            # Test basic query
            result = db.execute_query("SELECT current_database(), current_user")
            if result:
                print(f"📊 Connected to database: {result[0][0]} as user: {result[0][1]}")
            
            return True
        else:
            print("❌ Database connection failed")
            return False
        
    except Exception as e:
        print(f"❌ Database test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_static_data():
    """Test static data functionality"""
    try:
        print("\n🧪 Testing static data...")
        
        import static_data
        
        # Test academic year calculation
        current_year = static_data.get_current_academic_year()
        print(f"📅 Current academic year: {current_year}")
        
        # Test faculty data
        faculties = static_data.get_faculty_data()
        print(f"🏛️ Found {len(faculties)} faculties")
        
        # Test program data
        programs = static_data.get_program_data()
        total_programs = sum(len(prog_list) for prog_list in programs.values())
        print(f"🎓 Found {total_programs} programs across {len(programs)} faculties")
        
        return True
        
    except Exception as e:
        print(f"❌ Static data test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """Run all tests"""
    print("🎯 Running system tests...\n")
    
    tests = [
        ("Module Imports", test_imports),
        ("Database Connection", test_database_connection), 
        ("Static Data", test_static_data)
    ]
    
    passed = 0
    failed = 0
    
    for test_name, test_func in tests:
        try:
            if test_func():
                passed += 1
            else:
                failed += 1
        except Exception as e:
            print(f"❌ Test {test_name} failed with exception: {e}")
            failed += 1
    
    print(f"\n📊 Test Results:")
    print(f"✅ Passed: {passed}")
    print(f"❌ Failed: {failed}")
    print(f"📈 Total: {passed + failed}")
    
    if failed == 0:
        print("\n🎉 All tests passed! System is ready for data generation.")
        return True
    else:
        print(f"\n⚠️ {failed} test(s) failed. Please fix issues before running data generation.")
        return False

if __name__ == "__main__":
    success = main()
    
    if success:
        print("\n💡 Next steps:")
        print("1. Run: python setup_and_run.py")
        print("2. Or run individual components as needed")
        print("3. Check README.md for detailed usage instructions")
    
    sys.exit(0 if success else 1) 