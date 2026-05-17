ALTER TABLE payment_request
    ADD COLUMN IF NOT EXISTS status VARCHAR(30) NOT NULL DEFAULT 'DRAFT',
    ADD COLUMN IF NOT EXISTS approved_by VARCHAR(36) NULL,
    ADD COLUMN IF NOT EXISTS approved_at DATETIME NULL,
    ADD COLUMN IF NOT EXISTS queued_for_payment_by VARCHAR(36) NULL,
    ADD COLUMN IF NOT EXISTS queued_for_payment_at DATETIME NULL,
    ADD COLUMN IF NOT EXISTS paid_by VARCHAR(36) NULL,
    ADD COLUMN IF NOT EXISTS paid_at DATETIME NULL,
    ADD COLUMN IF NOT EXISTS failed_at DATETIME NULL,
    ADD COLUMN IF NOT EXISTS failure_reason TEXT NULL,
    ADD COLUMN IF NOT EXISTS bank_message_reference VARCHAR(255) NULL,
    ADD COLUMN IF NOT EXISTS updated_by VARCHAR(36) NULL,
    ADD COLUMN IF NOT EXISTS updated_at DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_payment_request_status
    ON payment_request (status);

CREATE INDEX IF NOT EXISTS idx_payment_request_approved_at
    ON payment_request (approved_at);

CREATE INDEX IF NOT EXISTS idx_payment_request_queued_for_payment_at
    ON payment_request (queued_for_payment_at);

CREATE INDEX IF NOT EXISTS idx_payment_request_paid_at
    ON payment_request (paid_at);

CREATE INDEX IF NOT EXISTS idx_payment_request_bank_message_reference
    ON payment_request (bank_message_reference);


ALTER TABLE message_queue
    ADD COLUMN IF NOT EXISTS reference_id VARCHAR(255) NULL,
    ADD COLUMN IF NOT EXISTS reference_no VARCHAR(100) NULL;

CREATE INDEX IF NOT EXISTS idx_message_queue_reference_id
    ON message_queue (reference_id);

CREATE UNIQUE INDEX IF NOT EXISTS uq_message_queue_type_reference
    ON message_queue (type, reference_id);