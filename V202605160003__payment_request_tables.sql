DROP TABLE IF EXISTS payment_request_status_history;
DROP TABLE IF EXISTS payment_request;

CREATE TABLE payment_request (
    id                      VARCHAR(255) NOT NULL PRIMARY KEY,

    request_no              VARCHAR(50) NOT NULL,

    request_type            VARCHAR(50) NOT NULL,
    -- SUPPLIER_INVOICE, CUSTOMER_REFUND, CLAIM_PAYOUT, GROUP_PAYOUT, GENERAL_PAYOUT

    source_type             VARCHAR(50) NULL,
    -- SUPPLIER_INVOICE, CUSTOMER_REFUND, MEMBERSHIP_CLAIM, GROUP_SOCIETY, MANUAL

    source_id               VARCHAR(255) NULL,

    payee_partner_id        VARCHAR(255) NULL,
    payee_name              VARCHAR(255) NOT NULL,

    amount                  DECIMAL(18,2) NOT NULL,
    currency                VARCHAR(10) NOT NULL DEFAULT 'ZAR',

    payment_method          VARCHAR(50) NOT NULL,
    -- CASH, EFT, CARD, INTERNAL_TRANSFER

    bank_name               VARCHAR(100) NULL,
    account_holder          VARCHAR(255) NULL,
    account_number          VARCHAR(100) NULL,
    branch_code             VARCHAR(50) NULL,
    account_type            VARCHAR(50) NULL,

    invoice_no              VARCHAR(100) NULL,
    external_reference      VARCHAR(100) NULL,

    payment_reason          VARCHAR(500) NULL,
    notes                   TEXT NULL,

    requested_payment_date  DATE NULL,

    status                  VARCHAR(50) NOT NULL DEFAULT 'DRAFT',
    -- DRAFT, PENDING_APPROVAL, APPROVED, REJECTED, CANCELLED, PAID

    approval_request_id     VARCHAR(255) NULL,

    paid_date               DATE NULL,
    paid_reference          VARCHAR(100) NULL,
    paid_by                 VARCHAR(255) NULL,

    created_at              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by              VARCHAR(255) NULL,

    updated_at              DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
    updated_by              VARCHAR(255) NULL,

    UNIQUE KEY uk_payment_request_no (request_no),

    INDEX idx_payment_request_status (status),
    INDEX idx_payment_request_type (request_type),
    INDEX idx_payment_request_payee_partner (payee_partner_id),
    INDEX idx_payment_request_source (source_type, source_id)

) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;


CREATE TABLE payment_request_status_history (
    id                  VARCHAR(255) NOT NULL PRIMARY KEY,

    payment_request_id  VARCHAR(255) NOT NULL,

    old_status          VARCHAR(50) NULL,
    new_status          VARCHAR(50) NOT NULL,

    comment             VARCHAR(500) NULL,

    changed_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by          VARCHAR(255) NULL,

    CONSTRAINT fk_payment_request_status_history_request
        FOREIGN KEY (payment_request_id)
        REFERENCES payment_request(id)
        ON DELETE CASCADE,

    INDEX idx_payment_request_history_request (payment_request_id)

) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;

INSERT INTO number_sequence (seq_type, next_no)
VALUES ('PAYMENT_REQUEST', 1000000001)
ON DUPLICATE KEY UPDATE next_no = next_no;
