-- =================================================================
-- ICEBERG CATALOG SETUP ONLY
-- Sets up connection to Polaris catalog without creating any jobs
-- =================================================================

-- Create Iceberg catalog in Flink with Polaris
CREATE CATALOG IF NOT EXISTS iceberg_catalog WITH (
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

-- Use the Iceberg catalog
USE CATALOG iceberg_catalog;

-- Create namespace/database
CREATE DATABASE IF NOT EXISTS university;

-- Show available databases to verify connection
SHOW DATABASES;

-- Use university database
USE university;

-- List tables (will be empty initially)
SHOW TABLES; 