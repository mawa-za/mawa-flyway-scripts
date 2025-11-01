ALTER TABLE `storage_bin` 
ADD COLUMN `batch_number` VARCHAR(45) NULL AFTER `product_id`,
ADD COLUMN `expiry_date` DATE NULL AFTER `batch_number`;
