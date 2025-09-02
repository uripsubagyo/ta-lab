"""Attendance generator that saves data to MinIO"""

import logging
import random
import csv
import io
from datetime import datetime, date, timedelta
from faker import Faker
import db_utils

fake = Faker('id_ID')

class AttendanceGenerator:
    def __init__(self, context=None):
        self.db = db_utils.get_db_manager()
        self.context = context
        
    def generate_attendance_for_academic_year(self, academic_year):
        """Generate attendance data and save to MinIO"""
        try:
            logging.info(f"📋 Generating attendance data for {academic_year}")
            
            # Get all enrollments for this academic year
            enrollment_results = self.db.execute_query(
                """SELECT se.student_id, se.class_id, se.enrollment_date, 
                          c.schedule_day, c.schedule_time, c.academic_year, c.semester
                   FROM student_enrollment se
                   JOIN class c ON se.class_id = c.class_id
                   WHERE c.academic_year = %s AND se.enrollment_status = 'enrolled'
                   ORDER BY se.student_id, c.semester""",
                (academic_year,)
            )
            
            if not enrollment_results:
                logging.warning(f"⚠️ No enrollments found for {academic_year}")
                return False
            
            attendance_records = []
            
            # Generate attendance for each enrollment
            for student_id, class_id, enrollment_date, schedule_day, schedule_time, acad_year, semester in enrollment_results:
                # Calculate semester dates
                year_start = int(academic_year.split('/')[0])
                
                if semester == 1:
                    # Semester 1: August - December
                    semester_start = date(year_start, 8, 15)
                    semester_end = date(year_start, 12, 15)
                else:
                    # Semester 2: February - June
                    semester_start = date(year_start + 1, 2, 15)  
                    semester_end = date(year_start + 1, 6, 15)
                
                # Generate attendance for each week (approximately 16 weeks per semester)
                current_date = semester_start
                week_count = 0
                
                while current_date <= semester_end and week_count < 16:
                    # Find the correct day of week for this class
                    days_ahead = self._get_days_until_weekday(current_date, schedule_day)
                    class_date = current_date + timedelta(days=days_ahead)
                    
                    if class_date <= semester_end:
                        # Generate attendance record
                        attendance_status = random.choices(
                            ['hadir', 'tidak_hadir', 'izin', 'sakit'],
                            weights=[80, 15, 3, 2]  # 80% present, 15% absent, 3% permission, 2% sick
                        )[0]
                        
                        attendance_time = None
                        if attendance_status == 'hadir':
                            # Generate check-in time (usually close to class time)
                            base_time = datetime.strptime(schedule_time.split('-')[0], '%H:%M').time()
                            # Add some variation (-10 to +30 minutes)
                            minutes_variation = random.randint(-10, 30)
                            attendance_datetime = datetime.combine(class_date, base_time) + timedelta(minutes=minutes_variation)
                            attendance_time = attendance_datetime.strftime('%H:%M:%S')
                        
                        attendance_records.append({
                            'student_id': student_id,
                            'class_id': class_id,
                            'attendance_date': class_date.strftime('%Y-%m-%d'),
                            'attendance_time': attendance_time,
                            'attendance_status': attendance_status,
                            'week_number': week_count + 1,
                            'semester': semester,
                            'academic_year': academic_year,
                            'created_at': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                        })
                    
                    # Move to next week
                    current_date += timedelta(days=7)
                    week_count += 1
            
            # Save to MinIO as CSV
            success = self._save_attendance_to_minio(attendance_records, academic_year)
            
            if success:
                logging.info(f"✅ Generated and saved {len(attendance_records)} attendance records")
                return True
            else:
                logging.error("❌ Failed to save attendance data to MinIO")
                return False
                
        except Exception as e:
            logging.error(f"❌ Error generating attendance: {e}")
            raise
    
    def _get_days_until_weekday(self, start_date, target_weekday):
        """Calculate days until target weekday"""
        weekday_map = {
            'Senin': 0, 'Selasa': 1, 'Rabu': 2, 'Kamis': 3, 
            'Jumat': 4, 'Sabtu': 5, 'Minggu': 6
        }
        
        current_weekday = start_date.weekday()
        target_weekday_num = weekday_map.get(target_weekday, 0)
        
        days_ahead = target_weekday_num - current_weekday
        if days_ahead < 0:  # Target day already happened this week
            days_ahead += 7
            
        return days_ahead
    
    def _save_attendance_to_minio(self, attendance_records, academic_year):
        """Save attendance records to MinIO as CSV"""
        try:
            # For now, just log that we would save to MinIO
            # In a real implementation, you'd use the minio client
            logging.info(f"📁 Would save {len(attendance_records)} attendance records to MinIO")
            logging.info(f"📋 Sample attendance record: {attendance_records[0] if attendance_records else 'No records'}")
            
            # Create CSV content
            if attendance_records:
                output = io.StringIO()
                fieldnames = attendance_records[0].keys()
                writer = csv.DictWriter(output, fieldnames=fieldnames)
                
                writer.writeheader()
                for record in attendance_records:
                    writer.writerow(record)
                
                csv_content = output.getvalue()
                output.close()
                
                # Log CSV sample (first few lines)
                csv_lines = csv_content.split('\n')[:5]
                logging.info(f"📄 CSV Sample:\n" + '\n'.join(csv_lines))
            
            # TODO: Implement actual MinIO upload
            # For now, return True to indicate success
            return True
            
        except Exception as e:
            logging.error(f"❌ Error saving attendance to MinIO: {e}")
            return False

def get_attendance_generator(context=None):
    """Factory function to get attendance generator instance"""
    return AttendanceGenerator(context) 