-- =================================================================
-- START STREAMING JOBS
-- These INSERT statements create continuous streaming jobs
-- =================================================================

-- Stream students data from Kafka to Iceberg
INSERT INTO iceberg_catalog.university.students_iceberg
SELECT student_id, full_name, entry_year, program_id, degree, faculty_id, status, created_at
FROM default_catalog.default_database.kafka_students
WHERE op != 'd';  -- Exclude deletes 