# Connection Health Check Guide

This document provides step-by-step instructions to verify that all services in the docker-compose setup are connected and working properly.

## Prerequisites

1. Ensure all services are running:
```bash
docker-compose up -d
```

2. Wait for all services to be healthy (approximately 2-3 minutes for full startup)

## Service Health Checks

### 1. PostgreSQL Database
**Check if PostgreSQL is running and accessible:**

```bash
# Check container status
docker-compose ps postgres

# Test database connection
docker-compose exec postgres psql -U postgres -d sourcedb -c "SELECT version();"

# Verify CDC configuration
docker-compose exec postgres psql -U postgres -d sourcedb -c "SHOW wal_level;"
```

**Expected Output:**
- Container status: `Up`
- Version information should be displayed
- wal_level should be `logical`

---

### 2. Kafka Broker
**Check if Kafka is running and topics are available:**

```bash
# Check container status
docker compose ps kafka-broker

# Test Kafka connectivity (from within kafka container)
docker compose exec kafka-broker /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka-broker:29092 --list

# Create a test topic and verify
docker compose exec kafka-broker /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka-broker:29092 --create --topic test-connection --partitions 1 --replication-factor 1
docker compose exec kafka-broker /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka-broker:29092 --describe --topic test-connection
```

**Expected Output:**
- Container status: `Up`
- List of topics (including Debezium topics if configured)
- Test topic creation should succeed

---

### 3. Debezium Connect
**Check if Debezium Connect is running and can connect to Kafka:**

```bash
# Check container status
docker-compose ps debezium-connect

# Test Debezium Connect API
curl -H "Accept:application/json" http://localhost:8083/

# Check connector plugins
curl -H "Accept:application/json" http://localhost:8083/connector-plugins

# Check connector status (if any connectors are deployed)
curl -H "Accept:application/json" http://localhost:8083/connectors
```

**Expected Output:**
- Container status: `Up`
- API should return Kafka Connect version information
- Should list available connector plugins including PostgreSQL

---

### 4. MinIO Object Storage
**Check if MinIO is running and accessible:**

```bash
# Check container status
docker-compose ps minio minio-client

# Test MinIO API
curl http://localhost:9000/minio/health/live

# Check if warehouse bucket exists
docker-compose exec minio-client mc ls minio/

# Test file operations
docker-compose exec minio-client mc cp /etc/hostname minio/warehouse/test-file
docker-compose exec minio-client mc ls minio/warehouse/
docker-compose exec minio-client mc rm minio/warehouse/test-file
```

**Expected Output:**
- Container status: `Up` for both minio and minio-client
- Health check should return `200 OK`
- Warehouse bucket should be listed
- File operations should succeed

---

### 5. Polaris (Iceberg Catalog)
**Check if Polaris is running and accessible:**

```bash
# Check container status
docker-compose ps polaris

# Test Polaris health endpoint
curl http://localhost:8182/healthcheck

# Test Polaris management API
curl -u "root:secret" http://localhost:8181/api/management/v1/catalogs
```

**Expected Output:**
- Container status: `Up` and `healthy`
- Health check should return successful response
- Management API should return catalog information

---

### 6. Flink Cluster
**Check if Flink JobManager and TaskManager are running:**

```bash
# Check container status
docker-compose ps flink-jobmanager flink-taskmanager

# Test Flink Web UI
curl http://localhost:8081/

# Check Flink cluster status
curl http://localhost:8081/overview

# Check TaskManager registration
curl http://localhost:8081/taskmanagers
```

**Expected Output:**
- Container status: `Up` for both services
- Web UI should return HTML content
- Overview should show cluster information
- At least one TaskManager should be registered

---

### 7. Flink SQL Client
**Test Flink SQL Client connectivity:**

```bash
# Check container status
docker-compose ps flink-sql-client

# Test Flink SQL Client (interactive)
docker-compose exec flink-sql-client sql-client.sh

# In the SQL client, test basic commands:
# Flink SQL> SHOW CATALOGS;
# Flink SQL> SHOW DATABASES;
```

**Expected Output:**
- Container status: `Up`
- SQL client should start successfully
- Should be able to execute SHOW commands

---

### 8. Trino Query Engine
**Check if Trino is running and can connect to catalogs:**

```bash
# Check container status
docker-compose ps trino

# Test Trino coordinator
curl http://localhost:8080/v1/info

# Test Trino CLI (if available)
docker-compose exec trino trino --server localhost:8080 --execute "SHOW CATALOGS;"
```

**Expected Output:**
- Container status: `Up`
- Info endpoint should return Trino version information
- Should list available catalogs including Iceberg

---

## Integration Tests

### 1. End-to-End CDC Pipeline Test
**Test the complete data flow from PostgreSQL to Iceberg:**

1. **Create test data in PostgreSQL:**
```bash
docker-compose exec postgres psql -U postgres -d sourcedb -c "
CREATE TABLE IF NOT EXISTS test_table (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO test_table (name) VALUES ('test-connection-1'), ('test-connection-2');
"
```

