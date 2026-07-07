-- Appointment invoicing traceability and company logo support for PDF printouts.

SET @invoice_source_type_exists := (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'invoice' AND COLUMN_NAME = 'source_type'
);
SET @invoice_source_type_sql := IF(
    @invoice_source_type_exists = 0,
    'ALTER TABLE invoice ADD COLUMN source_type VARCHAR(50) NULL AFTER external_ref',
    'SELECT 1'
);
PREPARE invoice_source_type_stmt FROM @invoice_source_type_sql;
EXECUTE invoice_source_type_stmt;
DEALLOCATE PREPARE invoice_source_type_stmt;

SET @invoice_source_id_exists := (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'invoice' AND COLUMN_NAME = 'source_id'
);
SET @invoice_source_id_sql := IF(
    @invoice_source_id_exists = 0,
    'ALTER TABLE invoice ADD COLUMN source_id CHAR(36) NULL AFTER source_type',
    'SELECT 1'
);
PREPARE invoice_source_id_stmt FROM @invoice_source_id_sql;
EXECUTE invoice_source_id_stmt;
DEALLOCATE PREPARE invoice_source_id_stmt;

SET @idx_invoice_source_exists := (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'invoice' AND INDEX_NAME = 'idx_invoice_source'
);
SET @idx_invoice_source_sql := IF(
    @idx_invoice_source_exists = 0,
    'CREATE INDEX idx_invoice_source ON invoice(source_type, source_id)',
    'SELECT 1'
);
PREPARE idx_invoice_source_stmt FROM @idx_invoice_source_sql;
EXECUTE idx_invoice_source_stmt;
DEALLOCATE PREPARE idx_invoice_source_stmt;

CREATE TABLE IF NOT EXISTS company_logo (
    id              CHAR(36) NOT NULL PRIMARY KEY,
    file_name       VARCHAR(255) NOT NULL,
    content_type    VARCHAR(100) NOT NULL,
    width_px        INT NOT NULL,
    height_px       INT NOT NULL,
    size_bytes      BIGINT NOT NULL,
    content         LONGBLOB NOT NULL,
    uploaded_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    uploaded_by     CHAR(36),
    INDEX idx_company_logo_uploaded_at (uploaded_at)
);
