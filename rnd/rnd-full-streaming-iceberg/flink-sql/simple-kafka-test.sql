-- =====================================================
-- STEP 2: SIMPLE KAFKA CONNECTIVITY TEST
-- =====================================================

-- Create Kafka source table
CREATE TABLE faculty_from_kafka (
    id BIGINT,
    faculty_code STRING,
    faculty_name STRING,
    `__op` STRING
) WITH (
    'connector' = 'kafka',
    'topic' = 'university-server.public.faculty',
    'properties.bootstrap.servers' = 'kafka-broker:29092',
    'properties.group.id' = 'test-group',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'debezium-json'
);

-- Create print sink to verify data
CREATE TABLE print_sink (
    id BIGINT,
    faculty_code STRING,
    faculty_name STRING,
    operation STRING
) WITH (
    'connector' = 'print'
);

-- Simple streaming job: Kafka → Print
INSERT INTO print_sink 
SELECT 
    id,
    faculty_code,
    faculty_name,
    `__op` as operation
FROM faculty_from_kafka
WHERE `__op` IN ('c', 'r', 'u'); 