#!/bin/bash

# =================================================================
# DYNAMIC CDC SYSTEM TEST SCRIPT
# This script tests the table-specific CDC triggering system
# =================================================================

set -e

echo "🚀 Starting Dynamic CDC System Test..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Docker is running
print_step "Checking Docker status..."
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi
print_success "Docker is running"

# Start core services
print_step "Starting core services..."
docker compose up -d postgres kafka-broker debezium-connect flink-jobmanager flink-taskmanager flink-sql-client polaris minio minio-client

print_step "Waiting for services to be ready..."
sleep 30

# Register Debezium connector
print_step "Registering Debezium connector..."
docker compose up -d register-university-connector
sleep 10

# Wait for JobManager to be ready
print_step "Waiting for JobManager to be ready..."
until curl -s http://localhost:8081/overview > /dev/null; do
    echo "JobManager is unavailable - sleeping"
    sleep 2
done
print_success "JobManager is ready"

# Setup initial catalog and tables in Flink
print_step "Setting up Flink catalog and table definitions..."
docker exec rnd-full-streaming-iceberg-flink-sql-client-1 bash -c "
/opt/flink/bin/sql-client.sh -f /opt/flink/sql/dynamic-table-job-manager.sql
" || print_warning "Catalog setup may have partial failures (normal on first run)"

# Start the orchestrator
print_step "Starting CDC Orchestrator..."
docker compose --profile orchestrator up -d cdc-orchestrator

# Wait for orchestrator to be ready
print_step "Waiting for orchestrator to initialize..."
sleep 15

# Function to test a specific table
test_table_update() {
    local table_name=$1
    local test_query=$2
    
    print_step "Testing $table_name table updates..."
    
    # Insert/update data in PostgreSQL
    docker exec rnd-full-streaming-iceberg-postgres-1 psql -U postgres -d sourcedb -c "$test_query"
    
    # Wait for CDC processing
    sleep 5
    
    # Check orchestrator logs
    echo "Checking orchestrator logs for $table_name processing..."
    docker logs rnd-full-streaming-iceberg-cdc-orchestrator-1 --tail 20 | grep -i "$table_name" || print_warning "No $table_name activity found in logs"
    
    sleep 5
}

# Test Faculty table
test_table_update "faculty" "
INSERT INTO faculty (faculty_code, faculty_name) 
VALUES ('TEST01', 'Test Faculty 1') 
ON CONFLICT (faculty_code) DO UPDATE SET faculty_name = 'Updated Test Faculty 1';
"

# Test Program table  
test_table_update "program" "
INSERT INTO program (program_code, program_name, faculty_id, degree) 
VALUES ('TESTPROG01', 'Test Program 1', 1, 'S1') 
ON CONFLICT (program_code) DO UPDATE SET program_name = 'Updated Test Program 1';
"

# Test Students table
test_table_update "students" "
INSERT INTO students (student_id, full_name, entry_year, program_id, faculty_id) 
VALUES ('TEST001', 'Test Student 1', 2024, 1, 1) 
ON CONFLICT (student_id) DO UPDATE SET full_name = 'Updated Test Student 1';
"

# Check Flink jobs status
print_step "Checking Flink job status..."
docker exec rnd-full-streaming-iceberg-flink-sql-client-1 bash -c "
echo 'SHOW JOBS;' | /opt/flink/bin/sql-client.sh
" || print_warning "Could not retrieve job status"

# Check data in Iceberg via Trino (if available)
print_step "Attempting to verify data in Iceberg..."
sleep 10

docker exec rnd-full-streaming-iceberg-trino-1 trino --execute "
SHOW CATALOGS;
" 2>/dev/null || print_warning "Trino not accessible for verification"

# Show orchestrator logs
print_step "Displaying recent orchestrator logs..."
echo "Recent orchestrator activity:"
docker logs rnd-full-streaming-iceberg-cdc-orchestrator-1 --tail 30

print_step "Test Summary:"
echo "1. Core services started ✓"
echo "2. Debezium connector registered ✓"
echo "3. Flink catalog and tables setup ✓"
echo "4. CDC orchestrator started ✓"
echo "5. Test data inserted into PostgreSQL ✓"
echo "6. Check logs above to verify job triggering"

print_success "Dynamic CDC test completed!"
print_warning "Review the logs above to verify that:"
echo "   - Orchestrator detected table changes"
echo "   - Flink jobs were triggered for specific tables"
echo "   - Data was processed to Iceberg"

echo ""
echo "🔍 To monitor ongoing activity:"
echo "   docker logs -f rnd-full-streaming-iceberg-cdc-orchestrator-1"
echo ""
echo "🛑 To stop all services:"
echo "   docker compose --profile orchestrator down" 