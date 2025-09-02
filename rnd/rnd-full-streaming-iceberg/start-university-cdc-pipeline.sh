#!/bin/bash

# =================================================================
# UNIVERSITY CDC PIPELINE AUTOMATION SCRIPT
# This script starts and configures the complete CDC pipeline
# =================================================================

set -e  # Exit on any error

echo "🚀 Starting University CDC Pipeline..."
echo "======================================"

# Function to wait for service to be ready
wait_for_service() {
    local service_name=$1
    local health_check_url=$2
    local max_retries=30
    local retry_count=0
    
    echo "⏳ Waiting for $service_name to be ready..."
    
    while [ $retry_count -lt $max_retries ]; do
        if curl -s "$health_check_url" > /dev/null 2>&1; then
            echo "✅ $service_name is ready!"
            return 0
        fi
        
        echo "⏳ $service_name not ready yet (attempt $((retry_count + 1))/$max_retries)..."
        sleep 10
        retry_count=$((retry_count + 1))
    done
    
    echo "❌ $service_name failed to start within expected time"
    exit 1
}

# Function to check if connector exists
connector_exists() {
    local connector_name=$1
    curl -s "http://localhost:8083/connectors/$connector_name" > /dev/null 2>&1
}

# =================================================================
# STEP 1: Start all services
# =================================================================

echo "📦 Starting Docker services..."
docker-compose up -d

echo "⏳ Waiting for services to initialize..."
sleep 30

# =================================================================
# STEP 2: Wait for critical services
# =================================================================

echo "🔍 Checking service health..."

# Check PostgreSQL
wait_for_service "PostgreSQL" "http://localhost:5433"

# Check Kafka
echo "⏳ Waiting for Kafka..."
until docker exec kafka-broker kafka-topics.sh --bootstrap-server localhost:9092 --list > /dev/null 2>&1; do
    echo "⏳ Kafka not ready yet..."
    sleep 5
done
echo "✅ Kafka is ready!"

# Check Debezium Connect
wait_for_service "Debezium Connect" "http://localhost:8083"

# Check Flink JobManager
wait_for_service "Flink JobManager" "http://localhost:8081"

# Check Polaris (Iceberg Catalog)
wait_for_service "Polaris" "http://localhost:8182/healthcheck"

# Check MinIO
wait_for_service "MinIO" "http://localhost:9000/minio/health/live"

echo "🎉 All services are ready!"

# =================================================================
# STEP 3: Setup Debezium CDC Connector
# =================================================================

echo "🔧 Setting up Debezium connector..."

# Delete existing connector if it exists
if connector_exists "university-connector"; then
    echo "🗑️ Removing existing university-connector..."
    curl -X DELETE http://localhost:8083/connectors/university-connector
    sleep 5
fi

# Register new connector
echo "📡 Registering university CDC connector..."
curl -X POST http://localhost:8083/connectors \
    -H "Content-Type: application/json" \
    -d @debezium/university-connector.json

# Wait for connector to be running
echo "⏳ Waiting for connector to start..."
sleep 10

# Check connector status
connector_status=$(curl -s http://localhost:8083/connectors/university-connector/status | jq -r '.connector.state')
if [ "$connector_status" = "RUNNING" ]; then
    echo "✅ University connector is running!"
else
    echo "❌ Connector failed to start. Status: $connector_status"
    echo "📋 Checking connector logs..."
    curl -s http://localhost:8083/connectors/university-connector/status | jq '.'
    exit 1
fi

# =================================================================
# STEP 4: Verify Kafka topics
# =================================================================

echo "📊 Checking Kafka topics..."
echo "Available topics:"
docker exec kafka-broker kafka-topics.sh --bootstrap-server localhost:9092 --list | grep university-server || echo "⚠️ No university topics found yet"

# =================================================================
# STEP 5: Display access information
# =================================================================

echo ""
echo "🎯 CDC Pipeline is ready!"
echo "========================"
echo ""
echo "📊 Service Access URLs:"
echo "  • Flink Web UI:      http://localhost:8081"
echo "  • Debezium Connect:  http://localhost:8083"
echo "  • MinIO Console:     http://localhost:9001 (admin/password)"
echo "  • Trino:             http://localhost:8080"
echo "  • PostgreSQL:        localhost:5433 (postgres/postgres)"
echo ""
echo "🔧 Next Steps:"
echo "  1. Access Flink SQL Client:"
echo "     docker exec -it \$(docker ps -q -f name=flink-sql-client) sql-client.sh"
echo ""
echo "  2. Execute the University CDC pipeline SQL:"
echo "     Copy contents from: flink-sql/university-cdc-pipeline.sql"
echo ""
echo "  3. Monitor streaming jobs:"
echo "     Visit Flink Web UI at http://localhost:8081"
echo ""
echo "  4. Query data with Trino:"
echo "     docker exec -it \$(docker ps -q -f name=trino) trino"
echo ""
echo "  5. Test the pipeline:"
echo "     Run: ./test-university-pipeline.sh"
echo ""
echo "🎉 University CDC Pipeline Setup Complete!"
echo "Ready to stream university data from PostgreSQL to Iceberg! 🚀" 