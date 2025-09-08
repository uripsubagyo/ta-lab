-- ==========================================
-- UNIVERSITY STREAMING PIPELINE SETUP
-- Kafka → Flink → Iceberg
-- ==========================================

-- 1. CREATE CATALOGS
-- ==========================================

-- Kafka Catalog for source tables
CREATE CATALOG kafka_catalog WITH ('type'='generic_in_memory');
CREATE DATABASE kafka_catalog.university_db;

-- Polaris/Iceberg Catalog for destination tables  
CREATE CATALOG polaris_catalog WITH (
    'type'='iceberg',
    'catalog-type'='rest',
    'uri'='http://polaris:8181/api/catalog',
    'warehouse'='polariscatalog',
    'oauth2-server-uri'='http://polaris:8181/api/catalog/v1/oauth/tokens',
    'credential'='root:secret',
    'scope'='PRINCIPAL_ROLE:ALL'
);

-- Create database in Iceberg catalog
CREATE DATABASE IF NOT EXISTS polaris_catalog.university_lakehouse;

-- 2. KAFKA SOURCE TABLES (from Debezium CDC)
-- ==========================================

-- Faculty Table
CREATE TABLE kafka_catalog.university_db.faculty (
    id INT,
    faculty_code STRING,
    faculty_name STRING,
    created_at TIMESTAMP(3),
    WATERMARK FOR created_at AS created_at - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'topic' = 'dbserver1.university.faculty'
);

-- Program Table
CREATE TABLE kafka_catalog.university_db.program (
    id INT,
    program_code STRING,
    program_name STRING,
    faculty_id INT,
    degree_level STRING,
    created_at TIMESTAMP(3),
    WATERMARK FOR created_at AS created_at - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'topic' = 'dbserver1.university.program'
);

-- Students Table
CREATE TABLE kafka_catalog.university_db.students (
    id INT,
    student_id STRING,
    first_name STRING,
    last_name STRING,
    email STRING,
    phone STRING,
    program_id INT,
    admission_year INT,
    status STRING,
    created_at TIMESTAMP(3),
    WATERMARK FOR created_at AS created_at - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'topic' = 'dbserver1.university.students'
);

-- Class Table
CREATE TABLE kafka_catalog.university_db.class (
    id INT,
    class_code STRING,
    class_name STRING,
    course_id INT,
    lecturer_id INT,
    room_id INT,
    semester STRING,
    academic_year STRING,
    schedule_day STRING,
    schedule_time STRING,
    max_capacity INT,
    created_at TIMESTAMP(3),
    WATERMARK FOR created_at AS created_at - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'topic' = 'dbserver1.university.class'
);

-- Course Table
CREATE TABLE kafka_catalog.university_db.course (
    id INT,
    course_code STRING,
    course_name STRING,
    credits INT,
    program_id INT,
    prerequisite_course_id INT,
    created_at TIMESTAMP(3),
    WATERMARK FOR created_at AS created_at - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'topic' = 'dbserver1.university.course'
);

-- Lecturer Table
CREATE TABLE kafka_catalog.university_db.lecturer (
    id INT,
    lecturer_id STRING,
    first_name STRING,
    last_name STRING,
    email STRING,
    phone STRING,
    faculty_id INT,
    specialization STRING,
    employment_status STRING,
    created_at TIMESTAMP(3),
    WATERMARK FOR created_at AS created_at - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'topic' = 'dbserver1.university.lecturer'
);

-- Payment Table
CREATE TABLE kafka_catalog.university_db.payment (
    id INT,
    payment_id STRING,
    student_id INT,
    amount DECIMAL(10,2),
    payment_type STRING,
    payment_method STRING,
    payment_date TIMESTAMP(3),
    semester STRING,
    academic_year STRING,
    status STRING,
    created_at TIMESTAMP(3),
    WATERMARK FOR payment_date AS payment_date - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'topic' = 'dbserver1.university.payment'
);

-- Registration Table
CREATE TABLE kafka_catalog.university_db.registration (
    id INT,
    student_id INT,
    class_id INT,
    registration_date TIMESTAMP(3),
    semester STRING,
    academic_year STRING,
    status STRING,
    grade STRING,
    created_at TIMESTAMP(3),
    WATERMARK FOR registration_date AS registration_date - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'topic' = 'dbserver1.university.registration'
);

