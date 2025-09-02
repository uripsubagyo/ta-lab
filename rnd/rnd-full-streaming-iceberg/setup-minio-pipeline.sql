-- =================================================================
-- ICEBERG + MINIO S3 PIPELINE SETUP
-- Data akan disimpan di MinIO S3 (bisa dilihat di MinIO Console)
-- =================================================================

-- Create Iceberg catalog dengan MinIO S3 sebagai storage
CREATE CATALOG iceberg_minio WITH (
  'type' = 'iceberg',
  'catalog-type' = 'hadoop',
  'warehouse' = 's3a://warehouse/',
  'io-impl' = 'org.apache.iceberg.aws.s3.S3FileIO',
  's3.endpoint' = 'http://minio:9000',
  's3.access-key-id' = 'admin',
  's3.secret-access-key' = 'password',
  's3.path-style-access' = 'true'
);

USE CATALOG iceberg_minio;
CREATE DATABASE IF NOT EXISTS university;
USE university;

-- Create Iceberg sink tables (data akan tersimpan di MinIO)
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

CREATE TABLE faculty_iceberg (
  id INT,
  faculty_code STRING,
  faculty_name STRING,
  created_at TIMESTAMP(3),
  PRIMARY KEY (id) NOT ENFORCED
);

-- Switch to default catalog untuk Kafka sources
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
  ts_ms BIGINT,
  PRIMARY KEY (student_id) NOT ENFORCED
) WITH (
  'connector' = 'kafka',
  'topic' = 'university-server.public.students',
  'properties.bootstrap.servers' = 'kafka-broker:29092',
  'properties.group.id' = 'flink-students-consumer-minio',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'debezium-json'
);

-- Create Kafka source table untuk faculty  
CREATE TABLE kafka_faculty (
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
  'properties.group.id' = 'flink-faculty-consumer-minio',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'debezium-json'
);

SHOW CATALOGS; 