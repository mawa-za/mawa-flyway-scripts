/*
  Enable Appointment and Calendar tiles for existing roles.

  The Flutter Home Screen receives tiles from /role/{role}/workcenter.
  The dedicated appointment module already exists, but the appointment/calendar
  workcenters must also be available and assigned to roles before tiles appear.
*/

INSERT INTO role_workcenter (`role`, `workcenter`, `position`)
SELECT
    r.id,
    'calendar',
    COALESCE((
        SELECT MAX(rw.position)
          FROM role_workcenter rw
         WHERE rw.role = r.id
    ), 0) + 1
FROM `role` r
WHERE (r.valid_to IS NULL OR r.valid_to >= CURRENT_DATE)
  AND NOT EXISTS (
      SELECT 1
        FROM role_workcenter existing
       WHERE existing.role = r.id
         AND existing.workcenter = 'calendar'
  );

INSERT INTO role_workcenter (`role`, `workcenter`, `position`)
SELECT
    r.id,
    'appointment',
    COALESCE((
        SELECT MAX(rw.position)
          FROM role_workcenter rw
         WHERE rw.role = r.id
    ), 0) + 1
FROM `role` r
WHERE (r.valid_to IS NULL OR r.valid_to >= CURRENT_DATE)
  AND NOT EXISTS (
      SELECT 1
        FROM role_workcenter existing
       WHERE existing.role = r.id
         AND existing.workcenter = 'appointment'
  );
