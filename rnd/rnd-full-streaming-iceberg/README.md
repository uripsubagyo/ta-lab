# Streaming Data Lakehouse Setup Guide

## Architecture Overview

This setup creates a real-time streaming data lakehouse with the following flow:
```
PostgreSQL → Debezium → Kafka → Flink → Iceberg → MinIO (Storage)
                                          ↓
                                       Trino (Query Engine)
```

## Components

- **PostgreSQL**: Source database with WAL enabled for CDC
- **Debezium**: Change Data Capture connector
- **Kafka**: Streaming message broker  
- **Flink**: Stream processing engine
- **Polaris**: Iceberg catalog service
- **MinIO**: S3-compatible object storage
- **Trino**: Query engine for analytics

## Prerequisites

- Docker and Docker Compose
- Basic understanding of SQL and streaming concepts

## Step-by-Step Manual Setup

### Step 1: Start All Services

```bash
cd rnd/rnd-full-streaming-iceberg
docker-compose up -d
```

Wait for all services to start (approximately 2-3 minutes).

### Step 2: Verify All Services Are Running

Check that all containers are healthy:

```bash
docker-compose ps
```

All services should show "Up" status. Key ports to verify:
- PostgreSQL: 5433
- Kafka: 9092  
- Debezium Connect: 8083
- Flink JobManager: 8081
- Polaris: 8181
- MinIO: 9000, 9001
- Trino: 8080

### Step 3: Verify Individual Service Health

#### 3.1 PostgreSQL Connection Test
```bash
docker exec -it $(docker-compose ps -q postgres) psql -U postgres -d sourcedb -c "\dt"
```
Should show university tables.

#### 3.2 Kafka Broker Test
```bash
docker exec -it $(docker-compose ps -q kafka-broker) kafka-topics.sh --bootstrap-server localhost:29092 --list
```

#### 3.3 Debezium Connect Test
```bash
curl -H "Accept:application/json" localhost:8083/
curl -H "Accept:application/json" localhost:8083/connectors/
```

#### 3.4 Flink JobManager Test  
```bash
curl -s http://localhost:8081/overview
```

#### 3.5 Polaris Catalog Test
```bash
curl -s http://localhost:8181/api/management/v1/catalogs
```

#### 3.6 MinIO Console Access
Open browser: http://localhost:9001
- Username: admin
- Password: password

#### 3.7 Trino Query Interface Test
```bash
docker exec -it $(docker-compose ps -q trino) trino --server localhost:8080 --catalog iceberg --schema information_schema --execute "SELECT 1"
```

### Step 4: Verify CDC is Working

#### 4.1 Check Debezium Connector Status
```bash
curl -s http://localhost:8083/connectors/university-connector/status | jq
```

Should show `"state": "RUNNING"`.

#### 4.2 Monitor Kafka Topics
```bash
# List all topics (should include university tables)
docker exec -it $(docker-compose ps -q kafka-broker) kafka-topics.sh --bootstrap-server localhost:29092 --list

# Check messages in a specific topic
docker exec -it $(docker-compose ps -q kafka-broker) kafka-console-consumer.sh --bootstrap-server localhost:29092 --topic university-server.public.faculty --from-beginning --max-messages 5
```

### Step 5: Connect to Flink SQL Client

```bash
docker-compose exec flink-sql-client /opt/flink/bin/sql-client.sh
```

### Step 6: Setup Iceberg Catalog in Flink

In the Flink SQL client, run:

```sql
-- Execute the catalog setup
\i /opt/flink/sql/setup-catalog-only.sql
```

Verify the setup:
```sql
SHOW CATALOGS;
USE CATALOG iceberg_catalog;
SHOW DATABASES;
```

### Step 7: Run Individual Streaming Jobs

#### 7.1 Start Faculty Table Streaming Job
```sql
\i /opt/flink/sql/individual-jobs/setup-faculty-job.sql
```

#### 7.2 Start Student Fee Table Streaming Job  
```sql
\i /opt/flink/sql/individual-jobs/setup-student-fee-job.sql
```

