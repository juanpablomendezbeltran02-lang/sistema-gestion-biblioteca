-- =====================================================================================
-- biblioteca_test.sql — Pruebas de integridad integral del proyecto
-- Autores: Yheriam Noelber Diaz Obando, Johan Stiverson Mendoza Durte,
--          Juan Pablo Mendez Beltran, Juan Camilo Romero
--
-- Verifica que el proyecto completo (estructura, datos, vistas y reglas de negocio)
-- quedó correctamente desplegado en MariaDB. No usa procedimientos almacenados (para
-- funcionar incluso en instalaciones de XAMPP con la tabla de sistema mysql.proc
-- desactualizada). En su lugar, las pruebas que deben fallar se ejecutan como INSERT
-- individuales que MariaDB rechaza por trigger, UNIQUE o CHECK; el script se ejecuta
-- con la bandera --force para poder seguir evaluando después de esos errores
-- esperados, y cada prueba negativa se verifica y se limpia con una consulta posterior.
--
-- CÓMO SE EJECUTA (obligatorio usar --force, ver motivo arriba):
--   Debe correrse DESPUÉS de haber ejecutado, en orden, los ocho scripts descritos en
--   el README (biblioteca.sql, biblioteca_insert.sql y commands/01 a 06).
--
--   mariadb -u root -p -h 127.0.0.1 -P 3306 --default-character-set=utf8mb4 \
--       --force biblioteca < tests/mariadb/biblioteca_test.sql
--
-- El resultado final es una tabla con una fila por prueba (PASS/FAIL) y un resumen
-- con el total de pruebas aprobadas y fallidas.
--
-- EJECUCIÓN SEGURA / IDEMPOTENCIA:
--   Este script puede ejecutarse varias veces seguidas sin dejar residuos: todos los
--   datos de prueba usan fechas del año 2000 o textos 'TEST-...' como marcas, se borran
--   antes de empezar (por si una corrida anterior se interrumpió) y se vuelven a
--   borrar al terminar. La tabla `test_results` es TEMPORARY (vive sólo en la sesión
--   actual) y se elimina explícitamente al terminar.
-- =====================================================================================

USE `biblioteca`;

-- Tabla temporal (vive sólo durante esta sesión) donde se acumulan los resultados.
CREATE TEMPORARY TABLE `test_results` (
    `Test_ID` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `Nombre_Prueba` VARCHAR(150) NOT NULL,
    `Resultado` ENUM('PASS', 'FAIL') NOT NULL,
    `Detalle` VARCHAR(255) NULL,
    PRIMARY KEY (`Test_ID`)
);

-- ---------------------------------------------------------------------------------
-- LIMPIEZA PREVIA: borra restos de una corrida anterior interrumpida y devuelve a
-- 'Disponible' el libro que usan las pruebas de sincronización de estado.
-- ---------------------------------------------------------------------------------
DELETE FROM `multa` WHERE `motivo` LIKE 'TEST-%';
DELETE FROM `reserva` WHERE `fecha_reserva` < '2001-01-01';
DELETE FROM `prestamo` WHERE `fecha_prestamo` < '2001-01-01';
UPDATE `libro` SET `estado` = 'Disponible'
WHERE `isbn` IN ('978-958-00-0002-2', '978-958-00-0008-8')
  AND `estado` IN ('Prestado', 'Perdido')
  AND NOT EXISTS (
      SELECT 1 FROM `prestamo` WHERE `prestamo`.`libro_id` = `libro`.`libro_id` AND `prestamo`.`estado` = 'Pendiente'
  );

-- Variables de sesión: resuelven cada registro de ejemplo por su llave natural.
SET @t_valentina = (SELECT `usuario_id` FROM `usuario` WHERE `email` = 'valentina.ruiz@example.com');
SET @t_camilo    = (SELECT `usuario_id` FROM `usuario` WHERE `email` = 'camilo.herrera@example.com');
SET @t_daniela   = (SELECT `usuario_id` FROM `usuario` WHERE `email` = 'daniela.castro@example.com');
SET @t_isabela   = (SELECT `usuario_id` FROM `usuario` WHERE `email` = 'isabela.moreno@example.com');

