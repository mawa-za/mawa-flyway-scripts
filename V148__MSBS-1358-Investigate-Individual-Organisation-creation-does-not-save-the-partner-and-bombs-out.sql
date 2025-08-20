DROP VIEW IF EXISTS `transaction_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER
VIEW `transaction_view` AS
SELECT DISTINCT
  `transaction`.`id` AS `transaction_id`,
  `transaction`.`type` AS `transaction_type`,
  `transaction`.`sub_type` AS `transaction_subtype`,
  `transaction`.`number` AS `transaction_number`,
  partner_identity.`type` AS `identity_type`,
  partner_identity.`value` AS `identity_number`,
  CONCAT(COALESCE(`main_partner`.`name1`,''),' ',COALESCE(`main_partner`.`name2`,''),' ',COALESCE(`main_partner`.`name3`,'')) AS `main_partner`,
  CONCAT(COALESCE(`employee`.`name1`,''),' ',COALESCE(`employee`.`name2`,''),' ',COALESCE(`employee`.`name3`,'')) AS `employee_responsible`,
  CONCAT(COALESCE(`recipient`.`name1`,''),' ',COALESCE(`recipient`.`name2`,''),' ',COALESCE(`recipient`.`name3`,'')) AS `recipient`,
  CONCAT(COALESCE(`created_by`.`name1`,''),' ',COALESCE(`created_by`.`name2`,''),' ',COALESCE(`created_by`.`name3`,'')) AS `created_by`,
  CONCAT(COALESCE(`changed_by`.`name1`,''),' ',COALESCE(`changed_by`.`name2`,''),' ',COALESCE(`changed_by`.`name3`,'')) AS `changed_by`,
  `product`.`description` AS `product`,
  `product`.`id` AS `product_id`,
  `transaction`.`valid_from` AS `creation_date`,
  `transaction`.`category` AS `category`,
  `transaction`.`priority` AS `priority`,
  `transaction`.`status` AS `transaction_status`,
  amount_collected.`amount` AS `amount_collected`,
  amount_deposited.`amount` AS `amount_deposited`,
  payment_amount.`amount` AS `amount`,
  linked_batch_transaction.`number` AS `batch_number`,
  due_date.`value` AS `due_date`,
  death_date.`value` AS `death_date`,
  burial_date.`value` AS `burial_date`,
  date_joined.`value` AS `date_joined`,
  date_effective.`value` AS `date_effective`,
  transaction_link.`transaction2` AS `reference`,
  CONCAT(COALESCE(`p`.`name1`,''),' ',COALESCE(`p`.`name2`,''),' ',COALESCE(`p`.`name3`,'')) AS `claimant`
FROM `transaction`
LEFT JOIN `transaction_partner` `main_tx_partner`
  ON `transaction`.`id` = `main_tx_partner`.`transaction`
 AND (`main_tx_partner`.`partner_function` = 'CUSTOMER'
      OR `main_tx_partner`.`partner_function` = 'MAIN-MEMBER'
      OR `main_tx_partner`.`partner_function` = 'CLIENT')
LEFT JOIN `partner` `main_partner`
  ON `main_tx_partner`.`partner` = `main_partner`.`id`
LEFT JOIN (
    SELECT
      `partner_identity`.`partner`     AS `partner`,
      `partner_identity`.`type`       AS `type`,
      `partner_identity`.`value`      AS `value`,
      ROW_NUMBER() OVER (
         PARTITION BY `partner_identity`.`partner`
         ORDER BY `partner_identity`.`type`
      ) AS `rn`
    FROM `partner_identity`
) AS partner_identity
  ON main_tx_partner.`partner` = partner_identity.`partner`
 AND partner_identity.`rn` = 1
LEFT JOIN (
    SELECT
      `transaction_partner`.`transaction`,
      `transaction_partner`.`partner`,
      ROW_NUMBER() OVER (
          PARTITION BY `transaction_partner`.`transaction`
          ORDER BY `transaction_partner`.`partner`
      ) AS `rn`
    FROM `transaction_partner`
    WHERE `transaction_partner`.`partner_function` IN (
      'SALES-REPRESENTATIVE','EMPLOYEE-RESPONSIBLE','PERSON-RESPONSIBLE'
    )
) AS employee_partner
  ON `transaction`.`id` = employee_partner.`transaction`
 AND employee_partner.`rn` = 1
LEFT JOIN `partner` AS `employee`
  ON employee_partner.`partner` = `employee`.`id`
LEFT JOIN (
    SELECT
      `transaction_partner`.`transaction`,
      `transaction_partner`.`partner`,
      ROW_NUMBER() OVER (
        PARTITION BY `transaction_partner`.`transaction`
        ORDER BY `transaction_partner`.`partner`
      ) AS `rn`
    FROM `transaction_partner`
    WHERE `transaction_partner`.`partner_function` = 'RECIPIENT'
) AS recipient_partner
  ON `transaction`.`id` = recipient_partner.`transaction`
 AND recipient_partner.`rn` = 1
LEFT JOIN `partner` AS `recipient`
  ON recipient_partner.`partner` = recipient.`id`
LEFT JOIN (
    SELECT
      `transaction_item`.`transaction`,
      `transaction_item`.`product`,
      ROW_NUMBER() OVER (
        PARTITION BY `transaction_item`.`transaction`
        ORDER BY `transaction_item`.`transaction`
      ) AS `rn`
    FROM `transaction_item`
) AS item
  ON item.`transaction` = `transaction`.`id`
 AND `transaction`.`type` IN ('MEMBERSHIP','GROUP-SOCIETY')
 AND item.`rn` = 1
LEFT JOIN `product`
  ON `product`.`id` = item.`product`
LEFT JOIN (
    SELECT
      `transaction_amount`.`transaction`,
      `transaction_amount`.`amount`,
      ROW_NUMBER() OVER (
        PARTITION BY `transaction_amount`.`transaction`
        ORDER BY `transaction_amount`.`transaction`
      ) AS `rn`
    FROM `transaction_amount`
    WHERE `transaction_amount`.`type` = 'AMOUNT-COLLECTED'
) AS amount_collected
  ON `transaction`.`id` = amount_collected.`transaction`
 AND amount_collected.`rn` = 1
LEFT JOIN (
    SELECT
      `transaction_amount`.`transaction`,
      `transaction_amount`.`amount`,
      ROW_NUMBER() OVER (
        PARTITION BY `transaction_amount`.`transaction`
        ORDER BY `transaction_amount`.`transaction`
      ) AS `rn`
    FROM `transaction_amount`
    WHERE `transaction_amount`.`type` = 'AMOUNT-DEPOSITED'
) AS amount_deposited
  ON `transaction`.`id` = amount_deposited.`transaction`
 AND amount_deposited.`rn` = 1
LEFT JOIN (
    SELECT
      `transaction_amount`.`transaction`,
      `transaction_amount`.`amount`,
      ROW_NUMBER() OVER (
        PARTITION BY `transaction_amount`.`transaction`
        ORDER BY `transaction_amount`.`transaction`
      ) AS `rn`
    FROM `transaction_amount`
    WHERE `transaction_amount`.`type` = 'PAYMENT-AMOUNT'
) AS payment_amount
  ON `transaction`.`id` = payment_amount.`transaction`
 AND payment_amount.`rn` = 1
LEFT JOIN (
    SELECT
      `transaction_date`.`transaction`,
      `transaction_date`.`value`,
      ROW_NUMBER() OVER (
        PARTITION BY `transaction_date`.`transaction`
        ORDER BY `transaction_date`.`transaction`
      ) AS `rn`
    FROM `transaction_date`
    WHERE `transaction_date`.`type` = 'DUE-DATE'
) AS due_date
  ON `transaction`.`id` = due_date.`transaction`
 AND due_date.`rn` = 1
LEFT JOIN (
    SELECT
      `transaction_date`.`transaction`,
      `transaction_date`.`value`,
      ROW_NUMBER() OVER (
        PARTITION BY `transaction_date`.`transaction`
        ORDER BY `transaction_date`.`transaction`
      ) AS `rn`
    FROM `transaction_date`
    WHERE `transaction_date`.`type` = 'DEATH-DATE'
) AS death_date
  ON `transaction`.`id` = death_date.`transaction`
 AND death_date.`rn` = 1
LEFT JOIN (
    SELECT
      `transaction_date`.`transaction`,
      `transaction_date`.`value`,
      ROW_NUMBER() OVER (
        PARTITION BY `transaction_date`.`transaction`
        ORDER BY `transaction_date`.`transaction`
      ) AS `rn`
    FROM `transaction_date`
    WHERE `transaction_date`.`type` = 'BURIAL-DATE'
) AS burial_date
  ON `transaction`.`id` = burial_date.`transaction`
 AND burial_date.`rn` = 1
LEFT JOIN (
    SELECT
      `transaction_date`.`transaction`,
      `transaction_date`.`value`,
      ROW_NUMBER() OVER (
        PARTITION BY `transaction_date`.`transaction`
        ORDER BY `transaction_date`.`transaction`
      ) AS `rn`
    FROM `transaction_date`
    WHERE `transaction_date`.`type` = 'DATE-JOINED'
) AS date_joined
  ON `transaction`.`id` = date_joined.`transaction`
 AND date_joined.`rn` = 1
LEFT JOIN (
    SELECT
      `transaction_date`.`transaction`,
      `transaction_date`.`value`,
      ROW_NUMBER() OVER (
        PARTITION BY `transaction_date`.`transaction`
        ORDER BY `transaction_date`.`transaction`
      ) AS `rn`
    FROM `transaction_date`
    WHERE `transaction_date`.`type` = 'DATE-EFFECT'
) AS date_effective
  ON `transaction`.`id` = date_effective.`transaction`
 AND date_effective.`rn` = 1
LEFT JOIN (
    SELECT
      `transaction_partner`.`transaction`,
      `transaction_partner`.`partner`,
      ROW_NUMBER() OVER (
        PARTITION BY `transaction_partner`.`transaction`
        ORDER BY `transaction_partner`.`partner`
      ) AS `rn`
    FROM `transaction_partner`
    WHERE `transaction_partner`.`partner_function` = 'CLAIMANT'
) AS t_partner
  ON `transaction`.`id` = t_partner.`transaction`
 AND t_partner.`rn` = 1
LEFT JOIN `partner` AS p
  ON t_partner.`partner` = p.`id`
LEFT JOIN (
  SELECT
    `transaction_link`.`transaction1`,
    `transaction_link`.`transaction2`,
    ROW_NUMBER() OVER (
      PARTITION BY `transaction_link`.`transaction1`
      ORDER BY `transaction_link`.`transaction1`
    ) AS `rn`
  FROM `transaction_link`
) AS transaction_link
  ON `transaction`.`id` = transaction_link.`transaction1`
 AND `transaction`.`type` = 'PAYMENT-REQUEST'
 AND transaction_link.`rn` = 1
LEFT JOIN (
  SELECT
    `transaction_link`.`transaction1`,
    `transaction_link`.`transaction2`,
    `transaction_link`.`type`,
    ROW_NUMBER() OVER (
      PARTITION BY `transaction_link`.`transaction2`
      ORDER BY `transaction_link`.`transaction2`
    ) AS `rn`
  FROM `transaction_link`
) AS transaction_batch_link
  ON `transaction`.`id` = transaction_batch_link.`transaction2`
 AND transaction_batch_link.`type` = 'PAYMENT-BATCH-LINK'
 AND transaction_batch_link.`rn` = 1
LEFT JOIN `transaction` AS `linked_batch_transaction`
  ON `linked_batch_transaction`.`id` = transaction_batch_link.`transaction1`
LEFT JOIN `user` AS `user_created_by`
  ON `transaction`.`created_by` = user_created_by.`username`
LEFT JOIN `partner` AS `created_by`
  ON user_created_by.`partner` = created_by.`id`
LEFT JOIN `user` AS `user_changed_by`
  ON `transaction`.`changed_by` = user_changed_by.`username`
LEFT JOIN `partner` AS `changed_by`
  ON user_changed_by.`partner` = changed_by.`id`;
