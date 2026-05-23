/* ============================================================
   MAWA MEMBERSHIP PREMIUM / RECEIPT MIGRATION SCRIPT

   OLD TABLE:
   membership_premium
   - actually contains payment / receipt data

   NEW DESIGN:
   membership_premium   = expected charge per membership period
   payment_batch        = one payment event
   receipt              = printed proof of payment
   receipt_allocation   = what the receipt paid for

   IMPORTANT:
   - Run once only.
   - Foreign keys to membership/partner are not added here to avoid
     varchar length / charset mismatch issues.
   ============================================================ */


/* ============================================================
   1. RENAME OLD TABLE
   ============================================================ */

RENAME TABLE membership_premium TO membership_premium_payment_old;
DROP TABLE IF EXISTS receipt;

/* ============================================================
   2. CREATE NEW MEMBERSHIP PREMIUM TABLE
   True premium / charge table.
   ============================================================ */

CREATE TABLE membership_premium (
    id                  VARCHAR(255) NOT NULL PRIMARY KEY,

    membership_id       VARCHAR(255) NOT NULL,
    period_yyyymm       VARCHAR(6) NOT NULL,

    amount_cents        BIGINT NOT NULL,
    paid_amount_cents   BIGINT NOT NULL DEFAULT 0,
    balance_cents       BIGINT NOT NULL DEFAULT 0,

    status              VARCHAR(30) NOT NULL DEFAULT 'UNPAID',
    -- UNPAID, PARTIALLY_PAID, PAID, CANCELLED, WRITTEN_OFF, REVERSED

    due_date            DATE NULL,

    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(255),

    updated_at          DATETIME NULL,
    updated_by          VARCHAR(255),

    UNIQUE KEY uk_membership_premium_period (membership_id, period_yyyymm),

    INDEX idx_membership_premium_membership (membership_id),
    INDEX idx_membership_premium_period (period_yyyymm),
    INDEX idx_membership_premium_status (status)
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;  


/* ============================================================
   3. CREATE PAYMENT BATCH TABLE
   One payment batch can group multiple receipts.

   Example:
   Member pays R750 for 3 months:
   - one payment_batch
   - three receipts
   - three receipt_allocation rows
   ============================================================ */

CREATE TABLE payment_batch (
    id                          VARCHAR(255) NOT NULL PRIMARY KEY,

    payment_batch_no            VARCHAR(100) NOT NULL UNIQUE,

    source_type                 VARCHAR(50) NOT NULL,
    -- MEMBERSHIP_PREMIUM, INVOICE, GROUP_SOCIETY, GENERAL

    received_from_partner_id    VARCHAR(255) NULL,
    membership_id               VARCHAR(255) NULL,

    payment_method              VARCHAR(50) NULL,
    total_amount_cents          BIGINT NOT NULL DEFAULT 0,

    payment_date                DATETIME NOT NULL,

    location                    VARCHAR(100) NULL,
    employee_responsible        VARCHAR(255) NULL,

    device_id                   VARCHAR(100) NULL,
    terminal_id                 VARCHAR(100) NULL,

    local_payment_batch_id      VARCHAR(255) NULL,

    status                      VARCHAR(30) NOT NULL DEFAULT 'POSTED',
    -- POSTED, REVERSED, CANCELLED

    sync_status                 VARCHAR(30) NOT NULL DEFAULT 'SYNCED',
    -- LOCAL_ONLY, PENDING_SYNC, SYNCED, SYNC_FAILED, SYNCED_WITH_WARNINGS

    notes                       TEXT,

    legacy_premium_payment_id   VARCHAR(50) NULL,

    created_at                  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                  VARCHAR(255),

    updated_at                  DATETIME NULL,
    updated_by                  VARCHAR(255),

    UNIQUE KEY uk_payment_batch_device_local (device_id, local_payment_batch_id),

    INDEX idx_payment_batch_no (payment_batch_no),
    INDEX idx_payment_batch_source_type (source_type),
    INDEX idx_payment_batch_membership (membership_id),
    INDEX idx_payment_batch_partner (received_from_partner_id),
    INDEX idx_payment_batch_payment_date (payment_date),
    INDEX idx_payment_batch_status (status),
    INDEX idx_payment_batch_legacy (legacy_premium_payment_id)
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;


/* ============================================================
   4. CREATE RECEIPT TABLE
   One receipt = one printout / proof of payment.

   For membership premiums:
   One premium period can have its own receipt printout.
   ============================================================ */

CREATE TABLE receipt (
    id                          VARCHAR(255) NOT NULL PRIMARY KEY,

    receipt_no                  VARCHAR(100) NOT NULL UNIQUE,

    payment_batch_id            VARCHAR(255) NULL,
    payment_batch_no            VARCHAR(100) NULL,

    source_type                 VARCHAR(50) NOT NULL,
    -- MEMBERSHIP_PREMIUM, INVOICE, GROUP_SOCIETY, GENERAL

    received_from_partner_id    VARCHAR(255) NULL,
    membership_id               VARCHAR(255) NULL,

    receipt_date                DATETIME NOT NULL,

    payment_method              VARCHAR(50) NULL,
    total_amount_cents          BIGINT NOT NULL DEFAULT 0,

    status                      VARCHAR(30) NOT NULL DEFAULT 'POSTED',
    -- DRAFT, POSTED, REVERSED, CANCELLED

    sync_status                 VARCHAR(30) NOT NULL DEFAULT 'SYNCED',

    location                    VARCHAR(100) NULL,
    employee_responsible        VARCHAR(255) NULL,

    device_id                   VARCHAR(100) NULL,
    terminal_id                 VARCHAR(100) NULL,

    external_receipt_no         VARCHAR(100) NULL,

    printed                     BOOLEAN NOT NULL DEFAULT TRUE,
    print_count                 INT NOT NULL DEFAULT 1,

    legacy_premium_payment_id   VARCHAR(50) NULL,

    notes                       TEXT,

    created_at                  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                  VARCHAR(255),

    updated_at                  DATETIME NULL,
    updated_by                  VARCHAR(255),

    UNIQUE KEY uk_receipt_device_legacy (device_id, legacy_premium_payment_id),

    INDEX idx_receipt_no (receipt_no),
    INDEX idx_receipt_batch (payment_batch_id),
    INDEX idx_receipt_batch_no (payment_batch_no),
    INDEX idx_receipt_source_type (source_type),
    INDEX idx_receipt_membership (membership_id),
    INDEX idx_receipt_partner (received_from_partner_id),
    INDEX idx_receipt_date (receipt_date),
    INDEX idx_receipt_status (status),
    INDEX idx_receipt_external_no (external_receipt_no),
    INDEX idx_receipt_legacy (legacy_premium_payment_id)
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;


/* ============================================================
   5. CREATE RECEIPT ALLOCATION TABLE
   This table says what the receipt paid for.

   For membership premiums:
   receipt_allocation.period_yyyymm tells you which premium month
   the receipt paid.
   ============================================================ */

CREATE TABLE receipt_allocation (
    id                          VARCHAR(255) NOT NULL PRIMARY KEY,

    receipt_id                  VARCHAR(255) NOT NULL,

    allocation_type             VARCHAR(50) NOT NULL,
    -- MEMBERSHIP_PREMIUM, INVOICE, GROUP_SOCIETY_BALANCE, GENERAL

    reference_id                VARCHAR(255) NULL,
    -- membership_premium.id, invoice.id, group transaction id, etc.

    reference_no                VARCHAR(150) NULL,
    -- Example: MEM001-202606, INV000123

    period_yyyymm               VARCHAR(6) NULL,
    -- Used mainly for membership premium allocations

    membership_id               VARCHAR(255) NULL,

    amount_cents                BIGINT NOT NULL DEFAULT 0,

    status                      VARCHAR(30) NOT NULL DEFAULT 'POSTED',
    -- POSTED, REVERSED, CANCELLED

    legacy_premium_payment_id   VARCHAR(50) NULL,

    created_at                  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by                  VARCHAR(255),

    updated_at                  DATETIME NULL,
    updated_by                  VARCHAR(255),

    INDEX idx_receipt_allocation_receipt (receipt_id),
    INDEX idx_receipt_allocation_type_ref (allocation_type, reference_id),
    INDEX idx_receipt_allocation_period (period_yyyymm),
    INDEX idx_receipt_allocation_membership (membership_id),
    INDEX idx_receipt_allocation_legacy (legacy_premium_payment_id),

    CONSTRAINT fk_receipt_allocation_receipt
        FOREIGN KEY (receipt_id) REFERENCES receipt(id)
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;


/* ============================================================
   6. MIGRATE OLD ROWS INTO MEMBERSHIP_PREMIUM
   Old table contained payments, so historical premiums are created
   as already PAID.

   If there are multiple old payment rows for the same membership
   and period, they are grouped into one premium row.
   ============================================================ */

INSERT INTO membership_premium (
    id,
    membership_id,
    period_yyyymm,
    amount_cents,
    paid_amount_cents,
    balance_cents,
    status,
    created_at,
    created_by,
    updated_at,
    updated_by
)
SELECT
    UUID() AS id,
    TRIM(membership_id) AS membership_id,
    TRIM(membership_period) AS period_yyyymm,
    CAST(ROUND(SUM(amount) * 100, 0) AS SIGNED) AS amount_cents,
    CAST(ROUND(SUM(amount) * 100, 0) AS SIGNED) AS paid_amount_cents,
    0 AS balance_cents,
    'PAID' AS status,
    MIN(COALESCE(creation_date, creation_time, CURRENT_TIMESTAMP)) AS created_at,
    MIN(created_by) AS created_by,
    MAX(COALESCE(creation_date, creation_time, CURRENT_TIMESTAMP)) AS updated_at,
    MIN(created_by) AS updated_by
FROM membership_premium_payment_old
WHERE membership_id IS NOT NULL
  AND TRIM(membership_id) <> ''
  AND membership_period IS NOT NULL
  AND TRIM(membership_period) <> ''
  AND amount IS NOT NULL
GROUP BY
    TRIM(membership_id),
    TRIM(membership_period);


/* ============================================================
   7. MIGRATE OLD ROWS INTO PAYMENT_BATCH
   Because the old table did not have payment batches,
   every old row gets one migration batch.
   ============================================================ */

INSERT INTO payment_batch (
    id,
    payment_batch_no,
    source_type,
    membership_id,
    payment_method,
    total_amount_cents,
    payment_date,
    location,
    employee_responsible,
    device_id,
    terminal_id,
    status,
    sync_status,
    legacy_premium_payment_id,
    created_at,
    created_by
)
SELECT
    UUID() AS id,
    CONCAT('MIG-BATCH-', old.id) AS payment_batch_no,
    'MEMBERSHIP_PREMIUM' AS source_type,
    TRIM(old.membership_id) AS membership_id,
    old.tender_type AS payment_method,
    CAST(ROUND(old.amount * 100, 0) AS SIGNED) AS total_amount_cents,
    COALESCE(old.creation_date, old.creation_time, CURRENT_TIMESTAMP) AS payment_date,
    old.location,
    old.employee_responsible,
    old.terminal_id AS device_id,
    old.terminal_id,
    'POSTED' AS status,
    'SYNCED' AS sync_status,
    old.id AS legacy_premium_payment_id,
    COALESCE(old.creation_date, old.creation_time, CURRENT_TIMESTAMP) AS created_at,
    old.created_by
FROM membership_premium_payment_old old
WHERE old.membership_id IS NOT NULL
  AND TRIM(old.membership_id) <> ''
  AND old.membership_period IS NOT NULL
  AND TRIM(old.membership_period) <> ''
  AND old.amount IS NOT NULL;


/* ============================================================
   8. MIGRATE OLD ROWS INTO RECEIPT
   Each old payment row becomes one receipt.

   Receipt number priority:
   1. ext_receipt_number
   2. number + old.id
   3. MIG-RCP-{old.id}
   ============================================================ */

INSERT INTO receipt (
    id,
    receipt_no,
    payment_batch_id,
    payment_batch_no,
    source_type,
    membership_id,
    receipt_date,
    payment_method,
    total_amount_cents,
    status,
    sync_status,
    location,
    employee_responsible,
    device_id,
    terminal_id,
    external_receipt_no,
    printed,
    print_count,
    legacy_premium_payment_id,
    created_at,
    created_by,
    notes
)
SELECT
    UUID() AS id,

    CASE
        WHEN old.ext_receipt_number IS NOT NULL AND TRIM(old.ext_receipt_number) <> ''
            THEN TRIM(old.ext_receipt_number)
        WHEN old.number IS NOT NULL AND TRIM(old.number) <> ''
            THEN CONCAT('MIG-RCP-', TRIM(old.number), '-', old.id)
        ELSE CONCAT('MIG-RCP-', old.id)
    END AS receipt_no,

    batch.id AS payment_batch_id,
    batch.payment_batch_no AS payment_batch_no,

    'MEMBERSHIP_PREMIUM' AS source_type,

    TRIM(old.membership_id) AS membership_id,

    COALESCE(old.creation_date, old.creation_time, CURRENT_TIMESTAMP) AS receipt_date,

    old.tender_type AS payment_method,

    CAST(ROUND(old.amount * 100, 0) AS SIGNED) AS total_amount_cents,

    'POSTED' AS status,
    'SYNCED' AS sync_status,

    old.location,
    old.employee_responsible,

    old.terminal_id AS device_id,
    old.terminal_id,

    old.ext_receipt_number AS external_receipt_no,

    TRUE AS printed,
    1 AS print_count,

    old.id AS legacy_premium_payment_id,

    COALESCE(old.creation_date, old.creation_time, CURRENT_TIMESTAMP) AS created_at,
    old.created_by,

    CONCAT(
        'Migrated from old membership_premium table. ',
        'Old number: ', COALESCE(old.number, ''), '. ',
        'Old ext receipt number: ', COALESCE(old.ext_receipt_number, ''), '. ',
        'Old membership period: ', COALESCE(old.membership_period, ''), '.'
    ) AS notes

FROM membership_premium_payment_old old
JOIN payment_batch batch
  ON batch.legacy_premium_payment_id = old.id
WHERE old.membership_id IS NOT NULL
  AND TRIM(old.membership_id) <> ''
  AND old.membership_period IS NOT NULL
  AND TRIM(old.membership_period) <> ''
  AND old.amount IS NOT NULL;


/* ============================================================
   9. MIGRATE OLD ROWS INTO RECEIPT_ALLOCATION

   This links each receipt to the new membership_premium row.

   receipt_allocation.reference_id = membership_premium.id
   receipt_allocation.period_yyyymm = old membership_period
   ============================================================ */

INSERT INTO receipt_allocation (
    id,
    receipt_id,
    allocation_type,
    reference_id,
    reference_no,
    period_yyyymm,
    membership_id,
    amount_cents,
    status,
    legacy_premium_payment_id,
    created_at,
    created_by
)
SELECT
    UUID() AS id,
    r.id AS receipt_id,
    'MEMBERSHIP_PREMIUM' AS allocation_type,
    mp.id AS reference_id,
    CONCAT(TRIM(old.membership_id), '-', TRIM(old.membership_period)) AS reference_no,
    TRIM(old.membership_period) AS period_yyyymm,
    TRIM(old.membership_id) AS membership_id,
    CAST(ROUND(old.amount * 100, 0) AS SIGNED) AS amount_cents,
    'POSTED' AS status,
    old.id AS legacy_premium_payment_id,
    COALESCE(old.creation_date, old.creation_time, CURRENT_TIMESTAMP) AS created_at,
    old.created_by
FROM membership_premium_payment_old old
JOIN receipt r
  ON r.legacy_premium_payment_id = old.id
JOIN membership_premium mp
  ON mp.membership_id = TRIM(old.membership_id)
 AND mp.period_yyyymm = TRIM(old.membership_period)
WHERE old.membership_id IS NOT NULL
  AND TRIM(old.membership_id) <> ''
  AND old.membership_period IS NOT NULL
  AND TRIM(old.membership_period) <> ''
  AND old.amount IS NOT NULL;


/* ============================================================
   10. OPTIONAL REPORTING INDEXES / SAFETY CHECKS
   ============================================================ */

CREATE INDEX idx_receipt_allocation_receipt_period
ON receipt_allocation (receipt_id, period_yyyymm);

CREATE INDEX idx_receipt_allocation_membership_period
ON receipt_allocation (membership_id, period_yyyymm);


/* ============================================================
   11. VALIDATION QUERIES
   Run these after migration.
   ============================================================ */

SELECT COUNT(*) AS old_payment_rows
FROM membership_premium_payment_old;

SELECT COUNT(*) AS new_premium_rows
FROM membership_premium;

SELECT COUNT(*) AS payment_batch_rows
FROM payment_batch;

SELECT COUNT(*) AS receipt_rows
FROM receipt;

SELECT COUNT(*) AS receipt_allocation_rows
FROM receipt_allocation;

SELECT COUNT(*) AS allocations_not_linked_to_premium
FROM receipt_allocation
WHERE allocation_type = 'MEMBERSHIP_PREMIUM'
  AND reference_id IS NULL;

SELECT
    r.receipt_no,
    r.payment_batch_no,
    r.membership_id,
    ra.period_yyyymm,
    ra.amount_cents,
    ra.reference_id AS premium_id
FROM receipt r
JOIN receipt_allocation ra
  ON ra.receipt_id = r.id
WHERE r.source_type = 'MEMBERSHIP_PREMIUM'
ORDER BY r.receipt_date DESC
LIMIT 20;


/* ============================================================
   12. OPTIONAL FOREIGN KEYS
   Add these only after checking membership.id has compatible:
   - data type
   - length
   - charset
   - collation

   Example:
   membership.id must also be VARCHAR(255) utf8mb4_0900_ai_ci
   before these will work safely.
   ============================================================ */

/*
ALTER TABLE membership_premium
ADD CONSTRAINT fk_membership_premium_membership
FOREIGN KEY (membership_id) REFERENCES membership(id);

ALTER TABLE payment_batch
ADD CONSTRAINT fk_payment_batch_membership
FOREIGN KEY (membership_id) REFERENCES membership(id);

ALTER TABLE receipt
ADD CONSTRAINT fk_receipt_membership
FOREIGN KEY (membership_id) REFERENCES membership(id);
*/