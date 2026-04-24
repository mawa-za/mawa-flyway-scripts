CREATE TABLE IF NOT EXISTS number_sequence (
  id  BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  seq_type VARCHAR(64) NOT NULL UNIQUE,
  next_no  BIGINT NOT NULL
);

INSERT INTO number_sequence (id, seq_type, next_no)
VALUES (1, 'CASHUP', 1000000001)
ON DUPLICATE KEY UPDATE next_no = next_no;

-- Ensure row exists
INSERT INTO number_sequence (id, seq_type, next_no)
VALUES (1, 'RECEIPT', 1)
ON DUPLICATE KEY UPDATE next_no = next_no;

INSERT INTO number_sequence (id, seq_type, next_no)
VALUES (1, 'MEMBERSHIP', 1000000001)
ON DUPLICATE KEY UPDATE next_no = next_no;

INSERT INTO number_sequence (id, seq_type, next_no)
VALUES (1, 'PARTNER', 1000000001)
ON DUPLICATE KEY UPDATE next_no = next_no;

CREATE TABLE IF NOT EXISTS number_range_allocation (
  id            BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  device_id     VARCHAR(128) NOT NULL,
  from_no       BIGINT NOT NULL,
  to_no         BIGINT NOT NULL,
  next_no       BIGINT NOT NULL,
  status        VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',
  allocated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  UNIQUE KEY uk_device_active (device_id, status),
  KEY idx_device (device_id),
  KEY idx_range (from_no, to_no)
);