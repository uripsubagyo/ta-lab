-- =================================================================
-- END-TO-END TEST: PostgreSQL → Debezium → Kafka → Flink → Iceberg
-- =================================================================

-- Step 1: Create Iceberg catalog (using local filesystem terlebih dahulu)
CREATE CATALOG iceberg_catalog WITH (
  'type' = 'iceberg',
  'catalog-type' = 'hadoop',
  'warehouse' = 'file:///tmp/warehouse'
);

USE CATALOG iceberg_catalog;
CREATE DATABASE IF NOT EXISTS university;
USE university;

-- Step 2: Create Iceberg table untuk students
CREATE TABLE students_iceberg (
  student_id STRING,
  full_name STRING,
  entry_year INT,
  program_id INT,
  degree STRING,
  faculty_id INT,
  status STRING,
  created_at TIMESTAMP(3),
  PRIMARY KEY (student_id) NOT ENFORCED
);

-- Step 3: Switch ke default catalog untuk Kafka source
USE CATALOG default_catalog;

-- Step 4: Create Kafka source table
CREATE TABLE kafka_students (
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
  'properties.group.id' = 'flink-test-e2e',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'debezium-json'
);

-- Step 5: Show all catalogs and tables
SHOW CATALOGS; 