"""Enrollment generator for linking students to classes"""

import logging
import random
from datetime import datetime, date, timedelta
from faker import Faker
import db_utils

fake = Faker('id_ID')

class EnrollmentGenerator:
    def __init__(self):
        self.db = db_utils.get_db_manager()
        
    def generate_enrollments_for_academic_year(self, academic_year):
        """Generate student enrollments for an academic year"""
        try:
            logging.info(f"📚 Generating enrollments for academic year {academic_year}")
            
            # Get all registrations for this academic year
            registration_results = self.db.execute_query(
                """SELECT registration_id, student_id, semester, total_sks, registration_date
                   FROM registration 
                   WHERE academic_year = %s AND registration_status = 'active'
                   ORDER BY student_id, semester""",
                (academic_year,)
            )
            
            if not registration_results:
                logging.warning(f"⚠️ No registrations found for {academic_year}")
                return []
            
            # Get all classes for this academic year
            class_results = self.db.execute_query(
                """SELECT c.class_id, c.course_id, c.semester, c.capacity, c.enrolled_count,
                          co.credits, co.program_id
                   FROM class c
                   JOIN course co ON c.course_id = co.id
                   WHERE c.academic_year = %s AND c.class_status = 'active'
                   ORDER BY c.semester, co.program_id""",
                (academic_year,)
            )
            
            if not class_results:
                logging.warning(f"⚠️ No classes found for {academic_year}")
                return []
            
            enrollments = []
            enrollment_counter = 1
            
            # Create a mapping of classes by semester and program
            classes_by_semester_program = {}
            for class_id, course_id, semester, capacity, enrolled_count, credits, program_id in class_results:
                key = f"{semester}_{program_id}"
                if key not in classes_by_semester_program:
                    classes_by_semester_program[key] = []
                classes_by_semester_program[key].append({
                    'class_id': class_id,
                    'course_id': course_id,
                    'credits': credits,
                    'capacity': capacity,
                    'enrolled_count': enrolled_count
                })
            
            # Generate enrollments for each registration
            for registration_id, student_id, semester, total_sks, reg_date in registration_results:
                # Get student's program
                student_program = self.db.execute_query(
                    "SELECT program_id FROM students WHERE student_id = %s",
                    (student_id,)
                )
                
                if not student_program:
                    continue
                    
                program_id = student_program[0][0]
                
                # Get available classes for this semester and program
                key = f"{semester}_{program_id}"
                available_classes = classes_by_semester_program.get(key, [])
                
                if not available_classes:
                    # Try to get classes from the same semester regardless of program
                    available_classes = []
                    for k, v in classes_by_semester_program.items():
                        if k.startswith(f"{semester}_"):
                            available_classes.extend(v)
                
                if not available_classes:
                    logging.warning(f"⚠️ No available classes for student {student_id} semester {semester}")
                    continue
                
                # Calculate how many classes to enroll based on target SKS
                current_sks = 0
                enrolled_classes = []
                
                # Shuffle available classes for randomness
                random.shuffle(available_classes)
                
                for class_info in available_classes:
                    if current_sks >= total_sks:
                        break
                        
                    # Check if class has capacity
                    if class_info['enrolled_count'] >= class_info['capacity']:
                        continue
                    
                    # Enroll in this class
                    enrolled_classes.append(class_info)
                    current_sks += class_info['credits']
                    
                    # Stop if we've reached the target SKS
                    if current_sks >= total_sks:
                        break
                
                # Generate enrollment records
                for class_info in enrolled_classes:
                    enrollment_date = reg_date + timedelta(days=random.randint(0, 7))  # Within a week of registration
                    
                    # Generate grades (some might not have grades yet)
                    has_grade = random.random() < 0.8  # 80% have grades
                    final_grade = None
                    grade_point = None
                    
                    if has_grade:
                        # Generate realistic grade distribution
                        grade_rand = random.random()
                        if grade_rand < 0.05:      # 5% A
                            final_grade = random.uniform(85, 100)
                            grade_point = 4.0
                        elif grade_rand < 0.20:    # 15% B+
                            final_grade = random.uniform(80, 84)
                            grade_point = 3.5
                        elif grade_rand < 0.45:    # 25% B
                            final_grade = random.uniform(75, 79)
                            grade_point = 3.0
                        elif grade_rand < 0.70:    # 25% C+
                            final_grade = random.uniform(70, 74)
                            grade_point = 2.5
                        elif grade_rand < 0.90:    # 20% C
                            final_grade = random.uniform(65, 69)
                            grade_point = 2.0
                        else:                      # 10% D or E
                            final_grade = random.uniform(40, 64)
                            grade_point = random.choice([1.0, 0.0])
                    
                    attendance_percentage = random.uniform(70, 100) if has_grade else None
                    
                    enrollments.append((
                        enrollment_counter,  # enrollment_id (will be removed during insertion)
                        student_id,
                        registration_id,
                        class_info['class_id'],
                        enrollment_date,
                        'enrolled',
                        final_grade,
                        grade_point,
                        attendance_percentage,
                        datetime.now(),
                        datetime.now()
                    ))
                    
                    enrollment_counter += 1
            
            logging.info(f"✅ Generated {len(enrollments)} enrollments")
            return enrollments
            
        except Exception as e:
            logging.error(f"❌ Error generating enrollments: {e}")
            raise

def get_enrollment_generator():
    """Factory function to get enrollment generator instance"""
    return EnrollmentGenerator() 