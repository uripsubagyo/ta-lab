"""Student generator for university database"""

import logging
import random
from datetime import datetime, date
from faker import Faker
import static_data
import db_utils

fake = Faker('id_ID')  # Indonesian locale

class StudentGenerator:
    def __init__(self):
        self.db = db_utils.get_db_manager()
        
    def generate_students_for_year(self, entry_year, target_count=4500):
        """Generate students for a specific entry year"""
        try:
            logging.info(f"👥 Generating {target_count} students for entry year {entry_year}")
            
            # Get available programs
            program_results = self.db.execute_query(
                "SELECT id, program_code, faculty_id, degree FROM program ORDER BY id"
            )
            
            if not program_results:
                raise Exception("❌ No programs found in database")
            
            students = []
            student_details = []
            student_fees = []
            
            # Generate NPM pattern: {entry_year}{program_code}{sequence}
            npm_counters = {}  # Track NPM sequence per program
            
            for i in range(target_count):
                # Select random program
                program_id, program_code, faculty_id, degree = random.choice(program_results)
                
                # Generate NPM
                if program_code not in npm_counters:
                    npm_counters[program_code] = 1
                else:
                    npm_counters[program_code] += 1
                
                # NPM format: last 2 digits of year + program identifier + sequence
                year_suffix = str(entry_year)[-2:]
                program_identifier = program_code[:3].upper()  # First 3 chars
                sequence = f"{npm_counters[program_code]:04d}"
                npm = f"{year_suffix}{program_identifier}{sequence}"
                
                # Generate student basic data
                full_name = fake.name()
                
                students.append((
                    npm,  # student_id (NPM)
                    full_name,
                    entry_year,
                    program_id,
                    degree,
                    faculty_id,
                    'active',
                    datetime.now()
                ))
                
                # Generate detailed student data
                gender = random.choice(static_data.GENDERS)
                birth_date = fake.date_of_birth(minimum_age=17, maximum_age=22)
                birth_place = random.choice(static_data.INDONESIAN_CITIES)
                religion = random.choice(static_data.RELIGIONS)
                registration_date = date(entry_year, random.randint(8, 9), random.randint(1, 28))
                
                student_details.append((
                    i + 1,  # student_detail_id (will be removed during insertion)
                    npm,    # student_id
                    gender,
                    birth_date,
                    birth_place,
                    religion,
                    'Indonesia',  # nationality
                    registration_date,
                    fake.address(),  # address
                    random.choice(static_data.INDONESIAN_CITIES),  # city
                    random.choice(static_data.INDONESIAN_PROVINCES),  # province
                    fake.postcode(),  # postal_code
                    fake.phone_number(),  # phone_number
                    fake.company(),  # high_school (using company as school name)
                    entry_year - 1,  # high_school_year
                    fake.name(),  # parent_name
                    random.randint(3000000, 15000000),  # parent_income (3-15 million IDR)
                    fake.job(),  # parent_occupation
                    random.choice(static_data.BLOOD_TYPES),  # blood_type
                    random.choice(['BPJS', 'Swasta', 'Tidak Ada']),  # health_insurance
                    random.choice(['Kos', 'Rumah Sendiri', 'Asrama'])  # accommodation
                ))
                
                # Generate student fees
                fee_id = f"FEE-{npm}-{entry_year}"
                ukt_fee = random.randint(5000000, 12500000)  # 5-12.5 million IDR
                bop_fee = random.randint(25000000, 100000000)  # 25-100 million IDR
                
                student_fees.append((
                    fee_id,
                    npm,  # student_id
                    ukt_fee,
                    bop_fee,
                    datetime.now()
                ))
            
            logging.info(f"✅ Generated {len(students)} students with details and fees")
            return students, student_details, student_fees
            
        except Exception as e:
            logging.error(f"❌ Error generating students: {e}")
            raise

def get_student_generator():
    """Factory function to get student generator instance"""
    return StudentGenerator() 