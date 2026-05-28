DROP TABLE IF EXISTS case_billing_item;
DROP TABLE IF EXISTS case_time_entry;
DROP TABLE IF EXISTS case_disbursement;
DROP TABLE IF EXISTS case_task;
DROP TABLE IF EXISTS case_event;
DROP TABLE IF EXISTS case_note;
DROP TABLE IF EXISTS case_party;
DROP TABLE IF EXISTS legal_case;

CREATE TABLE legal_case (
    id                      VARCHAR(255) NOT NULL PRIMARY KEY,

    case_no                 VARCHAR(80) NOT NULL UNIQUE,
    title                   VARCHAR(255) NOT NULL,

    client_partner_id       VARCHAR(255) NOT NULL,

    case_type               VARCHAR(80) NOT NULL,
    -- CIVIL, CRIMINAL, FAMILY, LABOUR, PROPERTY, COMMERCIAL, ESTATE, OTHER

    case_category           VARCHAR(120) NULL,
    -- Divorce, Eviction, Debt Collection, Contract Review, CCMA, etc.

    description             TEXT NULL,

    status                  VARCHAR(50) NOT NULL DEFAULT 'OPEN',
    -- OPEN, IN_PROGRESS, ON_HOLD, SETTLED, CLOSED, CANCELLED

    priority                VARCHAR(30) NOT NULL DEFAULT 'NORMAL',
    -- LOW, NORMAL, HIGH, URGENT

    assigned_to             VARCHAR(255) NULL,
    -- User responsible for the matter

    opened_date             DATE NOT NULL,
    closed_date             DATE NULL,

    court_name              VARCHAR(255) NULL,
    court_case_no           VARCHAR(100) NULL,
    forum_type              VARCHAR(80) NULL,
    -- COURT, CCMA, BARGAINING_COUNCIL, ARBITRATION, TRIBUNAL, INTERNAL, OTHER

    next_appearance_date    DATETIME NULL,

    billing_type            VARCHAR(50) NOT NULL DEFAULT 'HOURLY',
    -- HOURLY, FIXED_FEE, CONTINGENCY, PRO_BONO

    hourly_rate_cents       BIGINT NULL,
    fixed_fee_cents         BIGINT NULL,

    currency                VARCHAR(10) NOT NULL DEFAULT 'ZAR',

    billable                BOOLEAN NOT NULL DEFAULT TRUE,

    total_time_minutes      BIGINT NOT NULL DEFAULT 0,
    total_fees_cents        BIGINT NOT NULL DEFAULT 0,
    total_disbursements_cents BIGINT NOT NULL DEFAULT 0,
    total_billable_cents    BIGINT NOT NULL DEFAULT 0,
    total_billed_cents      BIGINT NOT NULL DEFAULT 0,
    balance_cents           BIGINT NOT NULL DEFAULT 0,

    created_at              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by              VARCHAR(255) NULL,
    updated_at              DATETIME NULL,
    updated_by              VARCHAR(255) NULL,

    INDEX idx_legal_case_client (client_partner_id),
    INDEX idx_legal_case_status (status),
    INDEX idx_legal_case_assigned_to (assigned_to),
    INDEX idx_legal_case_opened_date (opened_date)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3
COLLATE = utf8mb3_general_ci;


CREATE TABLE case_party (
    id                  VARCHAR(255) NOT NULL PRIMARY KEY,

    case_id             VARCHAR(255) NOT NULL,
    partner_id          VARCHAR(255) NULL,

    party_name          VARCHAR(255) NOT NULL,
    party_type          VARCHAR(80) NOT NULL,
    -- CLIENT, APPLICANT, RESPONDENT, PLAINTIFF, DEFENDANT, WITNESS,
    -- OPPOSING_ATTORNEY, ADVOCATE, EXPERT, OTHER

    id_number           VARCHAR(50) NULL,
    email               VARCHAR(150) NULL,
    phone_number        VARCHAR(50) NULL,

    attorney_firm       VARCHAR(255) NULL,
    attorney_name       VARCHAR(255) NULL,

    notes               TEXT NULL,

    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(255) NULL,

    CONSTRAINT fk_case_party_case
        FOREIGN KEY (case_id) REFERENCES legal_case(id)
        ON DELETE CASCADE,

    INDEX idx_case_party_case (case_id),
    INDEX idx_case_party_partner (partner_id),
    INDEX idx_case_party_type (party_type)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3
COLLATE = utf8mb3_general_ci;


CREATE TABLE case_note (
    id                  VARCHAR(255) NOT NULL PRIMARY KEY,

    case_id             VARCHAR(255) NOT NULL,

    note_type           VARCHAR(80) NOT NULL DEFAULT 'GENERAL',
    -- GENERAL, CONSULTATION, COURT_NOTE, TELEPHONE, EMAIL, INTERNAL

    title               VARCHAR(255) NULL,
    note                TEXT NOT NULL,

    private_note        BOOLEAN NOT NULL DEFAULT FALSE,

    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(255) NULL,

    CONSTRAINT fk_case_note_case
        FOREIGN KEY (case_id) REFERENCES legal_case(id)
        ON DELETE CASCADE,

    INDEX idx_case_note_case (case_id),
    INDEX idx_case_note_created_at (created_at)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3
COLLATE = utf8mb3_general_ci;


CREATE TABLE case_event (
    id                  VARCHAR(255) NOT NULL PRIMARY KEY,

    case_id             VARCHAR(255) NOT NULL,

    event_type          VARCHAR(80) NOT NULL,
    -- CONSULTATION, HEARING, TRIAL, MEETING, CALL, DEADLINE, FILING, OTHER

    title               VARCHAR(255) NOT NULL,
    description         TEXT NULL,

    start_at            DATETIME NOT NULL,
    end_at              DATETIME NULL,

    location            VARCHAR(255) NULL,

    reminder_at         DATETIME NULL,

    status              VARCHAR(50) NOT NULL DEFAULT 'SCHEDULED',
    -- SCHEDULED, COMPLETED, CANCELLED, POSTPONED

    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(255) NULL,
    updated_at          DATETIME NULL,
    updated_by          VARCHAR(255) NULL,

    CONSTRAINT fk_case_event_case
        FOREIGN KEY (case_id) REFERENCES legal_case(id)
        ON DELETE CASCADE,

    INDEX idx_case_event_case (case_id),
    INDEX idx_case_event_start_at (start_at),
    INDEX idx_case_event_status (status)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3
COLLATE = utf8mb3_general_ci;


CREATE TABLE case_task (
    id                  VARCHAR(255) NOT NULL PRIMARY KEY,

    case_id             VARCHAR(255) NOT NULL,

    title               VARCHAR(255) NOT NULL,
    description         TEXT NULL,

    assigned_to         VARCHAR(255) NULL,

    priority            VARCHAR(30) NOT NULL DEFAULT 'NORMAL',
    -- LOW, NORMAL, HIGH, URGENT

    status              VARCHAR(50) NOT NULL DEFAULT 'TODO',
    -- TODO, IN_PROGRESS, WAITING, COMPLETED, CANCELLED

    due_date            DATETIME NULL,
    completed_at        DATETIME NULL,
    completed_by        VARCHAR(255) NULL,

    billable            BOOLEAN NOT NULL DEFAULT FALSE,
    estimated_minutes   BIGINT NULL,

    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(255) NULL,
    updated_at          DATETIME NULL,
    updated_by          VARCHAR(255) NULL,

    CONSTRAINT fk_case_task_case
        FOREIGN KEY (case_id) REFERENCES legal_case(id)
        ON DELETE CASCADE,

    INDEX idx_case_task_case (case_id),
    INDEX idx_case_task_assigned_to (assigned_to),
    INDEX idx_case_task_status (status),
    INDEX idx_case_task_due_date (due_date)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3
COLLATE = utf8mb3_general_ci;


CREATE TABLE case_time_entry (
    id                  VARCHAR(255) NOT NULL PRIMARY KEY,

    case_id             VARCHAR(255) NOT NULL,
    task_id             VARCHAR(255) NULL,

    entry_date          DATE NOT NULL,

    user_id             VARCHAR(255) NOT NULL,

    description         TEXT NOT NULL,

    minutes             BIGINT NOT NULL,

    hourly_rate_cents   BIGINT NOT NULL,
    amount_cents        BIGINT NOT NULL,

    billable            BOOLEAN NOT NULL DEFAULT TRUE,
    billed              BOOLEAN NOT NULL DEFAULT FALSE,

    invoice_id          VARCHAR(255) NULL,

    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(255) NULL,

    CONSTRAINT fk_case_time_entry_case
        FOREIGN KEY (case_id) REFERENCES legal_case(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_case_time_entry_task
        FOREIGN KEY (task_id) REFERENCES case_task(id)
        ON DELETE SET NULL,

    INDEX idx_case_time_entry_case (case_id),
    INDEX idx_case_time_entry_task (task_id),
    INDEX idx_case_time_entry_user (user_id),
    INDEX idx_case_time_entry_billed (billed),
    INDEX idx_case_time_entry_entry_date (entry_date)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3
COLLATE = utf8mb3_general_ci;


CREATE TABLE case_disbursement (
    id                  VARCHAR(255) NOT NULL PRIMARY KEY,

    case_id             VARCHAR(255) NOT NULL,

    disbursement_date   DATE NOT NULL,

    disbursement_type   VARCHAR(80) NOT NULL,
    -- SHERIFF, COURT_FEE, TRAVEL, PRINTING, POSTAGE, ADVOCATE, EXPERT, OTHER

    description         TEXT NOT NULL,

    amount_cents        BIGINT NOT NULL,

    billable            BOOLEAN NOT NULL DEFAULT TRUE,
    billed              BOOLEAN NOT NULL DEFAULT FALSE,

    invoice_id          VARCHAR(255) NULL,

    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(255) NULL,

    CONSTRAINT fk_case_disbursement_case
        FOREIGN KEY (case_id) REFERENCES legal_case(id)
        ON DELETE CASCADE,

    INDEX idx_case_disbursement_case (case_id),
    INDEX idx_case_disbursement_billed (billed),
    INDEX idx_case_disbursement_date (disbursement_date)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3
COLLATE = utf8mb3_general_ci;


CREATE TABLE case_billing_item (
    id                  VARCHAR(255) NOT NULL PRIMARY KEY,

    case_id             VARCHAR(255) NOT NULL,

    source_type         VARCHAR(80) NOT NULL,
    -- TIME_ENTRY, DISBURSEMENT, FIXED_FEE, MANUAL

    source_id           VARCHAR(255) NULL,

    description         TEXT NOT NULL,

    quantity            DECIMAL(18,2) NOT NULL DEFAULT 1,
    unit_price_cents    BIGINT NOT NULL DEFAULT 0,
    amount_cents        BIGINT NOT NULL,

    billable            BOOLEAN NOT NULL DEFAULT TRUE,
    billed              BOOLEAN NOT NULL DEFAULT FALSE,

    invoice_id          VARCHAR(255) NULL,

    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(255) NULL,

    CONSTRAINT fk_case_billing_item_case
        FOREIGN KEY (case_id) REFERENCES legal_case(id)
        ON DELETE CASCADE,

    INDEX idx_case_billing_item_case (case_id),
    INDEX idx_case_billing_item_billed (billed),
    INDEX idx_case_billing_item_source (source_type, source_id)
)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3
COLLATE = utf8mb3_general_ci;