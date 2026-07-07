/*
  Keeps the stock/goods receipt/putaway/sales order implementation using normal
  business object names, but uses Inventory Management as the umbrella home tile.

  Safe for environments where the earlier stock tile migration was already run.
*/

INSERT INTO role_workcenter (role, workcenter, position)
SELECT rw.role, 'inventory', rw.position
FROM role_workcenter rw
WHERE rw.workcenter = 'stock'
  AND NOT EXISTS (
      SELECT 1
      FROM role_workcenter existing
      WHERE existing.role = rw.role
        AND existing.workcenter = 'inventory'
  );

DELETE FROM role_workcenter
WHERE workcenter = 'stock';

INSERT INTO role_workcenter (role, workcenter, position)
SELECT r.id, 'inventory', 100
FROM role r
WHERE NOT EXISTS (
    SELECT 1
    FROM role_workcenter rw
    WHERE rw.role = r.id
      AND rw.workcenter = 'inventory'
);
