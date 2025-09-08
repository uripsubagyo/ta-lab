CREATE CATALOG kafka_catalog WITH ('type'='generic_in_memory');
CREATE DATABASE kafka_catalog.university_db;


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

-- LAKUKAN INI UNRTUK BUAT ACCESS TOKEN UNTUK POLARIS CATALOG
ACCESS_TOKEN=$(curl -X POST \
  http://localhost:8181/api/catalog/v1/oauth/tokens \
  -d 'grant_type=client_credentials&client_id=root&client_secret=secret&scope=PRINCIPAL_ROLE:ALL' \
  | jq -r '.access_token')


curl -i -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  http://localhost:8181/api/management/v1/catalogs \
  --json '{
    "name": "polariscatalog",
    "type": "INTERNAL",
    "properties": {
      "default-base-location": "s3://warehouse",
      "s3.endpoint": "http://minio:9000",
      "s3.path-style-access": "true",
      "s3.access-key-id": "admin",
      "s3.secret-access-key": "password",
      "s3.region": "dummy-region"
    },
    "storageConfigInfo": {
      "roleArn": "arn:aws:iam::000000000000:role/minio-polaris-role",
      "storageType": "S3",
      "allowedLocations": [
        "s3://warehouse/*"
      ]
    }
  }'

--   Check
curl -X GET http://localhost:8181/api/management/v1/catalogs \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq

-- create a catalog in Flink to connect to the Polaris Iceberg catalog:
CREATE CATALOG polaris_catalog WITH (
    'type'='iceberg',
    'catalog-type'='rest',
    'uri'='http://polaris:8181/api/catalog',
    'warehouse'='polariscatalog',
    'oauth2-server-uri'='http://polaris:8181/api/catalog/v1/oauth/tokens',
    'credential'='root:secret',
    'scope'='PRINCIPAL_ROLE:ALL'
);


CREATE DATABASE polaris_catalog.university_db;

SET 'execution.checkpointing.interval' = '10s';


-- You can now create the dynamic table:
CREATE TABLE polaris_catalog.university_db.faculty AS  
    SELECT * FROM kafka_catalog.university_db.faculty;

CREATE TABLE polaris_catalog.university_db.program AS  
    SELECT * FROM kafka_catalog.university_db.program;

CREATE TABLE polaris_catalog.university_db.students AS  
    SELECT * FROM kafka_catalog.university_db.students;


CREATE TABLE polaris_catalog.university_db.class AS  
    SELECT * FROM kafka_catalog.university_db.class;

CREATE TABLE polaris_catalog.university_db.course AS  
    SELECT * FROM kafka_catalog.university_db.course;


CREATE TABLE polaris_catalog.university_db.lecturer AS  
    SELECT * FROM kafka_catalog.university_db.lecturer;

CREATE TABLE polaris_catalog.university_db.payment AS  
    SELECT * FROM kafka_catalog.university_db.payment;


CREATE TABLE polaris_catalog.university_db.registration AS  
    SELECT * FROM kafka_catalog.university_db.registration;

CREATE TABLE polaris_catalog.university_db.room AS  
    SELECT * FROM kafka_catalog.university_db.room;


CREATE TABLE polaris_catalog.university_db.student_detail AS  
    SELECT * FROM kafka_catalog.university_db.student_detail;

CREATE TABLE polaris_catalog.university_db.student_enrollment AS  
    SELECT * FROM kafka_catalog.university_db.student_enrollment;


CREATE TABLE polaris_catalog.university_db.student_fee AS  
    SELECT * FROM kafka_catalog.university_db.student_fee;




-- we need to create a Flink dynamic table to connect to the kafka_catalog.university_db.faculty table:



CREATE TABLE polaris_catalog.university_db.faculty AS  
    SELECT 
        after.* ,  
        op as operation_type, 
        CAST(ts_ms/1000 AS TIMESTAMP(3)) as event_timestamp
         FROM kafka_catalog.university_db.faculty;








-- ==========================================
-- KAFKA SOURCE TABLES WITH METADATA
-- ==========================================

