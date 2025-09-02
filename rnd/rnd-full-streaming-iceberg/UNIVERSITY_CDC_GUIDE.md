# 🎓 University CDC Pipeline Guide

Complete guide untuk setup dan penggunaan **Change Data Capture (CDC) Pipeline** untuk data universitas dari PostgreSQL ke Apache Iceberg menggunakan Kafka dan Flink.

## 🏗️ Architecture Overview

```
PostgreSQL (University Data) → Debezium → Kafka → Flink → Iceberg → Trino
```

### 🧩 Components

- **PostgreSQL 15**: Source database dengan logical replication enabled
- **Debezium Connect**: CDC connector untuk capture perubahan data PostgreSQL
- **Apache Kafka**: Message streaming platform untuk transport data
- **Apache Flink**: Stream processing engine untuk transform dan load data
- **Apache Polaris**: Iceberg REST catalog service
- **MinIO**: S3-compatible object storage untuk Iceberg data files
- **Trino**: SQL query engine untuk query data di Iceberg

## 📋 Prerequisites

- Docker & Docker Compose installed
- `curl` dan `jq` untuk testing
- Minimal 8GB RAM tersedia untuk containers
- Port 5433, 8080, 8081, 8083, 9000, 9001, 9092 harus available

## 🚀 Quick Start

### 1. Generate University Data

Pertama, pastikan data universitas sudah di-generate:

```bash
cd generate-data
source data_gen_env/bin/activate
python3 setup_and_run.py
```

### 2. Start CDC Pipeline

Jalankan script automation untuk start seluruh pipeline:

```bash
chmod +x start-university-cdc-pipeline.sh
./start-university-cdc-pipeline.sh
```

Script ini akan:
- Start semua Docker containers
- Wait sampai semua services ready
- Setup Debezium connector untuk university schema
- Verify Kafka topics terbuat
- Display access URLs dan next steps

### 3. Setup Flink Jobs

Setup Flink SQL jobs untuk streaming data:

```bash
chmod +x setup-flink-jobs.sh
./setup-flink-jobs.sh
```

Pilih option:
- **Option 1 (Recommended)**: Manual setup - membuka Flink SQL Client
- **Option 2**: Quick test - setup table faculty saja untuk testing

### 4. Test Pipeline

Verify bahwa pipeline bekerja dengan benar:

```bash
chmod +x test-university-pipeline.sh
./test-university-pipeline.sh
```

## 📊 Detailed Setup Steps

### Step 1: University Data Schema

Pipeline ini menggunakan schema universitas dengan tables:

#### Master Data Tables:
- `faculty` - Data fakultas
- `program` - Program studi per fakultas  
- `lecturer` - Data dosen
- `room` - Data ruangan
- `course` - Data mata kuliah

#### Transactional Tables:
- `students` - Data mahasiswa
- `student_detail` - Detail lengkap mahasiswa
- `student_fee` - Biaya kuliah mahasiswa
- `registration` - Registrasi semester mahasiswa
- `class` - Kelas kuliah
- `student_enrollment` - Enrollment mahasiswa ke kelas
- `payment` - Pembayaran mahasiswa

### Step 2: Debezium Configuration

File `debezium/university-connector.json` mengkonfigurasi:

```json
{
  "name": "university-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "postgres",
    "database.port": "5432",
    "database.user": "postgres", 
    "database.password": "postgres",
    "database.dbname": "sourcedb",
    "database.server.name": "university-server",
    "schema.include.list": "public",
    "table.include.list": "public.faculty,public.program,public.lecturer,public.students,public.room,public.course,public.semester,public.class_schedule,public.registration,public.enrollment,public.grade,public.attendance,public.semester_fee,public.payment"
  }
}
```

### Step 3: Flink SQL Jobs

File `flink-sql/university-cdc-pipeline.sql` berisi:

1. **Iceberg Catalog Setup**
2. **Kafka Source Tables** - untuk setiap university table
3. **Iceberg Sink Tables** - target tables di Iceberg  
4. **INSERT Jobs** - streaming dari Kafka ke Iceberg

#### Contoh Kafka Source Table:

```sql
CREATE TABLE kafka_faculty (
  id INT,
  faculty_code STRING,
  faculty_name STRING,
  created_at TIMESTAMP(3),
  op STRING,
  ts_ms BIGINT,
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector' = 'kafka',
  'topic' = 'university-server.public.faculty',
  'properties.bootstrap.servers' = 'kafka-broker:29092',
  'format' = 'debezium-json'
);
```

#### Contoh Iceberg Sink Table:

```sql
CREATE TABLE faculty_iceberg (
  id INT,
  faculty_code STRING,
  faculty_name STRING,
  created_at TIMESTAMP(3),
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'faculty_iceberg'
);
```

#### Contoh INSERT Job:

```sql
INSERT INTO faculty_iceberg
SELECT id, faculty_code, faculty_name, created_at
FROM kafka_faculty
WHERE op != 'd';  -- Exclude deletes
```

## 🔧 Manual Setup

### Setup Flink Jobs Step by Step

1. **Access Flink SQL Client:**
   ```bash
   docker exec -it $(docker ps -q -f name=flink-sql-client) sql-client.sh
   ```

2. **Setup Catalog:**
   ```sql
   CREATE CATALOG iceberg_catalog WITH (
     'type' = 'iceberg',
     'catalog-type' = 'rest',
     'uri' = 'http://polaris:8181/api/catalog/',
     'warehouse' = 'polariscatalog',
     'credential' = 'root:secret',
     'scope' = 'PRINCIPAL_ROLE:ALL',
     's3.endpoint' = 'http://minio:9000',
     's3.region' = 'dummy-region',
     's3.access-key-id' = 'admin',
     's3.secret-access-key' = 'password'
   );
   
   USE CATALOG iceberg_catalog;
   CREATE DATABASE IF NOT EXISTS university;
   USE university;
   ```

