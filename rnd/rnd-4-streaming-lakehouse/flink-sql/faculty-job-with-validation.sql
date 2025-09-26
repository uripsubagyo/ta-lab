-- Create Kafka Source Table
CREATE TABLE faculty_source (
    id INT,
    faculty_code STRING,
    faculty_name STRING,
    created_at BIGINT,
    source_timestamp TIMESTAMP(3),
    source_database STRING,
    source_schema STRING,
    source_table STRING,
    ingestion_timestamp TIMESTAMP(3),
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'connector' = 'kafka',
    'topic' = 'faculty-topic',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'properties.group.id' = 'faculty-consumer-group',
    'format' = 'json',
    'scan.startup.mode' = 'earliest-offset'
);

-- Create Iceberg Table for Valid Faculty Data
CREATE TABLE faculty_sink (
    id INT,
    faculty_code STRING,
    faculty_name STRING,
    created_at BIGINT,
    source_timestamp TIMESTAMP(3),
    source_database STRING,
    source_schema STRING,
    source_table STRING,
    ingestion_timestamp TIMESTAMP(3),
    validation_status STRING,
    error_message STRING,
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'connector' = 'iceberg',
    'catalog-name' = 'iceberg_catalog',
    'catalog-type' = 'hadoop',
    'warehouse' = 's3a://warehouse/iceberg',
    'format-version' = '2'
);

-- Create Error Logging Table in Kafka
CREATE TABLE faculty_errors (
    id INT,
    faculty_code STRING,
    error_message STRING,
    error_timestamp TIMESTAMP(3),
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'connector' = 'kafka',
    'topic' = 'faculty-errors',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'format' = 'json'
);

-- Create View for Existing Faculty Codes
CREATE VIEW existing_faculty_codes AS
SELECT DISTINCT faculty_code 
FROM faculty_sink
WHERE validation_status = 'VALID';

-- Insert with Validation Logic
INSERT INTO faculty_sink
SELECT 
    s.id,
    s.faculty_code,
    s.faculty_name,
    s.created_at,
    s.source_timestamp,
    s.source_database,
    s.source_schema,
    s.source_table,
    s.ingestion_timestamp,
    CASE 
        WHEN s.faculty_code IS NULL OR TRIM(s.faculty_code) = '' THEN 'INVALID'
        WHEN s.faculty_name IS NULL OR TRIM(s.faculty_name) = '' THEN 'INVALID'
        WHEN EXISTS (
            SELECT 1 FROM existing_faculty_codes 
            WHERE faculty_code = s.faculty_code
        ) THEN 'DUPLICATE'
        ELSE 'VALID'
    END as validation_status,
    CASE 
        WHEN s.faculty_code IS NULL OR TRIM(s.faculty_code) = '' THEN 'Faculty code cannot be empty'
        WHEN s.faculty_name IS NULL OR TRIM(s.faculty_name) = '' THEN 'Faculty name cannot be empty'
        WHEN EXISTS (
            SELECT 1 FROM existing_faculty_codes 
            WHERE faculty_code = s.faculty_code
        ) THEN 'Faculty code already exists'
        ELSE NULL
    END as error_message
FROM faculty_source s;

-- Log Errors to Kafka
INSERT INTO faculty_errors
SELECT 
    id,
    faculty_code,
    error_message,
    CURRENT_TIMESTAMP
FROM faculty_sink
WHERE validation_status IN ('INVALID', 'DUPLICATE'); 