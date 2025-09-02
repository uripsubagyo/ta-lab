-- =================================================================
-- FACULTY TABLE STREAMING JOB
-- PostgreSQL → Debezium → Kafka → Flink → Iceberg → MinIO
-- =================================================================

-- Create Iceberg catalog in Flink with Polaris
CREATE CATALOG IF NOT EXISTS iceberg_catalog WITH (
  'type' = 'iceberg',
  'catalog-type' = 'rest',
  'uri' = 'http://polaris:8181/api/catalog/',
  'warehouse' = 'polariscatalog',
  'credential' = 'root:secret',
  'scope' = 'PRINCIPAL_ROLE:ALL',
  's3.endpoint' = 'http://minio:9000',
  's3.region' = 'dummy-region',
  's3.access-key-id' = 'admin',
  's3.secret-access-key' = 'password'
);

-- Use the Iceberg catalog
USE CATALOG iceberg_catalog;

-- Create namespace/database
CREATE DATABASE IF NOT EXISTS university;
USE university;

-- Faculty Kafka Source
CREATE TABLE IF NOT EXISTS kafka_faculty (
  id INT,
  faculty_code STRING,
  faculty_name STRING,
  created_at TIMESTAMP(3),
  op STRING,
  ts_ms BIGINT,
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector' = 'kafka',
  'topic' = 'university-server.public.faculty',
  'properties.bootstrap.servers' = 'kafka-broker:29092',
  'properties.group.id' = 'flink-faculty-consumer',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'debezium-json'
);

-- Faculty Iceberg Sink
CREATE TABLE IF NOT EXISTS iceberg_faculty (
  id INT,
  faculty_code STRING,
  faculty_name STRING,
  created_at TIMESTAMP(3),
  ingestion_time TIMESTAMP(3),
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'faculty'
);

-- Faculty Streaming Job
INSERT INTO iceberg_faculty
SELECT 
  id,
  faculty_code,
  faculty_name,
  created_at,
  CURRENT_TIMESTAMP as ingestion_time
FROM kafka_faculty
WHERE op IN ('r', 'c', 'u'); 