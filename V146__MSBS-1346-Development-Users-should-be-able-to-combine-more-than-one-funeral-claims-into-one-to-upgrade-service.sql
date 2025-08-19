INSERT INTO `field_option` (`code`, `field`, `description`, `type`, `valid_from`, `valid_to`) 
VALUES ('COMBINE', 'CLAIM-TYPE', 'Combine', 'SYSTEM', '2023-09-14', '9999-12-31');

INSERT INTO `field_option` (`code`, `field`, `description`, `type`, `valid_from`, `valid_to`) 
VALUES ('COMBINE-VALUE', 'PRODUCT-ATTRIBUTE', 'Combine Value', 'SYSTEM', '2023-09-14', '9999-12-31');

INSERT INTO `field_option` (`code`, `field`, `description`, `type`, `valid_from`, `valid_to`) 
VALUES ('FUNERAL-CLAIM-COMBINE', 'PAYMENT-REASON', 'Funeral Claim Combine', 'SYSTEM', '2023-09-14', '9999-12-31');

DELETE FROM `field_option` WHERE (`code` = 'MERGER') and (`field` = 'CLAIM-TYPE') and (`type` = 'SYSTEM');
DELETE FROM `field_option` WHERE (`code` = 'MERGE-VALUE') and (`field` = 'PRODUCT-ATTRIBUTE') and (`type` = 'SYSTEM');
DELETE FROM `field_option` WHERE (`code` = 'FUNERAL-CLAIM-MERGE') and (`field` = 'PAYMENT-REASON') and (`type` = 'SYSTEM');