SET @t_cien      = (SELECT `libro_id` FROM `libro` WHERE `isbn` = '978-958-00-0001-1');
SET @t_quijote   = (SELECT `libro_id` FROM `libro` WHERE `isbn` = '978-958-00-0002-2');
SET @t_pedro     = (SELECT `libro_id` FROM `libro` WHERE `isbn` = '978-958-00-0004-4');
SET @t_elmasri   = (SELECT `libro_id` FROM `libro` WHERE `isbn` = '978-958-00-0007-7');
SET @t_silber    = (SELECT `libro_id` FROM `libro` WHERE `isbn` = '978-958-00-0008-8');

SET @t_pre_camilo  = (SELECT `prestamo_id` FROM `prestamo`
                      WHERE `libro_id` = @t_elmasri AND `usuario_id` = @t_camilo AND `fecha_prestamo` = '2026-09-10');
SET @t_pre_daniela = (SELECT `prestamo_id` FROM `prestamo`
                      WHERE `libro_id` = @t_pedro AND `usuario_id` = @t_daniela AND `fecha_prestamo` = '2026-10-01');

-- ---------------------------------------------------------------------------------
-- PRUEBA 1: existen las 5 tablas base del modelo.
-- ---------------------------------------------------------------------------------
INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT
    'Existen las 5 tablas base del modelo',
    IF(COUNT(*) = 5, 'PASS', 'FAIL'),
    CONCAT('Tablas encontradas: ', COUNT(*))
FROM `information_schema`.`tables`
WHERE `table_schema` = 'biblioteca' AND `table_type` = 'BASE TABLE';

-- ---------------------------------------------------------------------------------
-- PRUEBA 2: existen las 2 vistas definidas en 04_VDL.sql.
-- ---------------------------------------------------------------------------------
INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT
    'Existen las 2 vistas del proyecto',
    IF(COUNT(*) = 2, 'PASS', 'FAIL'),
    CONCAT('Vistas encontradas: ', COUNT(*))
FROM `information_schema`.`tables`
WHERE `table_schema` = 'biblioteca' AND `table_type` = 'VIEW';

-- ---------------------------------------------------------------------------------
-- PRUEBA 3: existen los 6 triggers de reglas de negocio.
-- ---------------------------------------------------------------------------------
INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT
    'Existen los 6 triggers de reglas de negocio',
    IF(COUNT(*) = 6, 'PASS', 'FAIL'),
    CONCAT('Triggers encontrados: ', COUNT(*))
FROM `information_schema`.`triggers`
WHERE `trigger_schema` = 'biblioteca';

-- ---------------------------------------------------------------------------------
-- PRUEBA 4: cada tabla base tiene al menos un registro cargado (datos de prueba).
-- ---------------------------------------------------------------------------------
INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT 'Tabla usuario tiene datos', IF(COUNT(*) > 0, 'PASS', 'FAIL'), CONCAT('Filas: ', COUNT(*)) FROM `usuario`;
INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT 'Tabla libro tiene datos', IF(COUNT(*) > 0, 'PASS', 'FAIL'), CONCAT('Filas: ', COUNT(*)) FROM `libro`;
INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT 'Tabla prestamo tiene datos', IF(COUNT(*) > 0, 'PASS', 'FAIL'), CONCAT('Filas: ', COUNT(*)) FROM `prestamo`;
INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT 'Tabla reserva tiene datos', IF(COUNT(*) > 0, 'PASS', 'FAIL'), CONCAT('Filas: ', COUNT(*)) FROM `reserva`;
INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT 'Tabla multa tiene datos', IF(COUNT(*) > 0, 'PASS', 'FAIL'), CONCAT('Filas: ', COUNT(*)) FROM `multa`;

