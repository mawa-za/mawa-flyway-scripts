/*
  Dedicated procurement and sales document model for Inventory Management.
  Adds quotations, purchase orders, richer sales order accounting, purchase-order based goods receipting,
  sales reservation/issue support and workcenter access.
*/

DROP PROCEDURE IF EXISTS add_column_if_missing;
DELIMITER $$
CREATE PROCEDURE add_column_if_missing(
    IN p_table_name VARCHAR(64),
    IN p_column_name VARCHAR(64),
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
        SET @ddl = CONCAT('ALTER TABLE `', p_table_name, '` ADD COLUMN `', p_column_name, '` ', p_column_definition);
        PREPARE stmt FROM @ddl;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS modify_column_if_exists;
DELIMITER $$
CREATE PROCEDURE modify_column_if_exists(
    IN p_table_name VARCHAR(64),
    IN p_column_name VARCHAR(64),
    IN p_column_definition TEXT
)
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name = p_table_name
          AND column_name = p_column_name
    ) THEN
        SET @ddl = CONCAT('ALTER TABLE `', p_table_name, '` MODIFY COLUMN `', p_column_name, '` ', p_column_definition);
        PREPARE stmt FROM @ddl;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$
DELIMITER ;

CREATE TABLE IF NOT EXISTS quotation (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    quotation_no VARCHAR(50) NOT NULL UNIQUE,
    customer_partner_id VARCHAR(60) NULL,
    customer_reference VARCHAR(100) NULL,
    quotation_date DATE NOT NULL,
    valid_until DATE NULL,
    requested_delivery_date DATE NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'DRAFT',
    currency VARCHAR(10) NOT NULL DEFAULT 'ZAR',
    subtotal_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    converted_sales_order_id VARCHAR(36) NULL,
    notes TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(60) NULL,
    updated_at DATETIME NULL,
    updated_by VARCHAR(60) NULL,
    INDEX idx_quotation_status (status),
    INDEX idx_quotation_customer (customer_partner_id),
    INDEX idx_quotation_date (quotation_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

CREATE TABLE IF NOT EXISTS quotation_line (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    quotation_id VARCHAR(36) NOT NULL,
    line_no INT NOT NULL,
    product_id VARCHAR(60) NOT NULL,
    product_description VARCHAR(255) NULL,
    quantity DECIMAL(18,3) NOT NULL,
    uom VARCHAR(20) NOT NULL,
    unit_price DECIMAL(18,2) NOT NULL DEFAULT 0,
    tax_rate DECIMAL(8,2) NOT NULL DEFAULT 0,
    line_subtotal DECIMAL(18,2) NOT NULL DEFAULT 0,
    line_tax DECIMAL(18,2) NOT NULL DEFAULT 0,
    line_total DECIMAL(18,2) NOT NULL DEFAULT 0,
    notes TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(60) NULL,
    UNIQUE KEY uk_quotation_line (quotation_id, line_no),
    INDEX idx_quotation_line_product (product_id),
    CONSTRAINT fk_quotation_line_header FOREIGN KEY (quotation_id) REFERENCES quotation(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

CREATE TABLE IF NOT EXISTS purchase_order (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    purchase_order_no VARCHAR(50) NOT NULL UNIQUE,
    supplier_partner_id VARCHAR(60) NULL,
    supplier_reference VARCHAR(100) NULL,
    order_date DATE NOT NULL,
    expected_delivery_date DATE NULL,
    warehouse_id VARCHAR(36) NULL,
    receiving_location_id VARCHAR(36) NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'DRAFT',
    currency VARCHAR(10) NOT NULL DEFAULT 'ZAR',
    subtotal_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    notes TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(60) NULL,
    updated_at DATETIME NULL,
    updated_by VARCHAR(60) NULL,
    INDEX idx_po_status (status),
    INDEX idx_po_supplier (supplier_partner_id),
    INDEX idx_po_date (order_date),
    INDEX idx_po_warehouse (warehouse_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

CREATE TABLE IF NOT EXISTS purchase_order_line (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    purchase_order_id VARCHAR(36) NOT NULL,
    line_no INT NOT NULL,
    product_id VARCHAR(60) NOT NULL,
    product_description VARCHAR(255) NULL,
    ordered_qty DECIMAL(18,3) NOT NULL,
    received_qty DECIMAL(18,3) NOT NULL DEFAULT 0,
    open_qty DECIMAL(18,3) NOT NULL DEFAULT 0,
    uom VARCHAR(20) NOT NULL,
    unit_cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    tax_rate DECIMAL(8,2) NOT NULL DEFAULT 0,
    line_subtotal DECIMAL(18,2) NOT NULL DEFAULT 0,
    line_tax DECIMAL(18,2) NOT NULL DEFAULT 0,
    line_total DECIMAL(18,2) NOT NULL DEFAULT 0,
    status VARCHAR(30) NOT NULL DEFAULT 'OPEN',
    notes TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(60) NULL,
    UNIQUE KEY uk_po_line (purchase_order_id, line_no),
    INDEX idx_po_line_product (product_id),
    INDEX idx_po_line_status (status),
    CONSTRAINT fk_po_line_header FOREIGN KEY (purchase_order_id) REFERENCES purchase_order(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

CALL modify_column_if_exists('goods_receipt_line', 'product_id', 'VARCHAR(60) NOT NULL');
CALL modify_column_if_exists('putaway_line', 'product_id', 'VARCHAR(60) NOT NULL');
CALL modify_column_if_exists('stock_balance', 'product_id', 'VARCHAR(60) NOT NULL');
CALL modify_column_if_exists('stock_movement', 'product_id', 'VARCHAR(60) NOT NULL');
CALL modify_column_if_exists('sales_order_line', 'product_id', 'VARCHAR(60) NOT NULL');

CALL add_column_if_missing('goods_receipt', 'purchase_order_id', 'VARCHAR(36) NULL');
CALL add_column_if_missing('goods_receipt', 'purchase_order_no', 'VARCHAR(50) NULL');
CALL add_column_if_missing('goods_receipt_line', 'purchase_order_line_id', 'VARCHAR(36) NULL');
CALL add_column_if_missing('goods_receipt_line', 'unit_cost', 'DECIMAL(18,2) NOT NULL DEFAULT 0');
CALL add_column_if_missing('goods_receipt_line', 'received_value', 'DECIMAL(18,2) NOT NULL DEFAULT 0');

CALL add_column_if_missing('sales_order', 'quotation_id', 'VARCHAR(36) NULL');
CALL add_column_if_missing('sales_order', 'customer_reference', 'VARCHAR(100) NULL');
CALL add_column_if_missing('sales_order', 'currency', 'VARCHAR(10) NOT NULL DEFAULT ''ZAR''');
CALL add_column_if_missing('sales_order', 'subtotal_amount', 'DECIMAL(18,2) NOT NULL DEFAULT 0');
CALL add_column_if_missing('sales_order', 'tax_amount', 'DECIMAL(18,2) NOT NULL DEFAULT 0');
CALL add_column_if_missing('sales_order', 'total_amount', 'DECIMAL(18,2) NOT NULL DEFAULT 0');

CALL add_column_if_missing('sales_order_line', 'product_description', 'VARCHAR(255) NULL');
CALL add_column_if_missing('sales_order_line', 'reserved_qty', 'DECIMAL(18,3) NOT NULL DEFAULT 0');
CALL add_column_if_missing('sales_order_line', 'unit_price', 'DECIMAL(18,2) NOT NULL DEFAULT 0');
CALL add_column_if_missing('sales_order_line', 'tax_rate', 'DECIMAL(8,2) NOT NULL DEFAULT 0');
CALL add_column_if_missing('sales_order_line', 'line_subtotal', 'DECIMAL(18,2) NOT NULL DEFAULT 0');
CALL add_column_if_missing('sales_order_line', 'line_tax', 'DECIMAL(18,2) NOT NULL DEFAULT 0');
CALL add_column_if_missing('sales_order_line', 'line_total', 'DECIMAL(18,2) NOT NULL DEFAULT 0');

INSERT INTO number_range (`current`, `end`, `object`, `prefix`, `start`, `valid_from`, `valid_to`)
SELECT '0000000000', '9999999999', 'QUOTATION', 'QT', '0000000000', CURRENT_DATE, NULL
WHERE NOT EXISTS (SELECT 1 FROM number_range WHERE object = 'QUOTATION');

INSERT INTO number_range (`current`, `end`, `object`, `prefix`, `start`, `valid_from`, `valid_to`)
SELECT '0000000000', '9999999999', 'PURCHASE_ORDER', 'PO', '0000000000', CURRENT_DATE, NULL
WHERE NOT EXISTS (SELECT 1 FROM number_range WHERE object = 'PURCHASE_ORDER');

INSERT INTO number_range (`current`, `end`, `object`, `prefix`, `start`, `valid_from`, `valid_to`)
SELECT '0000000000', '9999999999', 'STOCK_ISSUE', 'ISS', '0000000000', CURRENT_DATE, NULL
WHERE NOT EXISTS (SELECT 1 FROM number_range WHERE object = 'STOCK_ISSUE');

INSERT INTO role_workcenter (role, workcenter, position)
SELECT r.id, wc.workcenter, COALESCE(max_pos.max_position, 0) + wc.sort_order
FROM role r
JOIN (
    SELECT 'quotation' AS workcenter, 105 AS sort_order UNION ALL
    SELECT 'purchase-order', 106 UNION ALL
    SELECT 'inventory-management', 107
) wc
LEFT JOIN (
    SELECT role, MAX(position) AS max_position
    FROM role_workcenter
    GROUP BY role
) max_pos
  ON max_pos.role = r.id
LEFT JOIN role_workcenter rw
       ON rw.role = r.id
      AND rw.workcenter = wc.workcenter
WHERE rw.role IS NULL;

DROP PROCEDURE IF EXISTS add_column_if_missing;
DROP PROCEDURE IF EXISTS modify_column_if_exists;
