-- Funeral service request numbering, death details and approved claim amount hardening.

SET @funeral_service_no_col_exists := (
    SELECT COUNT(*)
      FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = 'funeral_service'
       AND COLUMN_NAME = 'service_request_no'
);
SET @funeral_service_no_sql := IF(
    @funeral_service_no_col_exists = 0,
    'ALTER TABLE funeral_service ADD COLUMN service_request_no VARCHAR(50) NULL AFTER id',
    'SELECT 1'
);
PREPARE funeral_service_no_stmt FROM @funeral_service_no_sql;
EXECUTE funeral_service_no_stmt;
DEALLOCATE PREPARE funeral_service_no_stmt;

SET @funeral_service_cert_col_exists := (
    SELECT COUNT(*)
      FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = 'funeral_service'
       AND COLUMN_NAME = 'death_certificate_no'
);
SET @funeral_service_cert_sql := IF(
    @funeral_service_cert_col_exists = 0,
    'ALTER TABLE funeral_service ADD COLUMN death_certificate_no VARCHAR(100) NULL AFTER funeral_area',
    'SELECT 1'
);
PREPARE funeral_service_cert_stmt FROM @funeral_service_cert_sql;
EXECUTE funeral_service_cert_stmt;
DEALLOCATE PREPARE funeral_service_cert_stmt;

SET @funeral_service_cause_col_exists := (
    SELECT COUNT(*)
      FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = 'funeral_service'
       AND COLUMN_NAME = 'cause_of_death'
);
SET @funeral_service_cause_sql := IF(
    @funeral_service_cause_col_exists = 0,
    'ALTER TABLE funeral_service ADD COLUMN cause_of_death VARCHAR(255) NULL AFTER death_certificate_no',
    'SELECT 1'
);
PREPARE funeral_service_cause_stmt FROM @funeral_service_cause_sql;
EXECUTE funeral_service_cause_stmt;
DEALLOCATE PREPARE funeral_service_cause_stmt;

SET @membership_claim_approved_col_exists := (
    SELECT COUNT(*)
      FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = 'membership_claim'
       AND COLUMN_NAME = 'approved_amount_cents'
);
SET @membership_claim_approved_sql := IF(
    @membership_claim_approved_col_exists = 0,
    'ALTER TABLE membership_claim ADD COLUMN approved_amount_cents BIGINT NULL AFTER claim_amount_cents',
    'SELECT 1'
);
PREPARE membership_claim_approved_stmt FROM @membership_claim_approved_sql;
EXECUTE membership_claim_approved_stmt;
DEALLOCATE PREPARE membership_claim_approved_stmt;

-- Populate approved amount for existing approved funeral/membership claims where it was left empty.
UPDATE membership_claim
   SET approved_amount_cents = claim_amount_cents
 WHERE status IN ('APPROVED', 'PARTIALLY_APPROVED', 'PAID')
   AND (approved_amount_cents IS NULL OR approved_amount_cents = 0)
   AND claim_amount_cents > 0;

-- Backfill request numbers for existing funeral service requests.
SET @row_no := 0;
UPDATE funeral_service fs
   SET fs.service_request_no = CONCAT('FSR-', LPAD((@row_no := @row_no + 1), 10, '0'))
 WHERE fs.service_request_no IS NULL OR TRIM(fs.service_request_no) = '';

SET @funeral_service_no_idx_exists := (
    SELECT COUNT(*)
      FROM INFORMATION_SCHEMA.STATISTICS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = 'funeral_service'
       AND INDEX_NAME = 'uk_funeral_service_request_no'
);
SET @funeral_service_no_idx_sql := IF(
    @funeral_service_no_idx_exists = 0,
    'ALTER TABLE funeral_service ADD UNIQUE KEY uk_funeral_service_request_no (service_request_no)',
    'SELECT 1'
);
PREPARE funeral_service_no_idx_stmt FROM @funeral_service_no_idx_sql;
EXECUTE funeral_service_no_idx_stmt;
DEALLOCATE PREPARE funeral_service_no_idx_stmt;

INSERT INTO number_sequence (seq_type, next_no)
VALUES
    ('FUNERAL_SERVICE_REQUEST', 1000000001),
    ('SERVICE-REQUEST', 1000000001),
    ('CLAIM', 1000000001),
    ('MEMBERSHIP_CLAIM', 1000000001)
ON DUPLICATE KEY UPDATE next_no = next_no;
