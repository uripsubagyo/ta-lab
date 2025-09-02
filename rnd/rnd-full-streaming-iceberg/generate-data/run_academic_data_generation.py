#!/usr/bin/env python3
"""Standalone academic data generation"""

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

def main(academic_year=None):
    """Generate academic data for a specific academic year"""
    try:
        # Default to current academic year if not specified
        if academic_year is None:
            current_year = datetime.now().year
            academic_year = f"{current_year}/{current_year + 1}"
        
        print(f"🏫 Generating academic data for {academic_year}")
        
        # Import local modules
        import academic_generator
        import db_utils
        
        # Get generator
        generator = academic_generator.get_academic_generator()
        db = db_utils.get_db_manager()
        
        # Check if academic data for this year already exists
        existing_registrations = 0
        existing_classes = 0
        
        if db.table_exists('registration'):
            result = db.execute_query(
                "SELECT COUNT(*) FROM registration WHERE academic_year = %s",
                (academic_year,)
            )
            existing_registrations = result[0][0] if result else 0
        
        if db.table_exists('class'):
            result = db.execute_query(
                "SELECT COUNT(*) FROM class WHERE academic_year = %s",
                (academic_year,)
            )
            existing_classes = result[0][0] if result else 0
        
        if existing_registrations > 0 and existing_classes > 0:
            print(f"✅ Academic data for year {academic_year} already exists ({existing_registrations} registrations, {existing_classes} classes)")
            return True
        
        # Generate data for both semesters
        total_registrations = 0
        total_classes = 0
        
        for semester in [1, 2]:
            print(f"📚 Generating data for semester {semester}")
            
            # Generate registrations for this semester
            registrations = generator.generate_registration_for_semester(academic_year, semester)
            if registrations:
                registration_columns = [
                    'registration_id', 'student_id', 'academic_year', 'semester',
                    'semester_code', 'registration_date', 'registration_status',
                    'total_sks', 'late_registration', 'created_at', 'updated_at'
                ]
                
                inserted_reg_count = db.bulk_insert_data('registration', registration_columns, registrations)
                total_registrations += inserted_reg_count
                print(f"✅ Inserted {inserted_reg_count} registrations for semester {semester}")
            
            # Generate classes for this semester
            classes = generator.generate_classes_for_semester(academic_year, semester)
            if classes:
                class_columns = [
                    'class_id', 'course_id', 'lecturer_id', 'academic_year', 'semester',
                    'class_code', 'room_code', 'schedule_day', 'schedule_time',
                    'capacity', 'enrolled_count', 'class_status', 'created_at'
                ]
                
                inserted_class_count = db.bulk_insert_data('class', class_columns, classes)
                total_classes += inserted_class_count
                print(f"✅ Inserted {inserted_class_count} classes for semester {semester}")
        
        print(f"✅ Generated academic data: {total_registrations} registrations, {total_classes} classes")
        return True
        
    except Exception as e:
        print(f"❌ Academic data generation error: {e}")
        logging.error(f"❌ Academic data generation error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Generate academic data (registrations and classes)')
    parser.add_argument('--year', type=str, help='Academic year (e.g., 2024/2025)')
    
    args = parser.parse_args()
    success = main(args.year)
    sys.exit(0 if success else 1) 