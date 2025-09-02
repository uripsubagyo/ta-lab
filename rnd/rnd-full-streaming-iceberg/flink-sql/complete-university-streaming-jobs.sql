-- =================================================================
-- COMPLETE UNIVERSITY STREAMING JOBS - FLINK SQL
-- This script creates streaming jobs for ALL university tables
-- PostgreSQL → Debezium → Kafka → Flink → Iceberg → MinIO
-- =================================================================

-- =================================================================
-- 1. SETUP ICEBERG CATALOG
-- =================================================================

-- Create Iceberg catalog in Flink with Polaris
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
CREATE DATABASE IF NOT EXISTS university;
USE university;

-- =================================================================
-- 2. KAFKA SOURCE TABLES (Reading from Debezium CDC Topics)
-- =================================================================

-- Faculty Kafka Source
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
  'properties.group.id' = 'flink-faculty-consumer',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'debezium-json'
);

-- Program Kafka Source
CREATE TABLE kafka_program (
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
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'debezium-json'
);

-- Students Kafka Source
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
  'properties.group.id' = 'flink-students-consumer',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'debezium-json'
);

-- Student Detail Kafka Source
CREATE TABLE kafka_student_detail (
  id INT,
  student_id STRING,
  gender STRING,
  birth_date DATE,
  birth_place STRING,
  religion STRING,
  nationality STRING,
  registration_date DATE,
  address STRING,
  city STRING,
  province STRING,
  postal_code STRING,
  phone_number STRING,
  high_school STRING,
  high_school_year INT,
  parent_name STRING,
  parent_income DECIMAL(15,2),
  parent_occupation STRING,
  blood_type STRING,
  health_insurance STRING,
  accommodation STRING,
  created_at TIMESTAMP(3),
  op STRING,
  ts_ms BIGINT,
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector' = 'kafka',
  'topic' = 'university-server.public.student_detail',
  'properties.bootstrap.servers' = 'kafka-broker:29092',
  'properties.group.id' = 'flink-student-detail-consumer',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'debezium-json'
);

