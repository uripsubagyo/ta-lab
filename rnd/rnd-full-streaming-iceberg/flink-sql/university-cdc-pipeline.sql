-- =================================================================
-- UNIVERSITY CDC PIPELINE - FLINK SQL JOB
-- This script sets up complete CDC pipeline for University data
-- PostgreSQL → Debezium → Kafka → Flink → Iceberg
-- =================================================================

-- =================================================================
-- 1. SETUP ICEBERG CATALOG
-- =================================================================

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
CREATE DATABASE IF NOT EXISTS university;
USE university;

-- =================================================================
-- 2. KAFKA SOURCE TABLES (for each university table)
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
  'properties.group.id' = 'flink-enrollment-consumer',
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
-- 3. ICEBERG SINK TABLES (for each university table)
-- =================================================================

-- Faculty Iceberg Sink
CREATE TABLE faculty_iceberg (
  id INT,
  faculty_code STRING,
  faculty_name STRING,
  created_at TIMESTAMP(3),
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'faculty_iceberg'
);

-- Program Iceberg Sink
CREATE TABLE program_iceberg (
  id INT,
  program_code STRING,
  program_name STRING,
  faculty_id INT,
  degree STRING,
  created_at TIMESTAMP(3),
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'program_iceberg'
);

-- Students Iceberg Sink
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
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'students_iceberg'
);

-- Student Detail Iceberg Sink
CREATE TABLE student_detail_iceberg (
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
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'student_detail_iceberg'
);

-- Student Fee Iceberg Sink
CREATE TABLE student_fee_iceberg (
  fee_id STRING,
  student_id STRING,
  ukt_fee DECIMAL(12,2),
  bop_fee DECIMAL(12,2),
  updated_at TIMESTAMP(3),
  PRIMARY KEY (fee_id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'student_fee_iceberg'
);

-- Lecturer Iceberg Sink
CREATE TABLE lecturer_iceberg (
  id INT,
  lecturer_id STRING,
  name STRING,
  email STRING,
  faculty_id INT,
  created_at TIMESTAMP(3),
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'lecturer_iceberg'
);

-- Room Iceberg Sink
CREATE TABLE room_iceberg (
  id INT,
  room_code STRING,
  building STRING,
  capacity INT,
  created_at TIMESTAMP(3),
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'room_iceberg'
);

-- Course Iceberg Sink
CREATE TABLE course_iceberg (
  id INT,
  course_code STRING,
  course_name STRING,
  credits INT,
  program_id INT,
  created_at TIMESTAMP(3),
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'course_iceberg'
);

-- Registration Iceberg Sink
CREATE TABLE registration_iceberg (
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
  PRIMARY KEY (registration_id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'registration_iceberg'
);

-- Class Iceberg Sink
CREATE TABLE class_iceberg (
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
  PRIMARY KEY (class_id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'class_iceberg'
);

-- Student Enrollment Iceberg Sink
CREATE TABLE student_enrollment_iceberg (
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
  PRIMARY KEY (enrollment_id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'student_enrollment_iceberg'
);

-- Payment Iceberg Sink
CREATE TABLE payment_iceberg (
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
  PRIMARY KEY (payment_id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'payment_iceberg'
);

-- =================================================================
-- 4. INSERT JOBS (Stream data from Kafka to Iceberg)
-- =================================================================

-- Note: These INSERT statements should be executed one by one in Flink SQL Client
-- Each INSERT creates a continuous streaming job

-- INSERT Faculty Data
INSERT INTO faculty_iceberg
SELECT id, faculty_code, faculty_name, created_at
FROM kafka_faculty
WHERE op != 'd';  -- Exclude deletes

-- INSERT Program Data
INSERT INTO program_iceberg
SELECT id, program_code, program_name, faculty_id, degree, created_at
FROM kafka_program
WHERE op != 'd';

-- INSERT Students Data
INSERT INTO students_iceberg
SELECT student_id, full_name, entry_year, program_id, degree, faculty_id, status, created_at
FROM kafka_students
WHERE op != 'd';

-- INSERT Student Detail Data
INSERT INTO student_detail_iceberg
SELECT id, student_id, gender, birth_date, birth_place, religion, nationality, 
       registration_date, address, city, province, postal_code, phone_number,
       high_school, high_school_year, parent_name, parent_income, parent_occupation,
       blood_type, health_insurance, accommodation, created_at
FROM kafka_student_detail
WHERE op != 'd';

-- INSERT Student Fee Data
INSERT INTO student_fee_iceberg
SELECT fee_id, student_id, ukt_fee, bop_fee, updated_at
FROM kafka_student_fee
WHERE op != 'd';

-- INSERT Lecturer Data
INSERT INTO lecturer_iceberg
SELECT id, lecturer_id, name, email, faculty_id, created_at
FROM kafka_lecturer
WHERE op != 'd';

-- INSERT Room Data
INSERT INTO room_iceberg
SELECT id, room_code, building, capacity, created_at
FROM kafka_room
WHERE op != 'd';

-- INSERT Course Data
INSERT INTO course_iceberg
SELECT id, course_code, course_name, credits, program_id, created_at
FROM kafka_course
WHERE op != 'd';

-- INSERT Registration Data
INSERT INTO registration_iceberg
SELECT registration_id, student_id, academic_year, semester, semester_code,
       registration_date, registration_status, total_sks, late_registration,
       created_at, updated_at
FROM kafka_registration
WHERE op != 'd';

-- INSERT Class Data
INSERT INTO class_iceberg
SELECT class_id, course_id, lecturer_id, academic_year, semester, class_code,
       room_code, schedule_day, schedule_time, capacity, enrolled_count, 
       class_status, created_at
FROM kafka_class
WHERE op != 'd';

-- INSERT Student Enrollment Data
INSERT INTO student_enrollment_iceberg
SELECT enrollment_id, student_id, registration_id, class_id, enrollment_date,
       enrollment_status, final_grade, grade_point, attendance_percentage,
       created_at, updated_at
FROM kafka_student_enrollment
WHERE op != 'd';

-- INSERT Payment Data
INSERT INTO payment_iceberg
SELECT payment_id, student_id, registration_id, payment_type, payment_amount,
       bank_name, virtual_account_number, payment_channel, payment_time,
       payment_status, installment_number, late_fee_charged, total_paid_amount,
       payment_proof_url, due_date, created_at, updated_at
FROM kafka_payment
WHERE op != 'd';

-- =================================================================
-- 5. UTILITY QUERIES (For monitoring and verification)
-- =================================================================

-- Check table counts
-- SELECT 'faculty' as table_name, COUNT(*) as count FROM faculty_iceberg
-- UNION ALL
-- SELECT 'program' as table_name, COUNT(*) as count FROM program_iceberg
-- UNION ALL
-- SELECT 'students' as table_name, COUNT(*) as count FROM students_iceberg;

-- Monitor streaming jobs
-- SHOW JOBS;

-- =================================================================
-- END OF UNIVERSITY CDC PIPELINE
-- ================================================================= 