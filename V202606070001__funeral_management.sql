-- Add approved amount tracking to the existing membership_claim table.
-- Existing claim_amount_cents remains the originally claimed amount; approved_amount_cents stores the final benefit decision.
SET @membership_claim_approved_amount_col_exists := (
    SELECT COUNT(*)
      FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = 'membership_claim'
       AND COLUMN_NAME = 'approved_amount_cents'
);
SET @membership_claim_approved_amount_sql := IF(
    @membership_claim_approved_amount_col_exists = 0,
    'ALTER TABLE membership_claim ADD COLUMN approved_amount_cents BIGINT NULL AFTER claim_amount_cents',
    'SELECT 1'
);
PREPARE membership_claim_approved_amount_stmt FROM @membership_claim_approved_amount_sql;
EXECUTE membership_claim_approved_amount_stmt;
DEALLOCATE PREPARE membership_claim_approved_amount_stmt;

CREATE TABLE IF NOT EXISTS funeral_pickup_request (
    id VARCHAR(255) NOT NULL PRIMARY KEY,
    deceased_name VARCHAR(255) NOT NULL,
    pickup_location VARCHAR(1000) NOT NULL,
    contact_person VARCHAR(255),
    contact_number VARCHAR(50),
    assigned_staff_id VARCHAR(255),
    completion_time DATETIME,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    mortuary_inventory_id VARCHAR(255),
    created_at DATETIME NOT NULL,
    updated_at DATETIME,
    INDEX idx_funeral_pickup_status (status),
    INDEX idx_funeral_pickup_staff (assigned_staff_id)
) ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3
COLLATE = utf8mb3_general_ci;

CREATE TABLE IF NOT EXISTS funeral_mortuary_inventory (
    id VARCHAR(255) NOT NULL PRIMARY KEY,
    pickup_request_id VARCHAR(255),
    deceased_partner_id VARCHAR(255),
    deceased_name VARCHAR(255) NOT NULL,
    tag_number VARCHAR(100) NOT NULL UNIQUE,
    check_in_date DATETIME NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'IN_MORTUARY',
    release_to VARCHAR(255),
    identity_number VARCHAR(100),
    checkout_date DATETIME,
    created_at DATETIME NOT NULL,
    updated_at DATETIME,
    INDEX idx_funeral_mortuary_status (status),
    INDEX idx_funeral_mortuary_pickup (pickup_request_id),
    INDEX idx_funeral_mortuary_deceased_partner (deceased_partner_id),
    CONSTRAINT fk_funeral_mortuary_pickup FOREIGN KEY (pickup_request_id) REFERENCES funeral_pickup_request(id),
    CONSTRAINT fk_funeral_mortuary_deceased_partner FOREIGN KEY (deceased_partner_id) REFERENCES partner(id)
) ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3
COLLATE = utf8mb3_general_ci;

ALTER TABLE funeral_pickup_request
    ADD CONSTRAINT fk_funeral_pickup_mortuary
    FOREIGN KEY (mortuary_inventory_id) REFERENCES funeral_mortuary_inventory(id);

CREATE TABLE IF NOT EXISTS funeral_package (
    id VARCHAR(255) NOT NULL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    base_price_cents BIGINT NOT NULL DEFAULT 0,
    inclusions_json JSON,
    active TINYINT(1) NOT NULL DEFAULT 1,
    INDEX idx_funeral_package_active (active)
) ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3
COLLATE = utf8mb3_general_ci;

CREATE TABLE IF NOT EXISTS funeral_service (
    id VARCHAR(255) NOT NULL PRIMARY KEY,
    mortuary_inventory_id VARCHAR(255),
    deceased_partner_id VARCHAR(255),
    deceased_name VARCHAR(255) NOT NULL,
    deceased_identity_number VARCHAR(100),
    package_id VARCHAR(255) NOT NULL,
    family_rep_id VARCHAR(255) NOT NULL,
    funeral_date DATE,
    funeral_area VARCHAR(255),
    total_amount_cents BIGINT NOT NULL DEFAULT 0,
    extras_json JSON,
    status VARCHAR(50) NOT NULL DEFAULT 'ARRANGEMENT_CREATED',
    created_at DATETIME NOT NULL,
    updated_at DATETIME,
    INDEX idx_funeral_service_status (status),
    INDEX idx_funeral_service_mortuary (mortuary_inventory_id),
    INDEX idx_funeral_service_deceased_partner (deceased_partner_id),
    INDEX idx_funeral_service_family_rep (family_rep_id),
    CONSTRAINT fk_funeral_service_mortuary FOREIGN KEY (mortuary_inventory_id) REFERENCES funeral_mortuary_inventory(id),
    CONSTRAINT fk_funeral_service_package FOREIGN KEY (package_id) REFERENCES funeral_package(id),
    CONSTRAINT fk_funeral_service_deceased_partner FOREIGN KEY (deceased_partner_id) REFERENCES partner(id),
    CONSTRAINT fk_funeral_service_family_rep FOREIGN KEY (family_rep_id) REFERENCES partner(id)
) ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3
COLLATE = utf8mb3_general_ci;

