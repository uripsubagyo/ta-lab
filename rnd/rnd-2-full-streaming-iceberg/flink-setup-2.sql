
CREATE CATALOG kafka_catalog WITH ('type'='generic_in_memory');

CREATE DATABASE kafka_catalog.university_db;


CREATE TABLE kafka_catalog. university_db.faculty (
    id INT, 
    faculty_code STRING, 
    faculty_name STRING, 
    created_at BIGINT,
    source_timestamp TIMESTAMP (3) METADATA FROM 'value. source. timestamp' VIRTUAL, 
    source_database STRING METADATA FROM 'value. source. database' VIRTUAL, 
    source_schema STRING METADATA FROM 'value. source. schema' VIRTUAL, 
    source_table STRING METADATA FROM 'value.source. table' VIRTUAL, 
    ingestion_timestamp TIMESTAMP(3) METADATA FROM 'value. ingestion-timestamp'
    WITH(
        'connector' = 'kafka'
        'properties.bootstrap.servers' = 'kafka-broker: 29092'
        'topic' = 'dbserver1.university.faculty',
        'format' = 'debezium-json',
        'scan.startup.mode' = 'earliest-offset',
        'debezium-json. schema-include' = 'false',
        'debezium-json. ignore-parse-errors' = 'true'
    );


CREATE TABLE kafka_catalog.university_db.program (
    id INT,
    program_code STRING,
    program_name STRING,
    faculty_id INT,
    degree_level STRING,
    created_at BIGINT,

    -- Debezium metadata fields
    source_timestamp TIMESTAMP(3) METADATA FROM 'value.source.timestamp' VIRTUAL,
    source_database STRING METADATA FROM 'value.source.database' VIRTUAL,
    source_schema STRING METADATA FROM 'value.source.schema' VIRTUAL,
    source_table STRING METADATA FROM 'value.source.table' VIRTUAL,
    ingestion_timestamp TIMESTAMP(3) METADATA FROM 'value.ingestion-timestamp' VIRTUAL
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'topic' = 'dbserver1.university.program',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'debezium-json.schema-include' = 'false',
    'debezium-json.ignore-parse-errors' = 'true'
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
    created_at BIGINT,

    -- Debezium metadata fields
    source_timestamp TIMESTAMP(3) METADATA FROM 'value.source.timestamp' VIRTUAL,
    source_database STRING METADATA FROM 'value.source.database' VIRTUAL,
    source_schema STRING METADATA FROM 'value.source.schema' VIRTUAL,
    source_table STRING METADATA FROM 'value.source.table' VIRTUAL,
    ingestion_timestamp TIMESTAMP(3) METADATA FROM 'value.ingestion-timestamp' VIRTUAL
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'topic' = 'dbserver1.university.students',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'debezium-json.schema-include' = 'false',
    'debezium-json.ignore-parse-errors' = 'true'
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
    created_at BIGINT,

    -- Debezium metadata fields
    source_timestamp TIMESTAMP(3) METADATA FROM 'value.source.timestamp' VIRTUAL,
    source_database STRING METADATA FROM 'value.source.database' VIRTUAL,
    source_schema STRING METADATA FROM 'value.source.schema' VIRTUAL,
    source_table STRING METADATA FROM 'value.source.table' VIRTUAL,
    ingestion_timestamp TIMESTAMP(3) METADATA FROM 'value.ingestion-timestamp' VIRTUAL
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'topic' = 'dbserver1.university.class',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'debezium-json.schema-include' = 'false',
    'debezium-json.ignore-parse-errors' = 'true'
);


CREATE TABLE kafka_catalog.university_db.course (
    id INT,
    course_code STRING,
    course_name STRING,
    credits INT,
    program_id INT,
    prerequisite_course_id INT,
    created_at BIGINT,

    -- Debezium metadata fields
    source_timestamp TIMESTAMP(3) METADATA FROM 'value.source.timestamp' VIRTUAL,
    source_database STRING METADATA FROM 'value.source.database' VIRTUAL,
    source_schema STRING METADATA FROM 'value.source.schema' VIRTUAL,
    source_table STRING METADATA FROM 'value.source.table' VIRTUAL,
    ingestion_timestamp TIMESTAMP(3) METADATA FROM 'value.ingestion-timestamp' VIRTUAL
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'topic' = 'dbserver1.university.course',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'debezium-json.schema-include' = 'false',
    'debezium-json.ignore-parse-errors' = 'true'
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
    created_at BIGINT,

    -- Debezium metadata fields
    source_timestamp TIMESTAMP(3) METADATA FROM 'value.source.timestamp' VIRTUAL,
    source_database STRING METADATA FROM 'value.source.database' VIRTUAL,
    source_schema STRING METADATA FROM 'value.source.schema' VIRTUAL,
    source_table STRING METADATA FROM 'value.source.table' VIRTUAL,
    ingestion_timestamp TIMESTAMP(3) METADATA FROM 'value.ingestion-timestamp' VIRTUAL
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'topic' = 'dbserver1.university.lecturer',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'debezium-json.schema-include' = 'false',
    'debezium-json.ignore-parse-errors' = 'true'
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
    created_at BIGINT,

    -- Debezium metadata fields
    source_timestamp TIMESTAMP(3) METADATA FROM 'value.source.timestamp' VIRTUAL,
    source_database STRING METADATA FROM 'value.source.database' VIRTUAL,
    source_schema STRING METADATA FROM 'value.source.schema' VIRTUAL,
    source_table STRING METADATA FROM 'value.source.table' VIRTUAL,
    ingestion_timestamp TIMESTAMP(3) METADATA FROM 'value.ingestion-timestamp' VIRTUAL
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'topic' = 'dbserver1.university.payment',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'debezium-json.schema-include' = 'false',
    'debezium-json.ignore-parse-errors' = 'true'
);

CREATE TABLE kafka_catalog.university_db.registration (
    id INT,
    registration_id STRING,
    student_id INT,
    class_id INT,
    registration_date TIMESTAMP(3),
    semester STRING,
    academic_year STRING,
    status STRING,
    grade STRING,
    created_at BIGINT,

    -- Debezium metadata fields
    source_timestamp TIMESTAMP(3) METADATA FROM 'value.source.timestamp' VIRTUAL,
    source_database STRING METADATA FROM 'value.source.database' VIRTUAL,
    source_schema STRING METADATA FROM 'value.source.schema' VIRTUAL,
    source_table STRING METADATA FROM 'value.source.table' VIRTUAL,
    ingestion_timestamp TIMESTAMP(3) METADATA FROM 'value.ingestion-timestamp' VIRTUAL
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'topic' = 'dbserver1.university.registration',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'debezium-json.schema-include' = 'false',
    'debezium-json.ignore-parse-errors' = 'true'
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
    created_at BIGINT,

    -- Debezium metadata fields
    source_timestamp TIMESTAMP(3) METADATA FROM 'value.source.timestamp' VIRTUAL,
    source_database STRING METADATA FROM 'value.source.database' VIRTUAL,
    source_schema STRING METADATA FROM 'value.source.schema' VIRTUAL,
    source_table STRING METADATA FROM 'value.source.table' VIRTUAL,
    ingestion_timestamp TIMESTAMP(3) METADATA FROM 'value.ingestion-timestamp' VIRTUAL
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'topic' = 'dbserver1.university.room',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'debezium-json.schema-include' = 'false',
    'debezium-json.ignore-parse-errors' = 'true'
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
    created_at BIGINT,

    -- Debezium metadata fields
    source_timestamp TIMESTAMP(3) METADATA FROM 'value.source.timestamp' VIRTUAL,
    source_database STRING METADATA FROM 'value.source.database' VIRTUAL,
    source_schema STRING METADATA FROM 'value.source.schema' VIRTUAL,
    source_table STRING METADATA FROM 'value.source.table' VIRTUAL,
    ingestion_timestamp TIMESTAMP(3) METADATA FROM 'value.ingestion-timestamp' VIRTUAL
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'topic' = 'dbserver1.university.student_detail',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'debezium-json.schema-include' = 'false',
    'debezium-json.ignore-parse-errors' = 'true'
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
    created_at BIGINT,

    -- Debezium metadata fields
    source_timestamp TIMESTAMP(3) METADATA FROM 'value.source.timestamp' VIRTUAL,
    source_database STRING METADATA FROM 'value.source.database' VIRTUAL,
    source_schema STRING METADATA FROM 'value.source.schema' VIRTUAL,
    source_table STRING METADATA FROM 'value.source.table' VIRTUAL,
    ingestion_timestamp TIMESTAMP(3) METADATA FROM 'value.ingestion-timestamp' VIRTUAL
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'topic' = 'dbserver1.university.student_enrollment',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'debezium-json.schema-include' = 'false',
    'debezium-json.ignore-parse-errors' = 'true'
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
    created_at BIGINT,

    -- Debezium metadata fields
    source_timestamp TIMESTAMP(3) METADATA FROM 'value.source.timestamp' VIRTUAL,
    source_database STRING METADATA FROM 'value.source.database' VIRTUAL,
    source_schema STRING METADATA FROM 'value.source.schema' VIRTUAL,
    source_table STRING METADATA FROM 'value.source.table' VIRTUAL,
    ingestion_timestamp TIMESTAMP(3) METADATA FROM 'value.ingestion-timestamp' VIRTUAL
) WITH (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'topic' = 'dbserver1.university.student_fee',
    'format' = 'debezium-json',
    'scan.startup.mode' = 'earliest-offset',
    'debezium-json.schema-include' = 'false',
    'debezium-json.ignore-parse-errors' = 'true'
);
