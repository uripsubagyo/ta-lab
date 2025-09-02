"""Static data module for university data generation"""

from datetime import datetime
import logging

def get_academic_year_from_execution_date(execution_date):
    """
    Determine academic year from execution date
    Academic year starts in August (e.g., 2024/2025 starts Aug 2024)
    """
    try:
        # Convert to datetime if it's not already
        if isinstance(execution_date, str):
            execution_date = datetime.fromisoformat(execution_date.replace('Z', '+00:00'))
        
        year = execution_date.year
        month = execution_date.month
        
        # If before August, we're in the previous academic year
        if month < 8:
            start_year = year - 1
        else:
            start_year = year
            
        academic_year = f"{start_year}/{start_year + 1}"
        logging.info(f"📅 Determined academic year: {academic_year} from date {execution_date}")
        return academic_year
        
    except Exception as e:
        logging.error(f"❌ Error determining academic year: {e}")
        # Fallback to current year
        current_year = datetime.now().year
        return f"{current_year}/{current_year + 1}"

def get_current_academic_year():
    """Get current academic year"""
    return get_academic_year_from_execution_date(datetime.now())

def get_semester_from_date(date_obj):
    """Determine semester from date (1 = odd/ganjil, 2 = even/genap)"""
    try:
        month = date_obj.month
        # Semester 1 (Ganjil): August - January
        # Semester 2 (Genap): February - July  
        if month >= 8 or month <= 1:
            return 1
        else:
            return 2
    except Exception as e:
        logging.error(f"❌ Error determining semester: {e}")
        return 1

# Static master data
INDONESIAN_CITIES = [
    'Jakarta', 'Surabaya', 'Bandung', 'Bekasi', 'Medan', 'Tangerang', 'Depok', 'Semarang',
    'Palembang', 'Makassar', 'South Tangerang', 'Batam', 'Bogor', 'Pekanbaru', 'Bandar Lampung'
]

INDONESIAN_PROVINCES = [
    'DKI Jakarta', 'Jawa Barat', 'Jawa Timur', 'Jawa Tengah', 'Sumatera Utara',
    'Sumatera Selatan', 'Sulawesi Selatan', 'Banten', 'Riau', 'Lampung'
]

RELIGIONS = ['Islam', 'Kristen Protestan', 'Katolik', 'Hindu', 'Buddha', 'Konghucu']

BLOOD_TYPES = ['A', 'B', 'AB', 'O']

GENDERS = ['L', 'P']  # L = Laki-laki, P = Perempuan

DAYS_OF_WEEK = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu']

TIME_SLOTS = [
    '07:00-08:40', '08:40-10:20', '10:30-12:10', '13:00-14:40', 
    '14:40-16:20', '16:30-18:10', '18:30-20:10'
]

UNIVERSITY_DATA = {
    'faculties': [
        {'code': 'FASILKOM', 'name': 'Fakultas Ilmu Komputer'},
        {'code': 'FT', 'name': 'Fakultas Teknik'},
        {'code': 'FMIPA', 'name': 'Fakultas Matematika dan Ilmu Pengetahuan Alam'},
        {'code': 'FEB', 'name': 'Fakultas Ekonomi dan Bisnis'},
        {'code': 'FHUI', 'name': 'Fakultas Hukum'},
        {'code': 'FIB', 'name': 'Fakultas Ilmu Budaya'},
        {'code': 'FISIP', 'name': 'Fakultas Ilmu Sosial dan Ilmu Politik'},
        {'code': 'FK', 'name': 'Fakultas Kedokteran'},
        {'code': 'FKG', 'name': 'Fakultas Kedokteran Gigi'},
        {'code': 'FKM', 'name': 'Fakultas Kesehatan Masyarakat'},
        {'code': 'FKUI', 'name': 'Fakultas Keperawatan'},
        {'code': 'FF', 'name': 'Fakultas Farmasi'},
        {'code': 'FPsi', 'name': 'Fakultas Psikologi'},
    ],
    'programs': {
        'FASILKOM': [
            {'code': 'ILK-S1', 'name': 'Ilmu Komputer S1', 'degree': 'S1'},
            {'code': 'SI-S1', 'name': 'Sistem Informasi S1', 'degree': 'S1'},
            {'code': 'ILK-S2', 'name': 'Ilmu Komputer S2', 'degree': 'S2'},
        ],
        'FT': [
            {'code': 'TEK-S1', 'name': 'Teknik Elektro S1', 'degree': 'S1'},
            {'code': 'TSI-S1', 'name': 'Teknik Sipil S1', 'degree': 'S1'},
            {'code': 'TME-S1', 'name': 'Teknik Mesin S1', 'degree': 'S1'},
        ],
        'FMIPA': [
            {'code': 'MAT-S1', 'name': 'Matematika S1', 'degree': 'S1'},
            {'code': 'FIS-S1', 'name': 'Fisika S1', 'degree': 'S1'},
            {'code': 'KIM-S1', 'name': 'Kimia S1', 'degree': 'S1'},
        ],
        'FEB': [
            {'code': 'MAN-S1', 'name': 'Manajemen S1', 'degree': 'S1'},
            {'code': 'AKT-S1', 'name': 'Akuntansi S1', 'degree': 'S1'},
            {'code': 'EKO-S1', 'name': 'Ekonomi S1', 'degree': 'S1'},
        ]
    }
}

def get_faculty_data():
    """Get faculty master data"""
    return UNIVERSITY_DATA['faculties']

def get_program_data():
    """Get program master data"""
    return UNIVERSITY_DATA['programs'] 