-- Student Fee Kafka Source
CREATE TABLE kafka_student_fee (
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

-- Lecturer Kafka Source
CREATE TABLE kafka_lecturer (
  id INT,
  lecturer_id STRING,
  name STRING,
  email STRING,
  faculty_id INT,
  created_at TIMESTAMP(3),
  op STRING,
  ts_ms BIGINT,
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector' = 'kafka',
  'topic' = 'university-server.public.lecturer',
  'properties.bootstrap.servers' = 'kafka-broker:29092',
  'properties.group.id' = 'flink-lecturer-consumer',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'debezium-json'
);

-- Room Kafka Source
CREATE TABLE kafka_room (
  id INT,
  room_code STRING,
  building STRING,
  capacity INT,
  created_at TIMESTAMP(3),
  op STRING,
  ts_ms BIGINT,
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector' = 'kafka',
  'topic' = 'university-server.public.room',
  'properties.bootstrap.servers' = 'kafka-broker:29092',
  'properties.group.id' = 'flink-room-consumer',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'debezium-json'
);

-- Course Kafka Source
CREATE TABLE kafka_course (
  id INT,
  course_code STRING,
  course_name STRING,
  credits INT,
  program_id INT,
  created_at TIMESTAMP(3),
  op STRING,
  ts_ms BIGINT,
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector' = 'kafka',
  'topic' = 'university-server.public.course',
  'properties.bootstrap.servers' = 'kafka-broker:29092',
  'properties.group.id' = 'flink-course-consumer',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'debezium-json'
);

-- Registration Kafka Source
CREATE TABLE kafka_registration (
  registration_id STRING,
  student_id STRING,
  academic_year STRING,
  semester INT,
  semester_code STRING,
  registration_date DATE,
  registration_status STRING,
  total_sks INT,
  late_registration BOOLEAN,
  created_at TIMESTAMP(3),
  updated_at TIMESTAMP(3),
  op STRING,
  ts_ms BIGINT,
  PRIMARY KEY (registration_id) NOT ENFORCED
) WITH (
  'connector' = 'kafka',
  'topic' = 'university-server.public.registration',
  'properties.bootstrap.servers' = 'kafka-broker:29092',
  'properties.group.id' = 'flink-registration-consumer',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'debezium-json'
);

-- Class Kafka Source
CREATE TABLE kafka_class (
  class_id STRING,
  course_id INT,
  lecturer_id INT,
  academic_year STRING,
  semester INT,
  class_code STRING,
  room_code STRING,
  schedule_day STRING,
  schedule_time STRING,
  capacity INT,
  enrolled_count INT,
  class_status STRING,
  created_at TIMESTAMP(3),
  op STRING,
  ts_ms BIGINT,
  PRIMARY KEY (class_id) NOT ENFORCED
) WITH (
  'connector' = 'kafka',
  'topic' = 'university-server.public.class',
  'properties.bootstrap.servers' = 'kafka-broker:29092',
  'properties.group.id' = 'flink-class-consumer',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'debezium-json'
);

-- Student Enrollment Kafka Source
CREATE TABLE kafka_student_enrollment (
  enrollment_id INT,
  student_id STRING,
  registration_id STRING,
  class_id STRING,
  enrollment_date DATE,
  enrollment_status STRING,
  final_grade DECIMAL(5,2),
  grade_point DECIMAL(3,2),
  attendance_percentage DECIMAL(5,2),
  created_at TIMESTAMP(3),
  updated_at TIMESTAMP(3),
  op STRING,
  ts_ms BIGINT,
  PRIMARY KEY (enrollment_id) NOT ENFORCED
) WITH (
  'connector' = 'kafka',
  'topic' = 'university-server.public.student_enrollment',
  'properties.bootstrap.servers' = 'kafka-broker:29092',
  'properties.group.id' = 'flink-student-enrollment-consumer',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'debezium-json'
);

-- Payment Kafka Source
CREATE TABLE kafka_payment (
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
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'debezium-json'
);

-- =================================================================
-- 3. ICEBERG SINK TABLES (Writing to MinIO via Iceberg)
-- =================================================================

-- Faculty Iceberg Sink
CREATE TABLE iceberg_faculty (
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

-- Program Iceberg Sink
CREATE TABLE iceberg_program (
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

-- Students Iceberg Sink
CREATE TABLE iceberg_students (
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

-- Student Detail Iceberg Sink
CREATE TABLE iceberg_student_detail (
  id INT,
  student_id STRING,
  gender STRING,
  birth_date DATE,
  birth_place STRING,
  religion STRING,
  nationality STRING,
  registration_date DATE,
  address STRING,
  city STRING,
  province STRING,
  postal_code STRING,
  phone_number STRING,
  high_school STRING,
  high_school_year INT,
  parent_name STRING,
  parent_income DECIMAL(15,2),
  parent_occupation STRING,
  blood_type STRING,
  health_insurance STRING,
  accommodation STRING,
  created_at TIMESTAMP(3),
  ingestion_time TIMESTAMP(3),
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'student_detail'
);

-- Student Fee Iceberg Sink
CREATE TABLE iceberg_student_fee (
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

-- Lecturer Iceberg Sink
CREATE TABLE iceberg_lecturer (
  id INT,
  lecturer_id STRING,
  name STRING,
  email STRING,
  faculty_id INT,
  created_at TIMESTAMP(3),
  ingestion_time TIMESTAMP(3),
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'lecturer'
);

-- Room Iceberg Sink
CREATE TABLE iceberg_room (
  id INT,
  room_code STRING,
  building STRING,
  capacity INT,
  created_at TIMESTAMP(3),
  ingestion_time TIMESTAMP(3),
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'room'
);

-- Course Iceberg Sink
CREATE TABLE iceberg_course (
  id INT,
  course_code STRING,
  course_name STRING,
  credits INT,
  program_id INT,
  created_at TIMESTAMP(3),
  ingestion_time TIMESTAMP(3),
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'course'
);

-- Registration Iceberg Sink
CREATE TABLE iceberg_registration (
  registration_id STRING,
  student_id STRING,
  academic_year STRING,
  semester INT,
  semester_code STRING,
  registration_date DATE,
  registration_status STRING,
  total_sks INT,
  late_registration BOOLEAN,
  created_at TIMESTAMP(3),
  updated_at TIMESTAMP(3),
  ingestion_time TIMESTAMP(3),
  PRIMARY KEY (registration_id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'registration'
);

-- Class Iceberg Sink
CREATE TABLE iceberg_class (
  class_id STRING,
  course_id INT,
  lecturer_id INT,
  academic_year STRING,
  semester INT,
  class_code STRING,
  room_code STRING,
  schedule_day STRING,
  schedule_time STRING,
  capacity INT,
  enrolled_count INT,
  class_status STRING,
  created_at TIMESTAMP(3),
  ingestion_time TIMESTAMP(3),
  PRIMARY KEY (class_id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'class'
);

-- Student Enrollment Iceberg Sink
CREATE TABLE iceberg_student_enrollment (
  enrollment_id INT,
  student_id STRING,
  registration_id STRING,
  class_id STRING,
  enrollment_date DATE,
  enrollment_status STRING,
  final_grade DECIMAL(5,2),
  grade_point DECIMAL(3,2),
  attendance_percentage DECIMAL(5,2),
  created_at TIMESTAMP(3),
  updated_at TIMESTAMP(3),
  ingestion_time TIMESTAMP(3),
  PRIMARY KEY (enrollment_id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'student_enrollment'
);

-- Payment Iceberg Sink
CREATE TABLE iceberg_payment (
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
-- 4. STREAMING JOBS (INSERT statements to transfer data)
-- =================================================================

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

-- Program Streaming Job
INSERT INTO iceberg_program
SELECT 
  id,
  program_code,
  program_name,
  faculty_id,
  degree,
  created_at,
  CURRENT_TIMESTAMP as ingestion_time
FROM kafka_program
WHERE op IN ('r', 'c', 'u');

-- Students Streaming Job
INSERT INTO iceberg_students
SELECT 
  student_id,
  full_name,
  entry_year,
  program_id,
  degree,
  faculty_id,
  status,
  created_at,
  CURRENT_TIMESTAMP as ingestion_time
FROM kafka_students
WHERE op IN ('r', 'c', 'u');

-- Student Detail Streaming Job
INSERT INTO iceberg_student_detail
SELECT 
  id,
  student_id,
  gender,
  birth_date,
  birth_place,
  religion,
  nationality,
  registration_date,
  address,
  city,
  province,
  postal_code,
  phone_number,
  high_school,
  high_school_year,
  parent_name,
  parent_income,
  parent_occupation,
  blood_type,
  health_insurance,
  accommodation,
  created_at,
  CURRENT_TIMESTAMP as ingestion_time
FROM kafka_student_detail
WHERE op IN ('r', 'c', 'u');

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

-- Lecturer Streaming Job
INSERT INTO iceberg_lecturer
SELECT 
  id,
  lecturer_id,
  name,
  email,
  faculty_id,
  created_at,
  CURRENT_TIMESTAMP as ingestion_time
FROM kafka_lecturer
WHERE op IN ('r', 'c', 'u');

-- Room Streaming Job
INSERT INTO iceberg_room
SELECT 
  id,
  room_code,
  building,
  capacity,
  created_at,
  CURRENT_TIMESTAMP as ingestion_time
FROM kafka_room
WHERE op IN ('r', 'c', 'u');

-- Course Streaming Job
INSERT INTO iceberg_course
SELECT 
  id,
  course_code,
  course_name,
  credits,
  program_id,
  created_at,
  CURRENT_TIMESTAMP as ingestion_time
FROM kafka_course
WHERE op IN ('r', 'c', 'u');

-- Registration Streaming Job
INSERT INTO iceberg_registration
SELECT 
  registration_id,
  student_id,
  academic_year,
  semester,
  semester_code,
  registration_date,
  registration_status,
  total_sks,
  late_registration,
  created_at,
  updated_at,
  CURRENT_TIMESTAMP as ingestion_time
FROM kafka_registration
WHERE op IN ('r', 'c', 'u');

-- Class Streaming Job
INSERT INTO iceberg_class
SELECT 
  class_id,
  course_id,
  lecturer_id,
  academic_year,
  semester,
  class_code,
  room_code,
  schedule_day,
  schedule_time,
  capacity,
  enrolled_count,
  class_status,
  created_at,
  CURRENT_TIMESTAMP as ingestion_time
FROM kafka_class
WHERE op IN ('r', 'c', 'u');

-- Student Enrollment Streaming Job
INSERT INTO iceberg_student_enrollment
SELECT 
  enrollment_id,
  student_id,
  registration_id,
  class_id,
  enrollment_date,
  enrollment_status,
  final_grade,
  grade_point,
  attendance_percentage,
  created_at,
  updated_at,
  CURRENT_TIMESTAMP as ingestion_time
FROM kafka_student_enrollment
WHERE op IN ('r', 'c', 'u');

-- Payment Streaming Job
INSERT INTO iceberg_payment
SELECT 
  payment_id,
  student_id,
  registration_id,
  payment_type,
  payment_amount,
  bank_name,
  virtual_account_number,
  payment_channel,
  payment_time,
  payment_status,
  installment_number,
  late_fee_charged,
  total_paid_amount,
  payment_proof_url,
  due_date,
  created_at,
  updated_at,
  CURRENT_TIMESTAMP as ingestion_time
FROM kafka_payment
WHERE op IN ('r', 'c', 'u');

-- =================================================================
-- NOTES:
-- - Each streaming job filters for 'r' (read/snapshot), 'c' (create/insert), 'u' (update) operations
-- - Delete operations ('d') are excluded to maintain data lineage
-- - Each Iceberg table includes an 'ingestion_time' field for tracking when data was processed
-- - All jobs run continuously and will process new messages as they arrive in Kafka
-- - Tables are partitioned and optimized for analytical queries via Trino
-- ================================================================= 