-- Prevent duplicate offline payment batch sync submissions per device.
-- Run once per tenant schema.
--
-- NOTE:
-- V202605220001__receipt_tables.sql already creates this unique key for new schemas.
-- This migration is defensive for older/partially migrated tenant schemas only.

SET @uk_payment_batch_device_local_exists := (
    SELECT COUNT(1)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'payment_batch'
      AND index_name = 'uk_payment_batch_device_local'
);

SET @uk_payment_batch_device_local_sql := IF(
    @uk_payment_batch_device_local_exists = 0,
    'ALTER TABLE payment_batch ADD UNIQUE KEY uk_payment_batch_device_local (device_id, local_payment_batch_id)',
    'SELECT ''uk_payment_batch_device_local already exists'' AS info'
);

PREPARE uk_payment_batch_device_local_stmt FROM @uk_payment_batch_device_local_sql;
EXECUTE uk_payment_batch_device_local_stmt;
DEALLOCATE PREPARE uk_payment_batch_device_local_stmt;

-- Optional data repair for old migrated memberships where membership.premium_cents is NULL
-- but membership_plan.premium_cents is populated.
UPDATE membership m
JOIN membership_plan p ON p.id = m.plan_id
SET m.premium_cents = p.premium_cents
WHERE m.premium_cents IS NULL
  AND p.premium_cents IS NOT NULL;
