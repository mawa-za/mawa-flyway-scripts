DROP TABLE IF EXISTS group_society_account_txn;
DROP TABLE IF EXISTS group_society_member;
DROP TABLE IF EXISTS group_society_contact;
DROP TABLE IF EXISTS group_society;

CREATE TABLE group_society (
    id                          VARCHAR(255) NOT NULL PRIMARY KEY,

    partner_id                  VARCHAR(255) NOT NULL,
    -- Must be partner.id where partner.type = 'GROUP'

    group_no                    VARCHAR(50) NOT NULL,

    society_type                VARCHAR(50) NULL,
    -- EMPLOYER, CHURCH, STOKVEL, BURIAL_SOCIETY, SCHOOL, OTHER

    status                      VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    -- ACTIVE, SUSPENDED, CLOSED

    available_balance_cents     BIGINT NOT NULL DEFAULT 0,
    total_paid_cents            BIGINT NOT NULL DEFAULT 0,
    total_claimed_cents         BIGINT NOT NULL DEFAULT 0,

    last_payment_date           DATE NULL,
    last_claim_date             DATE NULL,

    created_at                  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                  VARCHAR(36) NULL,
    updated_at                  DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    updated_by                  VARCHAR(36) NULL,

    UNIQUE KEY uq_group_society_partner (partner_id),
    UNIQUE KEY uq_group_society_group_no (group_no),

    INDEX idx_group_society_status (status),
    INDEX idx_group_society_society_type (society_type)
    ,CONSTRAINT fk_group_society_partner
        FOREIGN KEY (partner_id) REFERENCES partner(id)
)ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;

CREATE TABLE group_society_contact (
    id                          VARCHAR(255) NOT NULL PRIMARY KEY,

    group_society_id             VARCHAR(255) NOT NULL,

    contact_name                VARCHAR(150) NOT NULL,
    role                        VARCHAR(100) NULL,
    mobile_no                   VARCHAR(50) NULL,
    email                       VARCHAR(150) NULL,

    primary_contact             BOOLEAN NOT NULL DEFAULT FALSE,

    created_at                  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                  VARCHAR(36) NULL,
    updated_at                  DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    updated_by                  VARCHAR(36) NULL,

    INDEX idx_group_society_contact_group (group_society_id),
    INDEX idx_group_society_contact_primary (primary_contact),

    CONSTRAINT fk_group_society_contact_group
        FOREIGN KEY (group_society_id) REFERENCES group_society(id)
)ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;

CREATE TABLE group_society_member (
    id                          VARCHAR(255) NOT NULL PRIMARY KEY,

    group_society_id             VARCHAR(255) NOT NULL,

    member_id                   VARCHAR(255) NOT NULL,
    -- Partner/person id

    membership_id               VARCHAR(255) NULL,
    -- Optional membership id

    employee_no                 VARCHAR(100) NULL,
    external_ref                VARCHAR(100) NULL,

    join_date                   DATE NULL,
    exit_date                   DATE NULL,

    status                      VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    -- ACTIVE, SUSPENDED, EXITED

    created_at                  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                  VARCHAR(36) NULL,
    updated_at                  DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    updated_by                  VARCHAR(36) NULL,

    UNIQUE KEY uq_group_society_member_unique (group_society_id, member_id),
    INDEX idx_group_society_member_group (group_society_id),
    INDEX idx_group_society_member_member (member_id),
    INDEX idx_group_society_member_membership (membership_id),
    INDEX idx_group_society_member_status (status),

    CONSTRAINT fk_group_society_member_group
        FOREIGN KEY (group_society_id) REFERENCES group_society(id)
)ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;

CREATE TABLE group_society_account_txn (
    id                          VARCHAR(255) NOT NULL PRIMARY KEY,

    group_society_id             VARCHAR(255) NOT NULL,

    txn_type                    VARCHAR(30) NOT NULL,
    -- PAYMENT, CLAIM, PAYMENT_REVERSAL, CLAIM_REVERSAL, ADJUSTMENT_CREDIT, ADJUSTMENT_DEBIT

    direction                   VARCHAR(10) NOT NULL,
    -- CREDIT, DEBIT

    amount_cents                BIGINT NOT NULL,

    balance_before_cents        BIGINT NOT NULL,
    balance_after_cents         BIGINT NOT NULL,

    txn_date                    DATE NOT NULL,
    txn_datetime                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    reference_type              VARCHAR(50) NULL,
    -- RECEIPT, CLAIM, CASHUP, MANUAL_ADJUSTMENT, OPENING_BALANCE

    reference_id                VARCHAR(255) NULL,
    reference_no                VARCHAR(100) NULL,

    payment_method              VARCHAR(50) NULL,
    -- CASH, EFT, CARD, DEBIT_ORDER, SPEEDPOINT, OTHER

    period                      VARCHAR(6) NULL,
    -- YYYYMM

    notes                       TEXT NULL,

    created_at                  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                  VARCHAR(36) NULL,

    INDEX idx_group_society_txn_group (group_society_id),
    INDEX idx_group_society_txn_type (txn_type),
    INDEX idx_group_society_txn_date (txn_date),
    INDEX idx_group_society_txn_reference (reference_type, reference_id),
    INDEX idx_group_society_txn_period (period),

    CONSTRAINT fk_group_society_account_txn_group
        FOREIGN KEY (group_society_id) REFERENCES group_society(id)
)
ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;

INSERT INTO number_sequence (seq_type, next_no)
VALUES ('GROUP_SOCIETY', 1000000001)
ON DUPLICATE KEY UPDATE next_no = next_no;