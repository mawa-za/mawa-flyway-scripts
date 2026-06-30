CREATE TABLE IF NOT EXISTS cashup_deposit (
    id VARCHAR(255) NOT NULL,
    cashup_id VARCHAR(255) NOT NULL,
    deposit_date DATE NOT NULL,
    amount_cents BIGINT NOT NULL DEFAULT 0,
    payment_method VARCHAR(80) NULL,
    bank_name VARCHAR(120) NULL,
    reference_no VARCHAR(120) NULL,
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by VARCHAR(255) NULL,
    PRIMARY KEY (id),
    KEY idx_cashup_deposit_cashup_id (cashup_id),
    CONSTRAINT fk_cashup_deposit_cashup FOREIGN KEY (cashup_id) REFERENCES cashup(id)
)ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3
COLLATE = utf8mb3_general_ci;

ALTER TABLE cashup
    ADD COLUMN IF NOT EXISTS deposit_total_cents BIGINT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS deposit_count INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS approval_request_id VARCHAR(255) NULL;