-- ---------------------------------------------------------------------------------
-- PRUEBA 5: no existen registros huérfanos (integridad referencial real de los datos,
-- más allá de las restricciones FK que ya lo impedirían).
-- ---------------------------------------------------------------------------------
INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT
    'No hay préstamos huérfanos (sin usuario o libro válido)',
    IF(COUNT(*) = 0, 'PASS', 'FAIL'),
    CONCAT('Huérfanos: ', COUNT(*))
FROM `prestamo` p
LEFT JOIN `usuario` u ON u.`usuario_id` = p.`usuario_id`
LEFT JOIN `libro` l   ON l.`libro_id` = p.`libro_id`
WHERE u.`usuario_id` IS NULL OR l.`libro_id` IS NULL;

INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT
    'No hay multas huérfanas (sin préstamo o usuario válido)',
    IF(COUNT(*) = 0, 'PASS', 'FAIL'),
    CONCAT('Huérfanas: ', COUNT(*))
FROM `multa` m
LEFT JOIN `prestamo` p ON p.`prestamo_id` = m.`prestamo_id`
LEFT JOIN `usuario` u  ON u.`usuario_id` = m.`usuario_id`
WHERE p.`prestamo_id` IS NULL OR u.`usuario_id` IS NULL;

-- ---------------------------------------------------------------------------------
-- PRUEBA 6: ningún libro tiene más de un préstamo pendiente a la vez.
-- ---------------------------------------------------------------------------------
INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT
    'Ningún libro tiene más de un préstamo pendiente',
    IF(COUNT(*) = 0, 'PASS', 'FAIL'),
    CONCAT('Libros con más de un préstamo pendiente: ', COUNT(*))
FROM (
    SELECT `libro_id` FROM `prestamo` WHERE `estado` = 'Pendiente' GROUP BY `libro_id` HAVING COUNT(*) > 1
) AS `duplicados`;

-- ---------------------------------------------------------------------------------
-- PRUEBA 7: el trigger rechaza prestar un libro que ya está prestado.
-- "Pedro Páramo" tiene un préstamo pendiente (Daniela); el INSERT siguiente debe
-- fallar (por eso se requiere --force).
-- ---------------------------------------------------------------------------------
INSERT INTO `prestamo` (`libro_id`, `usuario_id`, `fecha_prestamo`, `fecha_devolucion`, `estado`)
VALUES (@t_pedro, @t_valentina, '2000-01-01', '2000-01-15', 'Pendiente');

INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT
    'Trigger: no se puede prestar un libro ya prestado',
    IF(COUNT(*) = 0, 'PASS', 'FAIL'),
    IF(COUNT(*) = 0, 'El INSERT fue rechazado correctamente', 'El INSERT no fue rechazado')
FROM `prestamo` WHERE `fecha_prestamo` = '2000-01-01';

DELETE FROM `prestamo` WHERE `fecha_prestamo` = '2000-01-01';

-- ---------------------------------------------------------------------------------
-- PRUEBA 8: el trigger rechaza préstamos a un usuario con la cuenta suspendida.
-- Isabela está 'Suspendido'; "Cien años de soledad" está disponible.
-- ---------------------------------------------------------------------------------
INSERT INTO `prestamo` (`libro_id`, `usuario_id`, `fecha_prestamo`, `fecha_devolucion`, `estado`)
VALUES (@t_cien, @t_isabela, '2000-01-02', '2000-01-16', 'Pendiente');

INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT
    'Trigger: un usuario suspendido no puede tomar libros',
    IF(COUNT(*) = 0, 'PASS', 'FAIL'),
    IF(COUNT(*) = 0, 'El INSERT fue rechazado correctamente', 'El INSERT no fue rechazado')
FROM `prestamo` WHERE `fecha_prestamo` = '2000-01-02';

DELETE FROM `prestamo` WHERE `fecha_prestamo` = '2000-01-02';

-- ---------------------------------------------------------------------------------
-- PRUEBA 9: el trigger rechaza prestar un libro marcado como 'Perdido'.
-- Se marca temporalmente un libro como perdido y se restaura al terminar la prueba.
-- ---------------------------------------------------------------------------------
UPDATE `libro` SET `estado` = 'Perdido' WHERE `libro_id` = @t_silber;

