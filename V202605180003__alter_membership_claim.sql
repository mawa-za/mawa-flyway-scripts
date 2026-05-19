ALTER TABLE `membership_claim` 
ADD COLUMN `approval_request_id` VARCHAR(255) NULL AFTER `updated_by`,
ADD COLUMN `approved_by` VARCHAR(36) NULL AFTER `approval_request_id`,
ADD COLUMN `approved_at` DATETIME NULL AFTER `approved_by`,
ADD COLUMN `payment_request_id` VARCHAR(255) NULL AFTER `approved_at`;
