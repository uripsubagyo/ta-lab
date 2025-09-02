#!/bin/bash

# Health Check Script for Streaming Data Lakehouse
# This script verifies all services are running and accessible

echo "🔍 Verifying Streaming Data Lakehouse Services..."
echo "================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check HTTP endpoint
check_http() {
    local service=$1
    local url=$2
    local expected_code=${3:-200}
    
    echo -n "Testing $service... "
    
    response=$(curl -s -w "%{http_code}" -o /dev/null "$url" --max-time 10)
    
    if [ "$response" = "$expected_code" ]; then
        echo -e "${GREEN}✓ OK${NC}"
        return 0
    else
        echo -e "${RED}✗ FAIL (HTTP $response)${NC}"
        return 1
    fi
}

# Function to check Docker container
check_container() {
    local service=$1
    echo -n "Checking $service container... "
    
    if docker-compose ps -q "$service" > /dev/null 2>&1; then
        status=$(docker-compose ps "$service" | grep -v "Name" | awk '{print $3}')
        if [[ "$status" == "Up" ]]; then
            echo -e "${GREEN}✓ Running${NC}"
            return 0
        else
            echo -e "${RED}✗ Not Running ($status)${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Container not found${NC}"
        return 1
    fi
}

# Check Docker Compose services
echo -e "\n${YELLOW}📦 Checking Docker Containers:${NC}"
check_container "postgres"
check_container "kafka-broker"
check_container "debezium-connect"
check_container "flink-jobmanager"
check_container "flink-taskmanager"
check_container "polaris"
check_container "minio"
check_container "trino"

# Check HTTP endpoints
echo -e "\n${YELLOW}🌐 Checking HTTP Endpoints:${NC}"
check_http "Debezium Connect" "http://localhost:8083/"
check_http "Flink JobManager" "http://localhost:8081/overview"
check_http "MinIO API" "http://localhost:9000/minio/health/live"
check_http "MinIO Console" "http://localhost:9001/login"
check_http "Trino" "http://localhost:8080/ui/"
check_http "Polaris" "http://localhost:8181/healthcheck"

# Check database connectivity
echo -e "\n${YELLOW}🗄️  Checking Database Connectivity:${NC}"
echo -n "PostgreSQL connection... "
if docker exec -i $(docker-compose ps -q postgres 2>/dev/null) psql -U postgres -d sourcedb -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Connected${NC}"
else
    echo -e "${RED}✗ Connection failed${NC}"
fi

# Check Kafka topics
echo -e "\n${YELLOW}📨 Checking Kafka:${NC}"
echo -n "Kafka broker connectivity... "
if docker exec -i $(docker-compose ps -q kafka-broker 2>/dev/null) kafka-topics.sh --bootstrap-server localhost:29092 --list > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Connected${NC}"
    
    echo -n "University CDC topics... "
    topics=$(docker exec -i $(docker-compose ps -q kafka-broker 2>/dev/null) kafka-topics.sh --bootstrap-server localhost:29092 --list 2>/dev/null | grep "university-server" | wc -l)
    if [ "$topics" -gt 0 ]; then
        echo -e "${GREEN}✓ Found $topics topics${NC}"
    else
        echo -e "${YELLOW}⚠ No CDC topics found yet${NC}"
    fi
else
    echo -e "${RED}✗ Connection failed${NC}"
fi

# Check Debezium connector
echo -e "\n${YELLOW}🔗 Checking Debezium Connector:${NC}"
echo -n "University connector status... "
connector_response=$(curl -s "http://localhost:8083/connectors/university-connector/status" 2>/dev/null)
if [ $? -eq 0 ] && echo "$connector_response" | grep -q '"state":"RUNNING"'; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${YELLOW}⚠ Not configured or not running${NC}"
    echo "   Run: curl -X POST http://localhost:8083/connectors -H 'Content-Type: application/json' --data-binary @debezium/university-connector.json"
fi

# Summary
echo -e "\n${YELLOW}📋 Summary:${NC}"
echo "If all services show ✓ OK/Running, your lakehouse is ready!"
echo ""
echo "Next steps:"
echo "1. Connect to Flink SQL: docker-compose exec flink-sql-client /opt/flink/bin/sql-client.sh"
echo "2. Setup catalog: \\i /opt/flink/sql/setup-catalog-only.sql"
echo "3. Run streaming jobs: \\i /opt/flink/sql/individual-jobs/setup-faculty-job.sql"
echo ""
echo "Web interfaces:"
echo "- Flink Dashboard: http://localhost:8081"
echo "- MinIO Console: http://localhost:9001 (admin/password)"
echo "- Trino UI: http://localhost:8080" 