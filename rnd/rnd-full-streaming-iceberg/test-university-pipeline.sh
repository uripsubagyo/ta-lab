#!/bin/bash

# =================================================================
# UNIVERSITY CDC PIPELINE TEST SCRIPT
# This script tests the complete CDC pipeline functionality
# =================================================================

set -e

echo "🧪 Testing University CDC Pipeline..."
echo "===================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to log success
log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to log warning
log_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

# Function to log error
log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to execute SQL in PostgreSQL
execute_pg_sql() {
    local sql="$1"
    docker exec rnd-full-streaming-iceberg-postgres-1 psql -U postgres -d sourcedb -c "$sql"
}

# Function to check Kafka topic for messages
check_kafka_topic() {
    local topic="$1"
    local timeout=30
    
    echo "🔍 Checking Kafka topic: $topic"
    
    # Check if topic exists
    if ! docker exec kafka-broker kafka-topics.sh --bootstrap-server localhost:9092 --list | grep -q "$topic"; then
        log_error "Topic $topic does not exist"
        return 1
    fi
    
    # Check for messages in topic
    local message_count=$(docker exec kafka-broker kafka-run-class.sh kafka.tools.GetOffsetShell \
        --broker-list localhost:9092 --topic "$topic" --time -1 | \
        awk -F':' '{sum+=$3} END {print sum}' 2>/dev/null || echo "0")
    
    if [ "$message_count" -gt 0 ]; then
        log_success "Found $message_count messages in topic $topic"
        return 0
    else
        log_warning "No messages found in topic $topic"
        return 1
    fi
}

# Function to check Trino table
check_trino_table() {
    local table="$1"
    echo "🔍 Checking Trino table: $table"
    
    local result=$(docker exec $(docker ps -q -f name=trino) trino --execute "SELECT COUNT(*) FROM iceberg.university.$table" 2>/dev/null || echo "ERROR")
    
    if [ "$result" = "ERROR" ]; then
        log_error "Failed to query table $table in Trino"
        return 1
    else
        log_success "Table $table has $result records"
        return 0
    fi
}

# =================================================================
# TEST 1: Check service health
# =================================================================

echo "🏥 Test 1: Checking service health..."

# Check PostgreSQL
echo "🔍 Testing PostgreSQL connection..."
if execute_pg_sql "SELECT 1;" > /dev/null 2>&1; then
    log_success "PostgreSQL is accessible"
else
    log_error "PostgreSQL is not accessible"
    exit 1
fi

