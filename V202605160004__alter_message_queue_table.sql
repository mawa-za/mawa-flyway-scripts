ALTER TABLE payment_request
    ADD COLUMN approved_by VARCHAR(36) NULL;

ALTER TABLE payment_request
    ADD COLUMN approved_at DATETIME NULL;

ALTER TABLE payment_request
    ADD COLUMN queued_for_payment_at DATETIME NULL;

ALTER TABLE payment_request
    ADD COLUMN queued_for_payment_by VARCHAR(36) NULL;

ALTER TABLE payment_request
    ADD COLUMN paid_at DATETIME NULL;

ALTER TABLE payment_request
    ADD COLUMN failed_at DATETIME NULL;

ALTER TABLE payment_request
    ADD COLUMN failure_reason TEXT NULL;

ALTER TABLE payment_request
    ADD COLUMN bank_message_reference VARCHAR(255) NULL;



CREATE INDEX idx_payment_request_approved_at
    ON payment_request (approved_at);

CREATE INDEX idx_payment_request_queued_for_payment_at
    ON payment_request (queued_for_payment_at);

CREATE INDEX idx_payment_request_paid_at
    ON payment_request (paid_at);

CREATE INDEX idx_payment_request_bank_message_reference
    ON payment_request (bank_message_reference);


ALTER TABLE message_queue
    ADD COLUMN reference_id VARCHAR(255) NULL;

ALTER TABLE message_queue
    ADD COLUMN reference_no VARCHAR(100) NULL;

CREATE INDEX idx_message_queue_reference_id
    ON message_queue (reference_id);

CREATE UNIQUE INDEX uq_message_queue_type_reference
    ON message_queue (message_type, reference_id);