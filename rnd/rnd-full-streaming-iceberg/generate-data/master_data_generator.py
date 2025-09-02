"""Master data generator for university database"""

import logging
import random
from datetime import datetime
from faker import Faker
import static_data
import db_utils

fake = Faker('id_ID')  # Indonesian locale

class MasterDataGenerator:
    def __init__(self):
        self.db = db_utils.get_db_manager()
        
    def setup_master_data(self):
        """Setup all master data in correct order"""
        try:
            logging.info("🏗️ Starting master data setup...")
            
            # Setup in dependency order
            self._setup_faculties()
            self._setup_programs()
            self._setup_lecturers()
            self._setup_rooms()
            self._setup_courses()
            
            logging.info("✅ Master data setup completed!")
            return True
            
        except Exception as e:
            logging.error(f"❌ Master data setup failed: {e}")
            return False
    
    def _setup_faculties(self):
        """Setup faculty master data"""
        try:
            logging.info("🏛️ Setting up faculties...")
            
            if self.db.table_exists('faculty'):
                existing_count = self.db.execute_query("SELECT COUNT(*) FROM faculty")[0][0]
                if existing_count > 0:
                    logging.info(f"✅ Faculties already exist ({existing_count} records), skipping...")
                    return
            
            faculties_data = []
            for i, faculty_info in enumerate(static_data.get_faculty_data(), 1):
                faculties_data.append((
                    faculty_info['code'],
                    faculty_info['name'],
                    datetime.now()
                ))
            
            columns = ['faculty_code', 'faculty_name', 'created_at']
            inserted_count = self.db.bulk_insert_data('faculty', columns, faculties_data)
            logging.info(f"✅ Inserted {inserted_count} faculties")
            
        except Exception as e:
            logging.error(f"❌ Error setting up faculties: {e}")
            raise
    
    def _setup_programs(self):
        """Setup program master data"""
        try:
            logging.info("🎓 Setting up programs...")
            
            if self.db.table_exists('program'):
                existing_count = self.db.execute_query("SELECT COUNT(*) FROM program")[0][0]
                if existing_count > 0:
                    logging.info(f"✅ Programs already exist ({existing_count} records), skipping...")
                    return
            
            # Get faculty IDs from database
            faculty_results = self.db.execute_query("SELECT id, faculty_code FROM faculty ORDER BY id")
            faculty_map = {code: id for id, code in faculty_results}
            
            programs_data = []
            
            for faculty_code, programs in static_data.get_program_data().items():
                if faculty_code in faculty_map:
                    faculty_id = faculty_map[faculty_code]
                    for program_info in programs:
                        programs_data.append((
                            program_info['code'],
                            program_info['name'],
                            faculty_id,
                            program_info['degree'],
                            datetime.now()
                        ))
            
            columns = ['program_code', 'program_name', 'faculty_id', 'degree', 'created_at']
            inserted_count = self.db.bulk_insert_data('program', columns, programs_data)
            logging.info(f"✅ Inserted {inserted_count} programs")
            
        except Exception as e:
            logging.error(f"❌ Error setting up programs: {e}")
            raise
    
    def _setup_lecturers(self):
        """Setup lecturer master data"""
        try:
            logging.info("👨‍🏫 Setting up lecturers...")
            
            if self.db.table_exists('lecturer'):
                existing_count = self.db.execute_query("SELECT COUNT(*) FROM lecturer")[0][0]
                if existing_count > 0:
                    logging.info(f"✅ Lecturers already exist ({existing_count} records), skipping...")
                    return
            
            # Get faculty IDs
            faculty_results = self.db.execute_query("SELECT id, faculty_code FROM faculty ORDER BY id")
            faculty_ids = [id for id, code in faculty_results]
            
            lecturers_data = []
            lecturer_count = 100  # Generate 100 lecturers
            
            for i in range(1, lecturer_count + 1):
                lecturer_id = f"L{i:04d}"  # L0001, L0002, etc.
                name = fake.name()
                email = f"{name.lower().replace(' ', '.')}@ui.ac.id"
                faculty_id = random.choice(faculty_ids)
                
                lecturers_data.append((
                    lecturer_id,
                    name,
                    email,
                    faculty_id,
                    datetime.now()
                ))
            
            columns = ['lecturer_id', 'name', 'email', 'faculty_id', 'created_at']
            inserted_count = self.db.bulk_insert_data('lecturer', columns, lecturers_data)
            logging.info(f"✅ Inserted {inserted_count} lecturers")
            
        except Exception as e:
            logging.error(f"❌ Error setting up lecturers: {e}")
            raise
    
    def _setup_rooms(self):
        """Setup room master data"""
        try:
            logging.info("🏢 Setting up rooms...")
            
            if self.db.table_exists('room'):
                existing_count = self.db.execute_query("SELECT COUNT(*) FROM room")[0][0]
                if existing_count > 0:
                    logging.info(f"✅ Rooms already exist ({existing_count} records), skipping...")
                    return
            
            rooms_data = []
            buildings = ['Fasilkom', 'Teknik', 'FMIPA', 'FEB', 'Gedung A', 'Gedung B']
            
            room_count = 50
            for i in range(1, room_count + 1):
                building = random.choice(buildings)
                room_code = f"{building}-{i:03d}"
                capacity = random.randint(20, 80)
                
                rooms_data.append((
                    room_code,
                    building,
                    capacity,
                    datetime.now()
                ))
            
            columns = ['room_code', 'building', 'capacity', 'created_at']
            inserted_count = self.db.bulk_insert_data('room', columns, rooms_data)
            logging.info(f"✅ Inserted {inserted_count} rooms")
            
        except Exception as e:
            logging.error(f"❌ Error setting up rooms: {e}")
            raise
    
    def _setup_courses(self):
        """Setup course master data"""
        try:
            logging.info("📚 Setting up courses...")
            
            if self.db.table_exists('course'):
                existing_count = self.db.execute_query("SELECT COUNT(*) FROM course")[0][0]
                if existing_count > 0:
                    logging.info(f"✅ Courses already exist ({existing_count} records), skipping...")
                    return
            
            # Get program IDs
            program_results = self.db.execute_query("SELECT id, program_code FROM program ORDER BY id")
            
            courses_data = []
            course_templates = {
                'ILK-S1': [
                    ('ILK101', 'Dasar Pemrograman', 3),
                    ('ILK102', 'Struktur Data', 3),
                    ('ILK201', 'Algoritma', 4),
                    ('ILK202', 'Basis Data', 3),
                ],
                'SI-S1': [
                    ('SI101', 'SIM', 3),
                    ('SI102', 'Analisis Sistem', 3),
                    ('SI201', 'ERP', 4),
                    ('SI202', 'E-Business', 3),
                ],
                'TEK-S1': [
                    ('TEK101', 'Rangkaian', 3),
                    ('TEK102', 'Elektronika', 3),
                    ('TEK201', 'Sistem Digital', 4),
                ],
                'MAT-S1': [
                    ('MAT101', 'Kalkulus I', 4),
                    ('MAT102', 'Aljabar', 3),
                    ('MAT201', 'Kalkulus II', 4),
                ]
            }
            
            # Add courses for matching programs
            for program_id, program_code in program_results:
                if program_code in course_templates:
                    for course_code, course_name, credits in course_templates[program_code]:
                        courses_data.append((
                            course_code,
                            course_name,
                            credits,
                            program_id,
                            datetime.now()
                        ))
            
            # Add general courses
            general_courses = [
                ('UNI101', 'Bahasa Indonesia', 2),
                ('UNI102', 'Pancasila', 2),
                ('UNI103', 'Bahasa Inggris', 2),
                ('UNI104', 'Agama', 2),
            ]
            
            # Add general courses to first 4 programs
            for program_id, program_code in program_results[:4]:
                for course_code, course_name, credits in general_courses:
                    short_program = program_code[:3]  # First 3 chars
                    full_course_code = f"{course_code[:6]}{short_program}"  # No dash to save space
                    courses_data.append((
                        full_course_code,
                        course_name,
                        credits,
                        program_id,
                        datetime.now()
                    ))
            
            if courses_data:
                columns = ['course_code', 'course_name', 'credits', 'program_id', 'created_at']
                inserted_count = self.db.bulk_insert_data('course', columns, courses_data)
                logging.info(f"✅ Inserted {inserted_count} courses")
            else:
                logging.warning("⚠️ No course data to insert")
            
        except Exception as e:
            logging.error(f"❌ Error setting up courses: {e}")
            raise

def get_master_data_generator():
    """Factory function to get master data generator instance"""
    return MasterDataGenerator() 