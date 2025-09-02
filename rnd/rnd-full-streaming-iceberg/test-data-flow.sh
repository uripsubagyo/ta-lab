#!/bin/bash

# Test Data Flow Script: PostgreSQL → Debezium → Kafka → Flink
# This script tests the complete CDC pipeline

set -e

echo "🚀 Starting Data Flow Test..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to wait for service
wait_for_service() {
    local host=$1
    local port=$2
    local service_name=$3
    
    echo -e "${YELLOW}⏳ Waiting for $service_name to be ready...${NC}"
    while ! nc -z $host $port; do
        sleep 2
    done
    echo -e "${GREEN}✅ $service_name is ready!${NC}"
}

# Function to check if Docker Compose is running
check_services() {
    echo -e "${BLUE}🔍 Checking if services are running...${NC}"
    
    if ! docker compose ps | grep -q "Up"; then
        echo -e "${RED}❌ Docker Compose services are not running. Please run 'docker compose up -d' first.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Docker Compose services are running!${NC}"
}

# Function to register Debezium connector
register_connector() {
    echo -e "${BLUE}📡 Registering Debezium connector...${NC}"
    
    # Wait for Debezium Connect to be ready
    wait_for_service localhost 8083 "Debezium Connect"
    
    # Delete existing connector if it exists
    curl -X DELETE http://localhost:8083/connectors/inventory-connector 2>/dev/null || true
    
    # Register the inventory connector
    curl -X POST \
        -H "Content-Type: application/json" \
        -d @debezium/inventory-connector.json \
        http://localhost:8083/connectors
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Debezium connector registered successfully!${NC}"
    else
        echo -e "${RED}❌ Failed to register Debezium connector${NC}"
        exit 1
    fi
    
    # Check connector status
    sleep 5
    echo -e "${BLUE}📊 Connector Status:${NC}"
    curl -s http://localhost:8083/connectors/inventory-connector/status | jq '.' || echo "Failed to get status"
}

# Function to start Flink job
start_flink_job() {
    echo -e "${BLUE}🔧 Starting Flink SQL job...${NC}"
    
    wait_for_service localhost 8081 "Flink JobManager"
    
    # Submit the Flink SQL job
    docker compose exec -T flink-sql-client bash -c "
        echo 'Starting Flink SQL Client...'
        /opt/flink/bin/sql-client.sh --init /opt/flink/sql/simple-test-job.sql --update <<EOF
-- Set execution mode to streaming
SET execution.runtime-mode = streaming;

-- Execute the simple test job
source '/opt/flink/sql/simple-test-job.sql';

-- Show running jobs
SHOW JOBS;
EOF
    " &
    
    FLINK_PID=$!
    echo -e "${GREEN}✅ Flink job submitted! PID: $FLINK_PID${NC}"
    echo -e "${YELLOW}💡 Flink Web UI available at: http://localhost:8081${NC}"
}

# Function to check Kafka topics
check_kafka_topics() {
    echo -e "${BLUE}📋 Checking Kafka topics...${NC}"
    
    # List all topics
    echo -e "${YELLOW}Available Kafka topics:${NC}"
    docker compose exec kafka-broker kafka-topics.sh --bootstrap-server localhost:29092 --list
    
    # Check specific topics
    for topic in "postgres-server.inventory.users" "postgres-server.inventory.products" "postgres-server.inventory.orders"; do
        echo -e "${YELLOW}Checking topic: $topic${NC}"
        docker compose exec kafka-broker kafka-topics.sh --bootstrap-server localhost:29092 --describe --topic "$topic" 2>/dev/null || echo "Topic $topic not found"
    done
}

# Function to insert test data
insert_test_data() {
    echo -e "${BLUE}💾 Inserting test data into PostgreSQL...${NC}"
    
    # Insert new user
    docker compose exec -T postgres psql -U postgres -d sourcedb -c "
        INSERT INTO inventory.users (username, email, full_name) 
        VALUES ('test_user_$(date +%s)', 'test$(date +%s)@example.com', 'Test User $(date +%H%M%S)');
    "
    
    # Insert new product
    docker compose exec -T postgres psql -U postgres -d sourcedb -c "
        INSERT INTO inventory.products (name, description, price, stock_quantity, category) 
        VALUES ('Test Product $(date +%H%M%S)', 'A test product', 99.99, 10, 'Test');
    "
    
    # Insert new order
    docker compose exec -T postgres psql -U postgres -d sourcedb -c "
        INSERT INTO inventory.orders (user_id, product_id, quantity, total_amount, order_status) 
        VALUES (1, 1, 1, 99.99, 'pending');
    "
    
    # Update existing user
    docker compose exec -T postgres psql -U postgres -d sourcedb -c "
        UPDATE inventory.users SET full_name = 'Updated User $(date +%H%M%S)' WHERE id = 1;
    "
    
    echo -e "${GREEN}✅ Test data inserted successfully!${NC}"
}