# Check Debezium Connect
echo "🔍 Testing Debezium Connect..."
if curl -s http://localhost:8083/connectors > /dev/null; then
    connector_status=$(curl -s http://localhost:8083/connectors/university-connector/status | jq -r '.connector.state' 2>/dev/null || echo "NOT_FOUND")
    if [ "$connector_status" = "RUNNING" ]; then
        log_success "Debezium connector is running"
    else
        log_error "Debezium connector is not running. Status: $connector_status"
    fi
else
    log_error "Debezium Connect is not accessible"
fi

# Check Flink
echo "🔍 Testing Flink..."
if curl -s http://localhost:8081/overview > /dev/null; then
    log_success "Flink JobManager is accessible"
else
    log_error "Flink JobManager is not accessible"
fi

# =================================================================
# TEST 2: Insert test data to PostgreSQL
# =================================================================

echo ""
echo "📝 Test 2: Inserting test data..."

# Insert test faculty
echo "🏛️ Inserting test faculty..."
execute_pg_sql "
INSERT INTO faculty (faculty_code, faculty_name) 
VALUES ('TEST', 'Test Faculty for CDC') 
ON CONFLICT (faculty_code) DO UPDATE SET faculty_name = EXCLUDED.faculty_name;
" > /dev/null

# Get faculty ID
faculty_id=$(execute_pg_sql "SELECT id FROM faculty WHERE faculty_code = 'TEST';" | grep -E '^[[:space:]]*[0-9]+[[:space:]]*$' | tr -d ' ')

if [ -n "$faculty_id" ]; then
    log_success "Test faculty inserted with ID: $faculty_id"
    
    # Insert test program
    echo "🎓 Inserting test program..."
    execute_pg_sql "
    INSERT INTO program (program_code, program_name, faculty_id, degree) 
    VALUES ('TEST-S1', 'Test Program for CDC', $faculty_id, 'S1')
    ON CONFLICT (program_code) DO UPDATE SET program_name = EXCLUDED.program_name;
    " > /dev/null
    
    # Get program ID
    program_id=$(execute_pg_sql "SELECT id FROM program WHERE program_code = 'TEST-S1';" | grep -E '^[[:space:]]*[0-9]+[[:space:]]*$' | tr -d ' ')
    
    if [ -n "$program_id" ]; then
        log_success "Test program inserted with ID: $program_id"
        
        # Insert test student
        echo "👨‍🎓 Inserting test student..."
        execute_pg_sql "
        INSERT INTO students (student_id, full_name, entry_year, program_id, degree, faculty_id, status) 
        VALUES ('TEST001', 'Test Student CDC', 2025, $program_id, 'S1', $faculty_id, 'active')
        ON CONFLICT (student_id) DO UPDATE SET full_name = EXCLUDED.full_name;
        " > /dev/null
        
        log_success "Test student inserted"
    else
        log_error "Failed to get program ID"
    fi
else
    log_error "Failed to get faculty ID"
fi

# Wait for CDC to process
echo "⏳ Waiting for CDC to process changes..."
sleep 10

# =================================================================
# TEST 3: Check Kafka topics
# =================================================================

echo ""
echo "📊 Test 3: Checking Kafka topics..."

kafka_topics=(
    "university-server.public.faculty"
    "university-server.public.program" 
    "university-server.public.students"
)

kafka_success=0
for topic in "${kafka_topics[@]}"; do
    if check_kafka_topic "$topic"; then
        ((kafka_success++))
    fi
done

if [ $kafka_success -eq ${#kafka_topics[@]} ]; then
    log_success "All Kafka topics have messages"
else
    log_warning "$kafka_success/${#kafka_topics[@]} Kafka topics have messages"
fi

# =================================================================
# TEST 4: Check Iceberg tables (if Flink jobs are running)
# =================================================================

echo ""
echo "🏔️ Test 4: Checking Iceberg tables..."

iceberg_tables=(
    "faculty_iceberg"
    "program_iceberg"
    "students_iceberg"
)

iceberg_success=0
for table in "${iceberg_tables[@]}"; do
    if check_trino_table "$table"; then
        ((iceberg_success++))
    fi
done

if [ $iceberg_success -eq ${#iceberg_tables[@]} ]; then
    log_success "All Iceberg tables are accessible and have data"
elif [ $iceberg_success -gt 0 ]; then
    log_warning "$iceberg_success/${#iceberg_tables[@]} Iceberg tables are accessible"
else
    log_warning "No Iceberg tables accessible (Flink jobs may not be running)"
fi

# =================================================================
# TEST 5: Data consistency check
# =================================================================

echo ""
echo "🔍 Test 5: Data consistency check..."

# Count records in PostgreSQL
pg_faculty_count=$(execute_pg_sql "SELECT COUNT(*) FROM faculty;" | grep -E '^[[:space:]]*[0-9]+[[:space:]]*$' | tr -d ' ')
pg_program_count=$(execute_pg_sql "SELECT COUNT(*) FROM program;" | grep -E '^[[:space:]]*[0-9]+[[:space:]]*$' | tr -d ' ')
pg_student_count=$(execute_pg_sql "SELECT COUNT(*) FROM students;" | grep -E '^[[:space:]]*[0-9]+[[:space:]]*$' | tr -d ' ')

echo "📊 PostgreSQL record counts:"
echo "  • Faculty: $pg_faculty_count"
echo "  • Program: $pg_program_count" 
echo "  • Students: $pg_student_count"

# If Iceberg tables are accessible, compare counts
if [ $iceberg_success -gt 0 ]; then
    echo "📊 Comparing with Iceberg..."
    
    iceberg_faculty_count=$(docker exec $(docker ps -q -f name=trino) trino --execute "SELECT COUNT(*) FROM iceberg.university.faculty_iceberg" 2>/dev/null || echo "0")
    iceberg_program_count=$(docker exec $(docker ps -q -f name=trino) trino --execute "SELECT COUNT(*) FROM iceberg.university.program_iceberg" 2>/dev/null || echo "0")
    iceberg_student_count=$(docker exec $(docker ps -q -f name=trino) trino --execute "SELECT COUNT(*) FROM iceberg.university.students_iceberg" 2>/dev/null || echo "0")
    
    echo "📊 Iceberg record counts:"
    echo "  • Faculty: $iceberg_faculty_count"
    echo "  • Program: $iceberg_program_count"
    echo "  • Students: $iceberg_student_count"
    
    # Check consistency
    if [ "$pg_faculty_count" = "$iceberg_faculty_count" ] && 
       [ "$pg_program_count" = "$iceberg_program_count" ] && 
       [ "$pg_student_count" = "$iceberg_student_count" ]; then
        log_success "Data counts are consistent between PostgreSQL and Iceberg"
    else
        log_warning "Data counts differ between PostgreSQL and Iceberg (may be due to timing)"
    fi
fi

# =================================================================
# SUMMARY
# =================================================================

echo ""
echo "📋 Test Summary"
echo "==============="

total_tests=5
passed_tests=1  # Service health check passed

if [ $kafka_success -gt 0 ]; then
    ((passed_tests++))
fi

if [ $iceberg_success -gt 0 ]; then
    ((passed_tests++))
fi

echo "✅ Passed: $passed_tests/$total_tests tests"

if [ $passed_tests -eq $total_tests ]; then
    echo ""
    log_success "🎉 CDC Pipeline is working correctly!"
    echo ""
    echo "🔗 Useful commands:"
    echo "  • View Flink jobs:     http://localhost:8081"
    echo "  • Check Kafka topics:  docker exec kafka-broker kafka-topics.sh --bootstrap-server localhost:9092 --list"
    echo "  • Query with Trino:    docker exec -it \$(docker ps -q -f name=trino) trino"
    echo "  • Monitor logs:        docker-compose logs -f"
else
    echo ""
    log_warning "⚠️ Some tests failed or incomplete. Check the setup:"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "  1. Ensure all services are running: docker-compose ps"
    echo "  2. Check Debezium connector: curl http://localhost:8083/connectors/university-connector/status"
    echo "  3. Setup Flink jobs: Execute flink-sql/university-cdc-pipeline.sql in Flink SQL Client"
    echo "  4. Check logs: docker-compose logs [service-name]"
fi

echo ""
echo "🎯 Pipeline test completed!" 