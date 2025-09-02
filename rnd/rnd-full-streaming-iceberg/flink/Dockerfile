FROM apache/flink:1.18-scala_2.12-java11

# Download essential connectors with fixed URLs
RUN wget -P /opt/flink/lib/ https://repo1.maven.org/maven2/org/apache/flink/flink-connector-kafka/3.1.0-1.18/flink-connector-kafka-3.1.0-1.18.jar && \
    wget -P /opt/flink/lib/ https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-flink-runtime-1.18/1.5.2/iceberg-flink-runtime-1.18-1.5.2.jar && \
    wget -P /opt/flink/lib/ https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-aws-bundle/1.5.2/iceberg-aws-bundle-1.5.2.jar && \
    wget -P /opt/flink/lib/ https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-common/3.3.6/hadoop-common-3.3.6.jar && \
    wget -P /opt/flink/lib/ https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-client-api/3.3.6/hadoop-client-api-3.3.6.jar && \
    wget -P /opt/flink/lib/ https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-auth/3.3.6/hadoop-auth-3.3.6.jar && \
    wget -P /opt/flink/lib/ https://repo1.maven.org/maven2/commons-configuration/commons-configuration/1.10/commons-configuration-1.10.jar && \
    wget -P /opt/flink/lib/ https://repo1.maven.org/maven2/commons-collections/commons-collections/3.2.2/commons-collections-3.2.2.jar && \
    wget -P /opt/flink/lib/ https://repo1.maven.org/maven2/commons-io/commons-io/2.11.0/commons-io-2.11.0.jar && \
    wget -P /opt/flink/lib/ https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar && \
    wget -P /opt/flink/lib/ https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar

# Copy auto-setup script that runs on container startup
COPY auto-setup.sql /opt/flink/auto-setup.sql

# Create entrypoint script for auto-setup
RUN echo '#!/bin/bash\n\
# Start Flink in background if this is JobManager\n\
if [ "$1" = "jobmanager" ]; then\n\
    /docker-entrypoint.sh "$@" &\n\
    FLINK_PID=$!\n\
    \n\
    # Wait for Flink to be ready\n\
    echo "Waiting for Flink to be ready..."\n\
    sleep 10\n\
    \n\
    # Auto-setup catalog and tables\n\
    echo "Setting up Iceberg catalog and tables..."\n\
    if [ -f /opt/flink/auto-setup.sql ]; then\n\
        sql-client.sh -f /opt/flink/auto-setup.sql || echo "Setup script failed, but continuing..."\n\
    fi\n\
    \n\
    # Keep Flink running\n\
    wait $FLINK_PID\n\
elif [ "$1" = "sql-client" ]; then\n\
    # For SQL client, wait for JobManager to be ready, then run setup\n\
    sleep 15\n\
    echo "Setting up Iceberg catalog and tables from SQL client..."\n\
    if [ -f /opt/flink/auto-setup.sql ]; then\n\
        sql-client.sh -f /opt/flink/auto-setup.sql &\n\
    fi\n\
    /docker-entrypoint.sh "$@"\n\
else\n\
    /docker-entrypoint.sh "$@"\n\
fi' > /opt/flink/entrypoint-with-setup.sh && \
    chmod +x /opt/flink/entrypoint-with-setup.sh

# Copy Flink configuration
COPY flink/conf/flink-conf.yaml /opt/flink/conf/

# Copy SQL scripts
COPY flink-sql/ /opt/flink/sql/

WORKDIR /opt/flink 