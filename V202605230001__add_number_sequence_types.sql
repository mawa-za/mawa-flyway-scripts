INSERT INTO number_sequence (id, seq_type, next_no)
VALUES (1, 'PAYMENT_BATCH', 1000000001)
ON DUPLICATE KEY UPDATE next_no = next_no;
