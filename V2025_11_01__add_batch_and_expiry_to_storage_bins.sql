ALTER TABLE storage_bin
  ADD COLUMN IF NOT EXISTS batch_number VARCHAR(64) NULL AFTER description,
  ADD COLUMN IF NOT EXISTS expiry_date  DATE NULL      AFTER batch_number;