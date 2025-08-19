INSERT INTO `field_option` (`code`, `field`, `description`, `type`, `valid_from`, `valid_to`) 
VALUES ('COMBINATION', 'CLAIM-TYPE', 'Combination', 'SYSTEM', '2023-09-14', '9999-12-31');

INSERT INTO `field_option` (`code`, `field`, `description`, `type`, `valid_from`, `valid_to`) 
VALUES ('COMBINATION-VALUE', 'PRODUCT-ATTRIBUTE', 'Combination Value', 'SYSTEM', '2023-09-14', '9999-12-31');

INSERT INTO `field_option` (`code`, `field`, `description`, `type`, `valid_from`, `valid_to`) 
VALUES ('FUNERAL-CLAIM-COMBINATION', 'PAYMENT-REASON', 'Funeral Claim Combination', 'SYSTEM', '2023-09-14', '9999-12-31');

DELETE FROM `field_option` WHERE (`code` = 'COMBINE') and (`field` = 'CLAIM-TYPE') and (`type` = 'SYSTEM');
DELETE FROM `field_option` WHERE (`code` = 'COMBINE-VALUE') and (`field` = 'PRODUCT-ATTRIBUTE') and (`type` = 'SYSTEM');
DELETE FROM `field_option` WHERE (`code` = 'FUNERAL-CLAIM-COMBINE') and (`field` = 'PAYMENT-REASON') and (`type` = 'SYSTEM');

