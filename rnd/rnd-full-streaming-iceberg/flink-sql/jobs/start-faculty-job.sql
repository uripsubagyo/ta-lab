-- =================================================================
-- START FACULTY STREAMING JOB
-- This script starts the streaming job ONLY for faculty table
-- =================================================================

USE CATALOG iceberg_catalog;
USE university;

-- Start Faculty Streaming Job
INSERT INTO iceberg_faculty
SELECT 
  id,
  faculty_code,
  faculty_name,
  created_at,
  CURRENT_TIMESTAMP as ingestion_time
FROM kafka_faculty
WHERE op IN ('r', 'c', 'u'); 