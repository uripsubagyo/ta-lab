#!/bin/bash

set -e

echo "🚀 Starting PostgreSQL to Iceberg CDC Pipeline Setup"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a service is ready
wait_for_service() {
    local service_name=$1
    local port=$2
    local max_attempts=30
    local attempt=1

    echo -e "${YELLOW}⏳ Waiting for $service_name to be ready...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:$port > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $service_name is ready!${NC}"
            return 0
        fi
        echo "   Attempt $attempt/$max_attempts - waiting 10s..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}❌ $service_name failed to start after $max_attempts attempts${NC}"
    return 1
}

# Function to wait for PostgreSQL
wait_for_postgres() {
    echo -e "${YELLOW}⏳ Waiting for PostgreSQL to be ready...${NC}"
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec $(docker ps -q -f name=postgres) pg_isready -U postgres > /dev/null 2>&1; then
            echo -e "${GREEN}✅ PostgreSQL is ready!${NC}"
            return 0
        fi
        echo "   Attempt $attempt/$max_attempts - waiting 5s..."
        sleep 5
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}❌ PostgreSQL failed to start after $max_attempts attempts${NC}"
    return 1
}

echo "1️⃣ Starting Docker services..."
docker-compose up -d

echo ""
echo "2️⃣ Waiting for services to be ready..."

# Wait for core services
wait_for_postgres
wait_for_service "Kafka Connect" 8083
wait_for_service "Flink JobManager" 8081
wait_for_service "Trino" 8080

echo ""
echo "3️⃣ Setting up Debezium PostgreSQL connector..."

# Wait a bit more to ensure Kafka Connect is fully ready
sleep 10

# Register Debezium connector
if curl -X POST http://localhost:8083/connectors \
    -H "Content-Type: application/json" \
    -d @debezium/university-connector.json > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Debezium connector registered successfully!${NC}"
else
    echo -e "${RED}❌ Failed to register Debezium connector${NC}"
    echo "   You can manually register it later with:"
    echo "   curl -X POST http://localhost:8083/connectors -H \"Content-Type: application/json\" -d @debezium/postgres-connector.json"
fi

echo ""
echo "4️⃣ Checking connector status..."
sleep 5

if curl -s http://localhost:8083/connectors/university-connector/status | grep -q '"state":"RUNNING"'; then
    echo -e "${GREEN}✅ Debezium connector is running!${NC}"
else
    echo -e "${YELLOW}⚠️  Connector might still be starting. Check status with:${NC}"
    echo "   curl http://localhost:8083/connectors/postgres-connector/status"
fi

echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "📋 Next Steps:"
echo "1. Set up Flink CDC pipeline:"
echo "   docker exec -it \$(docker ps -q -f name=flink-sql-client) sql-client.sh"
echo "   # Then copy and paste the contents of flink-sql/setup-cdc-pipeline.sql"
echo ""
echo "2. Query data with Trino:"
echo "   docker exec -it \$(docker ps -q -f name=trino) trino"
echo ""
echo "3. Test CDC by inserting data into PostgreSQL:"
echo "   docker exec -it \$(docker ps -q -f name=postgres) psql -U postgres -d sourcedb"
echo ""
echo "🌐 Web Interfaces:"
echo "   • Flink Dashboard: http://localhost:8081"
echo "   • Trino Web UI: http://localhost:8080"
echo "   • Kafka Connect API: http://localhost:8083"
echo "   • MinIO Console: http://localhost:9001 (admin/password)"
echo ""
echo "📖 For detailed instructions, see README.md" 