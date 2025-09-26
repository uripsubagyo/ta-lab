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