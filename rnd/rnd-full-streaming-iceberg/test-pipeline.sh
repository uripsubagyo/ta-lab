#!/bin/bash

# End-to-End Pipeline Test Script
# Tests PostgreSQL → Debezium → Kafka → Flink → Iceberg → MinIO → Trino

echo "🧪 Testing End-to-End Streaming Data Pipeline..."
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "\n${BLUE}🔍 Test: $test_name${NC}"
    echo -n "Running... "
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Function to run a test with output
run_test_with_output() {
    local test_name="$1"
    local test_command="$2"
    local expected_pattern="$3"
    
    echo -e "\n${BLUE}🔍 Test: $test_name${NC}"
    echo "Running command: $test_command"
    
    result=$(eval "$test_command" 2>&1)
    echo "Result: $result"
    
    if [[ "$result" =~ $expected_pattern ]]; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED - Expected pattern: $expected_pattern${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

echo -e "${YELLOW}Phase 1: Service Health Check${NC}"
run_test "All services running" "docker-compose ps | grep -E '(postgres|kafka-broker|debezium-connect|flink-jobmanager|polaris|minio|trino)' | grep -v 'Exit'"

echo -e "\n${YELLOW}Phase 2: Connectivity Tests${NC}"
run_test "PostgreSQL connectivity" "docker exec -i \$(docker-compose ps -q postgres) psql -U postgres -d sourcedb -c 'SELECT 1;'"
run_test "Kafka connectivity" "docker exec -i \$(docker-compose ps -q kafka-broker) kafka-topics.sh --bootstrap-server localhost:29092 --list"
run_test "Debezium Connect API" "curl -s http://localhost:8083/ | grep -q 'version'"
run_test "Flink JobManager API" "curl -s http://localhost:8081/overview | grep -q 'flink-version'"
run_test "Polaris health" "curl -s http://localhost:8181/healthcheck"
run_test "MinIO health" "curl -s http://localhost:9000/minio/health/live"

echo -e "\n${YELLOW}Phase 3: Data Source Tests${NC}"
run_test_with_output "Faculty table exists" "docker exec -i \$(docker-compose ps -q postgres) psql -U postgres -d sourcedb -c '\dt faculty'" "faculty"
run_test_with_output "Student fee table exists" "docker exec -i \$(docker-compose ps -q postgres) psql -U postgres -d sourcedb -c '\dt student_fee'" "student_fee"

echo -e "\n${YELLOW}Phase 4: CDC Pipeline Tests${NC}"
# Check if Debezium connector is registered
echo -e "\n${BLUE}🔍 Test: Debezium connector status${NC}"
connector_status=$(curl -s http://localhost:8083/connectors/university-connector/status 2>/dev/null)
if echo "$connector_status" | grep -q '"state":"RUNNING"'; then
    echo -e "${GREEN}✓ PASSED - Connector is running${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}⚠ Connector not running, attempting to register...${NC}"
    if curl -s -X POST http://localhost:8083/connectors -H "Content-Type: application/json" --data-binary @debezium/university-connector.json > /dev/null; then
        sleep 5
        connector_status=$(curl -s http://localhost:8083/connectors/university-connector/status 2>/dev/null)
        if echo "$connector_status" | grep -q '"state":"RUNNING"'; then
            echo -e "${GREEN}✓ PASSED - Connector registered and running${NC}"
            ((TESTS_PASSED++))
        else
            echo -e "${RED}✗ FAILED - Connector registration failed${NC}"
            ((TESTS_FAILED++))
        fi
    else
        echo -e "${RED}✗ FAILED - Could not register connector${NC}"
        ((TESTS_FAILED++))
    fi
fi

# Wait for topics to be created
echo -e "\n${BLUE}🔍 Test: Kafka topics created${NC}"
sleep 5
faculty_topic=$(docker exec -i $(docker-compose ps -q kafka-broker) kafka-topics.sh --bootstrap-server localhost:29092 --list | grep "university-server.public.faculty")
if [ ! -z "$faculty_topic" ]; then
    echo -e "${GREEN}✓ PASSED - Faculty topic exists: $faculty_topic${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ FAILED - Faculty topic not found${NC}"
    ((TESTS_FAILED++))
fi

echo -e "\n${YELLOW}Phase 5: Data Insertion Test${NC}"
# Insert test data
echo -e "\n${BLUE}🔍 Test: Insert test faculty data${NC}"
test_faculty_code="TEST_$(date +%s)"
insert_result=$(docker exec -i $(docker-compose ps -q postgres) psql -U postgres -d sourcedb -c "INSERT INTO faculty (faculty_code, faculty_name) VALUES ('$test_faculty_code', 'Test Faculty Pipeline'); SELECT 'inserted' as result;" 2>&1)

if echo "$insert_result" | grep -q "inserted"; then
    echo -e "${GREEN}✓ PASSED - Test data inserted${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ FAILED - Could not insert test data${NC}"
    echo "Error: $insert_result"
    ((TESTS_FAILED++))
fi

echo -e "\n${YELLOW}Phase 6: Kafka Message Verification${NC}"
# Check if message appears in Kafka
echo -e "\n${BLUE}🔍 Test: CDC message in Kafka${NC}"
sleep 3
kafka_message=$(timeout 10 docker exec -i $(docker-compose ps -q kafka-broker) kafka-console-consumer.sh --bootstrap-server localhost:29092 --topic university-server.public.faculty --from-beginning --max-messages 5 2>/dev/null | grep "$test_faculty_code" || echo "")

if [ ! -z "$kafka_message" ]; then
    echo -e "${GREEN}✓ PASSED - CDC message found in Kafka${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}⚠ Could not verify Kafka message (may need more time)${NC}"
    ((TESTS_FAILED++))
fi

echo -e "\n${YELLOW}Phase 7: Flink Job Status${NC}"
# Check Flink jobs
echo -e "\n${BLUE}🔍 Test: Flink job status${NC}"
flink_jobs=$(curl -s http://localhost:8081/jobs 2>/dev/null)
if echo "$flink_jobs" | grep -q '"state":"RUNNING"'; then
    running_jobs=$(echo "$flink_jobs" | grep -o '"state":"RUNNING"' | wc -l)
    echo -e "${GREEN}✓ PASSED - Found $running_jobs running Flink job(s)${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}⚠ No running Flink jobs found${NC}"
    echo "Note: You may need to manually start streaming jobs in Flink SQL client"
    ((TESTS_FAILED++))
fi

echo -e "\n${YELLOW}Phase 8: MinIO Storage Check${NC}"
# Check MinIO bucket
echo -e "\n${BLUE}🔍 Test: MinIO warehouse bucket${NC}"
minio_bucket=$(docker exec -i $(docker-compose ps -q minio-client) mc ls minio/warehouse 2>/dev/null | head -1)
if [ ! -z "$minio_bucket" ]; then
    echo -e "${GREEN}✓ PASSED - MinIO warehouse bucket accessible${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ FAILED - MinIO warehouse bucket not accessible${NC}"
    ((TESTS_FAILED++))
fi

echo -e "\n${YELLOW}Phase 9: Trino Connectivity${NC}"
# Test Trino connection
run_test "Trino iceberg catalog" "docker exec -i \$(docker-compose ps -q trino) trino --server localhost:8080 --catalog iceberg --schema information_schema --execute 'SELECT 1'"

# Summary
echo -e "\n${YELLOW}📊 Test Summary${NC}"
echo "=============="
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
total_tests=$((TESTS_PASSED + TESTS_FAILED))
echo "Total Tests: $total_tests"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All tests passed! Your streaming lakehouse is working correctly.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Set up Flink streaming jobs:"
    echo "   docker-compose exec flink-sql-client /opt/flink/bin/sql-client.sh"
    echo "   \\i /opt/flink/sql/setup-catalog-only.sql"
    echo "   \\i /opt/flink/sql/individual-jobs/setup-faculty-job.sql"
    echo ""
    echo "2. Monitor the pipeline:"
    echo "   - Flink UI: http://localhost:8081"
    echo "   - MinIO Console: http://localhost:9001"
    echo "   - Trino UI: http://localhost:8080"
else
    echo -e "\n${RED}⚠️  Some tests failed. Check the logs above for details.${NC}"
    echo ""
    echo "Common fixes:"
    echo "1. Wait a bit longer for services to start: docker-compose ps"
    echo "2. Check service logs: docker-compose logs [service-name]"
    echo "3. Restart if needed: docker-compose restart [service-name]"
fi

exit $TESTS_FAILED 