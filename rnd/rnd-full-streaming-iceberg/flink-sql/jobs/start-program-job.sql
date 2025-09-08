-- =================================================================
-- START PROGRAM STREAMING JOB
-- This script starts the streaming job ONLY for program table
-- =================================================================

USE CATALOG iceberg_catalog;
USE university;

-- Start Program Streaming Job
INSERT INTO iceberg_program
SELECT 
  id,
  program_code,
  program_name,
  faculty_id,
  degree,
  created_at,
  CURRENT_TIMESTAMP as ingestion_time
FROM kafka_program
WHERE op IN ('r', 'c', 'u'); 