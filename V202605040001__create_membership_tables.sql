CREATE TABLE IF NOT EXISTS membership_plan (
    id                  VARCHAR(255) NOT NULL PRIMARY KEY,
    plan_code           VARCHAR(50) NOT NULL,
    name                VARCHAR(150) NOT NULL,
    description         TEXT,

    premium_cents       BIGINT NOT NULL DEFAULT 0,
    currency            VARCHAR(10) NOT NULL DEFAULT 'ZAR',

    max_dependents      INT DEFAULT NULL,
    active              BOOLEAN NOT NULL DEFAULT TRUE,

    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(36),
    updated_at          DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    updated_by          VARCHAR(36),

    UNIQUE KEY uq_membership_plan_code (plan_code),
    INDEX idx_membership_plan_active (active)
);

CREATE TABLE IF NOT EXISTS membership (
    id                  VARCHAR(255) NOT NULL PRIMARY KEY,

    -- Partner/person who owns the membership
    member_id           VARCHAR(255) NOT NULL,

    membership_no       VARCHAR(50) NOT NULL,
    plan_id             VARCHAR(255) NOT NULL,

    start_date          DATE NOT NULL,
    end_date            DATE NULL,

    status              VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    -- ACTIVE, SUSPENDED, CANCELLED, LAPSED, DECEASED

    paid_up_to_period   VARCHAR(6) NULL,
    -- Format: YYYYMM, e.g. 202605

    join_date           DATE NULL,

    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(36),
    updated_at          DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    updated_by          VARCHAR(36),

    UNIQUE KEY uq_membership_no (membership_no),

    INDEX idx_membership_member (member_id),
    INDEX idx_membership_plan (plan_id),
    INDEX idx_membership_status (status),
    INDEX idx_membership_paid_up_to (paid_up_to_period),

    CONSTRAINT fk_membership_member
        FOREIGN KEY (member_id) REFERENCES partner(id),

    CONSTRAINT fk_membership_plan
        FOREIGN KEY (plan_id) REFERENCES membership_plan(id)
);

CREATE TABLE IF NOT EXISTS membership_dependent (
    id                  VARCHAR(255) NOT NULL PRIMARY KEY,

    membership_id       VARCHAR(255) NOT NULL,
    dependent_partner_id VARCHAR(255) NOT NULL,

    relationship        VARCHAR(50) NOT NULL,
    -- SPOUSE, CHILD, PARENT, EXTENDED_FAMILY, etc.

    active              BOOLEAN NOT NULL DEFAULT TRUE,

    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(36),
    updated_at          DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    updated_by          VARCHAR(36),

    UNIQUE KEY uq_membership_dependent (
        membership_id,
        dependent_partner_id
    ),

    INDEX idx_dependent_membership (membership_id),
    INDEX idx_dependent_partner (dependent_partner_id),

    CONSTRAINT fk_dependent_membership
        FOREIGN KEY (membership_id) REFERENCES membership(id),

    CONSTRAINT fk_dependent_partner
        FOREIGN KEY (dependent_partner_id) REFERENCES partner(id)
);