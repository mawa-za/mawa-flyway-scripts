CREATE TABLE IF NOT EXISTS invoice (
    id                  CHAR(36) NOT NULL PRIMARY KEY,

    invoice_no          VARCHAR(50) NOT NULL,
    external_ref        VARCHAR(100),

    partner_id          CHAR(36) NOT NULL,

    invoice_date        DATE NOT NULL,
    due_date            DATE,

    status              VARCHAR(30) NOT NULL DEFAULT 'DRAFT',

    subtotal_cents      BIGINT NOT NULL DEFAULT 0,
    tax_cents           BIGINT NOT NULL DEFAULT 0,
    discount_cents      BIGINT NOT NULL DEFAULT 0,
    total_cents         BIGINT NOT NULL DEFAULT 0,
    paid_cents          BIGINT NOT NULL DEFAULT 0,
    balance_cents       BIGINT NOT NULL DEFAULT 0,

    currency            VARCHAR(10) NOT NULL DEFAULT 'ZAR',

    notes               TEXT,

    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          CHAR(36),
    updated_at          DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    updated_by          CHAR(36),

    UNIQUE KEY uq_invoice_no (invoice_no),
    INDEX idx_invoice_partner (partner_id),
    INDEX idx_invoice_status (status),
    INDEX idx_invoice_date (invoice_date),
    INDEX idx_invoice_due_date (due_date)
);

CREATE TABLE IF NOT EXISTS invoice_line (
    id                  CHAR(36) NOT NULL PRIMARY KEY,

    invoice_id          CHAR(36) NOT NULL,

    product_id          CHAR(36),
    description         VARCHAR(255) NOT NULL,

    quantity            DECIMAL(15,3) NOT NULL DEFAULT 1.000,
    unit_price_cents    BIGINT NOT NULL DEFAULT 0,

    discount_cents      BIGINT NOT NULL DEFAULT 0,
    tax_cents           BIGINT NOT NULL DEFAULT 0,
    subtotal_cents      BIGINT NOT NULL DEFAULT 0,
    total_cents         BIGINT NOT NULL DEFAULT 0,

    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_invoice_line_invoice
        FOREIGN KEY (invoice_id) REFERENCES invoice(id)
        ON DELETE CASCADE,

    INDEX idx_invoice_line_invoice (invoice_id),
    INDEX idx_invoice_line_product (product_id)
);

CREATE TABLE IF NOT EXISTS invoice_payment (
    id                  CHAR(36) NOT NULL PRIMARY KEY,

    invoice_id          CHAR(36) NOT NULL,

    payment_date        DATETIME NOT NULL,
    amount_cents        BIGINT NOT NULL,

    payment_method      VARCHAR(50),
    reference_no        VARCHAR(100),

    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          CHAR(36),

    CONSTRAINT fk_invoice_payment_invoice
        FOREIGN KEY (invoice_id) REFERENCES invoice(id)
        ON DELETE CASCADE,

    INDEX idx_invoice_payment_invoice (invoice_id),
    INDEX idx_invoice_payment_date (payment_date)
);