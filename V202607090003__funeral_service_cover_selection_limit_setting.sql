/*
  Funeral service cover selection limit.

  MAX-SELECTED-COVERS controls how many membership covers may be selected on a
  single funeral service/arrangement. Value 0 means unlimited, preserving the
  legacy behaviour until each tenant chooses a limit.
*/

INSERT INTO `settings` (`attribute`, `setting`, `value`)
SELECT 'MAX-SELECTED-COVERS', 'FUNERAL-SERVICE', '0'
WHERE NOT EXISTS (
    SELECT 1
      FROM `settings`
     WHERE `attribute` = 'MAX-SELECTED-COVERS'
       AND `setting` = 'FUNERAL-SERVICE'
);
