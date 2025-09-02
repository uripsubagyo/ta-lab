-- =================================================================
-- START STREAMING JOB: Kafka → Iceberg
-- =================================================================

-- Insert streaming job untuk transfer data dari Kafka ke Iceberg
INSERT INTO iceberg_catalog.university.students_iceberg
SELECT 
    student_id, 
    full_name, 
    entry_year, 
    program_id, 
    degree, 
    faculty_id, 
    status, 
    created_at
FROM default_catalog.default_database.kafka_students
WHERE op != 'd';  -- Exclude deletes 