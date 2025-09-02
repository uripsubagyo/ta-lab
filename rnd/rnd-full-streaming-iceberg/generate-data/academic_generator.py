"""Academic generator for registrations and classes"""

import logging
import random
from datetime import datetime, date, timedelta
from faker import Faker
import static_data
import db_utils

fake = Faker('id_ID')

class AcademicGenerator:
    def __init__(self):
        self.db = db_utils.get_db_manager()
        
    def generate_registration_for_semester(self, academic_year, semester):
        """Generate registrations for a specific semester"""
        try:
            logging.info(f"📝 Generating registrations for {academic_year} semester {semester}")
            
            # Get students from all years (students can register each semester)
            student_results = self.db.execute_query(
                "SELECT student_id, entry_year, program_id FROM students WHERE status = 'active' ORDER BY student_id"
            )
            
            if not student_results:
                logging.warning("⚠️ No active students found")
                return []
            
            registrations = []
            year_start = int(academic_year.split('/')[0])
            
            for student_id, entry_year, program_id in student_results:
                # Calculate which year this student is in
                student_year = year_start - entry_year + 1
                
                # Only allow registrations for students who should be active in this year
                # (max 6 years for undergraduate)
                if student_year <= 0 or student_year > 6:
                    continue
                    
                # Some students might skip semesters (dropout probability)
                if random.random() < 0.05:  # 5% chance to skip
                    continue
                
                # Generate registration
                registration_id = f"REG-{student_id}-{academic_year.replace('/', '')}-{semester}"
                semester_code = f"{academic_year.replace('/', '')}-{semester}"
                
                # Registration date (usually in July for semester 1, December for semester 2)
                if semester == 1:
                    reg_date = date(year_start, random.randint(7, 8), random.randint(1, 31))
                else:
                    reg_date = date(year_start, random.randint(12, 12), random.randint(1, 31))
                
                # Calculate expected SKS based on student year
                if student_year <= 2:
                    target_sks = random.randint(18, 24)  # Fresh students take more
                elif student_year <= 4:
                    target_sks = random.randint(15, 21)  # Mid-level students
                else:
                    target_sks = random.randint(6, 15)   # Senior students (thesis)
                
                # Late registration probability
                late_registration = random.random() < 0.1  # 10% chance
                
                registrations.append((
                    registration_id,
                    student_id,
                    academic_year,
                    semester,
                    semester_code,
                    reg_date,
                    'active',
                    target_sks,
                    late_registration,
                    datetime.now(),
                    datetime.now()
                ))
            
            logging.info(f"✅ Generated {len(registrations)} registrations")
            return registrations
            
        except Exception as e:
            logging.error(f"❌ Error generating registrations: {e}")
            raise
    
    def generate_classes_for_semester(self, academic_year, semester):
        """Generate classes for a specific semester"""
        try:
            logging.info(f"🏫 Generating classes for {academic_year} semester {semester}")
            
            # Get courses and lecturers
            course_results = self.db.execute_query(
                "SELECT id, course_code, course_name, credits, program_id FROM course ORDER BY id"
            )
            
            lecturer_results = self.db.execute_query(
                "SELECT id, lecturer_id, name FROM lecturer ORDER BY id"
            )
            
            room_results = self.db.execute_query(
                "SELECT room_code FROM room ORDER BY id"
            )
            
            if not course_results or not lecturer_results or not room_results:
                logging.warning("⚠️ Missing required data for class generation")
                return []
            
            classes = []
            room_codes = [room[0] for room in room_results]
            
            # Generate multiple classes per course (different lecturers/schedules)
            for course_id, course_code, course_name, credits, program_id in course_results:
                # Generate 1-3 classes per course
                num_classes = random.randint(1, 3)
                
                for class_num in range(1, num_classes + 1):
                    # Select random lecturer
                    lecturer_id, lecturer_code, lecturer_name = random.choice(lecturer_results)
                    
                    # Generate class details
                    class_id = f"CLASS-{course_code}-{academic_year.replace('/', '')}-{semester}-{class_num}"
                    class_code = f"{course_code}-{class_num}"
                    room_code = random.choice(room_codes)
                    schedule_day = random.choice(static_data.DAYS_OF_WEEK)
                    schedule_time = random.choice(static_data.TIME_SLOTS)
                    capacity = random.randint(30, 60)
                    enrolled_count = random.randint(15, capacity - 5)  # Some empty spots
                    
                    classes.append((
                        class_id,
                        course_id,
                        lecturer_id,
                        academic_year,
                        semester,
                        class_code,
                        room_code,
                        schedule_day,
                        schedule_time,
                        capacity,
                        enrolled_count,
                        'active',
                        datetime.now()
                    ))
            
            logging.info(f"✅ Generated {len(classes)} classes")
            return classes
            
        except Exception as e:
            logging.error(f"❌ Error generating classes: {e}")
            raise

def get_academic_generator():
    """Factory function to get academic generator instance"""
    return AcademicGenerator() 