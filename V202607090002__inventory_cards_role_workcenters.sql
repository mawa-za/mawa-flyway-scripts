/*
  Inventory card workcenter configuration.

  Inventory Management is now a card/workcenter-driven screen. These workcenters
  control which cards appear inside the Inventory Management frontend screen.
  The inserts are additive and can still be removed per role from role workcenter
  configuration if a role should not see a card.
*/

INSERT INTO role_workcenter (role, workcenter, position)
SELECT r.id, wc.workcenter, COALESCE(max_pos.max_position, 0) + wc.sort_order
FROM role r
JOIN (
    SELECT 'stock-movement' AS workcenter, 108 AS sort_order UNION ALL
    SELECT 'inventory-audit', 109 UNION ALL
    SELECT 'inventory-setup', 110
) wc
LEFT JOIN (
    SELECT role, MAX(position) AS max_position
    FROM role_workcenter
    GROUP BY role
) max_pos
  ON max_pos.role = r.id
LEFT JOIN role_workcenter existing
  ON existing.role = r.id
 AND existing.workcenter = wc.workcenter
WHERE existing.role IS NULL;
