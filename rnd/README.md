# Data Lakehouse dengan Apache Iceberg dan Trino

Repositori ini berisi implementasi data lakehouse menggunakan Apache Iceberg, Trino, MinIO, dan komponen-komponen modern lainnya untuk analitik data skala enterprise.

## 🏗️ Arsitektur

### Komponen Utama

- **Apache Iceberg**: Table format untuk data lakehouse dengan dukungan ACID transactions
- **Trino**: Query engine terdistribusi untuk analitik performa tinggi
- **MinIO**: Object storage yang kompatibel dengan S3
- **Iceberg REST Catalog**: Metadata management untuk tabel Iceberg
- **Apache Spark**: Processing engine untuk transformasi data
- **PostgreSQL**: Source database (simulasi sistem SIAK)
- **Jupyter Notebook**: Development environment
- **StarRocks**: Analytical database (opsional)

### Arsitektur Data Lakehouse

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│ Source Data │───▶│ ETL Pipeline │───▶│ Data Lake   │
│ (PostgreSQL)│    │ (Spark/Trino)│    │ (MinIO)     │
└─────────────┘    └──────────────┘    └─────────────┘
                                              │
                                              ▼
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│ BI Tools    │◀───│ Query Engine │◀───│ Iceberg     │
│ (Jupyter)   │    │ (Trino)      │    │ Tables      │
└─────────────┘    └──────────────┘    └─────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Docker dan Docker Compose
- Minimal 8GB RAM
- 20GB disk space

### 1. Clone dan Setup

```bash
git clone <repository-url>
cd rnd-startrocks-iceberg
```

### 2. Jalankan Environment

```bash
docker-compose up -d
```

### 3. Verifikasi Services

```bash
# Cek semua container berjalan
docker-compose ps

# Akses web interfaces
echo "MinIO Console: http://localhost:9001 (admin/password)"
echo "Jupyter Notebook: http://localhost:8888 (token: lakehouse123)"
echo "Trino Web UI: http://localhost:8085"
echo "Spark Web UI: http://localhost:8080"
```

### 4. Setup Lakehouse Schema

```bash
# Akses Trino CLI
docker exec -it trino trino

# Jalankan setup script
\i /opt/scripts/lakehouse_setup.sql
```

### 5. Load Sample Data

```sql
-- Di Trino CLI
\i /opt/scripts/etl_pipeline.sql
```

## 📊 Struktur Data Lakehouse

### Bronze Layer (Raw Data)
- Data mentah dari sistem sumber (PostgreSQL)
- Format: Parquet files in MinIO
- Partitioning: By date and source

### Silver Layer (Cleaned Data)
- Data yang sudah dibersihkan dan terstruktur
- Dimensional model dengan fact dan dimension tables
- Iceberg tables dengan ACID transactions

### Gold Layer (Aggregated Data)
- Data yang sudah diagregasi untuk analytics
- Pre-calculated metrics dan KPIs
- Optimized untuk BI tools

## 🏢 Data Model

### Dimension Tables

#### dim_students
```sql
- student_key (surrogate key)
- student_id, npm, full_name
- faculty, program, entry_year
- SCD Type 2 implementation
- Partitioned by: faculty, entry_year
```

#### dim_courses
```sql
- course_key (surrogate key)  
- course_id, course_code, course_name
- credits, faculty, semester
- Partitioned by: faculty, semester
```

#### dim_date
```sql
- date_key, full_date
- year, quarter, month, week
- academic_year, semester
- Partitioned by: year, month
```

### Fact Tables

#### fact_enrollments
```sql
- enrollment_key (surrogate key)
- student_key, course_key, date_key
- grade, credits_attempted, credits_earned
- Partitioned by: academic_year, semester
```

#### fact_attendance
```sql
- attendance_key (surrogate key)
- student_key, course_key, date_key  
- status, is_present
- Partitioned by: year, month
```

#### fact_financial
```sql
- financial_key (surrogate key)
- student_key, date_key
- transaction_type, amount, is_paid
- Partitioned by: academic_year, semester
```

### Aggregated Tables

#### agg_student_performance
```sql
- student_key, academic_year, semester
- gpa, attendance_rate, financial_status
- Pre-calculated KPIs per student
```

#### agg_course_analytics
```sql
- course_key, academic_year, semester
- completion_rate, average_grade, pass_rate
- Course performance metrics
```

#### agg_financial_summary  
```sql
- faculty, academic_year, semester
- total_revenue, collection_rate
- Financial performance by faculty
```

## 🔧 Konfigurasi

### Trino Configuration

```properties
# iceberg.properties
connector.name=iceberg
iceberg.catalog.type=rest
iceberg.rest-catalog.uri=http://rest:8181
iceberg.rest-catalog.warehouse=s3://warehouse/
```

### MinIO Configuration

```properties
# Environment variables
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=password
MINIO_REGION=us-east-1
```

### Spark Configuration

```properties
# spark-defaults.conf
spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.iceberg.type=rest
spark.sql.catalog.iceberg.uri=http://rest:8181
```

