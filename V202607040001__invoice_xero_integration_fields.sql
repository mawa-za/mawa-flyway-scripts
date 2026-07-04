-- Adds Xero integration tracking fields to the new invoice table.
-- Defensive checks keep the migration safe where columns were manually introduced.

SET @schema_name = DATABASE();

SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE invoice ADD COLUMN xero_invoice_id VARCHAR(100) NULL AFTER notes',
        'SELECT 1'
    )
    FROM information_schema.columns
    WHERE table_schema = @schema_name
      AND table_name = 'invoice'
      AND column_name = 'xero_invoice_id'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE invoice ADD COLUMN xero_invoice_no VARCHAR(100) NULL AFTER xero_invoice_id',
        'SELECT 1'
    )
    FROM information_schema.columns
    WHERE table_schema = @schema_name
      AND table_name = 'invoice'
      AND column_name = 'xero_invoice_no'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE invoice ADD COLUMN integration_status VARCHAR(30) NULL AFTER xero_invoice_no',
        'SELECT 1'
    )
    FROM information_schema.columns
    WHERE table_schema = @schema_name
      AND table_name = 'invoice'
      AND column_name = 'integration_status'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE invoice ADD COLUMN integration_error TEXT NULL AFTER integration_status',
        'SELECT 1'
    )
    FROM information_schema.columns
    WHERE table_schema = @schema_name
      AND table_name = 'invoice'
      AND column_name = 'integration_error'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE invoice ADD COLUMN integration_last_attempt_at DATETIME NULL AFTER integration_error',
        'SELECT 1'
    )
    FROM information_schema.columns
    WHERE table_schema = @schema_name
      AND table_name = 'invoice'
      AND column_name = 'integration_last_attempt_at'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE invoice ADD COLUMN integration_posted_at DATETIME NULL AFTER integration_last_attempt_at',
        'SELECT 1'
    )
    FROM information_schema.columns
    WHERE table_schema = @schema_name
      AND table_name = 'invoice'
      AND column_name = 'integration_posted_at'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'CREATE INDEX idx_invoice_integration_status ON invoice (integration_status)',
        'SELECT 1'
    )
    FROM information_schema.statistics
    WHERE table_schema = @schema_name
      AND table_name = 'invoice'
      AND index_name = 'idx_invoice_integration_status'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = (
    SELECT IF(
        COUNT(*) = 0,
        'CREATE INDEX idx_invoice_xero_invoice_id ON invoice (xero_invoice_id)',
        'SELECT 1'
    )
    FROM information_schema.statistics
    WHERE table_schema = @schema_name
      AND table_name = 'invoice'
      AND index_name = 'idx_invoice_xero_invoice_id'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