#### 7.3 Monitor Running Jobs
In Flink Web UI (http://localhost:8081), you should see:
- Running Jobs section showing active streaming jobs
- Each job processing messages from Kafka

### Step 8: Verify Data Flow to MinIO

#### 8.1 Check MinIO Storage
1. Open MinIO Console: http://localhost:9001
2. Navigate to `warehouse` bucket
3. Look for Iceberg table files under paths like:
   ```
   warehouse/polariscatalog/university/faculty/
   warehouse/polariscatalog/university/student_fee/
   ```

#### 8.2 Query Data with Trino
```bash
docker exec -it $(docker-compose ps -q trino) trino --server localhost:8080 --catalog iceberg --schema university
```

In Trino CLI:
```sql
SHOW TABLES;
SELECT COUNT(*) FROM faculty;
SELECT COUNT(*) FROM student_fee;
SELECT * FROM faculty LIMIT 5;
```

### Step 9: Test Real-time Changes

#### 9.1 Insert Test Data in PostgreSQL
```bash
docker exec -it $(docker-compose ps -q postgres) psql -U postgres -d sourcedb
```

```sql
-- Insert a new faculty
INSERT INTO faculty (faculty_code, faculty_name) VALUES ('TEST', 'Test Faculty');

-- Update student fee
UPDATE student_fee SET ukt_fee = 5000000 WHERE student_id = 'STD-2020-001';
```

#### 9.2 Verify Real-time Processing
1. Check Kafka topic for new messages:
```bash
docker exec -it $(docker-compose ps -q kafka-broker) kafka-console-consumer.sh --bootstrap-server localhost:29092 --topic university-server.public.faculty --from-beginning --max-messages 1
```

2. Check Flink job is processing (in Flink Web UI):
   - Go to Running Jobs → Your job → Overview
   - See "Records Received" increasing

3. Query updated data in Trino:
```sql
SELECT * FROM faculty WHERE faculty_code = 'TEST';
SELECT * FROM student_fee WHERE student_id = 'STD-2020-001' ORDER BY ingestion_time DESC LIMIT 5;
```

## Adding More Tables

To add streaming for additional tables:

1. Create a new individual job file:
```bash
cp flink-sql/individual-jobs/setup-faculty-job.sql flink-sql/individual-jobs/setup-[table-name]-job.sql
```

2. Modify the new file to match your table schema

3. Run the job in Flink SQL client:
```sql
\i /opt/flink/sql/individual-jobs/setup-[table-name]-job.sql
```

## Troubleshooting

### Common Issues

#### 1. Debezium Connector Not Starting
```bash
# Check connector logs
docker-compose logs debezium-connect

# Delete and recreate connector
curl -X DELETE http://localhost:8083/connectors/university-connector
curl -X POST http://localhost:8083/connectors -H "Content-Type: application/json" --data-binary @debezium/university-connector.json
```

#### 2. Flink Cannot Connect to Polaris
- Verify Polaris is running: `curl http://localhost:8181/healthcheck`
- Check Flink logs: `docker-compose logs flink-jobmanager`

#### 3. No Data Appearing in MinIO
- Verify Kafka topics have messages
- Check Flink job status in Web UI
- Ensure MinIO bucket exists and is accessible

#### 4. Trino Cannot Query Tables
- Verify Iceberg tables are created in Polaris catalog
- Check Trino catalog configuration
- Ensure S3 credentials are correct

### Checking Logs

```bash
# View logs for specific service
docker-compose logs -f [service-name]

# Examples:
docker-compose logs -f debezium-connect
docker-compose logs -f flink-jobmanager
docker-compose logs -f polaris
```

### Cleanup and Restart

```bash
# Stop all services
docker-compose down

# Remove volumes (WARNING: This deletes all data)
docker-compose down -v

# Restart fresh
docker-compose up -d
```

## Performance Tuning

### Flink Configuration
- Adjust parallelism in `flink/conf/flink-conf.yaml`
- Increase memory for large datasets
- Configure checkpointing for fault tolerance

### Kafka Configuration  
- Increase partitions for higher throughput
- Adjust retention policies
- Configure consumer group settings

### MinIO Configuration
- Use multiple drives for better performance
- Configure appropriate bucket policies
- Monitor storage usage

## Monitoring

### Key Metrics to Monitor

1. **Kafka Lag**: Consumer group lag in Kafka
2. **Flink Throughput**: Records processed per second
3. **MinIO Storage**: Used storage space and I/O metrics  
4. **Polaris Health**: Catalog service availability
5. **Trino Query Performance**: Query execution times

### Monitoring Commands

```bash
# Kafka consumer lag
docker exec -it $(docker-compose ps -q kafka-broker) kafka-consumer-groups.sh --bootstrap-server localhost:29092 --describe --all-groups

# Flink metrics
curl -s http://localhost:8081/jobs | jq

# MinIO metrics  
curl -s http://localhost:9000/minio/health/live
```

## Security Considerations

- Change default passwords in production
- Configure proper network security
- Enable SSL/TLS for external connections
- Implement proper authentication for Polaris
- Secure MinIO with proper access policies

## Next Steps

1. **Add Data Validation**: Implement schema validation in Flink
2. **Error Handling**: Add dead letter queues for failed messages
3. **Monitoring**: Set up Prometheus/Grafana for metrics
4. **Backup Strategy**: Implement backup for MinIO data
5. **CI/CD Pipeline**: Automate deployment of streaming jobs 