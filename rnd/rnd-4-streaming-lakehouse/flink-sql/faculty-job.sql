-- Create Kafka Source Table for Faculty Events
CREATE TABLE faculty_source (
    action STRING,
    data ROW(
        id INT,
        name STRING,
        code STRING
    ),
    timestamp STRING,
    -- Metadata fields
    proctime AS PROCTIME(),
    WATERMARK FOR timestamp AS timestamp
) WITH (
    'connector' = 'kafka',
    'topic' = 'faculty-topic',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'properties.group.id' = 'faculty-consumer-group',
    'format' = 'json',
    'json.fail-on-missing-field' = 'false',
    'json.ignore-parse-errors' = 'true',
    'scan.startup.mode' = 'earliest-offset'
);

-- Create Iceberg Sink Table for Faculty
CREATE TABLE faculty_sink (
    id INT,
    faculty_code STRING,
    faculty_name STRING,
    created_at TIMESTAMP(3),
    updated_at TIMESTAMP(3),
    is_active BOOLEAN,
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'connector' = 'iceberg',
    'catalog-name' = 'iceberg_catalog',
    'catalog-type' = 'hadoop',
    'warehouse' = 's3a://warehouse/iceberg',
    'format-version' = '2'
);

-- Create a view to handle the event processing logic
CREATE VIEW faculty_processed AS
SELECT
    -- For new records (CREATE), generate a new ID
    -- For updates, use the existing ID
    COALESCE(data.id, CAST(UNIX_TIMESTAMP() * 1000 AS INT)) AS id,
    data.code AS faculty_code,
    data.name AS faculty_name,
    -- Handle timestamps based on action
    CASE 
        WHEN action = 'create' THEN CAST(timestamp AS TIMESTAMP(3))
        ELSE NULL 
    END AS created_at,
    CASE 
        WHEN action = 'update' THEN CAST(timestamp AS TIMESTAMP(3))
        ELSE NULL 
    END AS updated_at,
    -- Active status
    TRUE AS is_active
FROM faculty_source;

-- Merge data into the sink table
MERGE INTO faculty_sink t 
USING faculty_processed s
ON t.id = s.id
WHEN MATCHED AND s.updated_at IS NOT NULL THEN 
    UPDATE SET 
        faculty_code = s.faculty_code,
        faculty_name = s.faculty_name,
        updated_at = s.updated_at
WHEN NOT MATCHED THEN
    INSERT (id, faculty_code, faculty_name, created_at, updated_at, is_active)
    VALUES (
        s.id,
        s.faculty_code,
        s.faculty_name,
        s.created_at,
        s.updated_at,
        s.is_active
    ); 