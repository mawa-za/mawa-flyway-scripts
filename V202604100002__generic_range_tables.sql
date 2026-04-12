ALTER TABLE number_range_allocation
ADD COLUMN sequence_no INT NOT NULL DEFAULT 1 AFTER next_no;

CREATE INDEX idx_device_sequence 
ON number_range_allocation (device_id, sequence_no);