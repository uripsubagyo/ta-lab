#!/usr/bin/env python3
"""Complete data generation runner"""

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

def run_step(step_name, func, *args, **kwargs):
    """Run a generation step with error handling"""
    try:
        print(f"\n{'='*20} {step_name} {'='*20}")
        result = func(*args, **kwargs)
        print(f"✅ {step_name} completed successfully")
        return True
    except Exception as e:
        print(f"❌ {step_name} failed: {e}")
        logging.error(f"❌ {step_name} failed: {e}")
        return False

def main(academic_year=None, student_count=1000, skip_existing=True):
    """Run complete data generation pipeline"""
    try:
        # Import all modules
        import db_utils
        import master_data_generator
        import static_data
        import student_generator
        import academic_generator
        import enrollment_generator
        import payment_generator
        import attendance_generator
        
        # Determine academic year
        if academic_year is None:
            academic_year = static_data.get_current_academic_year()
        
        entry_year = int(academic_year.split('/')[0])
        
        print(f"🎓 Running complete data generation for academic year: {academic_year}")
        print(f"👥 New student entry year: {entry_year}")
        print(f"📊 Target student count: {student_count}")
        
        # Step 1: Test database connection
        def test_connection():
            db = db_utils.get_db_manager()
            return db.test_connection()
        
        if not run_step("Database Connection Test", test_connection):
            return False
        
        # Step 2: Setup master data
        def setup_master_data():
            generator = master_data_generator.get_master_data_generator()
            return generator.setup_master_data()
        
        if not run_step("Master Data Setup", setup_master_data):
            return False
        
        # Step 3: Generate students
        def generate_students():
            db = db_utils.get_db_manager()
            generator = student_generator.get_student_generator()
            
            # Check if students already exist
            if skip_existing and db.table_exists('students'):
                result = db.execute_query(
                    "SELECT COUNT(*) FROM students WHERE entry_year = %s",
                    (entry_year,)
                )
                existing_count = result[0][0] if result else 0
                if existing_count > 0:
                    print(f"✅ Students for year {entry_year} already exist ({existing_count} students), skipping...")
                    return True
            
            students, student_details, student_fees = generator.generate_students_for_year(entry_year, student_count)
            
            # Insert students
            student_columns = ['student_id', 'full_name', 'entry_year', 'program_id', 'degree', 'faculty_id', 'status', 'created_at']
            db.bulk_insert_data('students', student_columns, students)
            
            # Insert student details
            detail_columns = [
                'student_id', 'gender', 'birth_date', 'birth_place',
                'religion', 'nationality', 'registration_date', 'address', 'city',
                'province', 'postal_code', 'phone_number', 'high_school', 'high_school_year',
                'parent_name', 'parent_income', 'parent_occupation', 'blood_type',
                'health_insurance', 'accommodation'
            ]
            student_details_for_insert = [detail[1:] for detail in student_details]
            db.bulk_insert_data('student_detail', detail_columns, student_details_for_insert)
            
            # Insert student fees
            fee_columns = ['fee_id', 'student_id', 'ukt_fee', 'bop_fee', 'updated_at']
            db.bulk_insert_data('student_fee', fee_columns, student_fees)
            
            return True
        
        if not run_step("Student Generation", generate_students):
            return False
        
        # Step 4: Generate academic data
        def generate_academic_data():
            db = db_utils.get_db_manager()
            generator = academic_generator.get_academic_generator()
            
            # Check if academic data already exists
            if skip_existing:
                reg_result = db.execute_query(
                    "SELECT COUNT(*) FROM registration WHERE academic_year = %s",
                    (academic_year,)
                ) if db.table_exists('registration') else [(0,)]
                
                class_result = db.execute_query(
                    "SELECT COUNT(*) FROM class WHERE academic_year = %s",
                    (academic_year,)
                ) if db.table_exists('class') else [(0,)]
                
                if reg_result[0][0] > 0 and class_result[0][0] > 0:
                    print(f"✅ Academic data already exists, skipping...")
                    return True
            
            # Generate for both semesters
            for semester in [1, 2]:
                print(f"📚 Processing semester {semester}")
                
                # Generate registrations
                registrations = generator.generate_registration_for_semester(academic_year, semester)
                if registrations:
                    registration_columns = [
                        'registration_id', 'student_id', 'academic_year', 'semester',
                        'semester_code', 'registration_date', 'registration_status',
                        'total_sks', 'late_registration', 'created_at', 'updated_at'
                    ]
                    db.bulk_insert_data('registration', registration_columns, registrations)
                
                # Generate classes
                classes = generator.generate_classes_for_semester(academic_year, semester)
                if classes:
                    class_columns = [
                        'class_id', 'course_id', 'lecturer_id', 'academic_year', 'semester',
                        'class_code', 'room_code', 'schedule_day', 'schedule_time',
                        'capacity', 'enrolled_count', 'class_status', 'created_at'
                    ]
                    db.bulk_insert_data('class', class_columns, classes)
            
            return True
        
        if not run_step("Academic Data Generation", generate_academic_data):
            return False
        
        # Step 5: Generate enrollments
        def generate_enrollments():
            db = db_utils.get_db_manager()
            generator = enrollment_generator.get_enrollment_generator()
            
            # Check if enrollments already exist
            if skip_existing and db.table_exists('student_enrollment'):
                result = db.execute_query(
                    """SELECT COUNT(*) FROM student_enrollment se
                       JOIN registration r ON se.registration_id = r.registration_id
                       WHERE r.academic_year = %s""",
                    (academic_year,)
                )
                existing_count = result[0][0] if result else 0
                if existing_count > 0:
                    print(f"✅ Enrollments already exist ({existing_count} records), skipping...")
                    return True
            
            enrollments = generator.generate_enrollments_for_academic_year(academic_year)
            
            if enrollments:
                # Remove enrollment_id (first element) for insertion
                enrollments_for_insert = [enrollment[1:] for enrollment in enrollments]
                enrollment_columns = [
                    'student_id', 'registration_id', 'class_id', 'enrollment_date',
                    'enrollment_status', 'final_grade', 'grade_point', 'attendance_percentage',
                    'created_at', 'updated_at'
                ]
                db.bulk_insert_data('student_enrollment', enrollment_columns, enrollments_for_insert)
            
            return True
        
        if not run_step("Student Enrollment Generation", generate_enrollments):
            return False
        
        # Step 6: Generate payments
        def generate_payments():
            db = db_utils.get_db_manager()
            generator = payment_generator.get_payment_generator()
            
            # Check if payments already exist
            if skip_existing and db.table_exists('payment'):
                result = db.execute_query(
                    """SELECT COUNT(*) FROM payment p
                       JOIN registration r ON p.registration_id = r.registration_id
                       WHERE r.academic_year = %s""",
                    (academic_year,)
                )
                existing_count = result[0][0] if result else 0
                if existing_count > 0:
                    print(f"✅ Payments already exist ({existing_count} records), skipping...")
                    return True
            
            # Get registrations for payment generation
            registrations = db.execute_query(
                """SELECT registration_id, student_id, academic_year, semester, 
                          registration_date, registration_status
                   FROM registration 
                   WHERE academic_year = %s
                   ORDER BY student_id, semester""",
                (academic_year,)
            )
            
            if not registrations:
                print(f"⚠️ No registrations found for {academic_year}")
                return True
            
            payments = generator.generate_payments_for_registrations(academic_year, registrations)
            
            if payments:
                payment_columns = [
                    'payment_id', 'student_id', 'registration_id', 'payment_type',
                    'payment_amount', 'bank_name', 'virtual_account_number', 'payment_channel',
                    'payment_time', 'payment_status', 'installment_number', 'late_fee_charged',
                    'total_paid_amount', 'payment_proof_url', 'due_date', 'created_at', 'updated_at'
                ]
                db.bulk_insert_data('payment', payment_columns, payments)
            
            return True
        
        if not run_step("Payment Generation", generate_payments):
            return False
        
        # Step 7: Generate attendance (optional)
        def generate_attendance():
            generator = attendance_generator.get_attendance_generator()
            return generator.generate_attendance_for_academic_year(academic_year)
        
        run_step("Attendance Generation", generate_attendance)  # Don't fail on attendance
        
        print(f"\n🎉 Complete data generation pipeline finished successfully!")
        print(f"📊 Academic year: {academic_year}")
        print(f"👥 Entry year: {entry_year}")
        return True
        
    except Exception as e:
        print(f"❌ Complete generation error: {e}")
        logging.error(f"❌ Complete generation error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Run complete university data generation')
    parser.add_argument('--year', type=str, help='Academic year (e.g., 2024/2025)')
    parser.add_argument('--count', type=int, default=1000, help='Number of students to generate')
    parser.add_argument('--force', action='store_true', help='Force regeneration even if data exists')
    
    args = parser.parse_args()
    skip_existing = not args.force
    
    success = main(args.year, args.count, skip_existing)
    sys.exit(0 if success else 1) 