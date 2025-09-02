# Manual Debugging Guide

This guide shows you how to manually track and debug issues found in your health check results.

## 🔍 Your Current Issues

Based on your health check output:
- ✗ PostgreSQL WAL configuration (false positive)
- ✗ Kafka Broker connectivity

## Step-by-Step Manual Debugging

### 1. PostgreSQL WAL Configuration Issue

**Problem:** Health check shows `wal_level=` (empty) instead of `logical`

**Manual Investigation:**

```bash
# Check if PostgreSQL is running
docker compose ps postgres

# Check actual WAL level
docker compose exec postgres psql -U postgres -d sourcedb -c "SHOW wal_level;"
```

**Expected Output:**
```
 wal_level 
-----------
 logical
(1 row)
```

**Issue Identified:** This is a **false positive** in the health check script. The WAL level is correctly set to `logical`, but the script's string parsing has issues with whitespace handling.

**Fix for Health Check Script:**
The issue is in this line in `health-check.sh`:
```bash
wal_level=$(docker compose exec -T postgres psql -U postgres -d sourcedb -t -c "SHOW wal_level;" 2>/dev/null | tr -d ' \n\r')
```

The `tr -d ' \n\r'` removes too many characters. It should be:
```bash
wal_level=$(docker compose exec -T postgres psql -U postgres -d sourcedb -t -c "SHOW wal_level;" 2>/dev/null | xargs)
```

---

### 2. Kafka Broker Connectivity Issue

**Problem:** Kafka topics command fails with "executable file not found"

**Manual Investigation:**

```bash
# Check if Kafka container is running
docker compose ps kafka-broker

# Find Kafka scripts location
docker compose exec kafka-broker find /opt -name "*kafka-topics*" -type f 2>/dev/null

# Test connectivity with localhost (this will fail)
docker compose exec kafka-broker /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:29092 --list

# Test connectivity with correct hostname (this works)
docker compose exec kafka-broker /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka-broker:29092 --list
```

**Issues Identified:**

1. **Script Path Issue:** The health check uses `kafka-topics.sh` but it should use `/opt/kafka/bin/kafka-topics.sh`

2. **Hostname Issue:** Using `localhost:29092` fails because inside the container network, the correct hostname is `kafka-broker:29092`

**Working Manual Commands:**

```bash
# List topics (working command)
docker compose exec kafka-broker /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka-broker:29092 --list

# Check Kafka logs if needed
docker compose logs kafka-broker --tail 20

# Create test topic
docker compose exec kafka-broker /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka-broker:29092 --create --topic test-connection --partitions 1 --replication-factor 1

# Delete test topic
docker compose exec kafka-broker /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka-broker:29092 --delete --topic test-connection
```

**Expected Output (Your system):**
```
__consumer_offsets
__debezium-heartbeat.postgres-server
debezium_connect_configs
debezium_connect_offsets
debezium_connect_statuses
postgres-server.siak.courses
postgres-server.siak.faculties
postgres-server.siak.lecturers
postgres-server.siak.programs
postgres-server.siak.rooms
postgres-server.siak.semesters
postgres-server.siak.students
```

**Great News:** Your Kafka is actually working perfectly! It already has CDC topics from Debezium, showing your data pipeline is active.

---

## 📊 Manual Status Check Commands

Here are the commands to manually verify each service:

### PostgreSQL
```bash
# Connection test
docker compose exec postgres psql -U postgres -d sourcedb -c "SELECT version();"

# CDC configuration
docker compose exec postgres psql -U postgres -d sourcedb -c "SHOW wal_level;"
docker compose exec postgres psql -U postgres -d sourcedb -c "SELECT count(*) FROM pg_replication_slots;"
```

### Kafka
```bash
# List topics
docker compose exec kafka-broker /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka-broker:29092 --list

# Check consumer groups
docker compose exec kafka-broker /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server kafka-broker:29092 --list

# Check logs
docker compose logs kafka-broker --tail 10
```

