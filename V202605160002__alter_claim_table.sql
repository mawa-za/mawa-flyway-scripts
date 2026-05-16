ALTER TABLE membership_claim
ADD COLUMN payout_method VARCHAR(20) NULL AFTER claim_type,
ADD COLUMN bank_name VARCHAR(100) NULL AFTER payout_method,
ADD COLUMN account_holder_name VARCHAR(150) NULL AFTER bank_name,
ADD COLUMN account_number VARCHAR(50) NULL AFTER account_holder_name,
ADD COLUMN branch_code VARCHAR(20) NULL AFTER account_number,
ADD COLUMN account_type VARCHAR(30) NULL AFTER branch_code;