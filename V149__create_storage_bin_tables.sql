CREATE TABLE storage_bin (
    bin_id          VARCHAR(60) NOT NULL,  -- unique identifier
    warehouse_id    VARCHAR(60) NOT NULL,                    -- link to warehouse
    description     VARCHAR(255),                    -- optional description
    aisle           VARCHAR(10) NOT NULL,            -- aisle reference
    rack            VARCHAR(10) NOT NULL,            -- rack reference
    shelf           VARCHAR(10) NOT NULL,                    -- level/shelf number
    bin_code        VARCHAR(50) UNIQUE NOT NULL,     -- human-readable code like A1-R2-L3-BIN5
    bin_type        VARCHAR(20),                     -- e.g., 'PICK', 'STORAGE', 'RETURN'
    capacity        DECIMAL(10,2),                   -- max weight/volume allowed
    unit_of_measure VARCHAR(10) DEFAULT 'KG',        -- unit for capacity
    status          VARCHAR(20) DEFAULT 'AVAILABLE', -- AVAILABLE, BLOCKED, RESERVED
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    published       BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (bin_id)
);

CREATE TABLE product_storage_bin (
    bin_id    VARCHAR(60) NOT NULL,
    product_id  VARCHAR(60) NOT NULL,
    min_qty     DECIMAL(10,2) DEFAULT 0,   -- trigger for replenishment
    max_qty     DECIMAL(10,2) DEFAULT 0,   -- max stock allowed
    PRIMARY KEY (bin_id, product_id)
);

INSERT INTO `settings` (`attribute`, `setting`, `value`) VALUES ('AISLE-COUNT', 'WAREHOUSE-LAYOUT', '10');
INSERT INTO `settings` (`attribute`, `setting`, `value`) VALUES ('AISLE-RACK-COUNT', 'WAREHOUSE-LAYOUT', '20');
INSERT INTO `settings` (`attribute`, `setting`, `value`) VALUES ('AISLE-SHELF-COUNT', 'WAREHOUSE-LAYOUT', '7');