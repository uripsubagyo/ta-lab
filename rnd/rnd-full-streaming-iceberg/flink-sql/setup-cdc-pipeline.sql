-- Create Iceberg catalog in Flink
CREATE CATALOG iceberg_catalog WITH (
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
CREATE DATABASE IF NOT EXISTS siak;
USE siak;

-- Create Kafka source table for students
CREATE TABLE kafka_students (
  id INT,
  npm STRING,
  username STRING,
  name STRING,
  email STRING,
  phone STRING,
  program_id INT,
  enrollment_date DATE,
  birth_date DATE,
  gender STRING,
  address STRING,
  is_active BOOLEAN,
  created_at TIMESTAMP(3),
  updated_at TIMESTAMP(3),
  op STRING,
  ts_ms BIGINT,
  primary key (id) NOT ENFORCED
) WITH (
  'connector' = 'kafka',
  'topic' = 'postgres-server.siak.students',
  'properties.bootstrap.servers' = 'kafka-broker:29092',
  'properties.group.id' = 'flink-students-consumer',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'debezium-json'
);

-- Create Iceberg sink table for students
CREATE TABLE students_iceberg (
  id INT,
  npm STRING,
  username STRING,
  name STRING,
  email STRING,
  phone STRING,
  program_id INT,
  enrollment_date DATE,
  birth_date DATE,
  gender STRING,
  address STRING,
  is_active BOOLEAN,
  created_at TIMESTAMP(3),
  updated_at TIMESTAMP(3),
  primary key (id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'siak',
  'table-name' = 'students_iceberg'
);

-- Create Kafka source table for lecturers
CREATE TABLE kafka_lecturers (
  id INT,
  lecturer_code STRING,
  name STRING,
  email STRING,
  phone STRING,
  faculty_id INT,
  position STRING,
  degree STRING,
  specialization STRING,
  hire_date DATE,
  is_active BOOLEAN,
  created_at TIMESTAMP(3),
  updated_at TIMESTAMP(3),
  op STRING,
  ts_ms BIGINT,
  primary key (id) NOT ENFORCED
) WITH (
  'connector' = 'kafka',
  'topic' = 'postgres-server.siak.lecturers',
  'properties.bootstrap.servers' = 'kafka-broker:29092',
  'properties.group.id' = 'flink-lecturers-consumer',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'debezium-json'
);

-- Create Iceberg sink table for lecturers
CREATE TABLE lecturers_iceberg (
  id INT,
  lecturer_code STRING,
  name STRING,
  email STRING,
  phone STRING,
  faculty_id INT,
  position STRING,
  degree STRING,
  specialization STRING,
  hire_date DATE,
  is_active BOOLEAN,
  created_at TIMESTAMP(3),
  updated_at TIMESTAMP(3),
  primary key (id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'siak',
  'table-name' = 'lecturers_iceberg'
);

-- Create Kafka source table for faculties
CREATE TABLE kafka_faculties (
  id INT,
  faculty_code STRING,
  faculty_name STRING,
  dean_name STRING,
  establishment_year INT,
  created_at TIMESTAMP(3),
  updated_at TIMESTAMP(3),
  op STRING,
  ts_ms BIGINT,
  primary key (id) NOT ENFORCED
) WITH (
  'connector' = 'kafka',
  'topic' = 'postgres-server.siak.faculties',
  'properties.bootstrap.servers' = 'kafka-broker:29092',
  'properties.group.id' = 'flink-faculties-consumer',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'debezium-json'
);

-- Create Iceberg sink table for faculties
CREATE TABLE faculties_iceberg (
  id INT,
  faculty_code STRING,
  faculty_name STRING,
  dean_name STRING,
  establishment_year INT,
  created_at TIMESTAMP(3),
  updated_at TIMESTAMP(3),
  primary key (id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'siak',
  'table-name' = 'faculties_iceberg'
);

-- Insert streaming jobs
INSERT INTO students_iceberg
SELECT id, npm, username, name, email, phone, program_id, enrollment_date, birth_date, gender, address, is_active, created_at, updated_at
FROM kafka_students
WHERE op IN ('r', 'c', 'u');

INSERT INTO lecturers_iceberg  
SELECT id, lecturer_code, name, email, phone, faculty_id, position, degree, specialization, hire_date, is_active, created_at, updated_at
FROM kafka_lecturers
WHERE op IN ('r', 'c', 'u');

INSERT INTO faculties_iceberg
SELECT id, faculty_code, faculty_name, dean_name, establishment_year, created_at, updated_at
FROM kafka_faculties
WHERE op IN ('r', 'c', 'u'); 