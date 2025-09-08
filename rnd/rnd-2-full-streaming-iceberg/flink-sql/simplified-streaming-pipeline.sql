-- ==========================================
-- SIMPLIFIED UNIVERSITY STREAMING PIPELINE
-- Using CREATE TABLE AS SELECT (CTAS) approach
-- ==========================================

-- 1. CREATE CATALOGS
-- ==========================================

-- Kafka Catalog for source tables
CREATE CATALOG kafka_catalog WITH ('type'='generic_in_memory');
CREATE DATABASE kafka_catalog.university_db;

-- Polaris/Iceberg Catalog for destination tables  
CREATE CATALOG polaris_catalog WITH (
    'type'='iceberg',
    'catalog-type'='rest',
    'uri'='http://polaris:8181/api/catalog',
    'warehouse'='polariscatalog',
    'oauth2-server-uri'='http://polaris:8181/api/catalog/v1/oauth/tokens',
    'credential'='root:secret',
    'scope'='PRINCIPAL_ROLE:ALL'
);

-- Create database in Iceberg catalog
CREATE DATABASE polaris_catalog.university_lakehouse;

-- 2. KAFKA SOURCE TABLES (from Debezium CDC)
-- ==========================================

-- Faculty Table
CREATE TABLE kafka_catalog.university_db.faculty (
    id INT,
    faculty_code STRING,
    faculty_name STRING,
    created_at TIMESTAMP(3),
    WATERMARK FOR created_at AS created_at - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'topic' = 'dbserver1.university.faculty'
);

-- Program Table
CREATE TABLE kafka_catalog.university_db.program (
    id INT,
    program_code STRING,
    program_name STRING,
    faculty_id INT,
    degree_level STRING,
    created_at TIMESTAMP(3),
    WATERMARK FOR created_at AS created_at - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'topic' = 'dbserver1.university.program'
);

-- Students Table
CREATE TABLE kafka_catalog.university_db.students (
    id INT,
    student_id STRING,
    first_name STRING,
    last_name STRING,
    email STRING,
    phone STRING,
    program_id INT,
    admission_year INT,
    status STRING,
    created_at TIMESTAMP(3),
    WATERMARK FOR created_at AS created_at - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'topic' = 'dbserver1.university.students'
);

-- Add other tables as needed...

-- 3. CONFIGURE CHECKPOINTING
-- ==========================================
SET 'execution.checkpointing.interval' = '10s';
SET 'execution.checkpointing.mode' = 'EXACTLY_ONCE';
SET 'execution.checkpointing.timeout' = '60s';

-- 4. CREATE ICEBERG TABLES WITH STREAMING JOBS (CTAS)
-- ==========================================

-- Faculty: Auto schema + streaming job in one command
CREATE TABLE polaris_catalog.university_lakehouse.faculty AS  
    SELECT 
        id,
        faculty_code,
        faculty_name,
        created_at,
        CURRENT_TIMESTAMP as ingestion_time
    FROM kafka_catalog.university_db.faculty;

-- Program: Auto schema + streaming job
CREATE TABLE polaris_catalog.university_lakehouse.program AS  
    SELECT 
        id,
        program_code,
        program_name,
        faculty_id,
        degree_level,
        created_at,
        CURRENT_TIMESTAMP as ingestion_time
    FROM kafka_catalog.university_db.program;

-- Students: Auto schema + streaming job
CREATE TABLE polaris_catalog.university_lakehouse.students AS  
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

-- 5. VERIFICATION QUERIES
-- ==========================================
SHOW CATALOGS;
SHOW TABLES FROM kafka_catalog.university_db;
SHOW TABLES FROM polaris_catalog.university_lakehouse;

-- Check streaming job status
SHOW JOBS;

-- Test data flow
SELECT COUNT(*) as total_faculty FROM polaris_catalog.university_lakehouse.faculty;
SELECT COUNT(*) as total_students FROM polaris_catalog.university_lakehouse.students; 