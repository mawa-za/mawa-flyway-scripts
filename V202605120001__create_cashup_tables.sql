CREATE TABLE IF NOT EXISTS cashup (
    id                  VARCHAR(255) NOT NULL PRIMARY KEY,

    cashup_no            BIGINT NOT NULL,
    device_id            VARCHAR(128) NOT NULL,
    user_id              VARCHAR(255) NOT NULL,

    cashup_date          DATE NOT NULL,

    total_cents          BIGINT NOT NULL DEFAULT 0,
    receipt_count        INT NOT NULL DEFAULT 0,

    status               VARCHAR(30) NOT NULL DEFAULT 'SUBMITTED',
    -- DRAFT, SUBMITTED, APPROVED, REJECTED, CANCELLED

    notes                TEXT NULL,

    synced_at            DATETIME NULL,

    created_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by           VARCHAR(255) NULL,
    updated_at           DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    updated_by           VARCHAR(255) NULL,

    UNIQUE KEY uq_cashup_no (cashup_no),
    INDEX idx_cashup_device (device_id),
    INDEX idx_cashup_user (user_id),
    INDEX idx_cashup_date (cashup_date),
    INDEX idx_cashup_status (status)
)ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;

CREATE TABLE IF NOT EXISTS cashup_payment_summary (
    id                  VARCHAR(255) NOT NULL PRIMARY KEY,

    cashup_id            VARCHAR(255) NOT NULL,
    payment_method       VARCHAR(50) NOT NULL,
    -- CASH, CARD, EFT, DEBIT_ORDER, OTHER

    amount_cents         BIGINT NOT NULL DEFAULT 0,
    payment_count        INT NOT NULL DEFAULT 0,

    created_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_cashup_payment_summary_cashup
        FOREIGN KEY (cashup_id) REFERENCES cashup(id)
        ON DELETE CASCADE,

    UNIQUE KEY uq_cashup_payment_method (cashup_id, payment_method),
    INDEX idx_cashup_payment_cashup (cashup_id)
)ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;

CREATE TABLE IF NOT EXISTS cashup_receipt (
    id                  VARCHAR(255) NOT NULL PRIMARY KEY,

    cashup_id            VARCHAR(255) NOT NULL,
    receipt_id           VARCHAR(255) NULL,
    receipt_no           BIGINT NULL,

    amount_cents         BIGINT NOT NULL DEFAULT 0,
    payment_method       VARCHAR(50) NULL,

    created_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_cashup_receipt_cashup
        FOREIGN KEY (cashup_id) REFERENCES cashup(id)
        ON DELETE CASCADE,

    INDEX idx_cashup_receipt_cashup (cashup_id),
    INDEX idx_cashup_receipt_receipt_id (receipt_id),
    INDEX idx_cashup_receipt_no (receipt_no)
)ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;


  SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS number_range_allocation;
DROP TABLE IF EXISTS number_sequence;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE number_sequence (
    id          BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    seq_type    VARCHAR(64) NOT NULL,
    next_no     BIGINT NOT NULL,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uq_number_sequence_type (seq_type)
)ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;

CREATE TABLE number_range_allocation (
    id             BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,

    seq_type        VARCHAR(64) NOT NULL,
    device_id       VARCHAR(128) NOT NULL,

    from_no         BIGINT NOT NULL,
    to_no           BIGINT NOT NULL,
    next_local_no   BIGINT NOT NULL,

    allocation_size INT NOT NULL,

    status          VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',

    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by      VARCHAR(36),

    updated_at      DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    updated_by      VARCHAR(36),

    CONSTRAINT fk_number_range_sequence_type
        FOREIGN KEY (seq_type)
        REFERENCES number_sequence (seq_type),

    INDEX idx_number_range_device_type (device_id, seq_type),
    INDEX idx_number_range_type_status (seq_type, status),
    INDEX idx_number_range_status (status)
)
ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;

INSERT INTO number_sequence (seq_type, next_no)
VALUES 
    ('RECEIPT', 1),
    ('CASHUP', 1000000001),
    ('MEMBERSHIP', 1000000001),
    ('PARTNER', 1000000001)
ON DUPLICATE KEY UPDATE next_no = next_no;