2. **Configure Debezium Connector:**
```bash
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" \
http://localhost:8083/connectors/ -d '{
  "name": "postgres-connector-test",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "postgres",
    "database.port": "5432",
    "database.user": "postgres",
    "database.password": "postgres",
    "database.dbname": "sourcedb",
    "database.server.name": "postgres-test",
    "table.include.list": "public.test_table",
    "plugin.name": "pgoutput"
  }
}'
```

3. **Verify Kafka topics and messages:**
```bash
# Check if CDC topic is created
docker-compose exec kafka-broker kafka-topics.sh --bootstrap-server localhost:29092 --list | grep postgres-test

# Check messages in the topic
docker-compose exec kafka-broker kafka-console-consumer.sh --bootstrap-server localhost:29092 --topic postgres-test.public.test_table --from-beginning --max-messages 5
```

### 2. Flink to Iceberg Integration Test
**Test Flink can write to Iceberg tables via Polaris:**

```sql
-- Execute in Flink SQL Client
CREATE CATALOG iceberg_catalog WITH (
  'type' = 'iceberg',
  'catalog-type' = 'rest',
  'uri' = 'http://polaris:8181/api/catalog',
  'credential' = 'root:secret',
  'warehouse' = 's3://warehouse/',
  's3.endpoint' = 'http://minio:9000',
  's3.access-key-id' = 'admin',
  's3.secret-access-key' = 'password'
);

USE CATALOG iceberg_catalog;
CREATE DATABASE IF NOT EXISTS test_db;
USE test_db;

CREATE TABLE test_iceberg_table (
  id BIGINT,
  name STRING,
  ts TIMESTAMP(3)
) WITH (
  'format-version' = '2'
);

INSERT INTO test_iceberg_table VALUES (1, 'test', CURRENT_TIMESTAMP);
SELECT * FROM test_iceberg_table;
```

### 3. Trino Query Test
**Test Trino can query Iceberg tables:**

```bash
docker-compose exec trino trino --server localhost:8080 --execute "
SELECT * FROM iceberg.test_db.test_iceberg_table;
"
```

## Common Issues and Troubleshooting

### Services Not Starting
- **Check logs:** `docker-compose logs [service-name]`
- **Verify dependencies:** Ensure dependent services are healthy before starting
- **Check resource limits:** Ensure sufficient memory and CPU

### Connection Timeouts
- **Network issues:** Verify all services are on the same network (`local-iceberg-lakehouse`)
- **Port conflicts:** Ensure no other services are using the same ports
- **Firewall:** Check firewall settings on host machine

### CDC Not Working
- **PostgreSQL WAL settings:** Verify `wal_level=logical`
- **Replication slots:** Check `max_wal_senders` and `max_replication_slots`
- **Debezium connector status:** Check connector status via REST API

### Iceberg/Polaris Issues
- **Credentials:** Verify Polaris bootstrap credentials
- **S3 connectivity:** Test MinIO connectivity from Polaris
- **Catalog permissions:** Ensure proper catalog permissions

## Health Check Script

Create a simple script to run all checks:

```bash
#!/bin/bash
# save as health-check.sh

echo "=== Docker Compose Services Health Check ==="

# Check if all containers are running
echo "1. Checking container status..."
docker-compose ps

echo -e "\n2. Testing PostgreSQL..."
docker-compose exec -T postgres psql -U postgres -d sourcedb -c "SELECT 1;" > /dev/null 2>&1 && echo "✓ PostgreSQL OK" || echo "✗ PostgreSQL FAILED"

echo -e "\n3. Testing Kafka..."
docker-compose exec -T kafka-broker kafka-topics.sh --bootstrap-server localhost:29092 --list > /dev/null 2>&1 && echo "✓ Kafka OK" || echo "✗ Kafka FAILED"

echo -e "\n4. Testing Debezium Connect..."
curl -s http://localhost:8083/ > /dev/null 2>&1 && echo "✓ Debezium Connect OK" || echo "✗ Debezium Connect FAILED"

echo -e "\n5. Testing MinIO..."
curl -s http://localhost:9000/minio/health/live > /dev/null 2>&1 && echo "✓ MinIO OK" || echo "✗ MinIO FAILED"

echo -e "\n6. Testing Polaris..."
curl -s http://localhost:8182/healthcheck > /dev/null 2>&1 && echo "✓ Polaris OK" || echo "✗ Polaris FAILED"

echo -e "\n7. Testing Flink..."
curl -s http://localhost:8081/overview > /dev/null 2>&1 && echo "✓ Flink OK" || echo "✗ Flink FAILED"

echo -e "\n8. Testing Trino..."
curl -s http://localhost:8080/v1/info > /dev/null 2>&1 && echo "✓ Trino OK" || echo "✗ Trino FAILED"

echo -e "\n=== Health Check Complete ==="
```

Make the script executable:
```bash
chmod +x health-check.sh
./health-check.sh
```

This comprehensive guide should help you verify that all services are properly connected and functioning in your streaming Iceberg lakehouse setup. 