DROP TABLE IF EXISTS approval_action;
DROP TABLE IF EXISTS approval_request;
DROP TABLE IF EXISTS approval_workflow_step_approver;
DROP TABLE IF EXISTS approval_workflow_step;
DROP TABLE IF EXISTS approval_workflow;

CREATE TABLE approval_workflow (
    id                  VARCHAR(255) NOT NULL PRIMARY KEY,

    approval_type       VARCHAR(80) NOT NULL,
    -- CLAIM, PAYMENT, PAYMENT_REQUEST, LEAVE, CASHUP, INVOICE, etc.

    name                VARCHAR(150) NOT NULL,
    description         TEXT,

    min_amount          DECIMAL(18,2) NULL,
    max_amount          DECIMAL(18,2) NULL,

    active              BOOLEAN NOT NULL DEFAULT TRUE,

    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(255),
    updated_at          DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    updated_by          VARCHAR(255),

    UNIQUE KEY uq_approval_workflow_type (approval_type),
    INDEX idx_approval_workflow_active (active),
    INDEX idx_approval_workflow_type_active (approval_type, active)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3
COLLATE = utf8mb3_general_ci;


CREATE TABLE approval_workflow_step (
    id                  VARCHAR(255) NOT NULL PRIMARY KEY,

    workflow_id         VARCHAR(255) NOT NULL,

    step_no             INT NOT NULL,
    step_name           VARCHAR(150) NOT NULL,

    approval_mode       VARCHAR(50) NOT NULL DEFAULT 'ANY_ONE',
    -- ANY_ONE, ALL

    required_approvals  INT NOT NULL DEFAULT 1,
    -- useful where a step requires 2 approvers from a role/group

    active              BOOLEAN NOT NULL DEFAULT TRUE,

    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(255),
    updated_at          DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    updated_by          VARCHAR(255),

    CONSTRAINT fk_approval_step_workflow
        FOREIGN KEY (workflow_id) REFERENCES approval_workflow(id),

    UNIQUE KEY uq_workflow_step_no (workflow_id, step_no),
    INDEX idx_workflow_step_workflow (workflow_id),
    INDEX idx_workflow_step_active (active)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3
COLLATE = utf8mb3_general_ci;


CREATE TABLE approval_workflow_step_approver (
    id                  VARCHAR(255) NOT NULL PRIMARY KEY,

    workflow_step_id    VARCHAR(255) NOT NULL,

    approver_type       VARCHAR(50) NOT NULL,
    -- USER, ROLE, GROUP, MANAGER

    approver_value      VARCHAR(255) NOT NULL,
    -- user id, role code, group id, MANAGER, etc.

    approver_name       VARCHAR(255) NULL,

    active              BOOLEAN NOT NULL DEFAULT TRUE,

    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(255),
    updated_at          DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    updated_by          VARCHAR(255),

    CONSTRAINT fk_approval_step_approver_step
        FOREIGN KEY (workflow_step_id) REFERENCES approval_workflow_step(id),

    INDEX idx_approval_step_approver_step (workflow_step_id),
    INDEX idx_approval_step_approver_lookup (approver_type, approver_value),
    INDEX idx_approval_step_approver_active (active)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3
COLLATE = utf8mb3_general_ci;


CREATE TABLE approval_request (
    id                  VARCHAR(255) NOT NULL PRIMARY KEY,

    approval_type       VARCHAR(80) NOT NULL,
    reference_id        VARCHAR(255) NOT NULL,
    -- claim id, payment request id, leave id, etc.

    reference_no        VARCHAR(100),
    -- human-readable claim number/payment number/leave ref

    title               VARCHAR(255) NOT NULL,
    description         TEXT,

    requester_id        VARCHAR(255) NOT NULL,

    workflow_id         VARCHAR(255) NOT NULL,

    current_step_no     INT NOT NULL DEFAULT 1,

    status              VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    -- PENDING, IN_PROGRESS, APPROVED, REJECTED, CANCELLED

    payload_json        JSON NULL,
    -- snapshot for frontend display only

    final_action_by     VARCHAR(255),
    final_action_at     DATETIME,

    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(255),
    updated_at          DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    updated_by          VARCHAR(255),

    CONSTRAINT fk_approval_request_workflow
        FOREIGN KEY (workflow_id) REFERENCES approval_workflow(id),

    UNIQUE KEY uq_approval_reference (approval_type, reference_id),
    INDEX idx_approval_request_status (status),
    INDEX idx_approval_request_type (approval_type),
    INDEX idx_approval_request_reference (reference_id),
    INDEX idx_approval_request_current_step (current_step_no)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3
COLLATE = utf8mb3_general_ci;


CREATE TABLE approval_action (
    id                  VARCHAR(255) NOT NULL PRIMARY KEY,

    approval_request_id VARCHAR(255) NOT NULL,

    step_no             INT NOT NULL,

    action              VARCHAR(50) NOT NULL,
    -- SUBMITTED, APPROVED, REJECTED, CANCELLED, COMMENTED

    action_by           VARCHAR(255) NOT NULL,
    action_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    comments            TEXT,

    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(255),

    CONSTRAINT fk_approval_action_request
        FOREIGN KEY (approval_request_id) REFERENCES approval_request(id),

    INDEX idx_approval_action_request (approval_request_id),
    INDEX idx_approval_action_step (step_no),
    INDEX idx_approval_action_by (action_by)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3
COLLATE = utf8mb3_general_ci;