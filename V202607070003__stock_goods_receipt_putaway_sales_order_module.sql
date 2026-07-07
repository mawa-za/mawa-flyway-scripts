/*
  Goods Receipt, Putaway, Stock and Sales Order module.
  Uses the existing number_range feature for document numbers:
  - GOODS_RECEIPT
  - PUTAWAY
  - STOCK_MOVEMENT
  - SALES_ORDER
*/

CREATE TABLE IF NOT EXISTS warehouse (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    warehouse_code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    description VARCHAR(255) NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(36) NULL,
    updated_at DATETIME NULL,
    updated_by VARCHAR(36) NULL,
    INDEX idx_warehouse_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

CREATE TABLE IF NOT EXISTS storage_location (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    warehouse_id VARCHAR(36) NOT NULL,
    location_code VARCHAR(80) NOT NULL,
    name VARCHAR(150) NOT NULL,
    location_type VARCHAR(30) NOT NULL DEFAULT 'BIN',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(36) NULL,
    updated_at DATETIME NULL,
    updated_by VARCHAR(36) NULL,
    UNIQUE KEY uk_location_wh_code (warehouse_id, location_code),
    INDEX idx_location_warehouse (warehouse_id),
    INDEX idx_location_status (status),
    CONSTRAINT fk_location_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouse(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

CREATE TABLE IF NOT EXISTS goods_receipt (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    receipt_no VARCHAR(50) NOT NULL UNIQUE,
    supplier_partner_id VARCHAR(36) NULL,
    supplier_reference VARCHAR(100) NULL,
    warehouse_id VARCHAR(36) NOT NULL,
    storage_location_id VARCHAR(36) NOT NULL,
    receipt_date DATE NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'RECEIVED',
    notes TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(36) NULL,
    updated_at DATETIME NULL,
    updated_by VARCHAR(36) NULL,
    INDEX idx_gr_status (status),
    INDEX idx_gr_date (receipt_date),
    INDEX idx_gr_warehouse (warehouse_id),
    CONSTRAINT fk_gr_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouse(id),
    CONSTRAINT fk_gr_location FOREIGN KEY (storage_location_id) REFERENCES storage_location(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

CREATE TABLE IF NOT EXISTS goods_receipt_line (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    goods_receipt_id VARCHAR(36) NOT NULL,
    line_no INT NOT NULL,
    product_id VARCHAR(36) NOT NULL,
    quantity DECIMAL(18,3) NOT NULL,
    open_putaway_qty DECIMAL(18,3) NOT NULL DEFAULT 0,
    uom VARCHAR(20) NOT NULL,
    batch_no VARCHAR(80) NULL,
    expiry_date DATE NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(36) NULL,
    UNIQUE KEY uk_gr_line (goods_receipt_id, line_no),
    INDEX idx_gr_line_product (product_id),
    CONSTRAINT fk_gr_line_header FOREIGN KEY (goods_receipt_id) REFERENCES goods_receipt(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

CREATE TABLE IF NOT EXISTS putaway (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    putaway_no VARCHAR(50) NOT NULL UNIQUE,
    goods_receipt_id VARCHAR(36) NULL,
    warehouse_id VARCHAR(36) NOT NULL,
    from_location_id VARCHAR(36) NOT NULL,
    to_location_id VARCHAR(36) NOT NULL,
    movement_date DATE NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'COMPLETED',
    notes TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(36) NULL,
    updated_at DATETIME NULL,
    updated_by VARCHAR(36) NULL,
    INDEX idx_putaway_status (status),
    INDEX idx_putaway_date (movement_date),
    CONSTRAINT fk_putaway_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouse(id),
    CONSTRAINT fk_putaway_from_location FOREIGN KEY (from_location_id) REFERENCES storage_location(id),
    CONSTRAINT fk_putaway_to_location FOREIGN KEY (to_location_id) REFERENCES storage_location(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

CREATE TABLE IF NOT EXISTS putaway_line (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    putaway_id VARCHAR(36) NOT NULL,
    line_no INT NOT NULL,
    goods_receipt_line_id VARCHAR(36) NULL,
    product_id VARCHAR(36) NOT NULL,
    quantity DECIMAL(18,3) NOT NULL,
    uom VARCHAR(20) NOT NULL,
    batch_no VARCHAR(80) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(36) NULL,
    UNIQUE KEY uk_putaway_line (putaway_id, line_no),
    INDEX idx_putaway_line_product (product_id),
    CONSTRAINT fk_putaway_line_header FOREIGN KEY (putaway_id) REFERENCES putaway(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

CREATE TABLE IF NOT EXISTS stock_balance (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    product_id VARCHAR(36) NOT NULL,
    warehouse_id VARCHAR(36) NOT NULL,
    storage_location_id VARCHAR(36) NOT NULL,
    batch_no VARCHAR(80) NULL,
    on_hand_qty DECIMAL(18,3) NOT NULL DEFAULT 0,
    reserved_qty DECIMAL(18,3) NOT NULL DEFAULT 0,
    available_qty DECIMAL(18,3) NOT NULL DEFAULT 0,
    uom VARCHAR(20) NOT NULL,
    minimum_qty DECIMAL(18,3) NOT NULL DEFAULT 0,
    last_movement_at DATETIME NULL,
    updated_at DATETIME NULL,
    updated_by VARCHAR(36) NULL,
    UNIQUE KEY uk_stock_balance (product_id, warehouse_id, storage_location_id, batch_no),
    INDEX idx_stock_product (product_id),
    INDEX idx_stock_warehouse (warehouse_id),
    INDEX idx_stock_location (storage_location_id),
    INDEX idx_stock_available (available_qty),
    CONSTRAINT fk_stock_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouse(id),
    CONSTRAINT fk_stock_location FOREIGN KEY (storage_location_id) REFERENCES storage_location(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

CREATE TABLE IF NOT EXISTS stock_movement (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    movement_no VARCHAR(50) NOT NULL UNIQUE,
    movement_type VARCHAR(40) NOT NULL,
    reference_type VARCHAR(40) NULL,
    reference_id VARCHAR(36) NULL,
    reference_no VARCHAR(50) NULL,
    product_id VARCHAR(36) NOT NULL,
    warehouse_id VARCHAR(36) NOT NULL,
    from_location_id VARCHAR(36) NULL,
    to_location_id VARCHAR(36) NULL,
    quantity DECIMAL(18,3) NOT NULL,
    uom VARCHAR(20) NOT NULL,
    batch_no VARCHAR(80) NULL,
    movement_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_by VARCHAR(36) NULL,
    notes TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(36) NULL,
    INDEX idx_move_type (movement_type),
    INDEX idx_move_product (product_id),
    INDEX idx_move_reference (reference_type, reference_id),
    INDEX idx_move_date (movement_at),
    INDEX idx_move_user (processed_by)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

CREATE TABLE IF NOT EXISTS sales_order (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    sales_order_no VARCHAR(50) NOT NULL UNIQUE,
    customer_partner_id VARCHAR(36) NULL,
    order_date DATE NOT NULL,
    requested_delivery_date DATE NULL,
    warehouse_id VARCHAR(36) NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'OPEN',
    notes TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(36) NULL,
    updated_at DATETIME NULL,
    updated_by VARCHAR(36) NULL,
    INDEX idx_so_status (status),
    INDEX idx_so_customer (customer_partner_id),
    INDEX idx_so_date (order_date),
    INDEX idx_so_warehouse (warehouse_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

CREATE TABLE IF NOT EXISTS sales_order_line (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    sales_order_id VARCHAR(36) NOT NULL,
    line_no INT NOT NULL,
    product_id VARCHAR(36) NOT NULL,
    quantity DECIMAL(18,3) NOT NULL,
    allocated_qty DECIMAL(18,3) NOT NULL DEFAULT 0,
    issued_qty DECIMAL(18,3) NOT NULL DEFAULT 0,
    uom VARCHAR(20) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'OPEN',
    notes TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(36) NULL,
    UNIQUE KEY uk_so_line (sales_order_id, line_no),
    INDEX idx_so_line_product (product_id),
    INDEX idx_so_line_status (status),
    CONSTRAINT fk_so_line_header FOREIGN KEY (sales_order_id) REFERENCES sales_order(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

CREATE TABLE IF NOT EXISTS stock_audit_log (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    entity_type VARCHAR(60) NOT NULL,
    entity_id VARCHAR(36) NOT NULL,
    action VARCHAR(60) NOT NULL,
    old_value TEXT NULL,
    new_value TEXT NULL,
    notes TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(36) NULL,
    INDEX idx_audit_entity (entity_type, entity_id),
    INDEX idx_audit_user (created_by),
    INDEX idx_audit_date (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

CREATE TABLE IF NOT EXISTS product_audit_history (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    product_id VARCHAR(36) NOT NULL,
    action VARCHAR(60) NOT NULL,
    old_value TEXT NULL,
    new_value TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(36) NULL,
    INDEX idx_product_audit_product (product_id),
    INDEX idx_product_audit_date (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

INSERT INTO number_range (`current`, `end`, `object`, `prefix`, `start`, `valid_from`, `valid_to`)
SELECT '0000000000', '9999999999', 'GOODS_RECEIPT', 'GRN', '0000000000', CURRENT_DATE, NULL
WHERE NOT EXISTS (SELECT 1 FROM number_range WHERE object = 'GOODS_RECEIPT');

INSERT INTO number_range (`current`, `end`, `object`, `prefix`, `start`, `valid_from`, `valid_to`)
SELECT '0000000000', '9999999999', 'PUTAWAY', 'PUT', '0000000000', CURRENT_DATE, NULL
WHERE NOT EXISTS (SELECT 1 FROM number_range WHERE object = 'PUTAWAY');

INSERT INTO number_range (`current`, `end`, `object`, `prefix`, `start`, `valid_from`, `valid_to`)
SELECT '0000000000', '9999999999', 'STOCK_MOVEMENT', 'STM', '0000000000', CURRENT_DATE, NULL
WHERE NOT EXISTS (SELECT 1 FROM number_range WHERE object = 'STOCK_MOVEMENT');

INSERT INTO number_range (`current`, `end`, `object`, `prefix`, `start`, `valid_from`, `valid_to`)
SELECT '0000000000', '9999999999', 'SALES_ORDER', 'SO', '0000000000', CURRENT_DATE, NULL
WHERE NOT EXISTS (SELECT 1 FROM number_range WHERE object = 'SALES_ORDER');

-- Role tiles for existing active roles.
INSERT INTO role_workcenter (role, workcenter, position)
SELECT r.id, wc.workcenter, COALESCE(max_pos.max_position, 0) + wc.sort_order
FROM role r
JOIN (
    SELECT 'inventory' AS workcenter, 100 AS sort_order UNION ALL
    SELECT 'goods-receipt', 101 UNION ALL
    SELECT 'putaway', 102 UNION ALL
    SELECT 'stock-on-hand', 103 UNION ALL
    SELECT 'sales-order', 104
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
