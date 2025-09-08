-- ==========================================
-- STREAMING JOBS: Kafka → Iceberg
-- Transfer CDC data from Kafka to Iceberg tables
-- ==========================================

-- ⚠️  IMPORTANT: Run setup-university-streaming-pipeline.sql first!

-- 1. Faculty streaming job
INSERT INTO polaris_catalog.university_lakehouse.faculty
SELECT 
    id,
    faculty_code,
    faculty_name,
    created_at,
    CURRENT_TIMESTAMP as ingestion_time
FROM kafka_catalog.university_db.faculty;

-- 2. Program streaming job
INSERT INTO polaris_catalog.university_lakehouse.program
SELECT 
    id,
    program_code,
    program_name,
    faculty_id,
    degree_level,
    created_at,
    CURRENT_TIMESTAMP as ingestion_time
FROM kafka_catalog.university_db.program;

-- 3. Students streaming job
INSERT INTO polaris_catalog.university_lakehouse.students
SELECT 
    id,
    student_id,
    first_name,
    last_name,
    email,
    phone,
    program_id,
    admission_year,
    status,
    created_at,
    CURRENT_TIMESTAMP as ingestion_time
FROM kafka_catalog.university_db.students;

-- 4. Class streaming job
INSERT INTO polaris_catalog.university_lakehouse.class
SELECT 
    id,
    class_code,
    class_name,
    course_id,
    lecturer_id,
    room_id,
    semester,
    academic_year,
    schedule_day,
    schedule_time,
    max_capacity,
    created_at,
    CURRENT_TIMESTAMP as ingestion_time
FROM kafka_catalog.university_db.class;

-- 5. Course streaming job
INSERT INTO polaris_catalog.university_lakehouse.course
SELECT 
    id,
    course_code,
    course_name,
    credits,
    program_id,
    prerequisite_course_id,
    created_at,
    CURRENT_TIMESTAMP as ingestion_time
FROM kafka_catalog.university_db.course;

-- 6. Lecturer streaming job
INSERT INTO polaris_catalog.university_lakehouse.lecturer
SELECT 
    id,
    lecturer_id,
    first_name,
    last_name,
    email,
    phone,
    faculty_id,
    specialization,
    employment_status,
    created_at,
    CURRENT_TIMESTAMP as ingestion_time
FROM kafka_catalog.university_db.lecturer;

-- 7. Payment streaming job
INSERT INTO polaris_catalog.university_lakehouse.payment
SELECT 
    id,
    payment_id,
    student_id,
    amount,
    payment_type,
    payment_method,
    payment_date,
    semester,
    academic_year,
    status,
    created_at,
    CURRENT_TIMESTAMP as ingestion_time
FROM kafka_catalog.university_db.payment;

-- 8. Registration streaming job
INSERT INTO polaris_catalog.university_lakehouse.registration
SELECT 
    id,
    student_id,
    class_id,
    registration_date,
    semester,
    academic_year,
    status,
    grade,
    created_at,
    CURRENT_TIMESTAMP as ingestion_time
FROM kafka_catalog.university_db.registration;

-- 9. Room streaming job
INSERT INTO polaris_catalog.university_lakehouse.room
SELECT 
    id,
    room_code,
    room_name,
    building,
    floor_number,
    capacity,
    room_type,
    facilities,
    created_at,
    CURRENT_TIMESTAMP as ingestion_time
FROM kafka_catalog.university_db.room;

-- 10. Student Detail streaming job
INSERT INTO polaris_catalog.university_lakehouse.student_detail
SELECT 
    id,
    student_id,
    address,
    city,
    province,
    postal_code,
    date_of_birth,
    place_of_birth,
    gender,
    nationality,
    religion,
    created_at,
    CURRENT_TIMESTAMP as ingestion_time
FROM kafka_catalog.university_db.student_detail;

-- 11. Student Enrollment streaming job
INSERT INTO polaris_catalog.university_lakehouse.student_enrollment
SELECT 
    id,
    student_id,
    semester,
    academic_year,
    enrollment_date,
    status,
    total_credits,
    gpa,
    created_at,
    CURRENT_TIMESTAMP as ingestion_time
FROM kafka_catalog.university_db.student_enrollment;

-- 12. Student Fee streaming job
INSERT INTO polaris_catalog.university_lakehouse.student_fee
SELECT 
    id,
    student_id,
    fee_type,
    amount,
    semester,
    academic_year,
    due_date,
    status,
    created_at,
    CURRENT_TIMESTAMP as ingestion_time
FROM kafka_catalog.university_db.student_fee; 