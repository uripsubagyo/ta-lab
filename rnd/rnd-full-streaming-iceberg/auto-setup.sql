-- =================================================================
-- AUTO-SETUP SCRIPT: Simple Working Pipeline Test
-- Iceberg → Local + MinIO via Polaris REST API 
-- =================================================================

-- Create Iceberg catalog dengan local filesystem (untuk test awal)
CREATE CATALOG iceberg_local WITH (
  'type' = 'iceberg',
  'catalog-type' = 'hadoop',
  'warehouse' = 'file:///tmp/warehouse'
);

USE CATALOG iceberg_local;
CREATE DATABASE IF NOT EXISTS university;
USE university;

-- Create Iceberg table untuk students (local filesystem)
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

-- Switch to default catalog untuk create Kafka source
USE CATALOG default_catalog;

-- Create Kafka source table untuk students
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
  PRIMARY KEY (student_id) NOT ENFORCED
) WITH (
  'connector' = 'kafka',
  'topic' = 'university-server.public.students',
  'properties.bootstrap.servers' = 'kafka-broker:9092',
  'properties.group.id' = 'flink-students-group',
  'format' = 'debezium-json',
  'debezium-json.schema-include' = 'true',
  'scan.startup.mode' = 'earliest-offset'
);

-- Show successful setup
SHOW CATALOGS; 