# Function to monitor Kafka messages
monitor_kafka() {
    echo -e "${BLUE}👀 Monitoring Kafka messages (Ctrl+C to stop)...${NC}"
    echo -e "${YELLOW}This will show CDC events from PostgreSQL in real-time${NC}"
    
    # Monitor users topic
    docker compose exec kafka-broker kafka-console-consumer.sh \
        --bootstrap-server localhost:29092 \
        --topic postgres-server.inventory.users \
        --from-beginning \
        --max-messages 10 \
        2>/dev/null || echo "No messages in users topic yet"
}

# Function to check Flink job status
check_flink_status() {
    echo -e "${BLUE}🔍 Checking Flink job status...${NC}"
    
    # Get job list
    curl -s http://localhost:8081/jobs | jq '.jobs[] | {id: .id, name: .name, status: .status}' 2>/dev/null || echo "Failed to get job status"
    
    echo -e "${YELLOW}💡 Check Flink Web UI for detailed job information: http://localhost:8081${NC}"
}

# Main execution
main() {
    echo -e "${GREEN}🎯 Data Flow Test Script${NC}"
    echo -e "${GREEN}=========================${NC}"
    
    case "${1:-all}" in
        "setup")
            check_services
            register_connector
            ;;
        "flink")
            start_flink_job
            ;;
        "test")
            insert_test_data
            ;;
        "monitor")
            monitor_kafka
            ;;
        "status")
            check_services
            check_kafka_topics
            check_flink_status
            ;;
        "all")
            check_services
            register_connector
            check_kafka_topics
            start_flink_job
            sleep 10
            insert_test_data
            sleep 5
            echo -e "${GREEN}🎉 Data flow test completed!${NC}"
            echo -e "${YELLOW}💡 To monitor real-time data flow:${NC}"
            echo -e "  - Kafka UI: Run 'docker compose exec kafka-broker kafka-console-consumer.sh --bootstrap-server localhost:29092 --topic postgres-server.inventory.users --from-beginning'"
            echo -e "  - Flink UI: http://localhost:8081"
            echo -e "  - Insert more data: ./test-data-flow.sh test"
            ;;
        "python-pyflink")
            echo -e "${BLUE}🐍 Starting PyFlink processor...${NC}"
            docker-compose --profile python up -d pyflink-processor
            echo -e "${GREEN}✅ PyFlink processor started!${NC}"
            echo -e "${YELLOW}💡 Check logs: docker-compose logs -f pyflink-processor${NC}"
            ;;
        "python-standalone")
            echo -e "${BLUE}🐍 Starting standalone Python processor...${NC}"
            docker-compose --profile python up -d standalone-python-processor
            echo -e "${GREEN}✅ Standalone Python processor started!${NC}"
            echo -e "${YELLOW}💡 Check logs: docker-compose logs -f standalone-python-processor${NC}"
            ;;
        "python-all")
            echo -e "${BLUE}🐍 Starting all Python processors...${NC}"
            docker-compose --profile python up -d
            echo -e "${GREEN}✅ All Python processors started!${NC}"
            echo -e "${YELLOW}💡 Available services:${NC}"
            echo -e "  - PyFlink: docker-compose logs -f pyflink-processor"
            echo -e "  - Standalone Python: docker-compose logs -f standalone-python-processor"
            ;;
        "help")
            echo -e "${BLUE}Usage: $0 [setup|flink|test|monitor|status|all|python-pyflink|python-standalone|python-all|help]${NC}"
            echo -e "  setup             - Register Debezium connector"
            echo -e "  flink             - Start Flink SQL job"
            echo -e "  test              - Insert test data into PostgreSQL"
            echo -e "  monitor           - Monitor Kafka messages"
            echo -e "  status            - Check service status"
            echo -e "  all               - Run complete test (default)"
            echo -e "  python-pyflink    - Start PyFlink processor (Python Flink API)"
            echo -e "  python-standalone - Start standalone Python processor (no Flink)"
            echo -e "  python-all        - Start all Python processors"
            echo -e "  help              - Show this help"
            ;;
        *)
            echo -e "${RED}❌ Unknown command: $1${NC}"
            echo -e "${BLUE}Use '$0 help' for usage information${NC}"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 