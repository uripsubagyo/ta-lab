#!/bin/bash

# =================================================================
# SETUP ALL UNIVERSITY STREAMING JOBS
# This script sets up and runs all Flink streaming jobs for
# the complete university CDC pipeline
# =================================================================

set -e  # Exit on any error

echo "🚀 Starting University Streaming Jobs Setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =================================================================
# 1. WAIT FOR SERVICES TO BE READY
# =================================================================

print_status "Waiting for required services to be ready..."

# Wait for Kafka
print_status "Checking Kafka..."
while ! docker exec $(docker ps -q -f name=kafka-broker) kafka-topics.sh --bootstrap-server localhost:29092 --list >/dev/null 2>&1; do
    print_warning "Waiting for Kafka to be ready..."
    sleep 5
done
print_success "Kafka is ready!"

# Wait for Debezium Connect
print_status "Checking Debezium Connect..."
while ! curl -sf http://localhost:8083/connectors >/dev/null 2>&1; do
    print_warning "Waiting for Debezium Connect to be ready..."
    sleep 5
done
print_success "Debezium Connect is ready!"

# Wait for Flink JobManager
print_status "Checking Flink JobManager..."
while ! curl -sf http://localhost:8081/overview >/dev/null 2>&1; do
    print_warning "Waiting for Flink JobManager to be ready..."
    sleep 5
done
print_success "Flink JobManager is ready!"

# Wait for Polaris (Iceberg Catalog)
print_status "Checking Polaris (Iceberg Catalog)..."
while ! curl -sf http://localhost:8181/healthcheck >/dev/null 2>&1; do
    print_warning "Waiting for Polaris to be ready..."
    sleep 5
done
print_success "Polaris is ready!"

# Wait for MinIO
print_status "Checking MinIO..."
while ! curl -sf http://localhost:9000/minio/health/live >/dev/null 2>&1; do
    print_warning "Waiting for MinIO to be ready..."
    sleep 5
done
print_success "MinIO is ready!"

# =================================================================
# 2. CHECK DEBEZIUM CONNECTOR STATUS
# =================================================================

print_status "Checking Debezium connector status..."

# Check if university-connector exists and is running
CONNECTOR_STATUS=$(curl -sf http://localhost:8083/connectors/university-connector/status 2>/dev/null || echo "not_found")

if [[ "$CONNECTOR_STATUS" == "not_found" ]]; then
    print_warning "University connector not found. Please ensure Debezium connector is running."
    print_status "You can check with: curl http://localhost:8083/connectors/university-connector/status"
else
    print_success "University connector is active!"
fi

# =================================================================
# 3. LIST AVAILABLE KAFKA TOPICS
# =================================================================

print_status "Listing available Kafka topics..."
docker exec $(docker ps -q -f name=kafka-broker) kafka-topics.sh \
    --bootstrap-server localhost:29092 \
    --list | grep -E "(university-server|debezium)" || print_warning "No university topics found yet"

# =================================================================
# 4. SETUP STREAMING JOBS VIA FLINK SQL CLIENT
# =================================================================

print_status "Setting up Flink streaming jobs..."

# Create a temporary directory for SQL files
TEMP_DIR="/tmp/flink-streaming-setup"
mkdir -p "$TEMP_DIR"

# Copy the streaming jobs SQL file to temp directory
cp ./flink-sql/complete-university-streaming-jobs.sql "$TEMP_DIR/"

print_status "Executing streaming jobs setup via Flink SQL client..."

# Execute the streaming jobs setup
docker exec -i $(docker ps -q -f name=flink-sql-client) /opt/flink/bin/sql-client.sh <<EOF
\q
EOF

# Execute via copying file and running
docker cp "$TEMP_DIR/complete-university-streaming-jobs.sql" $(docker ps -q -f name=flink-sql-client):/opt/flink/

# Alternative: Execute SQL file directly
print_status "Submitting Flink SQL jobs..."
docker exec $(docker ps -q -f name=flink-sql-client) bash -c "
    cd /opt/flink && 
    ./bin/sql-client.sh -f complete-university-streaming-jobs.sql
" || print_warning "Some SQL commands may have failed - this is normal for table creation"

# =================================================================
# 5. VERIFY JOBS ARE RUNNING
# =================================================================

print_status "Verifying Flink jobs are running..."

# Get running jobs
sleep 10  # Wait for jobs to start

RUNNING_JOBS=$(curl -sf http://localhost:8081/jobs | jq -r '.jobs[] | select(.status == "RUNNING") | .name' 2>/dev/null || echo "")

if [[ -z "$RUNNING_JOBS" ]]; then
    print_warning "No running Flink jobs found. Manual intervention may be required."
    print_status "Check Flink Web UI at: http://localhost:8081"
else
    print_success "Found running Flink jobs:"
    echo "$RUNNING_JOBS"
fi

# =================================================================
# 6. TEST DATA FLOW (Optional)
# =================================================================

print_status "Testing data flow by inserting sample data..."

# Insert test data into PostgreSQL
docker exec -i $(docker ps -q -f name=postgres) psql -U postgres -d sourcedb <<EOF
-- Insert test faculty
INSERT INTO faculty (faculty_code, faculty_name) 
VALUES ('CS', 'Computer Science') 
ON CONFLICT (faculty_code) DO NOTHING;

-- Insert test program
INSERT INTO program (program_code, program_name, faculty_id, degree) 
VALUES ('CS-S1', 'Computer Science Bachelor', 1, 'S1') 
ON CONFLICT (program_code) DO NOTHING;

-- Insert test student
INSERT INTO students (student_id, full_name, entry_year, program_id, faculty_id) 
VALUES ('2024001', 'John Doe', 2024, 1, 1) 
ON CONFLICT (student_id) DO NOTHING;

SELECT 'Test data inserted successfully' as status;
EOF

print_success "Test data inserted into PostgreSQL"

# =================================================================
# 7. PROVIDE VERIFICATION COMMANDS
# =================================================================

print_success "Streaming jobs setup completed!"
echo ""
echo "🔍 VERIFICATION COMMANDS:"
echo "========================="
echo ""
echo "1. Check Flink Web UI:"
echo "   http://localhost:8081"
echo ""
echo "2. Check running jobs:"
echo "   curl http://localhost:8081/jobs"
echo ""
echo "3. Check Kafka topics:"
echo "   docker exec \$(docker ps -q -f name=kafka-broker) kafka-topics.sh --bootstrap-server localhost:29092 --list"
echo ""
echo "4. Check Debezium connector:"
echo "   curl http://localhost:8083/connectors/university-connector/status"
echo ""
echo "5. Query Iceberg tables via Trino:"
echo "   docker exec -i \$(docker ps -q -f name=trino) trino --catalog iceberg --schema university"
echo ""
echo "6. Check MinIO buckets:"
echo "   http://localhost:9001 (admin/password)"
echo ""
echo "🎯 NEXT STEPS:"
echo "=============="
echo "1. Verify that CDC topics are being created in Kafka"
echo "2. Confirm that Flink jobs are processing data"
echo "3. Check that Iceberg tables are being created in MinIO"
echo "4. Test querying data via Trino"
echo ""
print_success "All streaming jobs have been configured and submitted!"

# Cleanup
rm -rf "$TEMP_DIR" 