CREATE TABLE IF NOT EXISTS funeral_service_claim (
    id VARCHAR(255) NOT NULL PRIMARY KEY,
    funeral_service_id VARCHAR(255) NOT NULL,
    membership_claim_id VARCHAR(255) NOT NULL,
    cover_source VARCHAR(50) NOT NULL DEFAULT 'LOCAL_TENANT',
    source_tenant_id VARCHAR(255),
    source_tenant_name VARCHAR(255),
    source_membership_id VARCHAR(255),
    source_reference VARCHAR(255),
    burial_society_partner_id VARCHAR(255),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_funeral_service_claim (funeral_service_id, membership_claim_id),
    INDEX idx_funeral_service_claim_service (funeral_service_id),
    INDEX idx_funeral_service_claim_claim (membership_claim_id),
    INDEX idx_funeral_service_claim_source (cover_source, source_tenant_id),
    CONSTRAINT fk_funeral_service_claim_service FOREIGN KEY (funeral_service_id) REFERENCES funeral_service(id),
    CONSTRAINT fk_funeral_service_claim_claim FOREIGN KEY (membership_claim_id) REFERENCES membership_claim(id),
    CONSTRAINT fk_funeral_service_claim_society_partner FOREIGN KEY (burial_society_partner_id) REFERENCES partner(id)
) ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3
COLLATE = utf8mb3_general_ci;

CREATE TABLE IF NOT EXISTS funeral_external_membership_cover (
    id VARCHAR(255) NOT NULL PRIMARY KEY,
    identity_number VARCHAR(100) NOT NULL,
    source_tenant_id VARCHAR(255) NOT NULL,
    source_tenant_name VARCHAR(255),
    source_membership_id VARCHAR(255) NOT NULL,
    source_membership_no VARCHAR(100),
    source_reference VARCHAR(255),
    burial_society_partner_id VARCHAR(255),
    burial_society_name VARCHAR(255) NOT NULL,
    cover_amount_cents BIGINT NOT NULL DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
    last_verified_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_funeral_external_cover_identity (identity_number, status),
    INDEX idx_funeral_external_cover_tenant_membership (source_tenant_id, source_membership_id),
    INDEX idx_funeral_external_cover_society_partner (burial_society_partner_id),
    CONSTRAINT fk_funeral_external_cover_society_partner FOREIGN KEY (burial_society_partner_id) REFERENCES partner(id)
) ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3
COLLATE = utf8mb3_general_ci;

CREATE TABLE IF NOT EXISTS funeral_service_invoice (
    id VARCHAR(255) NOT NULL PRIMARY KEY,
    funeral_service_id VARCHAR(255) NOT NULL,
    invoice_id CHAR(36) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    partner_id VARCHAR(255) NOT NULL,
    membership_claim_id VARCHAR(255),
    amount_cents BIGINT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_funeral_service_invoice (funeral_service_id, invoice_id),
    INDEX idx_funeral_service_invoice_service (funeral_service_id),
    INDEX idx_funeral_service_invoice_invoice (invoice_id),
    INDEX idx_funeral_service_invoice_claim (membership_claim_id),
    CONSTRAINT fk_funeral_service_invoice_service FOREIGN KEY (funeral_service_id) REFERENCES funeral_service(id),
    CONSTRAINT fk_funeral_service_invoice_invoice FOREIGN KEY (invoice_id) REFERENCES invoice(id),
    CONSTRAINT fk_funeral_service_invoice_claim FOREIGN KEY (membership_claim_id) REFERENCES membership_claim(id),
    CONSTRAINT fk_funeral_service_invoice_partner FOREIGN KEY (partner_id) REFERENCES partner(id)
) ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3
COLLATE = utf8mb3_general_ci;
