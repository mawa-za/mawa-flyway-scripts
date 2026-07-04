-- Make the post-device cashup stage explicit.
-- MAWAPay closure means the cashup is ready for ERP deposit capture, not approval submission.

UPDATE cashup
SET status = 'AWAITING_DEPOSITS'
WHERE status IN ('COMPLETED', 'SUBMITTED', 'DEPOSIT_PENDING')
  AND (approval_request_id IS NULL OR approval_request_id = '');

ALTER TABLE cashup
  MODIFY COLUMN status VARCHAR(30) NOT NULL DEFAULT 'AWAITING_DEPOSITS';
