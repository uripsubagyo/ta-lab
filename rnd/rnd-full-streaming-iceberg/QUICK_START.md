# Quick Start Guide - Streaming Data Lakehouse

## 🚀 Fast Setup (5 minutes)

### 1. Start All Services
```bash
docker-compose up -d
```

### 2. Verify Everything is Running
```bash
./verify-services.sh
```

### 3. Set Up Flink Streaming
```bash
# Connect to Flink SQL Client
docker-compose exec flink-sql-client /opt/flink/bin/sql-client.sh

# In Flink SQL Client, run:
\i /opt/flink/sql/setup-catalog-only.sql

# Start Faculty streaming job
\i /opt/flink/sql/individual-jobs/setup-faculty-job.sql

# Start Student Fee streaming job  
\i /opt/flink/sql/individual-jobs/setup-student-fee-job.sql

# Exit Flink SQL Client
exit;
```

### 4. Test the Pipeline
```bash
# Insert test data in PostgreSQL
docker exec -it $(docker-compose ps -q postgres) psql -U postgres -d sourcedb -c "
INSERT INTO faculty (faculty_code, faculty_name) VALUES ('TEST', 'Test Faculty');
UPDATE student_fee SET ukt_fee = 5000000 WHERE student_id = 'STD-2020-001' LIMIT 1;
"

# Query data in Trino
docker exec -it $(docker-compose ps -q trino) trino --server localhost:8080 --catalog iceberg --schema university --execute "
SELECT COUNT(*) as total_faculty FROM faculty;
SELECT * FROM faculty WHERE faculty_code = 'TEST';
SELECT COUNT(*) as total_student_fees FROM student_fee;
"
```

### 5. Check MinIO Storage
Open http://localhost:9001 (admin/password) and look for data in `warehouse/polariscatalog/university/` folders.

## 🎯 Key URLs
- **Flink Dashboard**: http://localhost:8081
- **MinIO Console**: http://localhost:9001 (admin/password)  
- **Trino UI**: http://localhost:8080

## 🔧 Essential Commands

### Check Service Health
```bash
./verify-services.sh
```

### Monitor Kafka Topics
```bash
docker exec -it $(docker-compose ps -q kafka-broker) kafka-topics.sh --bootstrap-server localhost:29092 --list
```

### View Streaming Data
```bash
docker exec -it $(docker-compose ps -q kafka-broker) kafka-console-consumer.sh --bootstrap-server localhost:29092 --topic university-server.public.faculty --from-beginning --max-messages 5
```

### Check Flink Jobs
```bash
curl -s http://localhost:8081/jobs | jq '.jobs[] | {id, name, state}'
```

### Connect to Services
```bash
# PostgreSQL
docker exec -it $(docker-compose ps -q postgres) psql -U postgres -d sourcedb

# Flink SQL Client
docker-compose exec flink-sql-client /opt/flink/bin/sql-client.sh

# Trino CLI
docker exec -it $(docker-compose ps -q trino) trino --server localhost:8080 --catalog iceberg --schema university
```

## 🚨 Quick Troubleshooting

### Service Won't Start
```bash
docker-compose logs [service-name]
# Examples: flink-jobmanager, debezium-connect, polaris
```

### Restart Everything
```bash
docker-compose down
docker-compose up -d
```

### Clean Reset (⚠️ Deletes all data)
```bash
docker-compose down -v
docker-compose up -d
```

### Check Individual Services
```bash
# PostgreSQL tables
docker exec -it $(docker-compose ps -q postgres) psql -U postgres -d sourcedb -c "\dt"

# Debezium connector status  
curl -s http://localhost:8083/connectors/university-connector/status | jq .connector.state

# Polaris health
curl -s http://localhost:8181/healthcheck
```

For detailed setup instructions, see [README.md](README.md). 