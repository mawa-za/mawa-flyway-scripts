-- Adds invoice-style totals to goods receipts so goods receiving can show subtotal, VAT and total values.

DROP PROCEDURE IF EXISTS add_column_if_missing;

DELIMITER $$

CREATE PROCEDURE add_column_if_missing(
    IN p_table_name VARCHAR(128),
    IN p_column_name VARCHAR(128),
    IN p_column_definition TEXT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name = p_table_name
          AND column_name = p_column_name
    ) THEN
        SET @ddl := CONCAT('ALTER TABLE `', p_table_name, '` ADD COLUMN ', p_column_definition);
        PREPARE stmt FROM @ddl;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$

DELIMITER ;

CALL add_column_if_missing('goods_receipt', 'currency', '`currency` VARCHAR(3) NULL DEFAULT ''ZAR'' AFTER `status`');
CALL add_column_if_missing('goods_receipt', 'subtotal_amount', '`subtotal_amount` DECIMAL(18,2) NOT NULL DEFAULT 0.00 AFTER `currency`');
CALL add_column_if_missing('goods_receipt', 'tax_amount', '`tax_amount` DECIMAL(18,2) NOT NULL DEFAULT 0.00 AFTER `subtotal_amount`');
CALL add_column_if_missing('goods_receipt', 'total_amount', '`total_amount` DECIMAL(18,2) NOT NULL DEFAULT 0.00 AFTER `tax_amount`');

CALL add_column_if_missing('goods_receipt_line', 'tax_rate', '`tax_rate` DECIMAL(5,2) NOT NULL DEFAULT 0.00 AFTER `unit_cost`');
CALL add_column_if_missing('goods_receipt_line', 'line_subtotal', '`line_subtotal` DECIMAL(18,2) NOT NULL DEFAULT 0.00 AFTER `tax_rate`');
CALL add_column_if_missing('goods_receipt_line', 'line_tax', '`line_tax` DECIMAL(18,2) NOT NULL DEFAULT 0.00 AFTER `line_subtotal`');
CALL add_column_if_missing('goods_receipt_line', 'line_total', '`line_total` DECIMAL(18,2) NOT NULL DEFAULT 0.00 AFTER `line_tax`');

UPDATE goods_receipt_line
SET line_subtotal = COALESCE(NULLIF(line_subtotal, 0), ROUND(COALESCE(unit_cost, 0) * COALESCE(quantity, 0), 2)),
    line_tax = COALESCE(line_tax, 0),
    line_total = COALESCE(NULLIF(line_total, 0), ROUND(COALESCE(unit_cost, 0) * COALESCE(quantity, 0), 2)),
    received_value = COALESCE(NULLIF(received_value, 0), ROUND(COALESCE(unit_cost, 0) * COALESCE(quantity, 0), 2));

UPDATE goods_receipt gr
LEFT JOIN (
    SELECT goods_receipt_id,
           ROUND(SUM(COALESCE(line_subtotal, 0)), 2) AS subtotal_amount,
           ROUND(SUM(COALESCE(line_tax, 0)), 2) AS tax_amount,
           ROUND(SUM(COALESCE(line_total, received_value, 0)), 2) AS total_amount
    FROM goods_receipt_line
    GROUP BY goods_receipt_id
) totals ON totals.goods_receipt_id = gr.id
SET gr.subtotal_amount = COALESCE(totals.subtotal_amount, 0),
    gr.tax_amount = COALESCE(totals.tax_amount, 0),
    gr.total_amount = COALESCE(totals.total_amount, 0),
    gr.currency = COALESCE(gr.currency, 'ZAR');

DROP PROCEDURE IF EXISTS add_column_if_missing;
