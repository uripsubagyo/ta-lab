-- =================================================================
-- DYNAMIC TABLE-SPECIFIC JOB MANAGER
-- This script creates table-specific streaming jobs that can be triggered dynamically
-- PostgreSQL → Debezium → Kafka → Flink → Iceberg → MinIO
-- =================================================================

-- =================================================================
-- 1. SETUP ICEBERG CATALOG (Common setup)
-- =================================================================

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

USE CATALOG iceberg_catalog;
CREATE DATABASE IF NOT EXISTS university;
USE university;

-- =================================================================
-- 2. DYNAMIC TABLE DEFINITIONS
-- Faculty Table Job
-- =================================================================

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
  'scan.startup.mode' = 'latest-offset',
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

-- =================================================================
-- Program Table Job
-- =================================================================

-- Program Kafka Source
CREATE TABLE IF NOT EXISTS kafka_program (
  id INT,
  program_code STRING,
  program_name STRING,
  faculty_id INT,
  degree STRING,
  created_at TIMESTAMP(3),
  op STRING,
  ts_ms BIGINT,
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector' = 'kafka',
  'topic' = 'university-server.public.program',
  'properties.bootstrap.servers' = 'kafka-broker:29092',
  'properties.group.id' = 'flink-program-consumer',
  'scan.startup.mode' = 'latest-offset',
  'format' = 'debezium-json'
);

-- Program Iceberg Sink
CREATE TABLE IF NOT EXISTS iceberg_program (
  id INT,
  program_code STRING,
  program_name STRING,
  faculty_id INT,
  degree STRING,
  created_at TIMESTAMP(3),
  ingestion_time TIMESTAMP(3),
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'program'
);

-- =================================================================
-- Students Table Job
-- =================================================================

-- Students Kafka Source
CREATE TABLE IF NOT EXISTS kafka_students (
  student_id STRING,
  full_name STRING,
  entry_year INT,
  program_id INT,
  degree STRING,
  faculty_id INT,
  status STRING,
  created_at TIMESTAMP(3),
  op STRING,
  ts_ms BIGINT,
  PRIMARY KEY (student_id) NOT ENFORCED
) WITH (
  'connector' = 'kafka',
  'topic' = 'university-server.public.students',
  'properties.bootstrap.servers' = 'kafka-broker:29092',
  'properties.group.id' = 'flink-students-consumer',
  'scan.startup.mode' = 'latest-offset',
  'format' = 'debezium-json'
);

-- Students Iceberg Sink
CREATE TABLE IF NOT EXISTS iceberg_students (
  student_id STRING,
  full_name STRING,
  entry_year INT,
  program_id INT,
  degree STRING,
  faculty_id INT,
  status STRING,
  created_at TIMESTAMP(3),
  ingestion_time TIMESTAMP(3),
  PRIMARY KEY (student_id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'students'
);

-- =================================================================
-- Payment Table Job
-- =================================================================

-- Payment Kafka Source
CREATE TABLE IF NOT EXISTS kafka_payment (
  payment_id STRING,
  student_id STRING,
  registration_id STRING,
  payment_type STRING,
  payment_amount DECIMAL(12,2),
  bank_name STRING,
  virtual_account_number STRING,
  payment_channel STRING,
  payment_time TIMESTAMP(3),
  payment_status STRING,
  installment_number INT,
  late_fee_charged DECIMAL(12,2),
  total_paid_amount DECIMAL(12,2),
  payment_proof_url STRING,
  due_date DATE,
  created_at TIMESTAMP(3),
  updated_at TIMESTAMP(3),
  op STRING,
  ts_ms BIGINT,
  PRIMARY KEY (payment_id) NOT ENFORCED
) WITH (
  'connector' = 'kafka',
  'topic' = 'university-server.public.payment',
  'properties.bootstrap.servers' = 'kafka-broker:29092',
  'properties.group.id' = 'flink-payment-consumer',
  'scan.startup.mode' = 'latest-offset',
  'format' = 'debezium-json'
);

-- Payment Iceberg Sink
CREATE TABLE IF NOT EXISTS iceberg_payment (
  payment_id STRING,
  student_id STRING,
  registration_id STRING,
  payment_type STRING,
  payment_amount DECIMAL(12,2),
  bank_name STRING,
  virtual_account_number STRING,
  payment_channel STRING,
  payment_time TIMESTAMP(3),
  payment_status STRING,
  installment_number INT,
  late_fee_charged DECIMAL(12,2),
  total_paid_amount DECIMAL(12,2),
  payment_proof_url STRING,
  due_date DATE,
  created_at TIMESTAMP(3),
  updated_at TIMESTAMP(3),
  ingestion_time TIMESTAMP(3),
  PRIMARY KEY (payment_id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'payment'
);

-- =================================================================
-- NOTES FOR DYNAMIC EXECUTION:
-- - Tables are created but streaming jobs are NOT started automatically
-- - Use separate INSERT statements to start specific table jobs
-- - Jobs can be triggered individually based on table changes
-- - Each job uses 'latest-offset' to process only new changes
-- ================================================================= 