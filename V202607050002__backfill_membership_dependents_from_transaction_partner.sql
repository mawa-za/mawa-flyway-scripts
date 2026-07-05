/*
 Backfill v2 membership dependents from the legacy transaction_partner table.

 This migration is intentionally idempotent:
 - It only inserts dependent rows that do not already exist for the membership/partner pair.
 - It only uses v2 membership rows that have old_id populated with the legacy transaction id.
 - It validates that the dependent partner still exists in partner.
*/

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
    m.id                    AS membership_id,
    tp.partner              AS dependent_partner_id,
    'ANY'                   AS relationship,
    CASE
        WHEN UPPER(COALESCE(tp.status, '')) IN ('INACTIVE', 'CANCELLED', 'CANCELED', 'DELETED', 'REMOVED')
            THEN FALSE
        ELSE TRUE
    END                     AS active,
    COALESCE(tp.date_added, m.created_at, CURRENT_TIMESTAMP) AS created_at,
    COALESCE(tp.createdBy, m.created_by)                     AS created_by,
    COALESCE(tp.date_effective, m.updated_at, m.created_at, CURRENT_TIMESTAMP) AS updated_at,
    COALESCE(tp.changedBy, m.updated_by, tp.createdBy, m.created_by)           AS updated_by
FROM membership m
JOIN transaction_partner tp
    ON tp.transaction = m.old_id
   AND UPPER(TRIM(tp.partner_function)) IN ('DEPENDENT', 'DEPENDANT')
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
