CREATE TABLE IF NOT EXISTS appointment (
    id VARCHAR(36) NOT NULL,
    appointment_no VARCHAR(50) NOT NULL,
    customer_partner_id VARCHAR(36) NOT NULL,
    employee_partner_id VARCHAR(36) NULL,
    responsible_user_id VARCHAR(36) NULL,
    service_product_id VARCHAR(36) NULL,
    appointment_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NULL,
    duration_minutes INT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'BOOKED',
    location VARCHAR(255) NULL,
    notes TEXT NULL,
    source_type VARCHAR(50) NULL,
    source_id VARCHAR(36) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    created_by VARCHAR(36) NULL,
    updated_at DATETIME(6) NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    updated_by VARCHAR(36) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_appointment_no (appointment_no),
    KEY idx_appointment_date_status (appointment_date, status),
    KEY idx_appointment_customer (customer_partner_id),
    KEY idx_appointment_employee (employee_partner_id),
    KEY idx_appointment_product (service_product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS appointment_status_history (
    id VARCHAR(36) NOT NULL,
    appointment_id VARCHAR(36) NOT NULL,
    old_status VARCHAR(30) NULL,
    new_status VARCHAR(30) NOT NULL,
    reason TEXT NULL,
    changed_by VARCHAR(36) NULL,
    changed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY idx_appointment_status_history_appt (appointment_id),
    CONSTRAINT fk_appointment_status_history_appt FOREIGN KEY (appointment_id) REFERENCES appointment(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS appointment_participant (
    id VARCHAR(36) NOT NULL,
    appointment_id VARCHAR(36) NOT NULL,
    partner_id VARCHAR(36) NULL,
    user_id VARCHAR(36) NULL,
    participant_type VARCHAR(50) NOT NULL,
    display_name VARCHAR(255) NULL,
    contact_number VARCHAR(50) NULL,
    email VARCHAR(255) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY idx_appointment_participant_appt (appointment_id),
    KEY idx_appointment_participant_partner (partner_id),
    KEY idx_appointment_participant_user (user_id),
    CONSTRAINT fk_appointment_participant_appt FOREIGN KEY (appointment_id) REFERENCES appointment(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS appointment_reminder (
    id VARCHAR(36) NOT NULL,
    appointment_id VARCHAR(36) NOT NULL,
    reminder_type VARCHAR(30) NOT NULL,
    reminder_at DATETIME(6) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    sent_at DATETIME(6) NULL,
    failure_reason TEXT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY idx_appointment_reminder_appt (appointment_id),
    KEY idx_appointment_reminder_due (status, reminder_at),
    CONSTRAINT fk_appointment_reminder_appt FOREIGN KEY (appointment_id) REFERENCES appointment(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO appointment (
    id,
    appointment_no,
    customer_partner_id,
    employee_partner_id,
    service_product_id,
    appointment_date,
    start_time,
    status,
    source_type,
    source_id,
    created_at,
    created_by,
    updated_at,
    updated_by
)
SELECT
    t.id,
    COALESCE(NULLIF(t.no, ''), NULLIF(t.number, ''), CONCAT('APT-', t.id)) AS appointment_no,
    customer.partner AS customer_partner_id,
    employee.partner AS employee_partner_id,
    item.product AS service_product_id,
    DATE(booking_date.value) AS appointment_date,
    TIME(booking_date.value) AS start_time,
    COALESCE(NULLIF(t.status, ''), 'BOOKED') AS status,
    'LEGACY_TRANSACTION' AS source_type,
    t.id AS source_id,
    COALESCE(booking_date.value, NOW(6)) AS created_at,
    t.created_by,
    NOW(6) AS updated_at,
    t.changed_by
FROM `transaction` t
JOIN transaction_date booking_date
    ON booking_date.transaction = t.id
   AND booking_date.type IN ('BOOKING-DATE', 'BOOKING_DATE')
JOIN transaction_partner customer
    ON customer.transaction = t.id
   AND customer.partner_function = 'CUSTOMER'
LEFT JOIN transaction_partner employee
    ON employee.transaction = t.id
   AND employee.partner_function IN ('EMPLOYEE-RESPONSIBLE', 'PERSON-RESPONSIBLE')
LEFT JOIN transaction_item item
    ON item.transaction = t.id
WHERE t.type = 'APPOINTMENT'
  AND NOT EXISTS (SELECT 1 FROM appointment a WHERE a.id = t.id);

INSERT INTO appointment_status_history (id, appointment_id, old_status, new_status, reason, changed_by, changed_at)
SELECT UUID(), a.id, NULL, a.status, 'Migrated from legacy transaction appointment', a.created_by, a.created_at
FROM appointment a
WHERE a.source_type = 'LEGACY_TRANSACTION'
  AND NOT EXISTS (SELECT 1 FROM appointment_status_history h WHERE h.appointment_id = a.id);