INSERT INTO `prestamo` (`libro_id`, `usuario_id`, `fecha_prestamo`, `fecha_devolucion`, `estado`)
VALUES (@t_silber, @t_valentina, '2000-01-03', '2000-01-17', 'Pendiente');

INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT
    'Trigger: no se puede prestar un libro perdido o en mantenimiento',
    IF(COUNT(*) = 0, 'PASS', 'FAIL'),
    IF(COUNT(*) = 0, 'El INSERT fue rechazado correctamente', 'El INSERT no fue rechazado')
FROM `prestamo` WHERE `fecha_prestamo` = '2000-01-03';

DELETE FROM `prestamo` WHERE `fecha_prestamo` = '2000-01-03';
UPDATE `libro` SET `estado` = 'Disponible' WHERE `libro_id` = @t_silber;

-- ---------------------------------------------------------------------------------
-- PRUEBA 10: el CHECK de prestamo rechaza una fecha límite anterior a la de préstamo.
-- (estado 'Devuelto' para no activar la validación de disponibilidad del trigger).
-- ---------------------------------------------------------------------------------
INSERT INTO `prestamo` (`libro_id`, `usuario_id`, `fecha_prestamo`, `fecha_devolucion`, `estado`)
VALUES (@t_quijote, @t_valentina, '2000-01-10', '2000-01-01', 'Devuelto');

INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT
    'CHECK: fecha_devolucion no puede ser anterior a fecha_prestamo',
    IF(COUNT(*) = 0, 'PASS', 'FAIL'),
    IF(COUNT(*) = 0, 'El INSERT fue rechazado correctamente', 'El INSERT no fue rechazado')
FROM `prestamo` WHERE `fecha_prestamo` = '2000-01-10';

DELETE FROM `prestamo` WHERE `fecha_prestamo` = '2000-01-10';

-- ---------------------------------------------------------------------------------
-- PRUEBA 11: los triggers mantienen sincronizado libro.estado con los préstamos.
-- Se presta "Don Quijote" (debe pasar a 'Prestado'), se devuelve (debe volver a
-- 'Disponible') y se borra el préstamo de prueba.
-- ---------------------------------------------------------------------------------
INSERT INTO `prestamo` (`libro_id`, `usuario_id`, `fecha_prestamo`, `fecha_devolucion`, `estado`)
VALUES (@t_quijote, @t_valentina, '2000-02-01', '2000-02-15', 'Pendiente');

INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT
    'Trigger: al crear un préstamo pendiente el libro pasa a Prestado',
    IF(`estado` = 'Prestado', 'PASS', 'FAIL'),
    CONCAT('Estado del libro: ', `estado`)
FROM `libro` WHERE `libro_id` = @t_quijote;

UPDATE `prestamo` SET `estado` = 'Devuelto' WHERE `fecha_prestamo` = '2000-02-01';

INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT
    'Trigger: al devolver el préstamo el libro vuelve a Disponible',
    IF(`estado` = 'Disponible', 'PASS', 'FAIL'),
    CONCAT('Estado del libro: ', `estado`)
FROM `libro` WHERE `libro_id` = @t_quijote;

DELETE FROM `prestamo` WHERE `fecha_prestamo` = '2000-02-01';

-- ---------------------------------------------------------------------------------
-- PRUEBA 12: el trigger rechaza reservar un libro que no está prestado.
-- "Cien años de soledad" está disponible, así que no se puede reservar.
-- ---------------------------------------------------------------------------------
INSERT INTO `reserva` (`libro_id`, `usuario_id`, `fecha_reserva`, `estado`)
VALUES (@t_cien, @t_valentina, '2000-01-04', 'Activa');

INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT
    'Trigger: no se puede reservar un libro que no está prestado',
    IF(COUNT(*) = 0, 'PASS', 'FAIL'),
    IF(COUNT(*) = 0, 'El INSERT fue rechazado correctamente', 'El INSERT no fue rechazado')
