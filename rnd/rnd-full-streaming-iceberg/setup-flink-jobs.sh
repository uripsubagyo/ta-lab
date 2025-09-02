#!/bin/bash

# =================================================================
# FLINK SQL JOBS SETUP SCRIPT
# This script sets up the Flink SQL jobs for University CDC Pipeline
# =================================================================

set -e

echo "🚀 Setting up Flink SQL Jobs for University CDC Pipeline..."
echo "==========================================================="

# Check if Flink is running
if ! curl -s http://localhost:8081/overview > /dev/null; then
    echo "❌ Flink JobManager is not running. Please start the pipeline first:"
    echo "   ./start-university-cdc-pipeline.sh"
    exit 1
fi

echo "✅ Flink JobManager is running"

# Function to execute SQL in Flink SQL Client
execute_flink_sql() {
    local sql_file="$1"
    echo "📝 Executing $sql_file..."
    
    # Create a temporary file with SQL commands
    local temp_sql="/tmp/flink_setup.sql"
    cp "$sql_file" "$temp_sql"
    
    # Execute SQL file in Flink SQL Client
    docker exec flink-sql-client bash -c "
        sql-client.sh -f $temp_sql
    "
}

# Function to submit Flink SQL one by one
submit_flink_sql_parts() {
    echo "📝 Setting up Flink SQL tables and jobs..."
    
    # Array of SQL parts to execute separately
    local sql_parts=(
        "CREATE CATALOG"
        "CREATE DATABASE" 
        "Kafka Source Tables"
        "Iceberg Sink Tables"
        "INSERT Jobs"
    )
    
    echo "⚠️ Note: You need to execute the SQL commands manually in Flink SQL Client"
    echo "   This script will open the SQL client for you."
    echo ""
    echo "📋 Steps to follow:"
    echo "   1. Copy and paste sections from: flink-sql/university-cdc-pipeline.sql"
    echo "   2. Execute each section step by step"
    echo "   3. Start with catalog and database setup"
    echo "   4. Then create Kafka source tables"
    echo "   5. Create Iceberg sink tables"
    echo "   6. Finally run INSERT jobs (one by one)"
    echo ""
    echo "🔧 Opening Flink SQL Client..."
    echo "   File location: $(pwd)/flink-sql/university-cdc-pipeline.sql"
    echo ""
    
    # Open Flink SQL Client
    docker exec -it flink-sql-client sql-client.sh
}

# Main execution
echo "🎯 Choose setup method:"
echo "  1. Manual setup (recommended) - Opens Flink SQL Client"
echo "  2. Quick test - Setup basic tables only"
echo ""
read -p "Enter choice (1 or 2): " choice

case $choice in
    1)
        echo "🔧 Manual setup selected..."
        submit_flink_sql_parts
        ;;
    2)
        echo "⚡ Quick test setup selected..."
        
        # Create a minimal SQL setup for testing
        cat > /tmp/quick_flink_setup.sql << 'EOF'
-- Quick setup for testing
CREATE CATALOG iceberg_catalog WITH (
  'type' = 'iceberg',
  'catalog-type' = 'rest',
  'uri' = 'http://polaris:8181/api/catalog/',
  'warehouse' = 'polariscatalog',
  'credential' = 'root:secret',
  'scope' = 'PRINCIPAL_ROLE:ALL',
  's3.endpoint' = 'http://minio:9000',
  's3.region' = 'dummy-region',
  's3.access-key-id' = 'admin',
  's3.secret-access-key' = 'password'
);

USE CATALOG iceberg_catalog;
CREATE DATABASE IF NOT EXISTS university;
USE university;

-- Create one test table
CREATE TABLE kafka_faculty (
  id INT,
  faculty_code STRING,
  faculty_name STRING,
  created_at TIMESTAMP(3),
  op STRING,
  ts_ms BIGINT,
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector' = 'kafka',
  'topic' = 'university-server.public.faculty',
  'properties.bootstrap.servers' = 'kafka-broker:29092',
  'properties.group.id' = 'flink-faculty-consumer',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'debezium-json'
);

CREATE TABLE faculty_iceberg (
  id INT,
  faculty_code STRING,
  faculty_name STRING,
  created_at TIMESTAMP(3),
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'database-name' = 'university',
  'table-name' = 'faculty_iceberg'
);

-- Show tables to verify
SHOW TABLES;
EOF

        echo "📤 Executing quick setup..."
        docker exec flink-sql-client bash -c "sql-client.sh -f /tmp/quick_flink_setup.sql"
        
        echo "✅ Quick setup completed!"
        echo "📊 To start streaming, execute this in Flink SQL Client:"
        echo "   INSERT INTO faculty_iceberg SELECT id, faculty_code, faculty_name, created_at FROM kafka_faculty WHERE op != 'd';"
        ;;
    *)
        echo "❌ Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo "📋 Next Steps:"
echo "============="
echo ""
echo "1. 🔍 Monitor Flink Jobs:"
echo "   Visit: http://localhost:8081"
echo ""
echo "2. 🧪 Test the pipeline:"
echo "   ./test-university-pipeline.sh"
echo ""
echo "3. 📊 Query data with Trino:"
echo "   docker exec -it \$(docker ps -q -f name=trino) trino"
echo "   trino> USE iceberg.university;"
echo "   trino> SHOW TABLES;"
echo "   trino> SELECT * FROM faculty_iceberg LIMIT 10;"
echo ""
echo "4. 🔧 Access Flink SQL Client again:"
echo "   docker exec -it flink-sql-client sql-client.sh"
echo ""
echo "🎉 Flink setup script completed!" 