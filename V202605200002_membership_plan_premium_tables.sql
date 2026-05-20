CREATE TABLE membership_plan_premium_rule (
    id VARCHAR(255) NOT NULL PRIMARY KEY,

    plan_id VARCHAR(255) NOT NULL,

    dependent_type VARCHAR(50) NOT NULL,
    -- SPOUSE, CHILD, PARENT, EXTENDED_FAMILY, MAIN_MEMBER, OTHER

    min_age INT NOT NULL,
    max_age INT NOT NULL,

    additional_premium_cents BIGINT NOT NULL,

    active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255),

    updated_at DATETIME NULL,
    updated_by VARCHAR(255),

    CONSTRAINT fk_membership_plan_premium_rule_plan
        FOREIGN KEY (plan_id)
        REFERENCES membership_plan(id),

    CONSTRAINT uk_plan_dependent_age_range
        UNIQUE (plan_id, dependent_type, min_age, max_age),

    INDEX idx_mppr_plan_id (plan_id),
    INDEX idx_mppr_dependent_type (dependent_type),
    INDEX idx_mppr_age_range (min_age, max_age),
    INDEX idx_mppr_active (active)

) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;     

ALTER TABLE membership 
    ADD COLUMN premium_cents BIGINT NULL AFTER plan_id;