-- Room Table
CREATE TABLE kafka_catalog.university_db.room (
    id INT,
    room_code STRING,
    room_name STRING,
    building STRING,
    floor_number INT,
    capacity INT,
    room_type STRING,
    facilities STRING,
    created_at TIMESTAMP(3),
    WATERMARK FOR created_at AS created_at - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'topic' = 'dbserver1.university.room'
);

-- Student Detail Table
CREATE TABLE kafka_catalog.university_db.student_detail (
    id INT,
    student_id INT,
    address STRING,
    city STRING,
    province STRING,
    postal_code STRING,
    date_of_birth DATE,
    place_of_birth STRING,
    gender STRING,
    nationality STRING,
    religion STRING,
    created_at TIMESTAMP(3),
    WATERMARK FOR created_at AS created_at - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'topic' = 'dbserver1.university.student_detail'
);

-- Student Enrollment Table
CREATE TABLE kafka_catalog.university_db.student_enrollment (
    id INT,
    student_id INT,
    semester STRING,
    academic_year STRING,
    enrollment_date TIMESTAMP(3),
    status STRING,
    total_credits INT,
    gpa DECIMAL(3,2),
    created_at TIMESTAMP(3),
    WATERMARK FOR enrollment_date AS enrollment_date - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'topic' = 'dbserver1.university.student_enrollment'
);

-- Student Fee Table
CREATE TABLE kafka_catalog.university_db.student_fee (
    id INT,
    student_id INT,
    fee_type STRING,
    amount DECIMAL(10,2),
    semester STRING,
    academic_year STRING,
    due_date DATE,
    status STRING,
    created_at TIMESTAMP(3),
    WATERMARK FOR created_at AS created_at - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'topic' = 'dbserver1.university.student_fee'
);

-- 3. ICEBERG DESTINATION TABLES
-- ==========================================

-- Faculty Iceberg Table
CREATE TABLE polaris_catalog.university_lakehouse.faculty (
    id INT,
    faculty_code STRING,
    faculty_name STRING,
    created_at TIMESTAMP(3),
    ingestion_time TIMESTAMP(3)
) WITH (
    'connector' = 'iceberg',
    'catalog-name' = 'polaris_catalog',
    'database-name' = 'university_lakehouse',
    'table-name' = 'faculty'
);

-- Program Iceberg Table
CREATE TABLE polaris_catalog.university_lakehouse.program (
    id INT,
    program_code STRING,
    program_name STRING,
    faculty_id INT,
    degree_level STRING,
    created_at TIMESTAMP(3),
    ingestion_time TIMESTAMP(3)
) WITH (
    'connector' = 'iceberg',
    'catalog-name' = 'polaris_catalog',
    'database-name' = 'university_lakehouse',
    'table-name' = 'program'
);

-- Students Iceberg Table
CREATE TABLE polaris_catalog.university_lakehouse.students (
    id INT,
    student_id STRING,
    first_name STRING,
    last_name STRING,
    email STRING,
    phone STRING,
    program_id INT,
    admission_year INT,
    status STRING,
    created_at TIMESTAMP(3),
    ingestion_time TIMESTAMP(3)
) WITH (
    'connector' = 'iceberg',
    'catalog-name' = 'polaris_catalog',
    'database-name' = 'university_lakehouse',
    'table-name' = 'students'
);

-- Class Iceberg Table
CREATE TABLE polaris_catalog.university_lakehouse.class (
    id INT,
    class_code STRING,
    class_name STRING,
    course_id INT,
    lecturer_id INT,
    room_id INT,
    semester STRING,
    academic_year STRING,
    schedule_day STRING,
    schedule_time STRING,
    max_capacity INT,
    created_at TIMESTAMP(3),
    ingestion_time TIMESTAMP(3)
) WITH (
    'connector' = 'iceberg',
    'catalog-name' = 'polaris_catalog',
    'database-name' = 'university_lakehouse',
    'table-name' = 'class'
);

-- Course Iceberg Table
CREATE TABLE polaris_catalog.university_lakehouse.course (
    id INT,
    course_code STRING,
    course_name STRING,
    credits INT,
    program_id INT,
    prerequisite_course_id INT,
    created_at TIMESTAMP(3),
    ingestion_time TIMESTAMP(3)
) WITH (
    'connector' = 'iceberg',
    'catalog-name' = 'polaris_catalog',
    'database-name' = 'university_lakehouse',
    'table-name' = 'course'
);

