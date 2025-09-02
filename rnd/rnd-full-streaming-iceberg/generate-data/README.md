# University Data Generation System

This folder contains the separated university data generation system that works with the PostgreSQL container defined in `docker-compose.yml`.

## Architecture

The system is now split into focused, modular components:

### Core Modules
- **`db_utils.py`** - Database connection and utilities
- **`static_data.py`** - Static university data and utilities  
- **`master_data_generator.py`** - Generates faculties, programs, lecturers, rooms, courses
- **`student_generator.py`** - Generates students, student details, and fees
- **`academic_generator.py`** - Generates registrations and classes
- **`enrollment_generator.py`** - Links students to classes
- **`payment_generator.py`** - Generates payment records
- **`attendance_generator.py`** - Generates attendance data (saves to MinIO)

### Runner Scripts
- **`run_db_connection_test.py`** - Test database connectivity
- **`run_master_data_setup.py`** - Setup master data only
- **`run_student_generation.py`** - Generate students for a specific year
- **`run_academic_data_generation.py`** - Generate registrations and classes
- **`run_complete_generation.py`** - Run the complete pipeline
- **`setup_and_run.py`** - Complete setup including schema creation

### Legacy Files
- **`__main__.py`** - Original monolithic Airflow DAG (kept for reference)
- **`_1_db_connection.py`** - Partial implementation (deprecated)
- **`_2_setup_master_data.py`** - Partial implementation (deprecated)

## Database Schema

The system uses the university schema defined in:
- **`../init-scripts/init-university-schema.sql`** - Complete university database schema

Key tables:
- `faculty` - University faculties
- `program` - Study programs 
- `students` - Student records
- `student_detail` - Detailed student information
- `student_fee` - Student fee information
- `lecturer` - Lecturer records
- `room` - Classroom information
- `course` - Course catalog
- `registration` - Semester registrations
- `class` - Class schedules
- `student_enrollment` - Student-class enrollments
- `payment` - Payment records

## Usage

### Prerequisites

1. **Start the PostgreSQL container:**
   ```bash
   cd /path/to/rnd-full-streaming-iceberg
   docker-compose up -d postgres
   ```

2. **Install Python dependencies:**
   ```bash
   cd generate-data
   pip install -r requirements.txt
   ```

### Quick Start (Complete Setup)

Run the complete setup and data generation:
```bash
python setup_and_run.py
```

This will:
1. Setup the university database schema
2. Generate master data
3. Generate 500 students for the current academic year
4. Generate academic data (registrations and classes)

### Individual Component Usage

**1. Test Database Connection:**
```bash
python run_db_connection_test.py
```

**2. Setup Master Data Only:**
```bash
python run_master_data_setup.py
```

**3. Generate Students for Specific Year:**
```bash
# Generate 1000 students for 2024
python run_student_generation.py --year 2024 --count 1000
```

**4. Generate Academic Data:**
```bash
# Generate for specific academic year
python run_academic_data_generation.py --year 2024/2025
```

**5. Run Complete Pipeline:**
```bash
# Generate 2000 students for current academic year
python run_complete_generation.py --count 2000

# Force regeneration even if data exists
python run_complete_generation.py --count 1000 --force

# Generate for specific academic year
python run_complete_generation.py --year 2023/2024 --count 1500
```

## Configuration

### Environment Variables

You can configure database connection using environment variables:

```bash
export DB_HOST="localhost"      # Database host
export DB_PORT="5432"          # Database port  
export DB_NAME="sourcedb"      # Database name
export DB_USER="postgres"      # Database user
export DB_PASSWORD="postgres"  # Database password
```

### Data Generation Settings

- **Student Count**: Configurable via `--count` parameter (default: 1000)
- **Academic Year**: Auto-detected or specify via `--year` parameter
- **Skip Existing**: By default, skips generation if data already exists (use `--force` to override)

## Database Connection

The system connects to PostgreSQL using the configuration from `docker-compose.yml`:
- Host: `localhost` (when running containers)
- Port: `5432`
- Database: `sourcedb`
- User: `postgres` 
- Password: `postgres`

## Data Generation Flow

1. **Master Data** → Faculties, Programs, Lecturers, Rooms, Courses
2. **Students** → Students, Student Details, Student Fees
3. **Academic Data** → Registrations, Classes (for both semesters)
4. **Enrollments** → Student-Class linkages with grades
5. **Payments** → UKT, BOP, Late fees
6. **Attendance** → Weekly attendance records (saved to MinIO/CSV)

## Troubleshooting

### Connection Issues
- Ensure PostgreSQL container is running: `docker ps`
- Check container logs: `docker logs <container_name>`
- Verify database configuration in environment variables

### Missing Dependencies
```bash
pip install psycopg2-binary faker
```

### Schema Issues
- The system will create tables automatically via `init-university-schema.sql`
- If tables exist but with wrong schema, drop and recreate the database

### Data Issues
- Use `--force` flag to regenerate existing data
- Check logs for specific error details
- Verify master data exists before generating students 