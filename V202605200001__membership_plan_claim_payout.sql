CREATE TABLE membership_plan_claim_payout (
    id VARCHAR(255) NOT NULL PRIMARY KEY,

    plan_id VARCHAR(255) NOT NULL,

    claim_type VARCHAR(50) NOT NULL,

    dependent_type VARCHAR(50) NOT NULL DEFAULT 'ANY',

    payout_amount_cents BIGINT NOT NULL,

    active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    created_by VARCHAR(255),

    updated_at DATETIME NULL,

    updated_by VARCHAR(255),

    CONSTRAINT fk_membership_plan_claim_payout_plan
        FOREIGN KEY (plan_id)
        REFERENCES membership_plan(id),

    CONSTRAINT uk_plan_claim_dependent_type
        UNIQUE (plan_id, claim_type, dependent_type),

    INDEX idx_mpcp_plan_id (plan_id),
    INDEX idx_mpcp_claim_type (claim_type),
    INDEX idx_mpcp_dependent_type (dependent_type),
    INDEX idx_mpcp_active (active)

) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;
