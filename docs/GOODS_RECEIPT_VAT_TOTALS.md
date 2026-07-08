# Goods receipt VAT/totals migration

Migration `V202607080003__goods_receipt_vat_totals.sql` adds invoice-style amount fields to goods receipts:

- `goods_receipt.currency`
- `goods_receipt.subtotal_amount`
- `goods_receipt.tax_amount`
- `goods_receipt.total_amount`
- `goods_receipt_line.tax_rate`
- `goods_receipt_line.line_subtotal`
- `goods_receipt_line.line_tax`
- `goods_receipt_line.line_total`

Existing goods receipt lines are backfilled using `unit_cost * quantity` with zero VAT.
