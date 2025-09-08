-- =================================================================
-- START PAYMENT STREAMING JOB
-- This script starts the streaming job ONLY for payment table
-- =================================================================

USE CATALOG iceberg_catalog;
USE university;

-- Start Payment Streaming Job
INSERT INTO iceberg_payment
SELECT 
  payment_id,
  student_id,
  registration_id,
  payment_type,
  payment_amount,
  bank_name,
  virtual_account_number,
  payment_channel,
  payment_time,
  payment_status,
  installment_number,
  late_fee_charged,
  total_paid_amount,
  payment_proof_url,
  due_date,
  created_at,
  updated_at,
  CURRENT_TIMESTAMP as ingestion_time
FROM kafka_payment
WHERE op IN ('r', 'c', 'u'); 