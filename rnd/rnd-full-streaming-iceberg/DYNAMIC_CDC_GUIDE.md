# Dynamic Table-Specific CDC System Guide

## 🎯 Overview

Sistem ini memungkinkan Anda untuk menjalankan streaming job Flink secara **dinamis** berdasarkan tabel yang mengalami perubahan. Ketika ada perubahan di tabel `faculty`, hanya job untuk `faculty` yang akan dijalankan, bukan semua job sekaligus.

## 🏗️ Arsitektur

```
PostgreSQL → Debezium → Kafka → Python Orchestrator → Flink Job (Per Table) → Iceberg → MinIO
                                      ↓
                               Detects table changes
                               Triggers specific jobs
```

### Komponen Utama:
1. **Dynamic CDC Orchestrator**: Python service yang mendengarkan Kafka topics
2. **Table-Specific Jobs**: Flink SQL jobs untuk setiap tabel  
3. **Job Manager**: SQL script yang mendefinisikan semua tabel sources dan sinks
4. **Individual Job Starters**: Scripts terpisah untuk memulai job per tabel

## 🚀 Quick Start

### 1. Start Core Services
```bash
# Start semua service utama
docker-compose up -d postgres kafka-broker debezium-connect \
  flink-jobmanager flink-taskmanager flink-sql-client \
  polaris minio minio-client

# Register Debezium connector
docker-compose up -d register-university-connector
```

### 2. Setup Flink Catalog dan Tables (One-time)
```bash
# Setup catalog dan definisi tabel (hanya perlu dijalankan sekali)
docker exec rnd-full-streaming-iceberg-flink-sql-client-1 bash -c "
/opt/flink/bin/sql-client.sh -f /opt/flink/sql/dynamic-table-job-manager.sql
"
```

### 3. Start Dynamic Orchestrator
```bash
# Start orchestrator yang akan mendeteksi perubahan dan trigger jobs
docker-compose --profile orchestrator up -d cdc-orchestrator
```

### 4. Test the System
```bash
# Jalankan automated test
chmod +x test-dynamic-cdc.sh
./test-dynamic-cdc.sh
```

## 📋 Manual Testing

### Insert Data ke PostgreSQL
```sql
-- Test faculty table
docker exec rnd-full-streaming-iceberg-postgres-1 psql -U postgres -d sourcedb -c "
INSERT INTO faculty (faculty_code, faculty_name) VALUES ('FIKOM', 'Fakultas Ilmu Komputer');
"

-- Test program table  
docker exec rnd-full-streaming-iceberg-postgres-1 psql -U postgres -d sourcedb -c "
INSERT INTO program (program_code, program_name, faculty_id, degree) VALUES ('INFM', 'Informatika', 1, 'S1');
"
```

### Monitor Orchestrator
```bash
# Live monitoring
docker logs -f rnd-full-streaming-iceberg-cdc-orchestrator-1

# Check recent activity
docker logs rnd-full-streaming-iceberg-cdc-orchestrator-1 --tail 50
```

## 🔍 How It Works

### 1. Change Detection
- Orchestrator subscribes ke semua Kafka topics: `university-server.public.*`
- Ketika ada message baru (CREATE, UPDATE, READ operations)
- Orchestrator extract table name dari topic name

### 2. Job Triggering Logic
```python
# Pseudocode
if table_change_detected:
    table_name = extract_table_from_topic(kafka_topic)
    
    if should_trigger_job(table_name):  # Check rate limiting & active jobs
        execute_flink_job(table_name)   # Start specific job
        mark_job_as_active(table_name)
```

### 3. Rate Limiting
- Jobs tidak akan di-trigger jika ada activity dalam 30 detik terakhir
- Mencegah duplicate jobs untuk table yang sama
- Auto cleanup setelah 60 detik inactivity

### 4. Supported Tables
Currently configured untuk tables:
- ✅ `faculty` 
- ✅ `program`
- ✅ `students` 
- ✅ `payment`
- 🔄 `lecturer`, `course`, `registration`, dll (bisa ditambahkan)

## 📊 Monitoring & Verification

