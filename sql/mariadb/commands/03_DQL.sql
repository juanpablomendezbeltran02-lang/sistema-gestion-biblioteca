-- =====================================================================================
-- 03_DQL.sql — Data Query Language
-- Objetivo: consultar los datos ya cargados para verificar que todo esté correcto.
-- Incluye: SELECT con condiciones, JOIN entre tablas y GROUP BY con conteos y sumas.
--
-- CÓMO SE EJECUTA:
--   Debe correrse DESPUÉS de 02_DML.sql, ya que consulta datos y columnas generados
--   en los scripts previos.
--
-- EJECUCIÓN SEGURA / IDEMPOTENCIA:
--   Todas las sentencias son SELECT de sólo lectura: no modifican datos, por lo que
--   ejecutar este script una o cien veces seguidas siempre produce el mismo
--   resultado (salvo las consultas que usan CURDATE(), que dependen del día actual).
-- =====================================================================================

USE `biblioteca`;

-- ---------------------------------------------------------------------------------
-- SELECT con condición: libros disponibles para prestar (estado 'Disponible').
-- ---------------------------------------------------------------------------------
SELECT
    l.`libro_id`,
    l.`titulo`,
    l.`autor`,
    l.`categoria`
FROM `libro` l
WHERE l.`estado` = 'Disponible'
ORDER BY l.`titulo`;

-- ---------------------------------------------------------------------------------
-- JOIN: préstamos pendientes de devolución, combinando prestamo + usuario + libro.
-- ---------------------------------------------------------------------------------
SELECT
    p.`prestamo_id`,
    u.`nombre`            AS Usuario,
    l.`titulo`            AS Libro,
    p.`fecha_prestamo`,
    p.`fecha_devolucion`  AS Fecha_Limite
FROM `prestamo` p
INNER JOIN `usuario` u ON u.`usuario_id` = p.`usuario_id`
INNER JOIN `libro` l   ON l.`libro_id` = p.`libro_id`
WHERE p.`estado` = 'Pendiente'
ORDER BY p.`fecha_devolucion`;

-- ---------------------------------------------------------------------------------
-- JOIN con subconsulta: préstamos vencidos (fecha límite superada y aún pendientes)
-- que todavía NO tienen una multa registrada; son los candidatos a multar.
-- ---------------------------------------------------------------------------------
SELECT
    p.`prestamo_id`,
    u.`nombre`                                  AS Usuario,
    l.`titulo`                                  AS Libro,
    p.`fecha_devolucion`                        AS Fecha_Limite,
    DATEDIFF(CURDATE(), p.`fecha_devolucion`)   AS Dias_Retraso
FROM `prestamo` p
INNER JOIN `usuario` u ON u.`usuario_id` = p.`usuario_id`
INNER JOIN `libro` l   ON l.`libro_id` = p.`libro_id`
WHERE p.`estado` = 'Pendiente'
  AND p.`fecha_devolucion` < CURDATE()
  AND NOT EXISTS (SELECT 1 FROM `multa` m WHERE m.`prestamo_id` = p.`prestamo_id`);

-- ---------------------------------------------------------------------------------
-- GROUP BY: cuenta cuántos libros hay registrados por cada categoría.
-- ---------------------------------------------------------------------------------
SELECT
    l.`categoria`   AS Categoria,
    COUNT(*)        AS Total_Libros
FROM `libro` l
GROUP BY l.`categoria`
ORDER BY Total_Libros DESC;

-- ---------------------------------------------------------------------------------
-- GROUP BY: cuenta cuántos libros hay en cada estado (disponible, prestado, etc.).
-- ---------------------------------------------------------------------------------
SELECT
    l.`estado`      AS Estado,
    COUNT(*)        AS Total_Libros
FROM `libro` l
GROUP BY l.`estado`;

-- ---------------------------------------------------------------------------------
-- GROUP BY con suma: total de multas pendientes de pago por usuario (los usuarios sin
-- multas pendientes aparecen con 0 gracias al LEFT JOIN).
-- ---------------------------------------------------------------------------------
SELECT
    u.`nombre`                              AS Usuario,
    COALESCE(SUM(m.`monto`), 0)             AS Total_Multas_Pendientes
FROM `usuario` u
LEFT JOIN `multa` m ON m.`usuario_id` = u.`usuario_id` AND m.`estado` = 'Pendiente'
GROUP BY u.`usuario_id`, u.`nombre`
ORDER BY Total_Multas_Pendientes DESC;

-- ---------------------------------------------------------------------------------
-- GROUP BY: cola de espera, es decir, cuántas reservas activas tiene cada libro.
-- ---------------------------------------------------------------------------------
SELECT
    l.`titulo`      AS Libro,
    COUNT(*)        AS Reservas_Activas
FROM `reserva` r
INNER JOIN `libro` l ON l.`libro_id` = r.`libro_id`
WHERE r.`estado` = 'Activa'
GROUP BY l.`libro_id`, l.`titulo`
ORDER BY Reservas_Activas DESC;
