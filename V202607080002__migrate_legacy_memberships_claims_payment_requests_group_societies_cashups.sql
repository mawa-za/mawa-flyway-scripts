/*
 MAWA legacy domain data migration

 Moves historical data from the old generic transaction design into the newer dedicated tables:
 - membership / membership_dependent / membership_plan
 - membership_claim / membership_claim_link
 - payment_request / payment_request_status_history
 - group_society / group_society_member / group_society_account_txn
 - cashup / cashup_receipt / cashup_payment_summary

 Notes:
 - This script is intentionally idempotent. It adds legacy_transaction_id columns and inserts only rows
   that have not already been migrated.
 - It does not delete or rename the old transaction tables.
 - It prefers deterministic business numbers from the old transaction.number/no fields where possible.
 - Some old optional fields were not consistently captured in the generic model; those are migrated as
   best effort and marked in notes.
*/

DROP PROCEDURE IF EXISTS add_column_if_missing;
DROP PROCEDURE IF EXISTS add_index_if_missing;

DELIMITER $$

CREATE PROCEDURE add_column_if_missing(
    IN p_table_name VARCHAR(128),
    IN p_column_name VARCHAR(128),
    IN p_column_definition TEXT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name = p_table_name
          AND column_name = p_column_name
    ) THEN
        SET @ddl := CONCAT('ALTER TABLE `', p_table_name, '` ADD COLUMN ', p_column_definition);
        PREPARE stmt FROM @ddl;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$

CREATE PROCEDURE add_index_if_missing(
    IN p_table_name VARCHAR(128),
    IN p_index_name VARCHAR(128),
    IN p_index_definition TEXT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.statistics
        WHERE table_schema = DATABASE()
          AND table_name = p_table_name
          AND index_name = p_index_name
    ) THEN
        SET @ddl := CONCAT('ALTER TABLE `', p_table_name, '` ADD ', p_index_definition);
        PREPARE stmt FROM @ddl;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$

DELIMITER ;

/* -------------------------------------------------------------------------
   0. Compatibility / lineage columns
   ------------------------------------------------------------------------- */

CALL add_column_if_missing('membership_claim', 'legacy_transaction_id', '`legacy_transaction_id` VARCHAR(255) NULL AFTER `payment_request_id`');
CALL add_column_if_missing('payment_request', 'legacy_transaction_id', '`legacy_transaction_id` VARCHAR(255) NULL AFTER `paid_by`');
CALL add_column_if_missing('group_society', 'legacy_transaction_id', '`legacy_transaction_id` VARCHAR(255) NULL AFTER `last_claim_date`');
CALL add_column_if_missing('cashup', 'legacy_transaction_id', '`legacy_transaction_id` VARCHAR(255) NULL AFTER `approval_request_id`');
CALL add_column_if_missing('cashup_receipt', 'legacy_transaction_id', '`legacy_transaction_id` VARCHAR(255) NULL AFTER `receipt_no`');
CALL add_column_if_missing('group_society_account_txn', 'legacy_transaction_id', '`legacy_transaction_id` VARCHAR(255) NULL AFTER `reference_no`');

CALL add_index_if_missing('membership', 'idx_membership_old_id', 'INDEX `idx_membership_old_id` (`old_id`)');
CALL add_index_if_missing('membership_plan', 'idx_membership_plan_old_id', 'INDEX `idx_membership_plan_old_id` (`old_id`)');
CALL add_index_if_missing('membership_claim', 'uk_membership_claim_legacy_transaction', 'UNIQUE KEY `uk_membership_claim_legacy_transaction` (`legacy_transaction_id`)');
CALL add_index_if_missing('payment_request', 'uk_payment_request_legacy_transaction', 'UNIQUE KEY `uk_payment_request_legacy_transaction` (`legacy_transaction_id`)');
CALL add_index_if_missing('group_society', 'uk_group_society_legacy_transaction', 'UNIQUE KEY `uk_group_society_legacy_transaction` (`legacy_transaction_id`)');
CALL add_index_if_missing('cashup', 'uk_cashup_legacy_transaction', 'UNIQUE KEY `uk_cashup_legacy_transaction` (`legacy_transaction_id`)');
CALL add_index_if_missing('cashup_receipt', 'idx_cashup_receipt_legacy_transaction', 'INDEX `idx_cashup_receipt_legacy_transaction` (`legacy_transaction_id`)');
CALL add_index_if_missing('cashup_receipt', 'uk_cashup_receipt_cashup_receipt', 'UNIQUE KEY `uk_cashup_receipt_cashup_receipt` (`cashup_id`, `receipt_id`)');
CALL add_index_if_missing('group_society_account_txn', 'idx_group_society_txn_legacy_transaction', 'INDEX `idx_group_society_txn_legacy_transaction` (`legacy_transaction_id`)');

