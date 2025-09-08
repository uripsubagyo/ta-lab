# University Streaming Pipeline Guide
## PostgreSQL → Debezium → Kafka → Flink → Iceberg

### 📋 Prerequisites
1. ✅ Docker containers running: `postgres`, `debezium-connect`, `kafka-broker`, `flink-jobmanager`, `flink-taskmanager`, `polaris`, `minio`
2. ✅ Debezium connector `debezium-postgres-connector` configured and running
3. ✅ University database schema created in PostgreSQL

### 🚀 Step 1: Setup Flink Catalogs and Tables
```bash
# Connect to Flink SQL Client
docker exec -it flink-sql-client sql-client.sh

# Run the setup script
SOURCE '/opt/flink/sql/setup-university-streaming-pipeline.sql';
```

### 🔍 Step 2: Verify Setup
```sql
-- Check catalogs
SHOW CATALOGS;

-- Check Kafka tables
SHOW TABLES FROM kafka_catalog.university_db;

-- Check Iceberg tables  
SHOW TABLES FROM polaris_catalog.university_lakehouse;

-- Test Kafka connectivity (should show data if CDC is working)
SELECT * FROM kafka_catalog.university_db.faculty LIMIT 5;
```

### 📊 Step 3: Start Streaming Jobs
**Option A: Run all jobs at once**
```sql
SOURCE '/opt/flink/sql/start-streaming-jobs.sql';
```

**Option B: Run individual jobs (recommended for testing)**
```sql
-- Start faculty streaming
INSERT INTO polaris_catalog.university_lakehouse.faculty
SELECT 
    id,
    faculty_code,
    faculty_name,
    created_at,
    CURRENT_TIMESTAMP as ingestion_time
FROM kafka_catalog.university_db.faculty;
```

### 🧪 Step 4: Test the Pipeline

#### Test 1: Insert new faculty data
```sql
-- In PostgreSQL
docker exec -it rnd-2-full-streaming-iceberg-postgres-1 psql -U postgres -d university -c "
INSERT INTO university.faculty (faculty_code, faculty_name) 
VALUES ('MED', 'Faculty of Medicine');
"
```

#### Test 2: Check data in Iceberg
```sql
-- In Flink SQL Client
SELECT * FROM polaris_catalog.university_lakehouse.faculty 
ORDER BY ingestion_time DESC 
LIMIT 10;
```

#### Test 3: Verify streaming job status
```sql
-- Check running jobs
SHOW JOBS;

-- Check job details
DESCRIBE JOB '<job-id>';
```

### 🔧 Troubleshooting

#### Problem: No data in Kafka topics
**Check:**
1. Debezium connector status:
   ```bash
   curl http://localhost:8083/connectors/debezium-postgres-connector/status
   ```
2. PostgreSQL replication slots:
   ```sql
   SELECT * FROM pg_replication_slots;
   ```
3. Kafka topics exist:
   ```bash
   docker exec kafka-broker /opt/kafka/bin/kafka-topics.sh --list --bootstrap-server kafka-broker:29092
   ```

#### Problem: Flink can't connect to Kafka
**Check:**
1. Network connectivity: `kafka-broker:29092`
2. Format configuration: should be `debezium-json`
3. Topic names match Debezium pattern: `dbserver1.university.faculty`

#### Problem: Iceberg tables not created
**Check:**
1. Polaris service health: `curl http://localhost:8181/healthcheck`
2. MinIO credentials and buckets
3. Catalog configuration in Flink

### 📈 Monitoring

#### Check Kafka Consumer Lag
```bash
docker exec kafka-broker /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server kafka-broker:29092 \
  --describe --all-groups
```

#### Monitor Flink Jobs
- Web UI: `http://localhost:8081`
- Check job metrics, throughput, and backpressure

#### Query Iceberg Data
```sql
-- Count records per table
SELECT 'faculty' as table_name, COUNT(*) as record_count 
FROM polaris_catalog.university_lakehouse.faculty
UNION ALL
SELECT 'students', COUNT(*) 
FROM polaris_catalog.university_lakehouse.students;
```

### 🎯 Expected Data Flow

1. **PostgreSQL** → Data changes in `university.faculty`
2. **Debezium** → Captures changes via PostgreSQL logical replication
3. **Kafka** → Stores change events in topic `dbserver1.university.faculty`
4. **Flink** → Reads from Kafka topic, processes data
5. **Iceberg** → Stores processed data in lakehouse format
6. **MinIO** → Physical storage backend for Iceberg files

### 📋 Complete Table List

The pipeline supports these tables:
- ✅ faculty
- ✅ program  
- ✅ students
- ✅ class
- ✅ course
- ✅ lecturer
- ✅ payment
- ✅ registration
- ✅ room
- ✅ student_detail
- ✅ student_enrollment
- ✅ student_fee

### 🔄 Data Format Notes

**Debezium JSON Format:**
```json
{
  "before": null,
  "after": {
    "id": 1,
    "faculty_code": "FCS",
    "faculty_name": "Faculty of Computer Science",
    "created_at": "2025-01-01T10:00:00Z"
  },
  "source": {
    "version": "2.7.0.Final",
    "connector": "postgresql",
    "name": "dbserver1",
    "ts_ms": 1735732800000,
    "snapshot": "false",
    "db": "university",
    "schema": "university",
    "table": "faculty"
  },
  "op": "c",
  "ts_ms": 1735732800123
}
```

The `debezium-json` format in Flink automatically extracts the `after` section for INSERT/UPDATE operations. 