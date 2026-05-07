CREATE TABLE IF NOT EXISTS payroll_payment_batch (
    id                      VARCHAR(255) NOT NULL PRIMARY KEY,

    batch_no                VARCHAR(50) NOT NULL,
    description             VARCHAR(255),

    pay_period              VARCHAR(6) NOT NULL,
    -- Format: YYYYMM e.g. 202605

    payment_date            DATE NOT NULL,

    source_batch_id         VARCHAR(255) NULL,
    -- If this batch was copied from another batch

    status                  VARCHAR(30) NOT NULL DEFAULT 'DRAFT',
    -- DRAFT, APPROVED, PROCESSING, SUBMITTED, PAID, FAILED, CANCELLED

    total_employees         INT NOT NULL DEFAULT 0,
    total_amount_cents      BIGINT NOT NULL DEFAULT 0,

    eft_file_generated      BOOLEAN NOT NULL DEFAULT FALSE,
    eft_file_name           VARCHAR(255) NULL,
    eft_file_generated_at   DATETIME NULL,

    notes                   TEXT NULL,

    created_at              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by              VARCHAR(36),

    updated_at              DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    updated_by              VARCHAR(36),

    UNIQUE KEY uq_payroll_payment_batch_no (batch_no),
    INDEX idx_payroll_payment_batch_period (pay_period),
    INDEX idx_payroll_payment_batch_status (status),
    INDEX idx_payroll_payment_batch_payment_date (payment_date),
    INDEX idx_payroll_payment_batch_source (source_batch_id),

    CONSTRAINT fk_payroll_payment_batch_source
        FOREIGN KEY (source_batch_id)
        REFERENCES payroll_payment_batch(id)
        ON DELETE SET NULL
)ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;

CREATE TABLE IF NOT EXISTS payroll_payment_item (
    id                      VARCHAR(255) NOT NULL PRIMARY KEY,

    batch_id                VARCHAR(255) NOT NULL,

    employee_id             VARCHAR(255) NULL,
    -- Can reference partner.id or employee.id depending on your design

    employee_no             VARCHAR(50) NULL,
    employee_name           VARCHAR(255) NOT NULL,

    bank_name               VARCHAR(100) NULL,
    branch_code             VARCHAR(20) NULL,
    account_no              VARCHAR(50) NOT NULL,
    account_type            VARCHAR(30) NULL,
    -- CURRENT, SAVINGS, TRANSMISSION, etc.

    account_holder_name     VARCHAR(255) NULL,

    amount_cents            BIGINT NOT NULL DEFAULT 0,

    payment_reference       VARCHAR(100) NULL,
    salary_reference        VARCHAR(100) NULL,

    status                  VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    -- PENDING, VALIDATED, EXCLUDED, SUBMITTED, PAID, FAILED

    excluded                BOOLEAN NOT NULL DEFAULT FALSE,
    exclusion_reason        VARCHAR(255) NULL,

    failure_reason          TEXT NULL,

    created_at              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by              VARCHAR(36),

    updated_at              DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    updated_by              VARCHAR(36),

    INDEX idx_payroll_payment_item_batch (batch_id),
    INDEX idx_payroll_payment_item_employee (employee_id),
    INDEX idx_payroll_payment_item_status (status),
    INDEX idx_payroll_payment_item_excluded (excluded),

    CONSTRAINT fk_payroll_payment_item_batch
        FOREIGN KEY (batch_id)
        REFERENCES payroll_payment_batch(id)
        ON DELETE CASCADE
)ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;

CREATE TABLE IF NOT EXISTS payroll_payment_batch_audit (
    id                      VARCHAR(255) NOT NULL PRIMARY KEY,

    batch_id                VARCHAR(255) NOT NULL,

    action                  VARCHAR(50) NOT NULL,
    -- CREATED, COPIED, ITEM_ADDED, ITEM_REMOVED, APPROVED, SUBMITTED, CANCELLED, etc.

    old_status              VARCHAR(30) NULL,
    new_status              VARCHAR(30) NULL,

    message                 TEXT NULL,

    created_at              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by              VARCHAR(36),

    INDEX idx_payroll_payment_batch_audit_batch (batch_id),
    INDEX idx_payroll_payment_batch_audit_action (action),

    CONSTRAINT fk_payroll_payment_batch_audit_batch
        FOREIGN KEY (batch_id)
        REFERENCES payroll_payment_batch(id)
        ON DELETE CASCADE
)ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;

ALTER TABLE payroll_payment_item
ADD CONSTRAINT fk_payroll_payment_item_employee_partner
FOREIGN KEY (employee_id)
REFERENCES partner(id);