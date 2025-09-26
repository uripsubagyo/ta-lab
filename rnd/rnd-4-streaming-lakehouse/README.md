# Streaming Lakehouse with Apache Flink

This project demonstrates a streaming data lakehouse architecture using Apache Flink, Kafka, and Apache Iceberg.

## Python Flink Jobs

### Prerequisites

1. Make sure all services are running:
```bash
docker-compose up -d
```

2. Verify the services are healthy:
```bash
docker-compose ps
```

### Project Structure

```
flink-python/
├── faculty_processor.py     # Main faculty data processor
├── iceberg_connector.py     # Iceberg connection utilities
└── requirements.txt         # Python dependencies
```

### Setting Up Python Environment

1. Build the Flink Python image:
```bash
# From the project root
docker build -f flink/Dockerfile.python -t flink-python .
```

2. Required Python dependencies (requirements.txt):
```
apache-flink==1.17.0
pandas
pyiceberg
```

### Running Python Flink Jobs

#### Faculty Data Processor

The Faculty Data Processor handles the streaming pipeline for faculty data:
- Reads from Kafka topic 'faculty-topic'
- Validates faculty data
- Saves valid records to Iceberg
- Sends error records to 'faculty-errors' topic

To submit the job:

```bash
# Submit the Python job to Flink
docker exec -it flink-jobmanager flink run \
  -py /opt/flink-python/faculty_processor.py \
  -j /opt/flink-python/lib/iceberg-flink-runtime.jar
```

### Monitoring and Debugging

1. View running jobs:
```bash
docker exec -it flink-jobmanager flink list
```

2. Monitor job execution:
- Access Flink Dashboard: http://localhost:8081

3. Check error records:
```bash
# View error messages in Kafka
docker exec -it kafka-broker kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic faculty-errors \
  --from-beginning
```

4. View Iceberg tables:
```bash
# Using Trino CLI
docker exec -it trino trino --execute "
SELECT * FROM iceberg.faculty_sink 
WHERE validation_status = 'VALID'
ORDER BY ingestion_timestamp DESC
LIMIT 5;"
```

### Validation Rules

The faculty processor implements the following validation rules:

1. Faculty Code:
   - Required field
   - Alphanumeric, 3-10 characters
   - Must start with a letter
   - Must be unique

2. Faculty Name:
   - Required field
   - Length between 5-100 characters
   - Only letters, numbers, spaces, and basic punctuation

### Error Handling

Errors are categorized into:
- `INVALID`: Failed validation rules
- `DUPLICATE`: Faculty code already exists
- `ERROR`: Processing or system errors

All errors are sent to the 'faculty-errors' Kafka topic with detailed messages.

### Development Guide

To modify or extend the processor:

1. Update validation rules in `faculty_processor.py`:
```python
def validate_faculty(self, data):
    # Add your validation rules here
    pass
```

2. Add new Iceberg operations in `iceberg_connector.py`:
```python
def your_new_method(self):
    # Add your Iceberg operations here
    pass
```

3. Test locally:
```bash
# Run with debugging enabled
docker exec -it flink-jobmanager flink run -d \
  -py /opt/flink-python/faculty_processor.py
```

### Troubleshooting

Common issues and solutions:

1. Job fails to start:
   - Check if Kafka topics exist
   - Verify Iceberg catalog is accessible
   - Check Python dependencies

2. Data not appearing in Iceberg:
   - Check validation rules
   - Verify Iceberg connection settings
   - Look for errors in Flink logs

3. Performance issues:
   - Adjust parallelism in FacultyProcessor
   - Monitor Kafka consumer lag
   - Check Iceberg write performance

For more detailed logs:
```bash
docker logs -f flink-jobmanager
docker logs -f flink-taskmanager
```