-- =================================================================
-- STUDENT FEE TABLE STREAMING JOB
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

-- Student Fee Kafka Source
CREATE TABLE IF NOT EXISTS kafka_student_fee (
  fee_id STRING,
  student_id STRING,
  ukt_fee DECIMAL(12,2),
  bop_fee DECIMAL(12,2),
  updated_at TIMESTAMP(3),
  op STRING,
  ts_ms BIGINT,
  PRIMARY KEY (fee_id) NOT ENFORCED
) WITH (
  'connector' = 'kafka',
  'topic' = 'university-server.public.student_fee',
  'properties.bootstrap.servers' = 'kafka-broker:29092',
  'properties.group.id' = 'flink-student-fee-consumer',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'debezium-json'
);

-- Student Fee Iceberg Sink
CREATE TABLE IF NOT EXISTS iceberg_student_fee (
  fee_id STRING,
  student_id STRING,
  ukt_fee DECIMAL(12,2),
  bop_fee DECIMAL(12,2),
  updated_at TIMESTAMP(3),
  ingestion_time TIMESTAMP(3),
  PRIMARY KEY (fee_id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'student_fee'
);

-- Student Fee Streaming Job
INSERT INTO iceberg_student_fee
SELECT 
  fee_id,
  student_id,
  ukt_fee,
  bop_fee,
  updated_at,
  CURRENT_TIMESTAMP as ingestion_time
FROM kafka_student_fee
WHERE op IN ('r', 'c', 'u'); 