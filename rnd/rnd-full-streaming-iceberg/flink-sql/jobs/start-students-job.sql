-- =================================================================
-- START STUDENTS STREAMING JOB
-- This script starts the streaming job ONLY for students table
-- =================================================================

USE CATALOG iceberg_catalog;
USE university;

-- Start Students Streaming Job
INSERT INTO iceberg_students
SELECT 
  student_id,
  full_name,
  entry_year,
  program_id,
  degree,
  faculty_id,
  status,
  created_at,
  CURRENT_TIMESTAMP as ingestion_time
FROM kafka_students
WHERE op IN ('r', 'c', 'u'); 