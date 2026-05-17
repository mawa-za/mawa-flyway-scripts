CREATE TABLE IF NOT EXISTS module_usage_event (
    id              VARCHAR(255) NOT NULL PRIMARY KEY,

    user_id         VARCHAR(255) NOT NULL,

    module_code     VARCHAR(100) NOT NULL,
    module_name     VARCHAR(150) NULL,
    module_path     VARCHAR(255) NULL,
    workcenter_id   VARCHAR(255) NULL,

    used_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by      VARCHAR(255) NULL,

    INDEX idx_module_usage_event_user_id (user_id),
    INDEX idx_module_usage_event_module_code (module_code),
    INDEX idx_module_usage_event_used_at (used_at),
    INDEX idx_module_usage_event_user_used_at (user_id, used_at)
)
ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;

CREATE TABLE IF NOT EXISTS user_module_usage (
    id                  VARCHAR(255) NOT NULL PRIMARY KEY,

    user_id             VARCHAR(255) NOT NULL,

    module_code         VARCHAR(100) NOT NULL,
    module_name         VARCHAR(150) NULL,
    module_path         VARCHAR(255) NULL,
    workcenter_id       VARCHAR(255) NULL,

    usage_count         BIGINT NOT NULL DEFAULT 0,
    first_used_at       DATETIME NULL,
    last_used_at        DATETIME NULL,

    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(255) NULL,
    updated_at          DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    updated_by          VARCHAR(255) NULL,

    UNIQUE KEY uq_user_module_usage_user_module (user_id, module_code),

    INDEX idx_user_module_usage_user_id (user_id),
    INDEX idx_user_module_usage_module_code (module_code),
    INDEX idx_user_module_usage_usage_count (usage_count),
    INDEX idx_user_module_usage_last_used_at (last_used_at)
)ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb3
  COLLATE = utf8mb3_general_ci;
