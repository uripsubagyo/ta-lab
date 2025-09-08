-- =================================================================
-- STEP 3: TEST ICEBERG WITH FILE-BASED CATALOG
-- Simplified approach without Polaris for initial testing
-- =================================================================

-- Create Iceberg file-based catalog (simpler than REST)
CREATE CATALOG IF NOT EXISTS iceberg_catalog WITH (
  'type' = 'iceberg',
  'catalog-type' = 'hadoop',
  'warehouse' = 's3://warehouse/iceberg',
  's3.endpoint' = 'http://minio:9000',
  's3.region' = 'dummy-region',
  's3.access-key-id' = 'admin',
  's3.secret-access-key' = 'password',
  's3.path-style-access' = 'true'
);

-- Switch to Iceberg catalog
USE CATALOG iceberg_catalog;

-- Create database
CREATE DATABASE IF NOT EXISTS university;

-- Use database
USE university;

-- Create Kafka source table
CREATE TABLE kafka_faculty_source (
    id BIGINT,
    faculty_code STRING,
    faculty_name STRING,
    created_at BIGINT,
    `__op` STRING,
    `__ts_ms` BIGINT
) WITH (
    'connector' = 'kafka',
    'topic' = 'university-server.public.faculty',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'properties.group.id' = 'flink-iceberg-consumer',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'debezium-json'
);

-- Create Iceberg table  
CREATE TABLE IF NOT EXISTS faculty_iceberg (
    id BIGINT,
    faculty_code STRING,
    faculty_name STRING,
    created_at BIGINT,
    operation STRING,
    process_time TIMESTAMP(3)
) WITH (
    'connector' = 'iceberg',
    'catalog-name' = 'iceberg_catalog',
    'database-name' = 'university',
    'table-name' = 'faculty_iceberg'
);

-- Test streaming insert: Kafka → Iceberg
INSERT INTO faculty_iceberg
SELECT 
    id,
    faculty_code,
    faculty_name,
    created_at,
    `__op` as operation,
    PROCTIME() as process_time
FROM kafka_faculty_source
WHERE `__op` IN ('c', 'r', 'u'); 