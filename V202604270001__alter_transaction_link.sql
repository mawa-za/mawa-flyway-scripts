ALTER TABLE `transaction_link` 
CHANGE COLUMN `transaction1` `transaction1` VARCHAR(100) NOT NULL ,
CHANGE COLUMN `transaction2` `transaction2` VARCHAR(100) NOT NULL ;

ALTER TABLE `transaction_attribute` 
CHANGE COLUMN `attribute` `attribute` VARCHAR(255) CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci' NULL DEFAULT NULL ,
CHANGE COLUMN `value` `value` VARCHAR(255) CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci' NULL DEFAULT NULL ;
