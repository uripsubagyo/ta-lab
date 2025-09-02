#!/bin/bash
# Health Check Script for Docker Compose Streaming Iceberg Lakehouse

echo "=== Docker Compose Services Health Check ==="
echo "Starting comprehensive health check for all services..."
echo ""

# Function to check if a service is responding
check_service() {
    local service_name=$1
    local check_command=$2
    local expected_pattern=$3
    
    echo -n "Checking $service_name... "
    
    if eval "$check_command" > /dev/null 2>&1; then
        echo "✓ OK"
        return 0
    else
        echo "✗ FAILED"
        return 1
    fi
}

# Function to check HTTP endpoint
check_http() {
    local service_name=$1
    local url=$2
    local expected_code=${3:-200}
    
    echo -n "Checking $service_name HTTP endpoint... "
    
    local response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    if [ "$response" = "$expected_code" ] || [ "$response" = "200" ]; then
        echo "✓ OK (HTTP $response)"
        return 0
    else
        echo "✗ FAILED (HTTP $response)"
        return 1
    fi
}

# Check if docker-compose is available
if ! command -v docker compose &> /dev/null; then
    echo "Error: docker-compose is not installed or not in PATH"
    exit 1
fi

# Check if in correct directory
if [ ! -f "docker-compose.yml" ]; then
    echo "Error: docker-compose.yml not found. Please run this script from the project directory."
    exit 1
fi

echo "1. Checking container status..."
echo "================================"
docker-compose ps
echo ""

echo "2. Individual Service Health Checks"
echo "===================================="

# PostgreSQL Check
check_service "PostgreSQL Connection" \
    "docker compose exec -T postgres psql -U postgres -d sourcedb -c 'SELECT 1;'"

# PostgreSQL WAL Level Check
echo -n "Checking PostgreSQL WAL configuration... "
wal_level=$(docker compose exec -T postgres psql -U postgres -d sourcedb -t -c "SHOW wal_level;" 2>/dev/null | xargs)
if [ "$wal_level" = "logical" ]; then
    echo "✓ OK (wal_level=logical)"
else
    echo "✗ FAILED (wal_level=$wal_level, expected: logical)"
fi

# Kafka Check
check_service "Kafka Broker" \
    "docker compose exec -T kafka-broker /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka-broker:29092 --list"

# Debezium Connect Check
check_http "Debezium Connect" "http://localhost:8083/"

# MinIO Checks
check_http "MinIO Health" "http://localhost:9000/minio/health/live"

check_service "MinIO Bucket Access" \
    "docker compose exec -T minio-client mc ls minio/warehouse"

# Polaris Checks
check_http "Polaris Health" "http://localhost:8182/healthcheck"

# Flink Checks
check_http "Flink JobManager" "http://localhost:8081/"

echo -n "Checking Flink TaskManager registration... "
taskmanagers=$(curl -s http://localhost:8081/taskmanagers 2>/dev/null | grep -o '"taskmanagers":\[.*\]' | grep -o '\[.*\]')
if [ "$taskmanagers" != "[]" ] && [ -n "$taskmanagers" ]; then
    echo "✓ OK (TaskManagers registered)"
else
    echo "✗ FAILED (No TaskManagers registered)"
fi

# Trino Check
check_http "Trino Coordinator" "http://localhost:8080/v1/info"

echo ""
echo "3. Advanced Connectivity Tests"
echo "==============================="

# Test Kafka topic creation
echo -n "Testing Kafka topic operations... "
if docker compose exec -T kafka-broker /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka-broker:29092 --create --topic health-check-test --partitions 1 --replication-factor 1 > /dev/null 2>&1; then
    if docker compose exec -T kafka-broker /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka-broker:29092 --delete --topic health-check-test > /dev/null 2>&1; then
        echo "✓ OK (Create/Delete successful)"
    else
        echo "⚠ WARNING (Created but failed to delete)"
    fi
else
    echo "✗ FAILED (Cannot create topic)"
fi

# Test MinIO file operations
echo -n "Testing MinIO file operations... "
if docker compose exec -T minio-client sh -c 'echo "health-check" | mc pipe minio/warehouse/health-check.txt' > /dev/null 2>&1; then
    if docker compose exec -T minio-client mc rm minio/warehouse/health-check.txt > /dev/null 2>&1; then
        echo "✓ OK (Upload/Delete successful)"
    else
        echo "⚠ WARNING (Uploaded but failed to delete)"
    fi
else
    echo "✗ FAILED (Cannot upload file)"
fi

# Test Debezium connector plugins
echo -n "Testing Debezium connector plugins... "
plugins=$(curl -s http://localhost:8083/connector-plugins 2>/dev/null | grep -i postgres)
if [ -n "$plugins" ]; then
    echo "✓ OK (PostgreSQL connector available)"
else
    echo "✗ FAILED (PostgreSQL connector not found)"
fi

# Test Polaris management API
echo -n "Testing Polaris management API... "
if curl -s -u "root:secret" http://localhost:8181/api/management/v1/catalogs > /dev/null 2>&1; then
    echo "✓ OK (Management API accessible)"
else
    echo "✗ FAILED (Management API not accessible)"
fi

echo ""
echo "4. Service URLs Summary"
echo "======================="
echo "PostgreSQL:      localhost:5432 (postgres/postgres)"
echo "Kafka:           localhost:9092"
echo "Debezium:        http://localhost:8083"
echo "MinIO Console:   http://localhost:9001 (admin/password)"
echo "MinIO API:       http://localhost:9000"
echo "Polaris:         http://localhost:8181 (root/secret)"
echo "Polaris Health:  http://localhost:8182"
echo "Flink Web UI:    http://localhost:8081"
echo "Trino:           http://localhost:8080"

echo ""
echo "5. Quick Start Commands"
echo "======================="
echo "# Access PostgreSQL:"
echo "docker compose exec postgres psql -U postgres -d sourcedb"
echo ""
echo "# Access Flink SQL Client:"
echo "docker compose exec flink-sql-client sql-client.sh"
echo ""
echo "# Access Trino CLI:"
echo "docker compose exec trino trino --server localhost:8080"
echo ""
echo "# Check Kafka topics:"
echo "docker compose exec kafka-broker /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka-broker:29092 --list"
echo ""
echo "# Check Debezium connectors:"
echo "curl http://localhost:8083/connectors"

echo ""
echo "=== Health Check Complete ==="

# Count failures
failed_checks=0
if ! docker compose exec -T postgres psql -U postgres -d sourcedb -c 'SELECT 1;' > /dev/null 2>&1; then
    ((failed_checks++))
fi
if ! curl -s http://localhost:8083/ > /dev/null 2>&1; then
    ((failed_checks++))
fi
if ! curl -s http://localhost:9000/minio/health/live > /dev/null 2>&1; then
    ((failed_checks++))
fi
if ! curl -s http://localhost:8182/healthcheck > /dev/null 2>&1; then
    ((failed_checks++))
fi
if ! curl -s http://localhost:8081/ > /dev/null 2>&1; then
    ((failed_checks++))
fi
if ! curl -s http://localhost:8080/v1/info > /dev/null 2>&1; then
    ((failed_checks++))
fi

if [ $failed_checks -eq 0 ]; then
    echo "🎉 All services are healthy and ready!"
    exit 0
elif [ $failed_checks -le 2 ]; then
    echo "⚠️  Some services need attention ($failed_checks issues found)"
    exit 1
else
    echo "❌ Multiple services are failing ($failed_checks issues found)"
    echo "   Please check the logs: docker-compose logs [service-name]"
    exit 2
fi 