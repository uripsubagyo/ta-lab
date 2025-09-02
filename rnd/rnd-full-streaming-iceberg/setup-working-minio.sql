-- =================================================================
-- WORKING ICEBERG + MINIO S3 PIPELINE SETUP
-- Data akan disimpan di MinIO S3 (bisa dilihat di MinIO Console)
-- =================================================================

-- Create Iceberg catalog dengan MinIO S3 sebagai storage
CREATE CATALOG iceberg_minio WITH (
  'type' = 'iceberg',
  'catalog-type' = 'hadoop',
  'warehouse' = 's3a://warehouse',
  'io-impl' = 'org.apache.iceberg.aws.s3.S3FileIO',
  's3.endpoint' = 'http://minio:9000',
  's3.access-key-id' = 'admin',
  's3.secret-access-key' = 'password',
  's3.path-style-access' = 'true'
);

USE CATALOG iceberg_minio;
CREATE DATABASE IF NOT EXISTS university;
USE university;

-- Create simple test table terlebih dahulu
CREATE TABLE test_students (
  student_id STRING,
  full_name STRING,
  entry_year INT,
  created_at TIMESTAMP(3),
  PRIMARY KEY (student_id) NOT ENFORCED
);

-- Show tables to verify
SHOW TABLES;

-- Kembali ke default catalog untuk membuat Kafka source
USE CATALOG default_catalog;

-- Create Kafka source table
CREATE TABLE kafka_test_data (
  student_id STRING,
  full_name STRING,
  entry_year INT,
  created_at TIMESTAMP(3),
  op STRING,
  ts_ms BIGINT,
  PRIMARY KEY (student_id) NOT ENFORCED
) WITH (
  'connector' = 'kafka',
  'topic' = 'university-server.public.students',
  'properties.bootstrap.servers' = 'kafka-broker:29092',
  'properties.group.id' = 'flink-test-consumer',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'debezium-json'
);

SHOW CATALOGS; 