-- Lecturer Iceberg Table
CREATE TABLE polaris_catalog.university_lakehouse.lecturer (
    id INT,
    lecturer_id STRING,
    first_name STRING,
    last_name STRING,
    email STRING,
    phone STRING,
    faculty_id INT,
    specialization STRING,
    employment_status STRING,
    created_at TIMESTAMP(3),
    ingestion_time TIMESTAMP(3)
) WITH (
    'connector' = 'iceberg',
    'catalog-name' = 'polaris_catalog',
    'database-name' = 'university_lakehouse',
    'table-name' = 'lecturer'
);

-- Payment Iceberg Table
CREATE TABLE polaris_catalog.university_lakehouse.payment (
    id INT,
    payment_id STRING,
    student_id INT,
    amount DECIMAL(10,2),
    payment_type STRING,
    payment_method STRING,
    payment_date TIMESTAMP(3),
    semester STRING,
    academic_year STRING,
    status STRING,
    created_at TIMESTAMP(3),
    ingestion_time TIMESTAMP(3)
) WITH (
    'connector' = 'iceberg',
    'catalog-name' = 'polaris_catalog',
    'database-name' = 'university_lakehouse',
    'table-name' = 'payment'
);

-- Registration Iceberg Table
CREATE TABLE polaris_catalog.university_lakehouse.registration (
    id INT,
    student_id INT,
    class_id INT,
    registration_date TIMESTAMP(3),
    semester STRING,
    academic_year STRING,
    status STRING,
    grade STRING,
    created_at TIMESTAMP(3),
    ingestion_time TIMESTAMP(3)
) WITH (
    'connector' = 'iceberg',
    'catalog-name' = 'polaris_catalog',
    'database-name' = 'university_lakehouse',
    'table-name' = 'registration'
);

-- Room Iceberg Table
CREATE TABLE polaris_catalog.university_lakehouse.room (
    id INT,
    room_code STRING,
    room_name STRING,
    building STRING,
    floor_number INT,
    capacity INT,
    room_type STRING,
    facilities STRING,
    created_at TIMESTAMP(3),
    ingestion_time TIMESTAMP(3)
) WITH (
    'connector' = 'iceberg',
    'catalog-name' = 'polaris_catalog',
    'database-name' = 'university_lakehouse',
    'table-name' = 'room'
);

-- Student Detail Iceberg Table
CREATE TABLE polaris_catalog.university_lakehouse.student_detail (
    id INT,
    student_id INT,
    address STRING,
    city STRING,
    province STRING,
    postal_code STRING,
    date_of_birth DATE,
    place_of_birth STRING,
    gender STRING,
    nationality STRING,
    religion STRING,
    created_at TIMESTAMP(3),
    ingestion_time TIMESTAMP(3)
) WITH (
    'connector' = 'iceberg',
    'catalog-name' = 'polaris_catalog',
    'database-name' = 'university_lakehouse',
    'table-name' = 'student_detail'
);

-- Student Enrollment Iceberg Table
CREATE TABLE polaris_catalog.university_lakehouse.student_enrollment (
    id INT,
    student_id INT,
    semester STRING,
    academic_year STRING,
    enrollment_date TIMESTAMP(3),
    status STRING,
    total_credits INT,
    gpa DECIMAL(3,2),
    created_at TIMESTAMP(3),
    ingestion_time TIMESTAMP(3)
) WITH (
    'connector' = 'iceberg',
    'catalog-name' = 'polaris_catalog',
    'database-name' = 'university_lakehouse',
    'table-name' = 'student_enrollment'
);

-- Student Fee Iceberg Table
CREATE TABLE polaris_catalog.university_lakehouse.student_fee (
    id INT,
    student_id INT,
    fee_type STRING,
    amount DECIMAL(10,2),
    semester STRING,
    academic_year STRING,
    due_date DATE,
    status STRING,
    created_at TIMESTAMP(3),
    ingestion_time TIMESTAMP(3)
) WITH (
    'connector' = 'iceberg',
    'catalog-name' = 'polaris_catalog',
    'database-name' = 'university_lakehouse',
    'table-name' = 'student_fee'
);

-- 4. SHOW CREATED OBJECTS
-- ==========================================
SHOW CATALOGS;
SHOW DATABASES FROM kafka_catalog;
SHOW TABLES FROM kafka_catalog.university_db;
SHOW DATABASES FROM polaris_catalog;
SHOW TABLES FROM polaris_catalog.university_lakehouse; 