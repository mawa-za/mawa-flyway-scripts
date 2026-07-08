# Legacy domain data migration

This migration moves historical records from the old generic `transaction*` design into the newer dedicated MAWA domain tables.

Migration file:

```text
V202607080002__migrate_legacy_memberships_claims_payment_requests_group_societies_cashups.sql
```

## Scope

Migrated from legacy `transaction` records:

| Legacy type | New tables |
|---|---|
| `MEMBERSHIP` | `membership`, `membership_plan`, `membership_dependent` |
| `CLAIM` | `membership_claim`, `membership_claim_link` |
| `PAYMENT-REQUEST` | `payment_request`, `payment_request_status_history` |
| `GROUP-SOCIETY` | `group_society`, `group_society_member`, `group_society_account_txn` |
| `CASHUP` | `cashup`, `cashup_receipt`, `cashup_payment_summary` |

The migration does not remove the legacy `transaction`, `transaction_partner`, `transaction_item`, `transaction_amount`, `transaction_date`, `transaction_attribute`, `transaction_text`, `transaction_link`, or `transaction_bank_account` records.

## Idempotency and lineage

The migration adds lineage columns where needed:

```text
membership.old_id
membership_claim.legacy_transaction_id
payment_request.legacy_transaction_id
group_society.legacy_transaction_id
cashup.legacy_transaction_id
cashup_receipt.legacy_transaction_id
group_society_account_txn.legacy_transaction_id
```

These are used to prevent duplicate inserts if the migration is rerun or if some data was already manually migrated.

## Important assumptions

1. Old memberships must have a main partner through `transaction_partner` using one of:
   - `MAIN-MEMBER`
   - `MAINMEMBER`
   - `CUSTOMER`
   - `CLIENT`

2. Old memberships must have a product through `transaction_item.product`. The migration creates `membership_plan` rows from those products where needed.

3. Old claims are migrated only when they are linked to a legacy membership through `transaction_link` with type `CLAIM`:

```text
transaction_link.transaction1 = legacy membership transaction id
transaction_link.transaction2 = legacy claim transaction id
transaction_link.type = CLAIM
```

4. Old payment requests are linked to claims/groups where a legacy `transaction_link` exists. Otherwise they are migrated as `MANUAL` / `GENERAL_PAYOUT`.

5. Cashup receipt links are migrated where the old `transaction_link` can be resolved to a new `receipt` by:
   - `receipt.id`
   - `receipt.legacy_premium_payment_id`
   - `receipt.receipt_no`
   - `receipt.external_receipt_no`

6. Group society balances are migrated as an opening-balance style `group_society_account_txn` row where the old transaction carried balance totals.

## Validation queries

After running Flyway, review:

```sql
SELECT *
FROM legacy_domain_migration_audit
WHERE migration_name = 'V202607080002'
ORDER BY migrated_at DESC, metric_name;
```

Detailed counts:

```sql
SELECT COUNT(*) AS legacy_memberships
FROM `transaction`
WHERE UPPER(TRIM(type)) = 'MEMBERSHIP';

SELECT COUNT(*) AS migrated_memberships
FROM membership
WHERE old_id IS NOT NULL AND TRIM(old_id) <> '';

SELECT COUNT(*) AS legacy_claims
FROM `transaction`
WHERE UPPER(TRIM(type)) = 'CLAIM';

SELECT COUNT(*) AS migrated_claims
FROM membership_claim
WHERE legacy_transaction_id IS NOT NULL AND TRIM(legacy_transaction_id) <> '';

SELECT COUNT(*) AS legacy_payment_requests
FROM `transaction`
WHERE UPPER(TRIM(type)) = 'PAYMENT-REQUEST';

SELECT COUNT(*) AS migrated_payment_requests
FROM payment_request
WHERE legacy_transaction_id IS NOT NULL AND TRIM(legacy_transaction_id) <> '';

SELECT COUNT(*) AS legacy_group_societies
FROM `transaction`
WHERE UPPER(TRIM(type)) = 'GROUP-SOCIETY';

SELECT COUNT(*) AS migrated_group_societies
FROM group_society
WHERE legacy_transaction_id IS NOT NULL AND TRIM(legacy_transaction_id) <> '';

SELECT COUNT(*) AS legacy_cashups
FROM `transaction`
WHERE UPPER(TRIM(type)) = 'CASHUP';

SELECT COUNT(*) AS migrated_cashups
FROM cashup
WHERE legacy_transaction_id IS NOT NULL AND TRIM(legacy_transaction_id) <> '';
```

Unmigrated claim investigation:

```sql
SELECT t.id, t.number, t.status, t.sub_type
FROM `transaction` t
LEFT JOIN membership_claim mc
  ON mc.legacy_transaction_id = t.id
WHERE UPPER(TRIM(t.type)) = 'CLAIM'
  AND mc.id IS NULL;
```

Most unmigrated claims will be missing a legacy `transaction_link` to a migrated membership.

## Deployment guidance

Run this through Flyway per tenant schema. Take a backup first because this is a data migration.

Recommended order:

1. Deploy the updated `mawa-flyway-scripts` archive.
2. Run Flyway against one dev tenant schema.
3. Review `legacy_domain_migration_audit` and validation queries.
4. Run user acceptance checks in ERP for memberships, claims, payment requests, group societies and cashups.
5. Roll out to the remaining tenant schemas.