### Check Flink Jobs
```bash
# Lihat active jobs di Flink
docker exec rnd-full-streaming-iceberg-flink-sql-client-1 bash -c "
echo 'SHOW JOBS;' | /opt/flink/bin/sql-client.sh
"
```

### Verify Data in Iceberg via Trino
```bash
# Connect to Trino
docker exec -it rnd-full-streaming-iceberg-trino-1 trino

# Query data
USE iceberg.university;
SHOW TABLES;
SELECT * FROM faculty LIMIT 10;
SELECT * FROM program LIMIT 10;
```

### Check MinIO Storage
```bash
# Access MinIO Console: http://localhost:9001
# Username: admin
# Password: password
```

## 🛠️ Customization

### Add New Table Support

1. **Update Orchestrator** (`python-jobs/dynamic_cdc_orchestrator.py`):
```python
# Add to table_topics mapping
self.table_topics = {
    'your_table': 'university-server.public.your_table',
    # ... existing tables
}

# Add to job_files mapping  
self.job_files = {
    'your_table': '/opt/flink/sql/jobs/start-your-table-job.sql',
    # ... existing files
}
```

2. **Create Job Starter** (`flink-sql/jobs/start-your-table-job.sql`):
```sql
USE CATALOG iceberg_catalog;
USE university;

INSERT INTO iceberg_your_table
SELECT 
  -- your columns
FROM kafka_your_table
WHERE op IN ('r', 'c', 'u');
```

3. **Add Table Definition** to `dynamic-table-job-manager.sql`:
```sql
-- Kafka Source
CREATE TABLE IF NOT EXISTS kafka_your_table (
  -- define columns with op, ts_ms
) WITH (
  'connector' = 'kafka',
  'topic' = 'university-server.public.your_table',
  -- ... kafka config
);

-- Iceberg Sink  
CREATE TABLE IF NOT EXISTS iceberg_your_table (
  -- define columns + ingestion_time
) WITH (
  'connector' = 'iceberg',
  -- ... iceberg config
);
```

## 🐛 Troubleshooting

### Common Issues

1. **Orchestrator not detecting changes**:
   ```bash
   # Check Kafka topics
   docker exec rnd-full-streaming-iceberg-kafka-broker-1 kafka-topics.sh \
     --bootstrap-server localhost:9092 --list
   
   # Check if Debezium is producing messages
   docker exec rnd-full-streaming-iceberg-kafka-broker-1 kafka-console-consumer.sh \
     --bootstrap-server localhost:9092 --topic university-server.public.faculty --from-beginning
   ```

2. **Flink jobs failing**:
   ```bash
   # Check Flink logs
   docker logs rnd-full-streaming-iceberg-flink-jobmanager-1
   docker logs rnd-full-streaming-iceberg-flink-taskmanager-1
   ```

3. **Polaris connection issues**:
   ```bash
   # Check Polaris health
   curl http://localhost:8182/healthcheck
   ```

### Reset Everything
```bash
# Stop all services
docker-compose --profile orchestrator down

# Remove volumes (⚠️ deletes all data)
docker-compose down -v

# Start fresh
./test-dynamic-cdc.sh
```

## 🎉 Success Indicators

Sistem bekerja dengan benar jika:

1. ✅ Orchestrator logs menunjukkan "Detected c/u operation on table: faculty"
2. ✅ Orchestrator logs menunjukkan "Successfully triggered job for: faculty"  
3. ✅ Flink Web UI (http://localhost:8081) menampilkan running jobs
4. ✅ Data muncul di Iceberg tables via Trino queries
5. ✅ MinIO menunjukkan files baru di bucket `warehouse`

## 📚 Key Files

- `dynamic-table-job-manager.sql`: Defines all table sources and sinks
- `jobs/start-*-job.sql`: Individual job starters per table
- `python-jobs/dynamic_cdc_orchestrator.py`: Main orchestrator logic
- `test-dynamic-cdc.sh`: Automated testing script

Sistem ini memberikan control yang fine-grained atas CDC processing, memungkinkan efficient resource usage dan better monitoring per table! 