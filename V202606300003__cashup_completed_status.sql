-- Device-submitted cashups should remain editable in ERP for deposit capture.
-- Older MAWAPay builds used SUBMITTED to mean "cashier completed/closed the device cashup".
-- ERP uses SUBMITTED for the later approval workflow step, after deposits have been captured.
UPDATE cashup
SET status = 'COMPLETED'
WHERE status = 'SUBMITTED'
  AND (approval_request_id IS NULL OR approval_request_id = '');
