-- Prevent duplicate offline payment batch sync submissions per device.
-- Run once per tenant schema.

ALTER TABLE payment_batch
    ADD UNIQUE KEY uk_payment_batch_device_local (device_id, local_payment_batch_id);

-- Optional data repair for old migrated memberships where membership.premium_cents is NULL
-- but membership_plan.premium_cents is populated.
UPDATE membership m
JOIN membership_plan p ON p.id = m.plan_id
SET m.premium_cents = p.premium_cents
WHERE m.premium_cents IS NULL
  AND p.premium_cents IS NOT NULL;
