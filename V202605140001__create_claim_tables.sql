CREATE TABLE IF NOT EXISTS membership_claim (
    id                          VARCHAR(255) NOT NULL PRIMARY KEY,

    claim_no                    VARCHAR(50) NOT NULL,

    membership_id               VARCHAR(255) NOT NULL,

    claim_type                  VARCHAR(40) NOT NULL,
    -- CASH, TOMBSTONE, FUNERAL, COMBINATION

    deceased_type               VARCHAR(30) NOT NULL,
    -- MAIN_MEMBER, DEPENDENT

    deceased_partner_id         VARCHAR(255) NOT NULL,

    date_of_death               DATE NOT NULL,
    claim_date                  DATE NOT NULL,

    cause_of_death              VARCHAR(255) NULL,
    death_certificate_no        VARCHAR(100) NULL,

    claimant_partner_id         VARCHAR(255) NULL,

    claim_amount_cents          BIGINT NOT NULL DEFAULT 0,

    status                      VARCHAR(30) NOT NULL DEFAULT 'DRAFT',
    -- DRAFT, SUBMITTED, CANCELLED, APPROVED, REJECTED, PAID
    -- APPROVED, REJECTED, PAID are expected to be updated by approval/payment modules

    rejection_reason            TEXT NULL,
    notes                       TEXT NULL,

    created_at                  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                  VARCHAR(36) NULL,
    updated_at                  DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    updated_by                  VARCHAR(36) NULL,

    CONSTRAINT uq_membership_claim_no UNIQUE (claim_no),

    INDEX idx_membership_claim_membership (membership_id),
    INDEX idx_membership_claim_type (claim_type),
    INDEX idx_membership_claim_status (status),
    INDEX idx_membership_claim_deceased_partner (deceased_partner_id),
    INDEX idx_membership_claim_claimant_partner (claimant_partner_id),
    INDEX idx_membership_claim_death_certificate (death_certificate_no),
    INDEX idx_membership_claim_claim_date (claim_date),

    CONSTRAINT fk_membership_claim_membership
        FOREIGN KEY (membership_id)
        REFERENCES membership(id)

    -- Enable only if partner.id is compatible with these columns.
    CONSTRAINT fk_membership_claim_deceased_partner
        FOREIGN KEY (deceased_partner_id)
        REFERENCES partner(id),

    CONSTRAINT fk_membership_claim_claimant_partner
        FOREIGN KEY (claimant_partner_id)
        REFERENCES partner(id)
);

CREATE TABLE IF NOT EXISTS membership_claim_link (
    id                  VARCHAR(255) NOT NULL PRIMARY KEY,

    parent_claim_id     VARCHAR(255) NOT NULL,
    -- Main COMBINATION claim

    linked_claim_id     VARCHAR(255) NOT NULL,
    -- Other COMBINATION claim attached to the main COMBINATION claim

    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(36) NULL,

    CONSTRAINT uq_membership_claim_link UNIQUE (parent_claim_id, linked_claim_id),

    INDEX idx_claim_link_parent (parent_claim_id),
    INDEX idx_claim_link_linked (linked_claim_id),

    CONSTRAINT fk_claim_link_parent
        FOREIGN KEY (parent_claim_id)
        REFERENCES membership_claim(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_claim_link_linked
        FOREIGN KEY (linked_claim_id)
        REFERENCES membership_claim(id)
)
ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;

INSERT INTO number_sequence (seq_type, next_no)
VALUES ('MEMBERSHIP_CLAIM', 1000000001)
ON DUPLICATE KEY UPDATE next_no = next_no;