-- Faculty Table
CREATE TABLE kafka_catalog.university_db.faculty (
    id INT,
    faculty_code STRING,
    faculty_name STRING,
    created_at BIGINT,
    source_timestamp TIMESTAMP(3) METADATA FROM 'value.source.timestamp' VIRTUAL,
    source_database STRING METADATA FROM 'value.source.database' VIRTUAL
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
    created_at BIGINT,
    source_timestamp TIMESTAMP(3) METADATA FROM 'value.source.timestamp' VIRTUAL,
    source_database STRING METADATA FROM 'value.source.database' VIRTUAL
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
    created_at BIGINT,
    source_timestamp TIMESTAMP(3) METADATA FROM 'value.source.timestamp' VIRTUAL,
    source_database STRING METADATA FROM 'value.source.database' VIRTUAL
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
    created_at BIGINT,
    source_timestamp TIMESTAMP(3) METADATA FROM 'value.source.timestamp' VIRTUAL,
    source_database STRING METADATA FROM 'value.source.database' VIRTUAL
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
    created_at BIGINT,
    source_timestamp TIMESTAMP(3) METADATA FROM 'value.source.timestamp' VIRTUAL,
    source_database STRING METADATA FROM 'value.source.database' VIRTUAL
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
    created_at BIGINT,
    source_timestamp TIMESTAMP(3) METADATA FROM 'value.source.timestamp' VIRTUAL,
    source_database STRING METADATA FROM 'value.source.database' VIRTUAL
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
    created_at BIGINT,
    source_timestamp TIMESTAMP(3) METADATA FROM 'value.source.timestamp' VIRTUAL,
    source_database STRING METADATA FROM 'value.source.database' VIRTUAL
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
    created_at BIGINT,
    source_timestamp TIMESTAMP(3) METADATA FROM 'value.source.timestamp' VIRTUAL,
    source_database STRING METADATA FROM 'value.source.database' VIRTUAL
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
    created_at BIGINT,
    source_timestamp TIMESTAMP(3) METADATA FROM 'value.source.timestamp' VIRTUAL,
    source_database STRING METADATA FROM 'value.source.database' VIRTUAL
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
    created_at BIGINT,
    source_timestamp TIMESTAMP(3) METADATA FROM 'value.source.timestamp' VIRTUAL,
    source_database STRING METADATA FROM 'value.source.database' VIRTUAL
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
    created_at BIGINT,
    source_timestamp TIMESTAMP(3) METADATA FROM 'value.source.timestamp' VIRTUAL,
    source_database STRING METADATA FROM 'value.source.database' VIRTUAL
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
    created_at BIGINT,
    source_timestamp TIMESTAMP(3) METADATA FROM 'value.source.timestamp' VIRTUAL,
    source_database STRING METADATA FROM 'value.source.database' VIRTUAL
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'topic' = 'dbserver1.university.student_fee'
);

-- ==========================================
-- STREAMING JOBS
-- ==========================================

-- Faculty Streaming
INSERT INTO polaris_catalog.university_db.faculty
SELECT 
    id,
    faculty_code,
    faculty_name,
    CAST(TO_TIMESTAMP_LTZ(created_at/1000, 3) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.faculty;

-- Program Streaming
INSERT INTO polaris_catalog.university_db.program
SELECT 
    id,
    program_code,
    program_name,
    faculty_id,
    degree_level,
    CAST(TO_TIMESTAMP_LTZ(created_at/1000, 3) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.program;

NSERT INTO polaris_catalog.university_db.students
SELECT 
    id,
    student_id,
    first_name,
    last_name,
    email,
    phone,
    program_id,
    admission_year,
    status,
    CAST(TO_TIMESTAMP_LTZ(created_at/1000, 3) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.students;

-- Class Streaming
INSERT INTO polaris_catalog.university_db.class
SELECT 
    id,
    class_code,
    class_name,
    course_id,
    lecturer_id,
    room_id,
    semester,
    academic_year,
    schedule_day,
    schedule_time,
    max_capacity,
    CAST(TO_TIMESTAMP_LTZ(created_at/1000, 3) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.class;

-- Course Streaming
INSERT INTO polaris_catalog.university_db.course
SELECT 
    id,
    course_code,
    course_name,
    credits,
    program_id,
    prerequisite_course_id,
    CAST(TO_TIMESTAMP_LTZ(created_at/1000, 3) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.course;

-- Lecturer Streaming
INSERT INTO polaris_catalog.university_db.lecturer
SELECT 
    id,
    lecturer_id,
    first_name,
    last_name,
    email,
    phone,
    faculty_id,
    specialization,
    employment_status,
    CAST(TO_TIMESTAMP_LTZ(created_at/1000, 3) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.lecturer;

-- Payment Streaming
INSERT INTO polaris_catalog.university_db.payment
SELECT 
    id,
    payment_id,
    student_id,
    amount,
    payment_type,
    payment_method,
    payment_date,
    semester,
    academic_year,
    status,
    CAST(TO_TIMESTAMP_LTZ(created_at/1000, 3) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.payment;

-- Registration Streaming
INSERT INTO polaris_catalog.university_db.registration
SELECT 
    id,
    student_id,
    class_id,
    registration_date,
    semester,
    academic_year,
    status,
    grade,
    CAST(TO_TIMESTAMP_LTZ(created_at/1000, 3) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.registration;

-- Room Streaming
INSERT INTO polaris_catalog.university_db.room
SELECT 
    id,
    room_code,
    room_name,
    building,
    floor_number,
    capacity,
    room_type,
    facilities,
    CAST(TO_TIMESTAMP_LTZ(created_at/1000, 3) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.room;

-- Student Detail Streaming
INSERT INTO polaris_catalog.university_db.student_detail
SELECT 
    id,
    student_id,
    address,
    city,
    province,
    postal_code,
    date_of_birth,
    place_of_birth,
    gender,
    nationality,
    religion,
    CAST(TO_TIMESTAMP_LTZ(created_at/1000, 3) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.student_detail;

-- Student Enrollment Streaming
INSERT INTO polaris_catalog.university_db.student_enrollment
SELECT 
    id,
    student_id,
    semester,
    academic_year,
    enrollment_date,
    status,
    total_credits,
    gpa,
    CAST(TO_TIMESTAMP_LTZ(created_at/1000, 3) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.student_enrollment;

-- Student Fee Streaming
INSERT INTO polaris_catalog.university_db.student_fee
SELECT 
    id,
    student_id,
    fee_type,
    amount,
    semester,
    academic_year,
    due_date,
    status,
    CAST(TO_TIMESTAMP_LTZ(created_at/1000, 3) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.student_fee;

-- Continue with similar INSERT statements for other tables...