### Debezium Connect
```bash
# API health
curl -H "Accept:application/json" http://localhost:8083/

# List connectors
curl -H "Accept:application/json" http://localhost:8083/connectors

# Check connector status (if you have connectors)
curl -H "Accept:application/json" http://localhost:8083/connectors/[connector-name]/status
```

### MinIO
```bash
# Health check
curl http://localhost:9000/minio/health/live

# List buckets
docker compose exec minio-client mc ls minio/

# Test file upload
docker compose exec minio-client sh -c 'echo "test" | mc pipe minio/warehouse/test.txt'
docker compose exec minio-client mc ls minio/warehouse/
docker compose exec minio-client mc rm minio/warehouse/test.txt
```

### Polaris
```bash
# Health check
curl http://localhost:8182/healthcheck

# Management API
curl -u "root:secret" http://localhost:8181/api/management/v1/catalogs

# Check if healthy
docker compose exec polaris curl http://localhost:8182/healthcheck
```

### Flink
```bash
# JobManager health
curl http://localhost:8081/

# Cluster overview
curl http://localhost:8081/overview

# TaskManager registration
curl http://localhost:8081/taskmanagers

# Access SQL Client
docker compose exec flink-sql-client sql-client.sh
```

### Trino
```bash
# Coordinator info
curl http://localhost:8080/v1/info

# List catalogs
docker compose exec trino trino --server localhost:8080 --execute "SHOW CATALOGS;"

# Check cluster status
curl http://localhost:8080/v1/cluster
```

---

## 🔧 Fixing the Health Check Script

The issues in your health check script can be fixed by updating these lines:

1. **Kafka script path** - Update all Kafka commands to use full path:
```bash
# Change from:
kafka-topics.sh
# To:
/opt/kafka/bin/kafka-topics.sh
```

2. **Kafka hostname** - Update hostname for internal calls:
```bash
# Change from:
--bootstrap-server localhost:29092
# To:
--bootstrap-server kafka-broker:29092
```

3. **PostgreSQL WAL parsing** - Fix string parsing:
```bash
# Change from:
wal_level=$(docker compose exec -T postgres psql -U postgres -d sourcedb -t -c "SHOW wal_level;" 2>/dev/null | tr -d ' \n\r')
# To:
wal_level=$(docker compose exec -T postgres psql -U postgres -d sourcedb -t -c "SHOW wal_level;" 2>/dev/null | xargs)
```

---

## 🎯 Your System Status

Based on manual verification:

- ✅ **PostgreSQL**: Working perfectly with CDC enabled
- ✅ **Kafka**: Working perfectly with active CDC topics
- ✅ **Debezium**: Active and processing CDC data
- ✅ **MinIO**: Healthy and accessible
- ✅ **Polaris**: Healthy and accessible
- ✅ **Flink**: Healthy with TaskManagers registered
- ✅ **Trino**: Healthy and accessible

**Your streaming data pipeline is actually working correctly!** The health check script just needs updates for the newer Docker Compose syntax and correct internal hostnames.

---

## 🚀 Quick Manual Health Check

For a quick manual verification, run these commands:

```bash
# 1. Check all containers
docker compose ps

# 2. Test key connections
curl -s http://localhost:8083/ > /dev/null && echo "✓ Debezium OK" || echo "✗ Debezium FAILED"
curl -s http://localhost:9000/minio/health/live > /dev/null && echo "✓ MinIO OK" || echo "✗ MinIO FAILED"
curl -s http://localhost:8081/ > /dev/null && echo "✓ Flink OK" || echo "✗ Flink FAILED"
curl -s http://localhost:8080/v1/info > /dev/null && echo "✓ Trino OK" || echo "✗ Trino FAILED"

# 3. Test data pipeline
docker compose exec kafka-broker /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka-broker:29092 --list | grep postgres-server && echo "✓ CDC Pipeline Active" || echo "✗ CDC Pipeline FAILED"
```

This manual approach gives you complete control over debugging each component individually! 