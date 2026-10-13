-- =====================================================================================
-- 04_VDL.sql — View Definition Language
-- Objetivo: definir y administrar vistas basadas en la estructura y datos ya cargados.
-- Incluye: CREATE VIEW, consulta de las vistas y DROP VIEW de ejemplo.
--
-- CÓMO SE EJECUTA:
--   Debe correrse DESPUÉS de 03_DQL.sql, cuando ya se confirmó que los datos base
--   son correctos. Las vistas se apoyan en las tablas prestamo, usuario, libro y multa.
--
-- EJECUCIÓN SEGURA / IDEMPOTENCIA:
--   Ambas vistas se definen con CREATE OR REPLACE VIEW, por lo que ejecutarlo varias
--   veces simplemente vuelve a definir la misma vista sin error. Los SELECT son de
--   sólo lectura y el DROP VIEW usa IF EXISTS (queda comentado por defecto).
-- =====================================================================================

USE `biblioteca`;

-- ---------------------------------------------------------------------------------
-- CREATE VIEW: combina prestamo + usuario + libro en una sola vista de consulta e
-- incluye los días de retraso (0 si el préstamo ya fue devuelto o aún está a tiempo).
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE VIEW `v_prestamos_detalle` AS
SELECT
    p.`prestamo_id`,
    u.`nombre`              AS Usuario,
    u.`tipo_usuario`        AS Tipo_Usuario,
    l.`titulo`              AS Libro,
    p.`fecha_prestamo`,
    p.`fecha_devolucion`    AS Fecha_Limite,
    p.`estado`              AS Estado_Prestamo,
    CASE
        WHEN p.`estado` = 'Pendiente' AND p.`fecha_devolucion` < CURDATE()
            THEN DATEDIFF(CURDATE(), p.`fecha_devolucion`)
        ELSE 0
    END                     AS Dias_Retraso
FROM `prestamo` p
INNER JOIN `usuario` u ON u.`usuario_id` = p.`usuario_id`
INNER JOIN `libro` l   ON l.`libro_id` = p.`libro_id`;

-- ---------------------------------------------------------------------------------
-- SELECT sobre la vista: se consulta exactamente igual que si fuera una tabla.
-- ---------------------------------------------------------------------------------
SELECT * FROM `v_prestamos_detalle` ORDER BY `fecha_prestamo`;

-- ---------------------------------------------------------------------------------
-- CREATE VIEW: multas con el nombre del usuario y el libro que las originó, útil para
-- el área de atención al usuario.
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE VIEW `v_multas_detalle` AS
SELECT
    m.`multa_id`,
    u.`nombre`          AS Usuario,
    l.`titulo`          AS Libro,
    m.`monto`,
    m.`fecha_multa`,
    m.`estado`          AS Estado_Multa,
    m.`motivo`
FROM `multa` m
INNER JOIN `usuario` u  ON u.`usuario_id` = m.`usuario_id`
INNER JOIN `prestamo` p ON p.`prestamo_id` = m.`prestamo_id`
INNER JOIN `libro` l    ON l.`libro_id` = p.`libro_id`;

-- Consulta de verificación de la segunda vista.
SELECT * FROM `v_multas_detalle` ORDER BY `fecha_multa`;

-- ---------------------------------------------------------------------------------
-- DROP VIEW: ejemplo de cómo eliminar una vista si dejara de ser necesaria.
-- Se deja comentado para no borrar las vistas recién creadas al ejecutar el script.
-- ---------------------------------------------------------------------------------
-- DROP VIEW IF EXISTS `v_prestamos_detalle`;
-- DROP VIEW IF EXISTS `v_multas_detalle`;