3. **Create Tables:**
   Copy dan execute sections dari `flink-sql/university-cdc-pipeline.sql`

4. **Start Streaming Jobs:**
   Execute INSERT statements satu per satu untuk setiap table

## 📊 Monitoring & Access

### Service URLs

- **Flink Web UI**: http://localhost:8081
- **Debezium Connect**: http://localhost:8083  
- **MinIO Console**: http://localhost:9001 (admin/password)
- **Trino**: http://localhost:8080
- **PostgreSQL**: localhost:5433 (postgres/postgres)

### Monitoring Commands

```bash
# Check running containers
docker-compose ps

# Check Debezium connector status
curl http://localhost:8083/connectors/university-connector/status

# List Kafka topics
docker exec kafka-broker kafka-topics.sh --bootstrap-server localhost:9092 --list

# Check Flink jobs
curl http://localhost:8081/jobs

# View container logs
docker-compose logs -f [service-name]
```

## 📊 Query Data

### Query with Trino

```bash
# Access Trino CLI
docker exec -it $(docker ps -q -f name=trino) trino

# Query examples
trino> USE iceberg.university;
trino> SHOW TABLES;
trino> SELECT * FROM faculty_iceberg LIMIT 10;
trino> SELECT COUNT(*) FROM students_iceberg;
trino> SELECT f.faculty_name, COUNT(s.student_id) as student_count 
       FROM faculty_iceberg f 
       LEFT JOIN students_iceberg s ON f.id = s.faculty_id 
       GROUP BY f.faculty_name;
```

### Query PostgreSQL Source

```bash
# Access PostgreSQL
docker exec rnd-full-streaming-iceberg-postgres-1 psql -U postgres -d sourcedb

# Query examples
sourcedb=# SELECT COUNT(*) FROM faculty;
sourcedb=# SELECT COUNT(*) FROM students;
sourcedb=# \dt  -- List tables
```

## 🧪 Testing

### Automated Testing

```bash
./test-university-pipeline.sh
```

Test script akan:
1. Check service health
2. Insert test data ke PostgreSQL
3. Verify data masuk ke Kafka topics
4. Check data masuk ke Iceberg tables
5. Compare data consistency

### Manual Testing

1. **Insert test data:**
   ```sql
   INSERT INTO faculty (faculty_code, faculty_name) 
   VALUES ('TEST', 'Test Faculty');
   ```

2. **Check Kafka topic:**
   ```bash
   docker exec kafka-broker kafka-console-consumer.sh \
     --bootstrap-server localhost:9092 \
     --topic university-server.public.faculty \
     --from-beginning
   ```

3. **Verify in Iceberg:**
   ```sql
   SELECT * FROM iceberg.university.faculty_iceberg 
   WHERE faculty_code = 'TEST';
   ```

## 🔧 Troubleshooting

### Common Issues

1. **Debezium connector failed:**
   ```bash
   # Check connector logs
   curl http://localhost:8083/connectors/university-connector/status
   
   # Restart connector
   curl -X POST http://localhost:8083/connectors/university-connector/restart
   ```

2. **Kafka topics tidak terbuat:**
   ```bash
   # Check if PostgreSQL has logical replication enabled
   docker exec rnd-full-streaming-iceberg-postgres-1 \
     psql -U postgres -d sourcedb -c "SHOW wal_level;"
   ```

3. **Flink jobs gagal:**
   ```bash
   # Check Flink logs
   docker-compose logs flink-jobmanager
   docker-compose logs flink-taskmanager
   
   # Restart Flink
   docker-compose restart flink-jobmanager flink-taskmanager
   ```

4. **Iceberg tables tidak accessible:**
   ```bash
   # Check Polaris and MinIO
   curl http://localhost:8182/healthcheck
   curl http://localhost:9000/minio/health/live
   ```

### Reset Pipeline

```bash
# Stop all services
docker-compose down

# Remove volumes (will delete all data)
docker-compose down -v

# Restart fresh
./start-university-cdc-pipeline.sh
```

## 📝 File Structure

```
rnd-full-streaming-iceberg/
├── docker-compose.yml                     # Main orchestration
├── debezium/
│   └── university-connector.json          # CDC connector config
├── flink-sql/
│   └── university-cdc-pipeline.sql        # Complete Flink SQL job
├── generate-data/                         # University data generation
├── start-university-cdc-pipeline.sh       # Main setup script
├── setup-flink-jobs.sh                   # Flink job setup
├── test-university-pipeline.sh           # Testing script
└── UNIVERSITY_CDC_GUIDE.md               # This guide
```

## 🎯 Next Steps

1. **Scale Testing**: Generate lebih banyak data dan test performance
2. **Real-time Analytics**: Buat dashboard untuk monitor data stream
3. **Data Quality**: Add validation dan quality checks
4. **Schema Evolution**: Test schema changes dan migrations
5. **Production Setup**: Configure untuk production environment

## 📚 Additional Resources

- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Debezium Documentation](https://debezium.io/documentation/)
- [Apache Flink Documentation](https://flink.apache.org/docs/)
- [Apache Iceberg Documentation](https://iceberg.apache.org/docs/)
- [Trino Documentation](https://trino.io/docs/)

---

🎉 **Happy streaming!** Jika ada pertanyaan atau issues, check troubleshooting section atau logs untuk debugging. 