CREATE TABLE IF NOT EXISTS legacy_domain_migration_audit (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    migration_name VARCHAR(150) NOT NULL,
    migrated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    metric_name VARCHAR(100) NOT NULL,
    metric_value BIGINT NOT NULL,
    notes TEXT NULL,
    INDEX idx_legacy_domain_migration_audit_name (migration_name, metric_name)
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;

/* -------------------------------------------------------------------------
   1. Membership plans from legacy membership/group products
   ------------------------------------------------------------------------- */

/* Backfill lineage on already-existing plans by matching legacy product id or generated plan code. */
UPDATE membership_plan mp
JOIN product p
  ON (mp.id = p.id
      OR mp.plan_code = CONCAT('LEG-', LEFT(COALESCE(NULLIF(TRIM(p.code), ''), p.id), 32), '-', RIGHT(REPLACE(p.id, '-', ''), 12)))
SET mp.old_id = p.id,
    mp.updated_at = COALESCE(mp.updated_at, CURRENT_TIMESTAMP),
    mp.updated_by = COALESCE(mp.updated_by, 'legacy-migration')
WHERE (mp.old_id IS NULL OR TRIM(mp.old_id) = '');

INSERT INTO membership_plan (
    id,
    plan_code,
    name,
    description,
    premium_cents,
    currency,
    max_dependents,
    active,
    created_at,
    created_by,
    updated_at,
    updated_by,
    old_id
)
SELECT
    REPLACE(UUID(), '-', '') AS id,
    CONCAT('LEG-', LEFT(COALESCE(NULLIF(TRIM(p.code), ''), p.id), 32), '-', RIGHT(REPLACE(p.id, '-', ''), 12)) AS plan_code,
    LEFT(COALESCE(NULLIF(TRIM(p.description), ''), NULLIF(TRIM(p.code), ''), CONCAT('Legacy product ', p.id)), 150) AS name,
    CONCAT('Migrated from product ', p.id, ' for legacy membership/group society transactions.') AS description,
    COALESCE(CAST(ROUND(MAX(COALESCE(pp.value, 0)) * 100, 0) AS SIGNED), 0) AS premium_cents,
    'ZAR' AS currency,
    NULL AS max_dependents,
    TRUE AS active,
    CURRENT_TIMESTAMP AS created_at,
    'legacy-migration' AS created_by,
    CURRENT_TIMESTAMP AS updated_at,
    'legacy-migration' AS updated_by,
    p.id AS old_id
FROM product p
JOIN transaction_item ti
  ON ti.product = p.id
JOIN `transaction` t
  ON t.id = ti.transaction
 AND UPPER(TRIM(t.type)) IN ('MEMBERSHIP', 'GROUP-SOCIETY')
LEFT JOIN product_pricing pp
  ON pp.product = p.id
 AND UPPER(TRIM(pp.pricing)) IN ('SELLING-PRICE', 'SELLING_PRICE', 'MONTHLY-PREMIUM', 'MONTHLY_PREMIUM')
LEFT JOIN membership_plan existing_plan
  ON existing_plan.old_id = p.id
  OR existing_plan.plan_code = CONCAT('LEG-', LEFT(COALESCE(NULLIF(TRIM(p.code), ''), p.id), 32), '-', RIGHT(REPLACE(p.id, '-', ''), 12))
WHERE p.id IS NOT NULL
  AND existing_plan.id IS NULL
GROUP BY p.id, p.code, p.description;

/* -------------------------------------------------------------------------
   2. Memberships from legacy transaction type MEMBERSHIP
   ------------------------------------------------------------------------- */

/* Backfill lineage on already-existing memberships that were manually or previously migrated by number. */
UPDATE membership m
JOIN `transaction` t
  ON UPPER(TRIM(t.type)) = 'MEMBERSHIP'
 AND m.membership_no = LEFT(COALESCE(NULLIF(TRIM(t.number), ''), NULLIF(TRIM(t.no), ''), CONCAT('MIG-MEM-', t.id)), 50)
SET m.old_id = t.id,
    m.updated_at = COALESCE(m.updated_at, CURRENT_TIMESTAMP),
    m.updated_by = COALESCE(m.updated_by, 'legacy-migration')
WHERE (m.old_id IS NULL OR TRIM(m.old_id) = '');

INSERT INTO membership (
    id,
    member_id,
    membership_no,
    plan_id,
    premium_cents,
    start_date,
    end_date,
    status,
    paid_up_to_period,
    join_date,
    created_at,
    created_by,
    updated_at,
    updated_by,
    old_id
)
SELECT
    REPLACE(UUID(), '-', '') AS id,
    main_partner.partner AS member_id,
    LEFT(COALESCE(NULLIF(TRIM(t.number), ''), NULLIF(TRIM(t.no), ''), CONCAT('MIG-MEM-', t.id)), 50) AS membership_no,
    mp.id AS plan_id,
    COALESCE(
        CAST(ROUND(MAX(CASE WHEN UPPER(TRIM(ta.type)) IN ('MONTHLY-PREMIUM', 'MONTHLY_PREMIUM') THEN ta.amount END) * 100, 0) AS SIGNED),
        CAST(ROUND(MAX(COALESCE(ti.unit_price, 0)) * 100, 0) AS SIGNED),
        mp.premium_cents,
        0
    ) AS premium_cents,
    COALESCE(DATE(joined_date.value), DATE(t.valid_from), CURRENT_DATE) AS start_date,
    DATE(t.valid_to) AS end_date,
    CASE
        WHEN UPPER(TRIM(COALESCE(t.status, ''))) IN ('SUSPENDED') THEN 'SUSPENDED'
        WHEN UPPER(TRIM(COALESCE(t.status, ''))) IN ('DECEASED') THEN 'DECEASED'
        WHEN UPPER(TRIM(COALESCE(t.status, ''))) IN ('CANCELLED', 'CANCELED', 'TERMINATED', 'INACTIVE') THEN 'CANCELLED'
        WHEN UPPER(TRIM(COALESCE(t.status, ''))) IN ('LAPSED') THEN 'LAPSED'
        ELSE 'ACTIVE'
    END AS status,
    NULLIF(TRIM(last_premium.value), '') AS paid_up_to_period,
    COALESCE(DATE(joined_date.value), DATE(t.valid_from), CURRENT_DATE) AS join_date,
    COALESCE(created_date.value, t.valid_from, CURRENT_TIMESTAMP) AS created_at,
    COALESCE(t.created_by, 'legacy-migration') AS created_by,
    COALESCE(effective_date.value, t.valid_to, created_date.value, t.valid_from, CURRENT_TIMESTAMP) AS updated_at,
    COALESCE(t.changed_by, t.created_by, 'legacy-migration') AS updated_by,
    t.id AS old_id
FROM `transaction` t
JOIN (
    SELECT transaction, partner
    FROM (
        SELECT
            tp.transaction,
            tp.partner,
            ROW_NUMBER() OVER (
                PARTITION BY tp.transaction
                ORDER BY FIELD(UPPER(TRIM(tp.partner_function)), 'MAIN-MEMBER', 'MAINMEMBER', 'CUSTOMER', 'CLIENT'), tp.partner
            ) AS rn
        FROM transaction_partner tp
        WHERE UPPER(TRIM(tp.partner_function)) IN ('MAIN-MEMBER', 'MAINMEMBER', 'CUSTOMER', 'CLIENT')
          AND tp.partner IS NOT NULL
          AND TRIM(tp.partner) <> ''
    ) ranked_partner
    WHERE rn = 1
) main_partner
  ON main_partner.transaction = t.id
JOIN partner p
  ON p.id = main_partner.partner
JOIN (
    SELECT transaction, product, unit_price
    FROM (
        SELECT
            ti.transaction,
            ti.product,
            ti.unit_price,
            ROW_NUMBER() OVER (PARTITION BY ti.transaction ORDER BY ti.valid_from DESC, ti.item) AS rn
        FROM transaction_item ti
        WHERE ti.product IS NOT NULL
          AND TRIM(ti.product) <> ''
    ) ranked_item
    WHERE rn = 1
) ti
  ON ti.transaction = t.id
JOIN membership_plan mp
  ON mp.old_id = ti.product
LEFT JOIN transaction_amount ta
  ON ta.transaction = t.id
LEFT JOIN (
    SELECT transaction, MAX(value) AS value
    FROM transaction_date
    WHERE UPPER(TRIM(type)) IN ('JOINED', 'DATE-JOINED')
    GROUP BY transaction
) joined_date
  ON joined_date.transaction = t.id
LEFT JOIN (
    SELECT transaction, MIN(value) AS value
    FROM transaction_date
    WHERE UPPER(TRIM(type)) IN ('CREATED', 'CREATION-DATE')
    GROUP BY transaction
) created_date
  ON created_date.transaction = t.id
LEFT JOIN (
    SELECT transaction, MAX(value) AS value
    FROM transaction_date
    WHERE UPPER(TRIM(type)) IN ('EFFECTIVE', 'DATE-EFFECTIVE')
    GROUP BY transaction
) effective_date
  ON effective_date.transaction = t.id
LEFT JOIN (
    SELECT transaction, MAX(value) AS value
    FROM transaction_attribute
    WHERE UPPER(TRIM(attribute)) = 'LAST-PREMIUM-PERIOD'
    GROUP BY transaction
) last_premium
  ON last_premium.transaction = t.id
LEFT JOIN membership existing_membership
  ON existing_membership.old_id = t.id
WHERE UPPER(TRIM(t.type)) = 'MEMBERSHIP'
  AND existing_membership.id IS NULL
GROUP BY
    t.id, t.number, t.no, t.status, t.valid_from, t.valid_to, t.created_by, t.changed_by,
    main_partner.partner, mp.id, mp.premium_cents, joined_date.value, created_date.value,
    effective_date.value, last_premium.value;

/* Re-run the dependent backfill here because this migration may create membership rows after the earlier dependent migration. */
INSERT INTO membership_dependent (
    id,
    membership_id,
    dependent_partner_id,
    relationship,
    active,
    created_at,
    created_by,
    updated_at,
    updated_by
)
SELECT
    REPLACE(UUID(), '-', '') AS id,
    m.id AS membership_id,
    tp.partner AS dependent_partner_id,
    CASE
        WHEN UPPER(TRIM(tp.partner_function)) IN ('SPOUSE') THEN 'SPOUSE'
        WHEN UPPER(TRIM(tp.partner_function)) IN ('CHILD') THEN 'CHILD'
        WHEN UPPER(TRIM(tp.partner_function)) IN ('PARENT') THEN 'PARENT'
        WHEN UPPER(TRIM(tp.partner_function)) IN ('EXTENDED-FAMILY', 'EXTENDED_FAMILY') THEN 'EXTENDED_FAMILY'
        ELSE 'ANY'
    END AS relationship,
    CASE
        WHEN UPPER(COALESCE(tp.status, '')) IN ('INACTIVE', 'CANCELLED', 'CANCELED', 'DELETED', 'REMOVED') THEN FALSE
        ELSE TRUE
    END AS active,
    COALESCE(tp.date_added, m.created_at, CURRENT_TIMESTAMP) AS created_at,
    COALESCE(tp.created_by, m.created_by) AS created_by,
    COALESCE(tp.date_effective, m.updated_at, m.created_at, CURRENT_TIMESTAMP) AS updated_at,
    COALESCE(tp.changed_by, m.updated_by, tp.created_by, m.created_by) AS updated_by
FROM membership m
JOIN transaction_partner tp
  ON tp.transaction = m.old_id
 AND UPPER(TRIM(tp.partner_function)) IN ('DEPENDENT', 'DEPENDANT', 'SPOUSE', 'CHILD', 'PARENT', 'EXTENDED-FAMILY', 'EXTENDED_FAMILY')
JOIN partner p
  ON p.id = tp.partner
LEFT JOIN membership_dependent md
  ON md.membership_id = m.id
 AND md.dependent_partner_id = tp.partner
WHERE m.old_id IS NOT NULL
  AND TRIM(m.old_id) <> ''
  AND tp.partner IS NOT NULL
  AND TRIM(tp.partner) <> ''
  AND md.id IS NULL;

/* -------------------------------------------------------------------------
   3. Group societies from legacy transaction type GROUP-SOCIETY
   ------------------------------------------------------------------------- */

/* Backfill lineage on already-existing group societies by group partner or group number. */
UPDATE group_society gs
JOIN `transaction` t
  ON UPPER(TRIM(t.type)) = 'GROUP-SOCIETY'
JOIN (
    SELECT transaction, partner
    FROM (
        SELECT tp.transaction, tp.partner,
               ROW_NUMBER() OVER (PARTITION BY tp.transaction ORDER BY tp.partner) AS rn
        FROM transaction_partner tp
        WHERE UPPER(TRIM(tp.partner_function)) IN ('CUSTOMER', 'MAIN-MEMBER', 'MAINMEMBER', 'CLIENT')
          AND tp.partner IS NOT NULL
          AND TRIM(tp.partner) <> ''
    ) ranked_partner
    WHERE rn = 1
) customer
  ON customer.transaction = t.id
SET gs.legacy_transaction_id = t.id,
    gs.updated_at = COALESCE(gs.updated_at, CURRENT_TIMESTAMP),
    gs.updated_by = COALESCE(gs.updated_by, 'legacy-migration')
WHERE (gs.legacy_transaction_id IS NULL OR TRIM(gs.legacy_transaction_id) = '')
  AND (gs.partner_id = customer.partner
       OR gs.group_no = LEFT(COALESCE(NULLIF(TRIM(t.number), ''), NULLIF(TRIM(t.no), ''), CONCAT('MIG-GRP-', t.id)), 50));

INSERT INTO group_society (
    id,
    partner_id,
    group_no,
    society_type,
    status,
    available_balance_cents,
    total_paid_cents,
    total_claimed_cents,
    last_payment_date,
    last_claim_date,
    legacy_transaction_id,
    created_at,
    created_by,
    updated_at,
    updated_by
)
SELECT
    REPLACE(UUID(), '-', '') AS id,
    customer.partner AS partner_id,
    LEFT(COALESCE(NULLIF(TRIM(t.number), ''), NULLIF(TRIM(t.no), ''), CONCAT('MIG-GRP-', t.id)), 50) AS group_no,
    LEFT(COALESCE(NULLIF(TRIM(t.sub_type), ''), 'BURIAL_SOCIETY'), 50) AS society_type,
    CASE
        WHEN UPPER(TRIM(COALESCE(t.status, ''))) IN ('SUSPENDED') THEN 'SUSPENDED'
        WHEN UPPER(TRIM(COALESCE(t.status, ''))) IN ('CLOSED', 'CANCELLED', 'CANCELED', 'TERMINATED', 'INACTIVE') THEN 'CLOSED'
        ELSE 'ACTIVE'
    END AS status,
    COALESCE(CAST(ROUND(MAX(CASE WHEN UPPER(TRIM(ta.type)) IN ('AVAILABLE-BALANCE', 'AVAILABLE_BALANCE') THEN ta.amount END) * 100, 0) AS SIGNED), 0) AS available_balance_cents,
    COALESCE(CAST(ROUND(MAX(CASE WHEN UPPER(TRIM(ta.type)) IN ('TOTAL-DEPOSITED', 'TOTAL_DEPOSITED') THEN ta.amount END) * 100, 0) AS SIGNED), 0) AS total_paid_cents,
    COALESCE(CAST(ROUND(MAX(CASE WHEN UPPER(TRIM(ta.type)) IN ('TOTAL-WITHDRAWN', 'TOTAL_WITHDRAWN') THEN ta.amount END) * 100, 0) AS SIGNED), 0) AS total_claimed_cents,
    DATE(MAX(CASE WHEN UPPER(TRIM(ta.type)) IN ('TOTAL-DEPOSITED', 'TOTAL_DEPOSITED') THEN COALESCE(t.valid_from, CURRENT_DATE) END)) AS last_payment_date,
    DATE(MAX(CASE WHEN UPPER(TRIM(ta.type)) IN ('TOTAL-WITHDRAWN', 'TOTAL_WITHDRAWN') THEN COALESCE(t.valid_from, CURRENT_DATE) END)) AS last_claim_date,
    t.id AS legacy_transaction_id,
    COALESCE(created_date.value, t.valid_from, CURRENT_TIMESTAMP) AS created_at,
    COALESCE(t.created_by, 'legacy-migration') AS created_by,
    COALESCE(last_updated.value, t.valid_to, created_date.value, t.valid_from, CURRENT_TIMESTAMP) AS updated_at,
    COALESCE(t.changed_by, t.created_by, 'legacy-migration') AS updated_by
FROM `transaction` t
JOIN (
    SELECT transaction, partner
    FROM (
        SELECT
            tp.transaction,
            tp.partner,
            ROW_NUMBER() OVER (
                PARTITION BY tp.transaction
                ORDER BY FIELD(UPPER(TRIM(tp.partner_function)), 'CUSTOMER', 'MAIN-MEMBER', 'MAINMEMBER', 'CLIENT'), tp.partner
            ) AS rn
        FROM transaction_partner tp
        WHERE UPPER(TRIM(tp.partner_function)) IN ('CUSTOMER', 'MAIN-MEMBER', 'MAINMEMBER', 'CLIENT')
          AND tp.partner IS NOT NULL
          AND TRIM(tp.partner) <> ''
    ) ranked_partner
    WHERE rn = 1
) customer
  ON customer.transaction = t.id
JOIN partner p
  ON p.id = customer.partner
LEFT JOIN transaction_amount ta
  ON ta.transaction = t.id
LEFT JOIN (
    SELECT transaction, MIN(value) AS value
    FROM transaction_date
    WHERE UPPER(TRIM(type)) IN ('CREATED', 'CREATION-DATE')
    GROUP BY transaction
) created_date
  ON created_date.transaction = t.id
LEFT JOIN (
    SELECT transaction, MAX(value) AS value
    FROM transaction_date
    WHERE UPPER(TRIM(type)) IN ('LAST-UPDATED', 'LAST_UPDATED')
    GROUP BY transaction
) last_updated
  ON last_updated.transaction = t.id
LEFT JOIN group_society existing_group
  ON existing_group.legacy_transaction_id = t.id
  OR existing_group.partner_id = customer.partner
WHERE UPPER(TRIM(t.type)) = 'GROUP-SOCIETY'
  AND existing_group.id IS NULL
GROUP BY
    t.id, t.number, t.no, t.sub_type, t.status, t.valid_from, t.valid_to, t.created_by, t.changed_by,
    customer.partner, created_date.value, last_updated.value;

/* Link group societies to migrated memberships where legacy transaction links point to memberships. */
INSERT IGNORE INTO group_society_member (
    id,
    group_society_id,
    member_id,
    membership_id,
    employee_no,
    external_ref,
    join_date,
    exit_date,
    status,
    created_at,
    created_by,
    updated_at,
    updated_by
)
SELECT DISTINCT
    REPLACE(UUID(), '-', '') AS id,
    gs.id AS group_society_id,
    m.member_id AS member_id,
    m.id AS membership_id,
    NULL AS employee_no,
    CONCAT('legacy-link:', tl.type) AS external_ref,
    m.join_date AS join_date,
    m.end_date AS exit_date,
    CASE WHEN m.status IN ('CANCELLED', 'LAPSED') THEN 'EXITED' ELSE m.status END AS status,
    COALESCE(tl.creation_date, m.created_at, CURRENT_TIMESTAMP) AS created_at,
    COALESCE(tl.created_by, m.created_by, 'legacy-migration') AS created_by,
    m.updated_at AS updated_at,
    m.updated_by AS updated_by
FROM group_society gs
JOIN (
    SELECT transaction1, transaction2, MIN(type) AS type, MIN(creation_date) AS creation_date, MIN(created_by) AS created_by
    FROM transaction_link
    GROUP BY transaction1, transaction2
) tl
  ON tl.transaction1 = gs.legacy_transaction_id
JOIN membership m
  ON m.old_id = tl.transaction2
LEFT JOIN group_society_member gsm
  ON gsm.group_society_id = gs.id
 AND gsm.member_id = m.member_id
WHERE gs.legacy_transaction_id IS NOT NULL
  AND gsm.id IS NULL;

/* Opening-balance style audit row for legacy group balances. */
INSERT INTO group_society_account_txn (
    id,
    group_society_id,
    txn_type,
    direction,
    amount_cents,
    balance_before_cents,
    balance_after_cents,
    txn_date,
    reference_type,
    reference_id,
    reference_no,
    legacy_transaction_id,
    payment_method,
    period,
    notes,
    created_at,
    created_by
)
SELECT
    REPLACE(UUID(), '-', '') AS id,
    gs.id AS group_society_id,
    'OPENING_BALANCE' AS txn_type,
    CASE WHEN gs.available_balance_cents < 0 THEN 'DEBIT' ELSE 'CREDIT' END AS direction,
    ABS(gs.available_balance_cents) AS amount_cents,
    0 AS balance_before_cents,
    gs.available_balance_cents AS balance_after_cents,
    COALESCE(gs.last_payment_date, gs.last_claim_date, DATE(gs.created_at), CURRENT_DATE) AS txn_date,
    'LEGACY_TRANSACTION' AS reference_type,
    gs.legacy_transaction_id AS reference_id,
    gs.group_no AS reference_no,
    CONCAT(gs.legacy_transaction_id, ':OPENING_BALANCE') AS legacy_transaction_id,
    NULL AS payment_method,
    NULL AS period,
    'Opening balance migrated from legacy group society transaction_amount totals.' AS notes,
    COALESCE(gs.created_at, CURRENT_TIMESTAMP) AS created_at,
    COALESCE(gs.created_by, 'legacy-migration') AS created_by
FROM group_society gs
LEFT JOIN group_society_account_txn existing_txn
  ON existing_txn.group_society_id = gs.id
 AND existing_txn.legacy_transaction_id = CONCAT(gs.legacy_transaction_id, ':OPENING_BALANCE')
WHERE gs.legacy_transaction_id IS NOT NULL
  AND gs.available_balance_cents <> 0
  AND existing_txn.id IS NULL;

/* -------------------------------------------------------------------------
   4. Claims from legacy transaction type CLAIM
   ------------------------------------------------------------------------- */

/* Backfill lineage on already-existing claims by claim number. */
UPDATE membership_claim mc
JOIN `transaction` t
  ON UPPER(TRIM(t.type)) = 'CLAIM'
 AND mc.claim_no = LEFT(COALESCE(NULLIF(TRIM(t.number), ''), NULLIF(TRIM(t.no), ''), CONCAT('MIG-CLM-', t.id)), 50)
SET mc.legacy_transaction_id = t.id,
    mc.updated_at = COALESCE(mc.updated_at, CURRENT_TIMESTAMP),
    mc.updated_by = COALESCE(mc.updated_by, 'legacy-migration')
WHERE (mc.legacy_transaction_id IS NULL OR TRIM(mc.legacy_transaction_id) = '');

INSERT INTO membership_claim (
    id,
    claim_no,
    membership_id,
    claim_type,
    deceased_type,
    deceased_partner_id,
    date_of_death,
    claim_date,
    cause_of_death,
    death_certificate_no,
    claimant_partner_id,
    claim_amount_cents,
    approved_amount_cents,
    status,
    rejection_reason,
    notes,
    created_at,
    created_by,
    updated_at,
    updated_by,
    legacy_transaction_id,
    payout_method,
    bank_name,
    account_holder_name,
    account_number,
    branch_code,
    account_type
)
SELECT
    REPLACE(UUID(), '-', '') AS id,
    LEFT(COALESCE(NULLIF(TRIM(t.number), ''), NULLIF(TRIM(t.no), ''), CONCAT('MIG-CLM-', t.id)), 50) AS claim_no,
    m.id AS membership_id,
    CASE
        WHEN UPPER(TRIM(COALESCE(t.sub_type, ''))) LIKE '%TOMBSTONE%' THEN 'TOMBSTONE'
        WHEN UPPER(TRIM(COALESCE(t.sub_type, ''))) LIKE '%FUNERAL%' THEN 'FUNERAL'
        WHEN UPPER(TRIM(COALESCE(t.sub_type, ''))) LIKE '%COMBINATION%' THEN 'COMBINATION'
        ELSE 'CASH'
    END AS claim_type,
    CASE WHEN deceased_partner.id = m.member_id THEN 'MAIN_MEMBER' ELSE 'DEPENDENT' END AS deceased_type,
    COALESCE(deceased_partner.id, m.member_id) AS deceased_partner_id,
    COALESCE(DATE(death_date.value), DATE(created_date.value), DATE(t.valid_from), CURRENT_DATE) AS date_of_death,
    COALESCE(DATE(created_date.value), DATE(t.valid_from), CURRENT_DATE) AS claim_date,
    LEFT(cause_text.text, 255) AS cause_of_death,
    LEFT(death_certificate.value, 100) AS death_certificate_no,
    claimant_partner.id AS claimant_partner_id,
    COALESCE(
        CAST(ROUND(MAX(CASE WHEN UPPER(TRIM(ta.type)) IN ('PAID-OUT-AMOUNT', 'PAID_OUT_AMOUNT', 'SERVICE-AMOUNT', 'SERVICE_AMOUNT') THEN ta.amount END) * 100, 0) AS SIGNED),
        0
    ) AS claim_amount_cents,
    CASE
        WHEN UPPER(TRIM(COALESCE(t.status, ''))) IN ('APPROVED', 'PAID', 'PROCESSED') THEN
            COALESCE(CAST(ROUND(MAX(CASE WHEN UPPER(TRIM(ta.type)) IN ('PAID-OUT-AMOUNT', 'PAID_OUT_AMOUNT', 'SERVICE-AMOUNT', 'SERVICE_AMOUNT') THEN ta.amount END) * 100, 0) AS SIGNED), 0)
        ELSE NULL
    END AS approved_amount_cents,
    CASE
        WHEN UPPER(TRIM(COALESCE(t.status, ''))) IN ('DRAFT', 'NEW') THEN 'DRAFT'
        WHEN UPPER(TRIM(COALESCE(t.status, ''))) IN ('CANCELLED', 'CANCELED') THEN 'CANCELLED'
        WHEN UPPER(TRIM(COALESCE(t.status, ''))) IN ('APPROVED') THEN 'APPROVED'
        WHEN UPPER(TRIM(COALESCE(t.status, ''))) IN ('REJECTED') THEN 'REJECTED'
        WHEN UPPER(TRIM(COALESCE(t.status, ''))) IN ('PAID', 'PROCESSED', 'SENT-TO-BANK') THEN 'PAID'
        ELSE 'SUBMITTED'
    END AS status,
    CASE WHEN UPPER(TRIM(COALESCE(t.status, ''))) = 'REJECTED' THEN t.status_reason ELSE NULL END AS rejection_reason,
    CONCAT('Migrated from legacy claim transaction ', t.id, '. Legacy status: ', COALESCE(t.status, ''), '.') AS notes,
    COALESCE(created_date.value, t.valid_from, CURRENT_TIMESTAMP) AS created_at,
    COALESCE(t.created_by, 'legacy-migration') AS created_by,
    COALESCE(last_updated.value, t.valid_to, created_date.value, t.valid_from, CURRENT_TIMESTAMP) AS updated_at,
    COALESCE(t.changed_by, t.created_by, 'legacy-migration') AS updated_by,
    t.id AS legacy_transaction_id,
    CASE
        WHEN UPPER(TRIM(COALESCE(payment_method.value, ''))) IN ('CASH') THEN 'CASH'
        WHEN UPPER(TRIM(COALESCE(payment_method.value, ''))) IN ('CARD', 'SPEEDPOINT') THEN 'CARD'
        WHEN UPPER(TRIM(COALESCE(payment_method.value, ''))) IN ('INTERNAL-TRANSFER', 'INTERNAL_TRANSFER') THEN 'INTERNAL_TRANSFER'
        ELSE 'EFT'
    END AS payout_method,
    tba.bank_name,
    tba.account_holder,
    tba.account_number,
    tba.branch_code,
    tba.account_type
FROM `transaction` t
JOIN (
    SELECT transaction2 AS claim_transaction_id, transaction1 AS membership_transaction_id
    FROM (
        SELECT tl.transaction1, tl.transaction2,
               ROW_NUMBER() OVER (PARTITION BY tl.transaction2 ORDER BY tl.creation_date, tl.transaction1) AS rn
        FROM transaction_link tl
        WHERE UPPER(TRIM(tl.type)) = 'CLAIM'
    ) ranked_claim_membership_link
    WHERE rn = 1
) claim_membership_link
  ON claim_membership_link.claim_transaction_id = t.id
JOIN membership m
  ON m.old_id = claim_membership_link.membership_transaction_id
LEFT JOIN (
    SELECT transaction, partner
    FROM (
        SELECT tp.transaction, tp.partner,
               ROW_NUMBER() OVER (PARTITION BY tp.transaction ORDER BY tp.partner) AS rn
        FROM transaction_partner tp
        WHERE UPPER(TRIM(tp.partner_function)) = 'DECEASED'
          AND tp.partner IS NOT NULL
          AND TRIM(tp.partner) <> ''
    ) ranked_deceased
    WHERE rn = 1
) deceased
  ON deceased.transaction = t.id
LEFT JOIN partner deceased_partner
  ON deceased_partner.id = deceased.partner
LEFT JOIN (
    SELECT transaction, partner
    FROM (
        SELECT tp.transaction, tp.partner,
               ROW_NUMBER() OVER (PARTITION BY tp.transaction ORDER BY tp.partner) AS rn
        FROM transaction_partner tp
        WHERE UPPER(TRIM(tp.partner_function)) = 'CLAIMANT'
          AND tp.partner IS NOT NULL
          AND TRIM(tp.partner) <> ''
    ) ranked_claimant
    WHERE rn = 1
) claimant
  ON claimant.transaction = t.id
LEFT JOIN partner claimant_partner
  ON claimant_partner.id = claimant.partner
LEFT JOIN (
    SELECT transaction, MAX(value) AS value
    FROM transaction_date
    WHERE UPPER(TRIM(type)) IN ('DEATH-DATE', 'DEATH_DATE')
    GROUP BY transaction
) death_date
  ON death_date.transaction = t.id
LEFT JOIN (
    SELECT transaction, MIN(value) AS value
    FROM transaction_date
    WHERE UPPER(TRIM(type)) IN ('CREATED', 'CREATION-DATE')
    GROUP BY transaction
) created_date
  ON created_date.transaction = t.id
LEFT JOIN (
    SELECT transaction, MAX(value) AS value
    FROM transaction_date
    WHERE UPPER(TRIM(type)) IN ('LAST-UPDATED', 'LAST_UPDATED')
    GROUP BY transaction
) last_updated
  ON last_updated.transaction = t.id
LEFT JOIN transaction_amount ta
  ON ta.transaction = t.id
LEFT JOIN (
    SELECT transaction, MAX(value) AS value
    FROM transaction_attribute
    WHERE UPPER(TRIM(attribute)) = 'PAYMENT-METHOD'
    GROUP BY transaction
) payment_method
  ON payment_method.transaction = t.id
LEFT JOIN (
    SELECT transaction, MAX(value) AS value
    FROM transaction_attribute
    WHERE UPPER(TRIM(attribute)) IN ('DEATH-CERTIFICATE-NO', 'DEATH_CERTIFICATE_NO', 'CERTIFICATE-NUMBER')
    GROUP BY transaction
) death_certificate
  ON death_certificate.transaction = t.id
LEFT JOIN (
    SELECT transaction, MAX(text) AS text
    FROM transaction_text
    WHERE UPPER(TRIM(type)) IN ('CAUSE-OF-DEATH', 'CAUSE_OF_DEATH')
    GROUP BY transaction
) cause_text
  ON cause_text.transaction = t.id
LEFT JOIN transaction_bank_account tba
  ON tba.transaction = t.id
LEFT JOIN membership_claim existing_claim
  ON existing_claim.legacy_transaction_id = t.id
WHERE UPPER(TRIM(t.type)) = 'CLAIM'
  AND existing_claim.id IS NULL
GROUP BY
    t.id, t.number, t.no, t.sub_type, t.status, t.status_reason, t.valid_from, t.valid_to, t.created_by, t.changed_by,
    m.id, m.member_id, deceased_partner.id, claimant_partner.id, death_date.value, created_date.value, last_updated.value,
    payment_method.value, death_certificate.value, cause_text.text, tba.bank_name, tba.account_holder, tba.account_number,
    tba.branch_code, tba.account_type;

INSERT INTO membership_claim_link (
    id,
    parent_claim_id,
    linked_claim_id,
    created_at,
    created_by
)
SELECT
    REPLACE(UUID(), '-', '') AS id,
    parent_claim.id AS parent_claim_id,
    linked_claim.id AS linked_claim_id,
    COALESCE(tl.creation_date, CURRENT_TIMESTAMP) AS created_at,
    COALESCE(tl.created_by, 'legacy-migration') AS created_by
FROM transaction_link tl
JOIN membership_claim parent_claim
  ON parent_claim.legacy_transaction_id = tl.transaction1
JOIN membership_claim linked_claim
  ON linked_claim.legacy_transaction_id = tl.transaction2
LEFT JOIN membership_claim_link existing_link
  ON existing_link.parent_claim_id = parent_claim.id
 AND existing_link.linked_claim_id = linked_claim.id
WHERE UPPER(TRIM(tl.type)) IN ('CLAIM-COMBINATION', 'CLAIM-COMBINED')
  AND existing_link.id IS NULL;

/* -------------------------------------------------------------------------
   5. Payment requests from legacy transaction type PAYMENT-REQUEST
   ------------------------------------------------------------------------- */

/* Backfill lineage on already-existing payment requests by request number. */
UPDATE payment_request pr
JOIN `transaction` t
  ON UPPER(TRIM(t.type)) = 'PAYMENT-REQUEST'
 AND pr.request_no = LEFT(COALESCE(NULLIF(TRIM(t.number), ''), NULLIF(TRIM(t.no), ''), CONCAT('MIG-PR-', t.id)), 50)
SET pr.legacy_transaction_id = t.id,
    pr.updated_at = COALESCE(pr.updated_at, CURRENT_TIMESTAMP),
    pr.updated_by = COALESCE(pr.updated_by, 'legacy-migration')
WHERE (pr.legacy_transaction_id IS NULL OR TRIM(pr.legacy_transaction_id) = '');

INSERT INTO payment_request (
    id,
    request_no,
    request_type,
    source_type,
    source_id,
    payee_partner_id,
    payee_name,
    amount,
    currency,
    payment_method,
    bank_name,
    account_holder,
    account_number,
    branch_code,
    account_type,
    invoice_no,
    external_reference,
    payment_reason,
    notes,
    requested_payment_date,
    status,
    legacy_transaction_id,
    paid_date,
    paid_reference,
    paid_by,
    created_at,
    created_by,
    updated_at,
    updated_by
)
SELECT
    REPLACE(UUID(), '-', '') AS id,
    LEFT(COALESCE(NULLIF(TRIM(t.number), ''), NULLIF(TRIM(t.no), ''), CONCAT('MIG-PR-', t.id)), 50) AS request_no,
    CASE
        WHEN linked_claim.id IS NOT NULL THEN 'CLAIM_PAYOUT'
        WHEN linked_group.id IS NOT NULL THEN 'GROUP_PAYOUT'
        WHEN UPPER(TRIM(COALESCE(t.category, ''))) LIKE '%REFUND%' THEN 'CUSTOMER_REFUND'
        WHEN UPPER(TRIM(COALESCE(t.category, ''))) LIKE '%SUPPLIER%' OR UPPER(TRIM(COALESCE(t.category, ''))) LIKE '%INVOICE%' THEN 'SUPPLIER_INVOICE'
        ELSE 'GENERAL_PAYOUT'
    END AS request_type,
    CASE
        WHEN linked_claim.id IS NOT NULL THEN 'MEMBERSHIP_CLAIM'
        WHEN linked_group.id IS NOT NULL THEN 'GROUP_SOCIETY'
        WHEN UPPER(TRIM(COALESCE(t.category, ''))) LIKE '%SUPPLIER%' OR UPPER(TRIM(COALESCE(t.category, ''))) LIKE '%INVOICE%' THEN 'SUPPLIER_INVOICE'
        WHEN UPPER(TRIM(COALESCE(t.category, ''))) LIKE '%REFUND%' THEN 'CUSTOMER_REFUND'
        ELSE 'MANUAL'
    END AS source_type,
    COALESCE(linked_claim.id, linked_group.id, tl.transaction2) AS source_id,
    recipient.partner AS payee_partner_id,
    LEFT(COALESCE(NULLIF(TRIM(CONCAT_WS(' ', NULLIF(p.name1, ''), NULLIF(p.name2, ''), NULLIF(p.name3, ''))), ''), 'Legacy Payee'), 255) AS payee_name,
    COALESCE(MAX(CASE WHEN UPPER(TRIM(ta.type)) IN ('PAYMENT-AMOUNT', 'PAYMENT_AMOUNT') THEN ta.amount END), 0.00) AS amount,
    'ZAR' AS currency,
    CASE
        WHEN UPPER(TRIM(COALESCE(t.sub_type, ''))) IN ('CASH') THEN 'CASH'
        WHEN UPPER(TRIM(COALESCE(t.sub_type, ''))) IN ('CARD', 'SPEEDPOINT') THEN 'CARD'
        WHEN UPPER(TRIM(COALESCE(t.sub_type, ''))) IN ('INTERNAL-TRANSFER', 'INTERNAL_TRANSFER') THEN 'INTERNAL_TRANSFER'
        ELSE 'EFT'
    END AS payment_method,
    tba.bank_name,
    tba.account_holder,
    tba.account_number,
    tba.branch_code,
    tba.account_type,
    CASE WHEN UPPER(TRIM(COALESCE(t.category, ''))) LIKE '%INVOICE%' THEN tl.transaction2 ELSE NULL END AS invoice_no,
    tl.transaction2 AS external_reference,
    LEFT(COALESCE(t.category, t.description, t.sub_description), 500) AS payment_reason,
    CONCAT('Migrated from legacy payment request transaction ', t.id, '. Legacy status: ', COALESCE(t.status, ''), '.') AS notes,
    DATE(due_date.value) AS requested_payment_date,
    CASE
        WHEN UPPER(TRIM(COALESCE(t.status, ''))) IN ('DRAFT', 'NEW') THEN 'DRAFT'
        WHEN UPPER(TRIM(COALESCE(t.status, ''))) IN ('AWAITING-APPROVAL', 'PENDING-APPROVAL', 'SUBMITTED') THEN 'PENDING_APPROVAL'
        WHEN UPPER(TRIM(COALESCE(t.status, ''))) = 'APPROVED' THEN 'APPROVED'
        WHEN UPPER(TRIM(COALESCE(t.status, ''))) = 'REJECTED' THEN 'REJECTED'
        WHEN UPPER(TRIM(COALESCE(t.status, ''))) IN ('CANCELLED', 'CANCELED') THEN 'CANCELLED'
        WHEN UPPER(TRIM(COALESCE(t.status, ''))) IN ('SENT-TO-BANK', 'QUEUED-FOR-PAYMENT') THEN 'QUEUED_FOR_PAYMENT'
        WHEN UPPER(TRIM(COALESCE(t.status, ''))) IN ('PAID', 'PROCESSED', 'CLOSED') THEN 'PAID'
        WHEN UPPER(TRIM(COALESCE(t.status, ''))) = 'FAILED' THEN 'FAILED'
        ELSE 'DRAFT'
    END AS status,
    t.id AS legacy_transaction_id,
    CASE WHEN UPPER(TRIM(COALESCE(t.status, ''))) IN ('PAID', 'PROCESSED', 'CLOSED') THEN DATE(COALESCE(last_updated.value, created_date.value, t.valid_to, t.valid_from)) ELSE NULL END AS paid_date,
    NULL AS paid_reference,
    CASE WHEN UPPER(TRIM(COALESCE(t.status, ''))) IN ('PAID', 'PROCESSED', 'CLOSED') THEN COALESCE(t.changed_by, t.created_by) ELSE NULL END AS paid_by,
    COALESCE(created_date.value, t.valid_from, CURRENT_TIMESTAMP) AS created_at,
    COALESCE(t.created_by, 'legacy-migration') AS created_by,
    COALESCE(last_updated.value, t.valid_to, created_date.value, t.valid_from, CURRENT_TIMESTAMP) AS updated_at,
    COALESCE(t.changed_by, t.created_by, 'legacy-migration') AS updated_by
FROM `transaction` t
LEFT JOIN transaction_amount ta
  ON ta.transaction = t.id
LEFT JOIN (
    SELECT transaction, partner
    FROM (
        SELECT tp.transaction, tp.partner,
               ROW_NUMBER() OVER (PARTITION BY tp.transaction ORDER BY tp.partner) AS rn
        FROM transaction_partner tp
        WHERE UPPER(TRIM(tp.partner_function)) = 'RECIPIENT'
          AND tp.partner IS NOT NULL
          AND TRIM(tp.partner) <> ''
    ) ranked_recipient
    WHERE rn = 1
) recipient
  ON recipient.transaction = t.id
LEFT JOIN partner p
  ON p.id = recipient.partner
LEFT JOIN transaction_bank_account tba
  ON tba.transaction = t.id
LEFT JOIN (
    SELECT transaction, MAX(value) AS value
    FROM transaction_date
    WHERE UPPER(TRIM(type)) IN ('DUE-DATE', 'DUE_DATE')
    GROUP BY transaction
) due_date
  ON due_date.transaction = t.id
LEFT JOIN (
    SELECT transaction, MIN(value) AS value
    FROM transaction_date
    WHERE UPPER(TRIM(type)) IN ('CREATED', 'CREATION-DATE')
    GROUP BY transaction
) created_date
  ON created_date.transaction = t.id
LEFT JOIN (
    SELECT transaction, MAX(value) AS value
    FROM transaction_date
    WHERE UPPER(TRIM(type)) IN ('LAST-UPDATED', 'LAST_UPDATED')
    GROUP BY transaction
) last_updated
  ON last_updated.transaction = t.id
LEFT JOIN (
    SELECT transaction1, transaction2
    FROM (
        SELECT tl.transaction1, tl.transaction2,
               ROW_NUMBER() OVER (PARTITION BY tl.transaction1 ORDER BY tl.creation_date, tl.transaction2) AS rn
        FROM transaction_link tl
        WHERE UPPER(TRIM(tl.type)) IN ('PAYMENT-REQUEST', 'CLAIM-PAYMENT-REQUEST', 'PAYMENT_REQUEST')
    ) ranked_payment_link
    WHERE rn = 1
) tl
  ON tl.transaction1 = t.id
LEFT JOIN membership_claim linked_claim
  ON linked_claim.legacy_transaction_id = tl.transaction2
LEFT JOIN group_society linked_group
  ON linked_group.legacy_transaction_id = tl.transaction2
LEFT JOIN payment_request existing_request
  ON existing_request.legacy_transaction_id = t.id
WHERE UPPER(TRIM(t.type)) = 'PAYMENT-REQUEST'
  AND existing_request.id IS NULL
GROUP BY
    t.id, t.number, t.no, t.sub_type, t.category, t.description, t.sub_description, t.status, t.valid_from, t.valid_to, t.created_by, t.changed_by,
    recipient.partner, p.name1, p.name2, p.name3, tba.bank_name, tba.account_holder, tba.account_number, tba.branch_code, tba.account_type,
    due_date.value, created_date.value, last_updated.value, tl.transaction2, linked_claim.id, linked_group.id;

INSERT INTO payment_request_status_history (
    id,
    payment_request_id,
    old_status,
    new_status,
    comment,
    changed_at,
    changed_by
)
SELECT
    REPLACE(UUID(), '-', '') AS id,
    pr.id AS payment_request_id,
    NULL AS old_status,
    pr.status AS new_status,
    'Initial status migrated from legacy payment request transaction.' AS comment,
    COALESCE(pr.created_at, CURRENT_TIMESTAMP) AS changed_at,
    COALESCE(pr.created_by, 'legacy-migration') AS changed_by
FROM payment_request pr
LEFT JOIN payment_request_status_history existing_history
  ON existing_history.payment_request_id = pr.id
WHERE pr.legacy_transaction_id IS NOT NULL
  AND existing_history.id IS NULL;

UPDATE membership_claim mc
JOIN payment_request pr
  ON pr.source_type = 'MEMBERSHIP_CLAIM'
 AND pr.source_id = mc.id
SET mc.payment_request_id = pr.id,
    mc.updated_at = COALESCE(mc.updated_at, CURRENT_TIMESTAMP),
    mc.updated_by = COALESCE(mc.updated_by, 'legacy-migration')
WHERE mc.legacy_transaction_id IS NOT NULL
  AND (mc.payment_request_id IS NULL OR mc.payment_request_id = '');

/* -------------------------------------------------------------------------
   6. Cashups from legacy transaction type CASHUP
   ------------------------------------------------------------------------- */

CREATE TEMPORARY TABLE tmp_legacy_cashup AS
SELECT
    t.id AS legacy_transaction_id,
    ROW_NUMBER() OVER (ORDER BY COALESCE(created_date.value, t.valid_from, CURRENT_TIMESTAMP), t.id) AS migration_row_no,
    t.number AS legacy_number,
    t.no AS legacy_no,
    t.sub_type,
    t.status,
    t.location,
    t.created_by,
    t.changed_by,
    t.valid_from,
    t.valid_to,
    created_date.value AS created_at,
    last_updated.value AS last_updated_at,
    employee.partner AS employee_partner_id,
    COALESCE(CAST(ROUND(MAX(CASE WHEN UPPER(TRIM(ta.type)) IN ('AMOUNT-COLLECTED', 'AMOUNT_COLLECTED') THEN ta.amount END) * 100, 0) AS SIGNED), 0) AS amount_collected_cents,
    COALESCE(CAST(ROUND(MAX(CASE WHEN UPPER(TRIM(ta.type)) IN ('AMOUNT-DEPOSITED', 'AMOUNT_DEPOSITED') THEN ta.amount END) * 100, 0) AS SIGNED), 0) AS amount_deposited_cents
FROM `transaction` t
LEFT JOIN transaction_amount ta
  ON ta.transaction = t.id
LEFT JOIN (
    SELECT transaction, MIN(value) AS value
    FROM transaction_date
    WHERE UPPER(TRIM(type)) IN ('CREATED', 'CREATION-DATE')
    GROUP BY transaction
) created_date
  ON created_date.transaction = t.id
LEFT JOIN (
    SELECT transaction, MAX(value) AS value
    FROM transaction_date
    WHERE UPPER(TRIM(type)) IN ('LAST-UPDATED', 'LAST_UPDATED')
    GROUP BY transaction
) last_updated
  ON last_updated.transaction = t.id
LEFT JOIN (
    SELECT transaction, partner
    FROM (
        SELECT tp.transaction, tp.partner,
               ROW_NUMBER() OVER (PARTITION BY tp.transaction ORDER BY tp.partner) AS rn
        FROM transaction_partner tp
        WHERE UPPER(TRIM(tp.partner_function)) IN ('EMPLOYEE-RESPONSIBLE', 'PERSON-RESPONSIBLE')
          AND tp.partner IS NOT NULL
          AND TRIM(tp.partner) <> ''
    ) ranked_employee
    WHERE rn = 1
) employee
  ON employee.transaction = t.id
WHERE UPPER(TRIM(t.type)) = 'CASHUP'
GROUP BY
    t.id, t.number, t.no, t.sub_type, t.status, t.location, t.created_by, t.changed_by,
    t.valid_from, t.valid_to, created_date.value, last_updated.value, employee.partner;

INSERT INTO cashup (
    id,
    cashup_no,
    device_id,
    user_id,
    cashup_date,
    total_cents,
    receipt_count,
    status,
    deposit_total_cents,
    deposit_count,
    approval_request_id,
    legacy_transaction_id,
    notes,
    synced_at,
    created_at,
    created_by,
    updated_at,
    updated_by
)
SELECT
    REPLACE(UUID(), '-', '') AS id,
    COALESCE((SELECT MAX(c_existing.cashup_no) FROM cashup c_existing), 990000000000) + tlc.migration_row_no AS cashup_no,
    LEFT(COALESCE(NULLIF(TRIM(tlc.location), ''), NULLIF(TRIM(tlc.created_by), ''), 'legacy'), 128) AS device_id,
    LEFT(COALESCE(NULLIF(TRIM(tlc.employee_partner_id), ''), NULLIF(TRIM(tlc.created_by), ''), 'legacy'), 255) AS user_id,
    COALESCE(DATE(tlc.created_at), DATE(tlc.valid_from), CURRENT_DATE) AS cashup_date,
    tlc.amount_collected_cents AS total_cents,
    COALESCE(linked_receipts.receipt_count, 0) AS receipt_count,
    CASE
        WHEN UPPER(TRIM(COALESCE(tlc.status, ''))) = 'OPEN' THEN 'OPEN'
        WHEN UPPER(TRIM(COALESCE(tlc.status, ''))) = 'APPROVED' THEN 'APPROVED'
        WHEN UPPER(TRIM(COALESCE(tlc.status, ''))) IN ('SUBMITTED') THEN 'SUBMITTED'
        WHEN UPPER(TRIM(COALESCE(tlc.status, ''))) IN ('CANCELLED', 'CANCELED') THEN 'CANCELLED'
        ELSE 'AWAITING_DEPOSITS'
    END AS status,
    tlc.amount_deposited_cents AS deposit_total_cents,
    CASE WHEN tlc.amount_deposited_cents > 0 THEN 1 ELSE 0 END AS deposit_count,
    NULL AS approval_request_id,
    tlc.legacy_transaction_id,
    CONCAT('Migrated from legacy cashup transaction ', tlc.legacy_transaction_id, '. Legacy number: ', COALESCE(tlc.legacy_number, tlc.legacy_no, ''), '.') AS notes,
    CURRENT_TIMESTAMP AS synced_at,
    COALESCE(tlc.created_at, tlc.valid_from, CURRENT_TIMESTAMP) AS created_at,
    COALESCE(tlc.created_by, 'legacy-migration') AS created_by,
    COALESCE(tlc.last_updated_at, tlc.valid_to, tlc.created_at, tlc.valid_from, CURRENT_TIMESTAMP) AS updated_at,
    COALESCE(tlc.changed_by, tlc.created_by, 'legacy-migration') AS updated_by
FROM tmp_legacy_cashup tlc
LEFT JOIN (
    SELECT tl.transaction1 AS legacy_cashup_id, COUNT(DISTINCT r.id) AS receipt_count
    FROM transaction_link tl
    JOIN receipt r
      ON r.id = tl.transaction2
      OR r.legacy_premium_payment_id = tl.transaction2
      OR r.receipt_no = tl.transaction2
      OR r.external_receipt_no = tl.transaction2
    WHERE UPPER(TRIM(tl.type)) = 'CASHUP'
    GROUP BY tl.transaction1
) linked_receipts
  ON linked_receipts.legacy_cashup_id = tlc.legacy_transaction_id
LEFT JOIN cashup existing_cashup
  ON existing_cashup.legacy_transaction_id = tlc.legacy_transaction_id
WHERE existing_cashup.id IS NULL;

INSERT IGNORE INTO cashup_receipt (
    id,
    cashup_id,
    receipt_id,
    receipt_no,
    legacy_transaction_id,
    amount_cents,
    payment_method,
    created_at
)
SELECT DISTINCT
    REPLACE(UUID(), '-', '') AS id,
    c.id AS cashup_id,
    r.id AS receipt_id,
    CASE WHEN r.receipt_no REGEXP '^[0-9]+$' THEN CAST(r.receipt_no AS UNSIGNED) ELSE NULL END AS receipt_no,
    CONCAT(c.legacy_transaction_id, ':', r.id) AS legacy_transaction_id,
    r.total_amount_cents AS amount_cents,
    r.payment_method,
    COALESCE(r.created_at, c.created_at, CURRENT_TIMESTAMP) AS created_at
FROM cashup c
JOIN (
    SELECT transaction1, transaction2
    FROM transaction_link
    WHERE UPPER(TRIM(type)) = 'CASHUP'
    GROUP BY transaction1, transaction2
) tl
  ON tl.transaction1 = c.legacy_transaction_id
JOIN receipt r
  ON r.id = tl.transaction2
  OR r.legacy_premium_payment_id = tl.transaction2
  OR r.receipt_no = tl.transaction2
  OR r.external_receipt_no = tl.transaction2
LEFT JOIN cashup_receipt existing_cashup_receipt
  ON existing_cashup_receipt.cashup_id = c.id
 AND existing_cashup_receipt.receipt_id = r.id
WHERE c.legacy_transaction_id IS NOT NULL
  AND existing_cashup_receipt.id IS NULL;

INSERT INTO cashup_payment_summary (
    id,
    cashup_id,
    payment_method,
    amount_cents,
    payment_count,
    created_at
)
SELECT
    REPLACE(UUID(), '-', '') AS id,
    c.id AS cashup_id,
    COALESCE(NULLIF(TRIM(cr.payment_method), ''), 'CASH') AS payment_method,
    SUM(cr.amount_cents) AS amount_cents,
    COUNT(*) AS payment_count,
    COALESCE(MIN(cr.created_at), c.created_at, CURRENT_TIMESTAMP) AS created_at
FROM cashup c
JOIN cashup_receipt cr
  ON cr.cashup_id = c.id
LEFT JOIN cashup_payment_summary cps
  ON cps.cashup_id = c.id
 AND cps.payment_method = COALESCE(NULLIF(TRIM(cr.payment_method), ''), 'CASH')
WHERE c.legacy_transaction_id IS NOT NULL
  AND cps.id IS NULL
GROUP BY c.id, COALESCE(NULLIF(TRIM(cr.payment_method), ''), 'CASH'), c.created_at;

/* Fallback summary for legacy cashups without receipt links. */
INSERT INTO cashup_payment_summary (
    id,
    cashup_id,
    payment_method,
    amount_cents,
    payment_count,
    created_at
)
SELECT
    REPLACE(UUID(), '-', '') AS id,
    c.id AS cashup_id,
    'CASH' AS payment_method,
    c.total_cents AS amount_cents,
    CASE WHEN c.total_cents > 0 THEN 1 ELSE 0 END AS payment_count,
    COALESCE(c.created_at, CURRENT_TIMESTAMP) AS created_at
FROM cashup c
LEFT JOIN cashup_payment_summary cps
  ON cps.cashup_id = c.id
WHERE c.legacy_transaction_id IS NOT NULL
  AND cps.id IS NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_legacy_cashup;

/* -------------------------------------------------------------------------
   7. Audit counts
   ------------------------------------------------------------------------- */

INSERT INTO legacy_domain_migration_audit (migration_name, metric_name, metric_value, notes)
SELECT 'V202607080002', 'legacy_membership_transactions', COUNT(*), 'Old transaction rows where type=MEMBERSHIP' FROM `transaction` WHERE UPPER(TRIM(type)) = 'MEMBERSHIP'
UNION ALL
SELECT 'V202607080002', 'migrated_memberships', COUNT(*), 'Rows in membership with old_id populated' FROM membership WHERE old_id IS NOT NULL AND TRIM(old_id) <> ''
UNION ALL
SELECT 'V202607080002', 'legacy_claim_transactions', COUNT(*), 'Old transaction rows where type=CLAIM' FROM `transaction` WHERE UPPER(TRIM(type)) = 'CLAIM'
UNION ALL
SELECT 'V202607080002', 'migrated_membership_claims', COUNT(*), 'Rows in membership_claim with legacy_transaction_id populated' FROM membership_claim WHERE legacy_transaction_id IS NOT NULL AND TRIM(legacy_transaction_id) <> ''
UNION ALL
SELECT 'V202607080002', 'legacy_payment_request_transactions', COUNT(*), 'Old transaction rows where type=PAYMENT-REQUEST' FROM `transaction` WHERE UPPER(TRIM(type)) = 'PAYMENT-REQUEST'
UNION ALL
SELECT 'V202607080002', 'migrated_payment_requests', COUNT(*), 'Rows in payment_request with legacy_transaction_id populated' FROM payment_request WHERE legacy_transaction_id IS NOT NULL AND TRIM(legacy_transaction_id) <> ''
UNION ALL
SELECT 'V202607080002', 'legacy_group_society_transactions', COUNT(*), 'Old transaction rows where type=GROUP-SOCIETY' FROM `transaction` WHERE UPPER(TRIM(type)) = 'GROUP-SOCIETY'
UNION ALL
SELECT 'V202607080002', 'migrated_group_societies', COUNT(*), 'Rows in group_society with legacy_transaction_id populated' FROM group_society WHERE legacy_transaction_id IS NOT NULL AND TRIM(legacy_transaction_id) <> ''
UNION ALL
SELECT 'V202607080002', 'legacy_cashup_transactions', COUNT(*), 'Old transaction rows where type=CASHUP' FROM `transaction` WHERE UPPER(TRIM(type)) = 'CASHUP'
UNION ALL
SELECT 'V202607080002', 'migrated_cashups', COUNT(*), 'Rows in cashup with legacy_transaction_id populated' FROM cashup WHERE legacy_transaction_id IS NOT NULL AND TRIM(legacy_transaction_id) <> '';

DROP PROCEDURE IF EXISTS add_column_if_missing;
DROP PROCEDURE IF EXISTS add_index_if_missing;
