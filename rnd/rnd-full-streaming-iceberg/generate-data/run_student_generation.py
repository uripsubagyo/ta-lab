#!/usr/bin/env python3
"""Standalone student generation"""

import logging
import sys
import os
from datetime import datetime
import argparse

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def main(entry_year=None, count=None):
    """Generate students for a specific year"""
    try:
        # Default to current academic year if not specified
        if entry_year is None:
            entry_year = datetime.now().year
        
        if count is None:
            count = 1000  # Default smaller count for testing
        
        print(f"👥 Generating {count} students for entry year {entry_year}")
        
        # Import local modules
        import student_generator
        import db_utils
        
        # Get generator
        generator = student_generator.get_student_generator()
        db = db_utils.get_db_manager()
        
        # Check if students for this year already exist
        existing_count = 0
        if db.table_exists('students'):
            result = db.execute_query(
                "SELECT COUNT(*) FROM students WHERE entry_year = %s",
                (entry_year,)
            )
            existing_count = result[0][0] if result else 0
        
        if existing_count > 0:
            print(f"✅ Students for year {entry_year} already exist ({existing_count} students)")
            return True
        
        # Generate students
        students, student_details, student_fees = generator.generate_students_for_year(entry_year, count)
        print(f"🎯 Generated {len(students)} students")
        
        # Insert students
        student_columns = ['student_id', 'full_name', 'entry_year', 'program_id', 'degree', 'faculty_id', 'status', 'created_at']
        inserted_count = db.bulk_insert_data('students', student_columns, students)
        print(f"✅ Successfully inserted {inserted_count} students")
        
        # Insert student details (remove the first element which is student_detail_id)
        student_details_for_insert = [detail[1:] for detail in student_details]
        detail_columns = [
            'student_id', 'gender', 'birth_date', 'birth_place',
            'religion', 'nationality', 'registration_date', 'address', 'city',
            'province', 'postal_code', 'phone_number', 'high_school', 'high_school_year',
            'parent_name', 'parent_income', 'parent_occupation', 'blood_type',
            'health_insurance', 'accommodation'
        ]
        db.bulk_insert_data('student_detail', detail_columns, student_details_for_insert)
        
        # Insert student fees
        fee_columns = ['fee_id', 'student_id', 'ukt_fee', 'bop_fee', 'updated_at']
        db.bulk_insert_data('student_fee', fee_columns, student_fees)
        
        print(f"✅ Generated complete student data for {entry_year}")
        return True
        
    except Exception as e:
        print(f"❌ Student generation error: {e}")
        logging.error(f"❌ Student generation error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Generate university students')
    parser.add_argument('--year', type=int, help='Entry year for students')
    parser.add_argument('--count', type=int, help='Number of students to generate')
    
    args = parser.parse_args()
    success = main(args.year, args.count)
    sys.exit(0 if success else 1) 