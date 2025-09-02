# PostgreSQL to Iceberg CDC Pipeline

This project sets up a complete Change Data Capture (CDC) pipeline that automatically streams data changes from PostgreSQL to Apache Iceberg tables through Kafka and Apache Flink.

## Architecture

```
PostgreSQL → Debezium (CDC) → Kafka → Flink → Iceberg → Trino (Query Engine)
```

## Components

- **PostgreSQL 15**: Source database with logical replication enabled
- **Debezium Connect**: CDC connector for PostgreSQL
- **Apache Kafka**: Message streaming platform
- **Apache Flink**: Stream processing for Kafka to Iceberg
- **Apache Polaris**: Iceberg REST catalog
- **MinIO**: S3-compatible object storage for Iceberg data
- **Trino**: SQL query engine for Iceberg

## Quick Start

### 1. Start the Environment

```bash
docker-compose up -d
```

This will start all services. Wait for all containers to be healthy (about 2-3 minutes).

### 2. Initialize PostgreSQL Data

The sample tables and data are automatically created via the initialization script in `init-scripts/init-postgres.sql`.

### 3. Set up Debezium Connector

Register the PostgreSQL connector with Debezium:

```bash
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @debezium/postgres-connector.json
```

Check if the connector is running:

```bash
curl http://localhost:8083/connectors/postgres-connector/status
```

### 4. Set up Flink CDC Pipeline

Access the Flink SQL Client:

```bash
docker exec -it $(docker ps -q -f name=flink-sql-client) sql-client.sh
```

Execute the CDC pipeline setup:

```sql
-- Load and execute the setup script
-- Copy the contents of flink-sql/setup-cdc-pipeline.sql
-- and paste them in the Flink SQL client
```

### 5. Query Data with Trino

Access Trino CLI:

```bash
docker exec -it $(docker ps -q -f name=trino) trino
```

Query the Iceberg tables:

```sql
-- List catalogs
SHOW CATALOGS;

-- Use iceberg catalog
USE iceberg.inventory;

-- List tables
SHOW TABLES;

-- Query users data
SELECT * FROM users;

-- Query products data
SELECT * FROM products;

-- Query orders data
SELECT * FROM orders;
```

## Testing CDC

### Insert New Data

Connect to PostgreSQL:

```bash
docker exec -it $(docker ps -q -f name=postgres) psql -U postgres -d sourcedb
```

Insert new records:

```sql
-- Insert new user
INSERT INTO inventory.users (username, email, full_name) 
VALUES ('alice_brown', 'alice@example.com', 'Alice Brown');

-- Update existing product
UPDATE inventory.products 
SET price = 899.99, stock_quantity = 45 
WHERE id = 1;

-- Insert new order
INSERT INTO inventory.orders (user_id, product_id, quantity, total_amount) 
VALUES (4, 1, 1, 899.99);
```

### Verify Changes in Iceberg

Go back to Trino and query the tables to see the changes reflected:

```sql
-- Check latest users (should include Alice)
SELECT * FROM iceberg.inventory.users ORDER BY id DESC;

-- Check product price update
SELECT * FROM iceberg.inventory.products WHERE id = 1;

-- Check new order
SELECT * FROM iceberg.inventory.orders ORDER BY id DESC;
```

## Web Interfaces

- **Flink Dashboard**: http://localhost:8081
- **Kafka Connect REST API**: http://localhost:8083
- **Trino Web UI**: http://localhost:8080
- **MinIO Console**: http://localhost:9001 (admin/password)
- **Polaris**: http://localhost:8181

## Monitoring

### Check Kafka Topics

List topics to see CDC topics created by Debezium:

```bash
docker exec kafka-broker kafka-topics.sh --bootstrap-server localhost:9092 --list
```

### Check Debezium Connector Status

```bash
curl http://localhost:8083/connectors/postgres-connector/status | jq
```

### View Kafka Messages

```bash
docker exec kafka-broker kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic postgres-server.inventory.users \
  --from-beginning
```

## File Structure

```
├── docker-compose.yml              # Main orchestration
├── flink/
│   ├── Dockerfile                  # Flink with connectors
│   └── conf/flink-conf.yaml        # Flink configuration
├── trino/
│   └── catalog/iceberg.properties  # Trino Iceberg catalog
├── debezium/
│   └── postgres-connector.json     # Debezium connector config
├── init-scripts/
│   └── init-postgres.sql           # PostgreSQL setup script
├── flink-sql/
│   └── setup-cdc-pipeline.sql      # Flink CDC pipeline
└── README.md                       # This file
```

## Troubleshooting

### PostgreSQL Connection Issues

Check if PostgreSQL is ready:

```bash
docker logs $(docker ps -q -f name=postgres)
```

### Debezium Connector Issues

Check connector logs:

```bash
docker logs $(docker ps -q -f name=debezium-connect)
```

### Flink Job Issues

Check Flink logs:

```bash
docker logs $(docker ps -q -f name=flink-jobmanager)
docker logs $(docker ps -q -f name=flink-taskmanager)
```

### Clean Restart

To completely reset the environment:

```bash
docker-compose down -v
docker-compose up -d
```

## Advanced Configuration

### Scaling Task Managers

To scale Flink task managers:

```bash
docker-compose up -d --scale flink-taskmanager=3
```

### Custom Kafka Topics

Modify the Debezium connector configuration in `debezium/postgres-connector.json` to customize topic names and behavior.

### Different Source Tables

1. Add tables to PostgreSQL schema
2. Update `table.include.list` in Debezium connector
3. Create corresponding Flink tables in the CDC pipeline script

## Next Steps

- Add more tables to the CDC pipeline
- Implement data transformations in Flink
- Set up monitoring with Prometheus/Grafana
- Add schema evolution handling
- Implement compaction strategies for Iceberg tables 