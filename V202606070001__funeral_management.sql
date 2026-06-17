ALTER TABLE `invoice_payment` 
DROP FOREIGN KEY `fk_invoice_payment_invoice`;
ALTER TABLE `invoice_payment` 
CHANGE COLUMN `id` `id` VARCHAR(255) NOT NULL ,
CHANGE COLUMN `invoice_id` `invoice_id` VARCHAR(255) NOT NULL ,
CHANGE COLUMN `created_by` `created_by` VARCHAR(255) NULL DEFAULT NULL ;
ALTER TABLE `invoice_payment` 
ADD CONSTRAINT `fk_invoice_payment_invoice`
  FOREIGN KEY (`invoice_id`)
  REFERENCES `invoice` (`id`)
  ON DELETE CASCADE;


ALTER TABLE `address` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `api_endpoint_log` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `approval_action` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `approval_request` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `approval_workflow` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `approval_workflow_step` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `approval_workflow_step_approver` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `attachment` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `bank_account` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `case_billing_item` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `case_disbursement` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `case_event` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `case_note` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `case_party` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `case_task` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `case_time_entry` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `case_trust_ledger` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `case_trust_transaction` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `cashup` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `cashup_payment_summary` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `cashup_range_allocation` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `cashup_receipt` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `cashup_sequence` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `employment` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `field` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `field_option` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `flyway_schema_history` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `generated_id` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `group_society` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `group_society_account_txn` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `group_society_contact` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `group_society_member` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `invoice` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `invoice_line` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `invoice_payment` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `legal_case` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `membership` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `membership_claim` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `membership_claim_link` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `membership_dependent` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `membership_plan` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `membership_plan_claim_payout` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `membership_plan_premium_rule` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `membership_premium` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `membership_premium_payment_old` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `message_queue` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `module_usage_event` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `notification` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `notification_log` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `number_range` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `number_range_allocation` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `number_sequence` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `partner` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `partner_address` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `partner_attachment` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `partner_attribute` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `partner_bank_account` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `partner_contact` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `partner_date` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `partner_identity` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `partner_relation` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `partner_resources` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `partner_role` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `payment_batch` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `payment_request` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `payment_request_status_history` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `payroll_payment_batch` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `payroll_payment_batch_audit` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `payroll_payment_item` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `print_job` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `product` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `product_attribute` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `product_category` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `product_pricing` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `product_storage_bin` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `product_type_category` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `receipt` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `receipt_allocation` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `receipt_range_allocation` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `receipt_sequence` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `role` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `role_workcenter` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `settings` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `storage_bin` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `tenant` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `tenant_property` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `test` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `transaction` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `transaction_amount` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `transaction_attachment` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `transaction_attribute` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `transaction_bank_account` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `transaction_date` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `transaction_item` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `transaction_link` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `transaction_partner` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `transaction_text` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `user` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `user_module_usage` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;
ALTER TABLE `user_role` ENGINE=InnoDB DEFAULT CHARACTER SET=utf8mb3 COLLATE=utf8mb3_general_ci;


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
    invoice_id VARCHAR(255) NOT NULL,
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


