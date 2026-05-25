INSERT INTO number_sequence (seq_type, next_no)
VALUES ('PAYMENT_BATCH', 1000000001)
ON DUPLICATE KEY UPDATE next_no = next_no;

DROP TABLE IF EXISTS api_endpoint_log;

CREATE TABLE api_endpoint_log (
    id                  VARCHAR(255) NOT NULL PRIMARY KEY,

    request_id          VARCHAR(100) NULL,

    user_id             VARCHAR(255) NULL,
    username            VARCHAR(255) NULL,

    method              VARCHAR(20) NOT NULL,
    endpoint            VARCHAR(500) NOT NULL,
    query_string        TEXT NULL,

    status_code         INT NULL,

    request_ip          VARCHAR(100) NULL,
    user_agent          TEXT NULL,

    request_body        LONGTEXT NULL,
    response_body       LONGTEXT NULL,

    duration_ms         BIGINT NULL,

    success             BOOLEAN NOT NULL DEFAULT TRUE,
    error_message       TEXT NULL,

    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_api_endpoint_log_created_at (created_at),
    INDEX idx_api_endpoint_log_endpoint (endpoint),
    INDEX idx_api_endpoint_log_user_id (user_id),
    INDEX idx_api_endpoint_log_status_code (status_code),
    INDEX idx_api_endpoint_log_success (success)

) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;