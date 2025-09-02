# Simple Data Flow Test Guide

This guide helps you test the complete data flow: **PostgreSQL → Debezium → Kafka → Flink**

## Quick Start

1. **Start all services:**
   ```bash
   docker-compose up -d
   ```

2. **Run the complete test:**
   ```bash
   ./test-data-flow.sh
   ```

That's it! The script will:
- Register the Debezium connector for inventory tables
- Start Flink jobs to process CDC events
- Insert test data into PostgreSQL
- Show you how to monitor the data flow

## Step-by-Step Testing

### 1. Setup Debezium Connector
```bash
./test-data-flow.sh setup
```

This registers a CDC connector that watches the `inventory` schema tables:
- `inventory.users`
- `inventory.products` 
- `inventory.orders`

### 2. Start Flink Jobs
```bash
./test-data-flow.sh flink
```

This starts two simple Flink jobs:
- **User Changes Log**: Prints all user table changes to console
- **Order Analytics**: Real-time analytics on orders (30-second windows)

### 3. Insert Test Data
```bash
./test-data-flow.sh test
```

This inserts and updates data in PostgreSQL to trigger CDC events.

### 4. Monitor Data Flow

**Check Kafka topics:**
```bash
docker-compose exec kafka-broker kafka-topics.sh --bootstrap-server localhost:29092 --list
```

**Monitor CDC events in real-time:**
```bash
docker-compose exec kafka-broker kafka-console-consumer.sh \
  --bootstrap-server localhost:29092 \
  --topic postgres-server.inventory.users \
  --from-beginning
```

**Check Flink job output:**
- Go to Flink Web UI: http://localhost:8081
- Check job logs to see processed events

## What You Should See

1. **Kafka Topics Created:**
   - `postgres-server.inventory.users`
   - `postgres-server.inventory.products`
   - `postgres-server.inventory.orders`

2. **CDC Events in Kafka:**
   ```json
   {
     "id": 1,
     "username": "john_doe",
     "email": "john@example.com",
     "op": "c",
     "ts_ms": 1642515234567
   }
   ```

3. **Flink Processing:**
   - User changes logged to console
   - Order analytics computed every 30 seconds

## Manual Testing

To manually test the flow:

```bash
# 1. Add a new user
docker-compose exec postgres psql -U postgres -d sourcedb -c \
  "INSERT INTO inventory.users (username, email, full_name) VALUES ('manual_test', 'manual@test.com', 'Manual Test User');"

# 2. Update existing user
docker-compose exec postgres psql -U postgres -d sourcedb -c \
  "UPDATE inventory.users SET full_name = 'Updated Manual User' WHERE username = 'manual_test';"

# 3. Watch the events flow through Kafka
docker-compose exec kafka-broker kafka-console-consumer.sh \
  --bootstrap-server localhost:29092 \
  --topic postgres-server.inventory.users \
  --from-beginning
```

## Monitoring UIs

- **Flink Dashboard**: http://localhost:8081
- **Postgres**: Access via `docker-compose exec postgres psql -U postgres -d sourcedb`
- **Debezium Connector Status**: 
  ```bash
  curl http://localhost:8083/connectors/inventory-connector/status
  ```

## Troubleshooting

**No CDC events?**
- Check Debezium connector status: `curl http://localhost:8083/connectors/inventory-connector/status`
- Ensure logical replication is enabled in PostgreSQL

**Flink job not running?**
- Check Flink Web UI: http://localhost:8081
- Check container logs: `docker-compose logs flink-jobmanager`

**Kafka topics empty?**
- List topics: `docker-compose exec kafka-broker kafka-topics.sh --bootstrap-server localhost:29092 --list`
- Check Debezium Connect logs: `docker-compose logs debezium-connect`

## Test Commands

```bash
# Full test
./test-data-flow.sh all

# Individual components
./test-data-flow.sh setup    # Setup Debezium
./test-data-flow.sh flink    # Start Flink jobs
./test-data-flow.sh test     # Insert test data
./test-data-flow.sh monitor  # Monitor Kafka
./test-data-flow.sh status   # Check all services
``` 