# Procurement, Sales and Inventory V2 Migration

Apply `V202607080001__procurement_sales_quotation_po_inventory_extensions.sql` after the existing stock migration `V202607070003__stock_goods_receipt_putaway_sales_order_module.sql`.

The migration is designed to be additive. It creates dedicated quotation and purchase order tables, extends goods receipt and sales order tables, and adds number ranges/workcenters required by the new ERP inventory screens.
