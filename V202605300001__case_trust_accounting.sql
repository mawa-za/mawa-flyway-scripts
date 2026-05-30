CREATE TABLE IF NOT EXISTS case_trust_ledger (
    id                          VARCHAR(255) NOT NULL PRIMARY KEY,

    case_id                     VARCHAR(255) NOT NULL,
    client_partner_id            VARCHAR(255) NOT NULL,

    currency                    VARCHAR(10) NOT NULL DEFAULT 'ZAR',

    total_received_cents         BIGINT NOT NULL DEFAULT 0,
    total_transferred_cents      BIGINT NOT NULL DEFAULT 0,
    total_refunded_cents         BIGINT NOT NULL DEFAULT 0,
    total_paid_out_cents         BIGINT NOT NULL DEFAULT 0,

    available_balance_cents      BIGINT NOT NULL DEFAULT 0,

    created_at                  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                  VARCHAR(255) NULL,
    updated_at                  DATETIME NULL,
    updated_by                  VARCHAR(255) NULL,

    UNIQUE KEY uk_case_trust_ledger_case (case_id),
    INDEX idx_case_trust_ledger_client (client_partner_id),

    CONSTRAINT fk_case_trust_ledger_case
        FOREIGN KEY (case_id) REFERENCES legal_case(id)
        ON DELETE CASCADE
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3
COLLATE = utf8mb3_general_ci;


CREATE TABLE IF NOT EXISTS case_trust_transaction (
    id                          VARCHAR(255) NOT NULL PRIMARY KEY,

    case_id                     VARCHAR(255) NOT NULL,
    client_partner_id            VARCHAR(255) NOT NULL,

    transaction_no               VARCHAR(80) NOT NULL UNIQUE,

    transaction_type             VARCHAR(80) NOT NULL,
    -- RECEIPT, TRANSFER_TO_BUSINESS, REFUND_TO_CLIENT, PAYMENT_TO_THIRD_PARTY, REVERSAL

    direction                    VARCHAR(20) NOT NULL,
    -- IN, OUT

    amount_cents                 BIGINT NOT NULL,
    balance_after_cents          BIGINT NOT NULL,

    payment_method               VARCHAR(50) NULL,
    -- CASH, EFT, CARD, BANK_TRANSFER, OTHER

    reference_no                 VARCHAR(150) NULL,
    bank_reference               VARCHAR(150) NULL,
    payee_name                   VARCHAR(255) NULL,

    description                  TEXT NULL,

    related_invoice_id           VARCHAR(255) NULL,
    related_receipt_id           VARCHAR(255) NULL,
    related_transaction_id       VARCHAR(255) NULL,

    transaction_date             DATETIME NOT NULL,

    reversed                     BOOLEAN NOT NULL DEFAULT FALSE,
    reversed_at                  DATETIME NULL,
    reversed_by                  VARCHAR(255) NULL,
    reversal_reason              TEXT NULL,

    created_at                  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                  VARCHAR(255) NULL,

    CONSTRAINT fk_case_trust_transaction_case
        FOREIGN KEY (case_id) REFERENCES legal_case(id)
        ON DELETE CASCADE,

    INDEX idx_case_trust_transaction_case (case_id),
    INDEX idx_case_trust_transaction_client (client_partner_id),
    INDEX idx_case_trust_transaction_no (transaction_no),
    INDEX idx_case_trust_transaction_type (transaction_type),
    INDEX idx_case_trust_transaction_date (transaction_date)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3
COLLATE = utf8mb3_general_ci;


ALTER TABLE case_disbursement
    ADD COLUMN paid_from_trust BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN trust_transaction_id VARCHAR(255) NULL;