FROM `reserva` WHERE `fecha_reserva` = '2000-01-04';

DELETE FROM `reserva` WHERE `fecha_reserva` = '2000-01-04';

-- ---------------------------------------------------------------------------------
-- PRUEBA 13: un préstamo no puede tener dos multas (UNIQUE sobre prestamo_id).
-- El préstamo de Camilo ya tiene una multa; el segundo INSERT debe ser rechazado.
-- ---------------------------------------------------------------------------------
INSERT INTO `multa` (`prestamo_id`, `usuario_id`, `monto`, `fecha_multa`, `estado`, `motivo`)
VALUES (@t_pre_camilo, @t_camilo, 1000.00, '2026-09-26', 'Pendiente', 'TEST-DUPLICADA');

INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT
    'UNIQUE: un préstamo genera como máximo una multa',
    IF(COUNT(*) = 0, 'PASS', 'FAIL'),
    IF(COUNT(*) = 0, 'El INSERT fue rechazado correctamente', 'El INSERT no fue rechazado')
FROM `multa` WHERE `motivo` = 'TEST-DUPLICADA';

DELETE FROM `multa` WHERE `motivo` = 'TEST-DUPLICADA';

-- ---------------------------------------------------------------------------------
-- PRUEBA 14: el trigger rechaza una multa a un usuario distinto del dueño del préstamo.
-- El préstamo de Daniela no tiene multa; se intenta multarlo a nombre de Camilo.
-- ---------------------------------------------------------------------------------
INSERT INTO `multa` (`prestamo_id`, `usuario_id`, `monto`, `fecha_multa`, `estado`, `motivo`)
VALUES (@t_pre_daniela, @t_camilo, 1000.00, '2099-01-01', 'Pendiente', 'TEST-USUARIO');

INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT
    'Trigger: la multa debe pertenecer al usuario del préstamo',
    IF(COUNT(*) = 0, 'PASS', 'FAIL'),
    IF(COUNT(*) = 0, 'El INSERT fue rechazado correctamente', 'El INSERT no fue rechazado')
FROM `multa` WHERE `motivo` = 'TEST-USUARIO';

DELETE FROM `multa` WHERE `motivo` = 'TEST-USUARIO';

-- ---------------------------------------------------------------------------------
-- PRUEBA 15: el trigger rechaza una multa fechada antes de que venza el préstamo.
-- ---------------------------------------------------------------------------------
INSERT INTO `multa` (`prestamo_id`, `usuario_id`, `monto`, `fecha_multa`, `estado`, `motivo`)
VALUES (@t_pre_daniela, @t_daniela, 1000.00, '2000-01-01', 'Pendiente', 'TEST-FECHA');

INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT
    'Trigger: la multa solo aplica con la fecha de devolución superada',
    IF(COUNT(*) = 0, 'PASS', 'FAIL'),
    IF(COUNT(*) = 0, 'El INSERT fue rechazado correctamente', 'El INSERT no fue rechazado')
FROM `multa` WHERE `motivo` = 'TEST-FECHA';

DELETE FROM `multa` WHERE `motivo` = 'TEST-FECHA';

-- ---------------------------------------------------------------------------------
-- PRUEBA 16: el CHECK de multa rechaza un monto negativo.
-- ---------------------------------------------------------------------------------
INSERT INTO `multa` (`prestamo_id`, `usuario_id`, `monto`, `fecha_multa`, `estado`, `motivo`)
VALUES (@t_pre_daniela, @t_daniela, -1.00, '2099-01-01', 'Pendiente', 'TEST-MONTO');

INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT
    'CHECK: el monto de una multa no puede ser negativo',
    IF(COUNT(*) = 0, 'PASS', 'FAIL'),
    IF(COUNT(*) = 0, 'El INSERT fue rechazado correctamente', 'El INSERT no fue rechazado')
FROM `multa` WHERE `motivo` = 'TEST-MONTO';