## 📈 Contoh Query Analytics

### 1. Student Performance Analysis

```sql
-- Top performing students
SELECT 
    ds.npm, ds.full_name, ds.faculty,
    asp.gpa, asp.attendance_rate
FROM iceberg.lakehouse.agg_student_performance asp
JOIN iceberg.lakehouse.dim_students ds ON asp.student_key = ds.student_key
WHERE asp.academic_year = '2024/2025' 
    AND asp.gpa > 3.5
ORDER BY asp.gpa DESC;
```

### 2. Course Analytics

```sql
-- Course performance by faculty
SELECT 
    dc.faculty, dc.course_name,
    ac.completion_rate, ac.average_grade, ac.pass_rate
FROM iceberg.lakehouse.agg_course_analytics ac
JOIN iceberg.lakehouse.dim_courses dc ON ac.course_key = dc.course_key
WHERE ac.academic_year = '2024/2025'
ORDER BY ac.pass_rate DESC;
```

### 3. Financial Analysis

```sql
-- Revenue by faculty
SELECT 
    faculty, total_revenue, collection_rate,
    revenue_collected, revenue_outstanding
FROM iceberg.lakehouse.agg_financial_summary
WHERE academic_year = '2024/2025'
ORDER BY total_revenue DESC;
```

## 🔄 ETL Pipeline

### Manual ETL

```bash
# Akses Trino CLI
docker exec -it trino trino

# Jalankan ETL pipeline
\i /opt/scripts/etl_pipeline.sql
```

### Automated ETL dengan Airflow

```python
# Contoh DAG untuk automated ETL
from airflow import DAG
from airflow.providers.trino.operators.trino import TrinoOperator

dag = DAG('lakehouse_etl', schedule_interval='@daily')

etl_task = TrinoOperator(
    task_id='run_etl',
    sql='/opt/scripts/etl_pipeline.sql',
    trino_conn_id='trino_default',
    dag=dag
)
```

## 📊 Monitoring dan Observability

### Trino Web UI
- Query execution monitoring
- Resource utilization
- Performance metrics

### MinIO Console  
- Storage usage monitoring
- Object lifecycle management
- Access pattern analysis

### Iceberg Table Metadata
```sql
-- Check table statistics
SELECT * FROM iceberg.lakehouse."fact_enrollments$files";

-- View table history
SELECT * FROM iceberg.lakehouse."fact_enrollments$history";

-- Snapshots information
SELECT * FROM iceberg.lakehouse."fact_enrollments$snapshots";
```

## 🛠️ Troubleshooting

### Common Issues

1. **Container Memory Issues**
   ```bash
   # Increase Docker memory allocation
   docker-compose down
   # Edit docker-compose.yml memory limits
   docker-compose up -d
   ```

2. **Trino Connection Issues**
   ```bash
   # Check Trino logs
   docker logs trino
   
   # Verify catalog configuration
   docker exec -it trino cat /etc/trino/catalog/iceberg.properties
   ```

3. **MinIO Access Issues**
   ```bash
   # Check MinIO status
   docker logs minio
   
   # Verify bucket creation
   docker exec -it mc mc ls minio/
   ```

### Performance Tuning

1. **Iceberg Table Optimization**
   ```sql
   -- Compact small files
   ALTER TABLE iceberg.lakehouse.fact_enrollments 
   EXECUTE optimize(file_size_threshold => '100MB');
   
   -- Update table statistics
   ANALYZE TABLE iceberg.lakehouse.fact_enrollments;
   ```

2. **Trino Query Optimization**
   ```sql
   -- Use appropriate filters for partition pruning
   SELECT * FROM iceberg.lakehouse.fact_enrollments
   WHERE academic_year = '2024/2025' 
     AND semester = 'GANJIL';
   ```

## 🔒 Security Best Practices

### Access Control
- Implement RBAC untuk Trino users
- Configure MinIO IAM policies
- Use encrypted connections

### Data Protection
- Enable MinIO encryption at rest
- Configure SSL/TLS untuk semua connections
- Implement data masking untuk sensitive fields

## 📚 Resources

### Documentation
- [Apache Iceberg Documentation](https://iceberg.apache.org/)
- [Trino Documentation](https://trino.io/docs/)
- [MinIO Documentation](https://docs.min.io/)

### Useful Commands

```bash
# Trino CLI shortcuts
\q                    # Quit
\h                    # Help
\l                    # List catalogs
\d iceberg           # Describe catalog
\dt iceberg.lakehouse # List tables

# MinIO CLI commands
mc ls minio/warehouse        # List objects
mc cp file.parquet minio/warehouse/  # Upload file
mc stat minio/warehouse/file.parquet # Object info
```

## 🤝 Contributing

1. Fork repository
2. Create feature branch
3. Make changes
4. Test thoroughly
5. Submit pull request

## 📄 License

MIT License - see LICENSE file for details.

---

**Tim Pengembang**: Data Engineering Team  
**Last Updated**: {{current_date}}  
**Version**: 1.0.0 