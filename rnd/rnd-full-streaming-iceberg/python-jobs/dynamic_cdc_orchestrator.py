#!/usr/bin/env python3
"""
Dynamic CDC Orchestrator
This script monitors Kafka topics for CDC events and triggers specific Flink jobs
based on which table has changes.

Flow: Kafka Topic Change Detection → Trigger Specific Flink Job → Monitor Job Status
"""

import json
import time
import logging
import subprocess
import threading
from datetime import datetime
from typing import Dict, Set, Optional
from kafka import KafkaConsumer
from collections import defaultdict
import os

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class DynamicCDCOrchestrator:
    def __init__(self):
        self.kafka_bootstrap_servers = os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'kafka-broker:29092')
        self.flink_sql_client_container = os.getenv('FLINK_SQL_CLIENT_CONTAINER', 'flink-sql-client')
        
        # Track active jobs to prevent duplicates
        self.active_jobs: Dict[str, bool] = {}
        
        # Table to topic mapping
        self.table_topics = {
            'faculty': 'university-server.public.faculty',
            'program': 'university-server.public.program', 
            'students': 'university-server.public.students',
            'payment': 'university-server.public.payment',
            'lecturer': 'university-server.public.lecturer',
            'course': 'university-server.public.course',
            'registration': 'university-server.public.registration',
            'class': 'university-server.public.class',
            'student_enrollment': 'university-server.public.student_enrollment',
            'student_fee': 'university-server.public.student_fee',
            'student_detail': 'university-server.public.student_detail',
            'room': 'university-server.public.room'
        }
        
        # Recent activity tracking (last 30 seconds)
        self.recent_activity: Dict[str, datetime] = {}
        self.activity_threshold = 30  # seconds
        
        # Job SQL file mapping
        self.job_files = {
            'faculty': '/opt/flink/sql/jobs/start-faculty-job.sql',
            'program': '/opt/flink/sql/jobs/start-program-job.sql',
            'students': '/opt/flink/sql/jobs/start-students-job.sql',
            'payment': '/opt/flink/sql/jobs/start-payment-job.sql'
        }

    def create_kafka_consumer(self) -> KafkaConsumer:
        """Create Kafka consumer for all university topics."""
        topics = list(self.table_topics.values())
        
        consumer = KafkaConsumer(
            *topics,
            bootstrap_servers=[self.kafka_bootstrap_servers],
            group_id='dynamic-cdc-orchestrator',
            value_deserializer=lambda m: json.loads(m.decode('utf-8')),
            key_deserializer=lambda m: m.decode('utf-8') if m else None,
            auto_offset_reset='latest',  # Only process new messages
            enable_auto_commit=True,
            consumer_timeout_ms=5000  # 5 second timeout
        )
        
        logger.info(f"Created Kafka consumer for topics: {topics}")
        return consumer

    def get_table_from_topic(self, topic: str) -> Optional[str]:
        """Extract table name from Kafka topic."""
        for table, topic_name in self.table_topics.items():
            if topic == topic_name:
                return table
        return None

    def execute_flink_job(self, table_name: str) -> bool:
        """Execute Flink SQL job for specific table."""
        if table_name not in self.job_files:
            logger.warning(f"No job file defined for table: {table_name}")
            return False
            
        job_file = self.job_files[table_name]
        
        try:
            # First, setup the catalog and tables (idempotent)
            setup_cmd = [
                'docker', 'exec', self.flink_sql_client_container,
                'bash', '-c',
                f'/opt/flink/bin/sql-client.sh -f /opt/flink/sql/dynamic-table-job-manager.sql'
            ]
            
            logger.info(f"Setting up Flink catalog and tables...")
            setup_result = subprocess.run(setup_cmd, capture_output=True, text=True, timeout=60)
            
            if setup_result.returncode != 0:
                logger.error(f"Setup failed: {setup_result.stderr}")
                return False
            
            # Then execute the specific job
            job_cmd = [
                'docker', 'exec', self.flink_sql_client_container,
                'bash', '-c',
                f'/opt/flink/bin/sql-client.sh -f {job_file}'
            ]
            
            logger.info(f"Starting Flink job for table: {table_name}")
            job_result = subprocess.run(job_cmd, capture_output=True, text=True, timeout=120)
            
            if job_result.returncode == 0:
                logger.info(f"Successfully started Flink job for table: {table_name}")
                self.active_jobs[table_name] = True
                return True
            else:
                logger.error(f"Failed to start job for {table_name}: {job_result.stderr}")
                return False
                
        except subprocess.TimeoutExpired:
            logger.error(f"Timeout executing Flink job for table: {table_name}")
            return False
        except Exception as e:
            logger.error(f"Error executing Flink job for {table_name}: {e}")
            return False

    def should_trigger_job(self, table_name: str) -> bool:
        """Check if we should trigger a job for this table."""
        now = datetime.now()
        
        # Check if we've seen activity for this table recently
        if table_name in self.recent_activity:
            time_diff = (now - self.recent_activity[table_name]).total_seconds()
            if time_diff < self.activity_threshold:
                logger.debug(f"Recent activity detected for {table_name}, skipping job trigger")
                return False
        
        # Check if job is already active
        if self.active_jobs.get(table_name, False):
            logger.debug(f"Job already active for table: {table_name}")
            return False
            
        return True

    def process_kafka_message(self, message):
        """Process a single Kafka message and trigger job if needed."""
        topic = message.topic
        table_name = self.get_table_from_topic(topic)
        
        if not table_name:
            logger.warning(f"Unknown topic: {topic}")
            return
            
        try:
            # Parse Debezium message
            payload = message.value
            
            # Check if this is a data change event
            if 'payload' in payload and payload.get('payload'):
                op = payload['payload'].get('op')  # c=create, u=update, d=delete, r=read
                
                if op in ['c', 'u', 'r']:  # Only process creates, updates, and reads
                    logger.info(f"Detected {op} operation on table: {table_name}")
                    
                    # Update recent activity
                    self.recent_activity[table_name] = datetime.now()
                    
                    # Check if we should trigger a job
                    if self.should_trigger_job(table_name):
                        logger.info(f"Triggering streaming job for table: {table_name}")
                        success = self.execute_flink_job(table_name)
                        
                        if success:
                            logger.info(f"Successfully triggered job for: {table_name}")
                        else:
                            logger.error(f"Failed to trigger job for: {table_name}")
                    else:
                        logger.debug(f"Job trigger skipped for table: {table_name}")
                        
        except Exception as e:
            logger.error(f"Error processing message from topic {topic}: {e}")

    def cleanup_old_activity(self):
        """Clean up old activity records."""
        now = datetime.now()
        expired_tables = []
        
        for table_name, last_activity in self.recent_activity.items():
            time_diff = (now - last_activity).total_seconds()
            if time_diff > self.activity_threshold * 2:  # Clean up after 60 seconds
                expired_tables.append(table_name)
                
        for table_name in expired_tables:
            del self.recent_activity[table_name]
            # Also mark job as inactive if no recent activity
            self.active_jobs[table_name] = False
            logger.debug(f"Cleaned up activity for table: {table_name}")

    def run(self):
        """Main orchestrator loop."""
        logger.info("Starting Dynamic CDC Orchestrator...")
        
        # Create Kafka consumer
        consumer = self.create_kafka_consumer()
        
        # Start cleanup thread
        cleanup_thread = threading.Thread(target=self.periodic_cleanup, daemon=True)
        cleanup_thread.start()
        
        try:
            logger.info("Listening for CDC events...")
            
            for message in consumer:
                self.process_kafka_message(message)
                
        except KeyboardInterrupt:
            logger.info("Shutting down orchestrator...")
        except Exception as e:
            logger.error(f"Error in main loop: {e}")
        finally:
            consumer.close()
            logger.info("Orchestrator stopped")

    def periodic_cleanup(self):
        """Run periodic cleanup in background."""
        while True:
            time.sleep(30)  # Clean up every 30 seconds
            self.cleanup_old_activity()

if __name__ == "__main__":
    orchestrator = DynamicCDCOrchestrator()
    orchestrator.run() 