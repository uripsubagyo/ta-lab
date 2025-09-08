-- =================================================================
-- TEST KAFKA CONNECTION ONLY
-- Test basic Flink connectivity to Kafka without Iceberg
-- =================================================================

-- Create a simple Kafka source table
CREATE TABLE kafka_faculty_test (
    id BIGINT,
    faculty_code STRING,
    faculty_name STRING,
    created_at BIGINT,
    `__deleted` STRING,
    `__op` STRING,
    `__ts_ms` BIGINT
) WITH (
    'connector' = 'kafka',
    'topic' = 'university-server.public.faculty',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'properties.group.id' = 'flink-test',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'debezium-json'
);

-- Test query to see data
SELECT 
    id,
    faculty_code,
    faculty_name,
    `__op` as operation,
    `__ts_ms` as timestamp_ms
FROM kafka_faculty_test
WHERE `__op` IN ('r', 'c', 'u')
LIMIT 10; 