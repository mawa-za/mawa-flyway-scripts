-- User-controlled scheduler defaults.
-- These defaults remove dependency on hardcoded cron/timer values while keeping jobs safe on first startup.

INSERT INTO `settings` (`attribute`, `setting`, `value`)
SELECT 'ENABLED', 'MESSAGE-QUEUE', 'true'
WHERE NOT EXISTS (SELECT 1 FROM `settings` WHERE `attribute` = 'ENABLED' AND `setting` = 'MESSAGE-QUEUE');

INSERT INTO `settings` (`attribute`, `setting`, `value`)
SELECT 'INTERVAL-SECONDS', 'MESSAGE-QUEUE', '60'
WHERE NOT EXISTS (SELECT 1 FROM `settings` WHERE `attribute` = 'INTERVAL-SECONDS' AND `setting` = 'MESSAGE-QUEUE');

INSERT INTO `settings` (`attribute`, `setting`, `value`)
SELECT 'BATCH-SIZE', 'MESSAGE-QUEUE', '10'
WHERE NOT EXISTS (SELECT 1 FROM `settings` WHERE `attribute` = 'BATCH-SIZE' AND `setting` = 'MESSAGE-QUEUE');

INSERT INTO `settings` (`attribute`, `setting`, `value`)
SELECT 'RETRY-DELAY-SECONDS', 'MESSAGE-QUEUE', '10'
WHERE NOT EXISTS (SELECT 1 FROM `settings` WHERE `attribute` = 'RETRY-DELAY-SECONDS' AND `setting` = 'MESSAGE-QUEUE');

INSERT INTO `settings` (`attribute`, `setting`, `value`)
SELECT 'ENABLED', 'LEGACY-MIGRATION', 'false'
WHERE NOT EXISTS (SELECT 1 FROM `settings` WHERE `attribute` = 'ENABLED' AND `setting` = 'LEGACY-MIGRATION');

INSERT INTO `settings` (`attribute`, `setting`, `value`)
SELECT 'INTERVAL-MINUTES', 'LEGACY-MIGRATION', '1440'
WHERE NOT EXISTS (SELECT 1 FROM `settings` WHERE `attribute` = 'INTERVAL-MINUTES' AND `setting` = 'LEGACY-MIGRATION');