DELETE FROM `multa` WHERE `motivo` = 'TEST-MONTO';

-- ---------------------------------------------------------------------------------
-- PRUEBA 17: las vistas devuelven datos consistentes con las tablas base.
-- ---------------------------------------------------------------------------------
INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT
    'La vista v_prestamos_detalle devuelve el mismo total que prestamo',
    IF((SELECT COUNT(*) FROM `v_prestamos_detalle`) = (SELECT COUNT(*) FROM `prestamo`), 'PASS', 'FAIL'),
    CONCAT('Vista: ', (SELECT COUNT(*) FROM `v_prestamos_detalle`), ' / Tabla: ', (SELECT COUNT(*) FROM `prestamo`));

INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT
    'La vista v_multas_detalle devuelve el mismo total que multa',
    IF((SELECT COUNT(*) FROM `v_multas_detalle`) = (SELECT COUNT(*) FROM `multa`), 'PASS', 'FAIL'),
    CONCAT('Vista: ', (SELECT COUNT(*) FROM `v_multas_detalle`), ' / Tabla: ', (SELECT COUNT(*) FROM `multa`));

-- ---------------------------------------------------------------------------------
-- PRUEBA 18: los usuarios creados en 05_DCL.sql existen con los permisos esperados.
-- ---------------------------------------------------------------------------------
INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT
    'Usuario biblioteca_reportes tiene sólo permiso SELECT',
    IF(
        SUM(`PRIVILEGE_TYPE` = 'SELECT') = 1 AND SUM(`PRIVILEGE_TYPE` IN ('INSERT', 'UPDATE', 'DELETE')) = 0,
        'PASS', 'FAIL'
    ),
    CONCAT('Privilegios encontrados: ', COALESCE(GROUP_CONCAT(`PRIVILEGE_TYPE` SEPARATOR ', '), 'ninguno'))
FROM `information_schema`.`SCHEMA_PRIVILEGES`
WHERE `GRANTEE` = "'biblioteca_reportes'@'localhost'" AND `TABLE_SCHEMA` = 'biblioteca';

INSERT INTO `test_results` (`Nombre_Prueba`, `Resultado`, `Detalle`)
SELECT
    'Usuario biblioteca_mostrador no tiene permiso DELETE',
    IF(COUNT(*) > 0 AND SUM(`PRIVILEGE_TYPE` = 'DELETE') = 0, 'PASS', 'FAIL'),
    CONCAT('Privilegios encontrados: ', COALESCE(GROUP_CONCAT(`PRIVILEGE_TYPE` SEPARATOR ', '), 'ninguno'))
FROM `information_schema`.`SCHEMA_PRIVILEGES`
WHERE `GRANTEE` = "'biblioteca_mostrador'@'localhost'" AND `TABLE_SCHEMA` = 'biblioteca';

-- ---------------------------------------------------------------------------------
-- LIMPIEZA FINAL: deja la base exactamente como estaba antes de las pruebas.
-- ---------------------------------------------------------------------------------
DELETE FROM `multa` WHERE `motivo` LIKE 'TEST-%';
DELETE FROM `reserva` WHERE `fecha_reserva` < '2001-01-01';
DELETE FROM `prestamo` WHERE `fecha_prestamo` < '2001-01-01';

-- ---------------------------------------------------------------------------------
-- RESULTADO: detalle de cada prueba y resumen final de aprobadas/fallidas.
-- ---------------------------------------------------------------------------------
SELECT * FROM `test_results` ORDER BY `Test_ID`;

SELECT
    COUNT(*)                                                        AS Total_Pruebas,
    SUM(`Resultado` = 'PASS')                                       AS Aprobadas,
    SUM(`Resultado` = 'FAIL')                                       AS Fallidas,
    IF(SUM(`Resultado` = 'FAIL') = 0, 'PROYECTO OK', 'REVISAR FALLAS') AS Veredicto
FROM `test_results`;

DROP TEMPORARY TABLE `test_results`;
