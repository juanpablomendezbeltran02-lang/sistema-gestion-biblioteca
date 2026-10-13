-- =====================================================================================
-- 02_DML.sql — Data Manipulation Language
-- Objetivo: manipular los datos ya cargados en la base de datos de la Biblioteca.
-- Incluye: INSERT (nuevo usuario y nueva reserva), UPDATE (cambio de estado de un
-- libro, renovación de un préstamo y actualización de un teléfono) y DELETE
-- (eliminación de una reserva).
--
-- CÓMO SE EJECUTA:
--   Debe correrse DESPUÉS de biblioteca_insert.sql (los datos de ejemplo ya deben
--   existir) y de 01_DDL.sql (la columna `observaciones` de `prestamo` ya debe existir).
--
-- EJECUCIÓN SEGURA / IDEMPOTENCIA:
--   Ninguna sentencia usa IDs numéricos fijos: los registros se localizan por su
--   llave natural (email del usuario, ISBN del libro). El INSERT de usuario usa IGNORE
--   (email es UNIQUE); el INSERT de reserva se protege con WHERE NOT EXISTS (la tabla
--   tiene un trigger con SIGNAL que IGNORE no suprime); y los UPDATE/DELETE son
--   naturalmente idempotentes: repetirlos no cambia el resultado ni genera error.
-- =====================================================================================

USE `biblioteca`;

-- ---------------------------------------------------------------------------------
-- INSERT: registra un nuevo usuario (profesor) en la biblioteca.
-- ---------------------------------------------------------------------------------
INSERT IGNORE INTO `usuario` (`nombre`, `tipo_usuario`, `direccion`, `telefono`, `email`, `fecha_registro`, `estado`)
VALUES ('Sofía Ramírez', 'Profesor', 'Calle 50 # 20-30', '3011122334', 'sofia.ramirez@example.com', '2026-10-05', 'Activo');

-- ---------------------------------------------------------------------------------
-- INSERT: Sofía reserva "Pedro Páramo", que está prestado a otro usuario. Se localiza
-- todo por llave natural (email e ISBN) y se protege con WHERE NOT EXISTS.
-- ---------------------------------------------------------------------------------
INSERT INTO `reserva` (`libro_id`, `usuario_id`, `fecha_reserva`, `estado`)
SELECT
    (SELECT `libro_id` FROM `libro` WHERE `isbn` = '978-958-00-0004-4'),
    (SELECT `usuario_id` FROM `usuario` WHERE `email` = 'sofia.ramirez@example.com'),
    '2026-10-06', 'Activa'
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM `reserva`
    WHERE `libro_id` = (SELECT `libro_id` FROM `libro` WHERE `isbn` = '978-958-00-0004-4')
      AND `usuario_id` = (SELECT `usuario_id` FROM `usuario` WHERE `email` = 'sofia.ramirez@example.com')
      AND `fecha_reserva` = '2026-10-06'
);

-- ---------------------------------------------------------------------------------
-- UPDATE: manda "La vorágine" a mantenimiento (por ejemplo, por daños en la
-- encuadernación). Mientras esté en 'Mantenimiento', el trigger de préstamos no
-- permite prestarlo. Repetir este UPDATE deja el mismo valor, sin error.
-- ---------------------------------------------------------------------------------
UPDATE `libro`
SET `estado` = 'Mantenimiento'
WHERE `isbn` = '978-958-00-0006-6' AND `estado` = 'Disponible';

-- ---------------------------------------------------------------------------------
-- UPDATE: renueva el préstamo de Daniela (amplía la fecha límite una semana) y deja
-- una observación; usa la columna `observaciones` agregada en 01_DDL.sql. Se usa una
-- fecha absoluta (no "+ 7 días") para que repetirlo no vuelva a mover la fecha.
-- El libro y el usuario se resuelven antes en variables, para que el UPDATE sólo lea
-- la tabla `prestamo` (los triggers de esa tabla modifican `libro`, y MariaDB no
-- permite modificar dentro de un trigger una tabla que la sentencia ya está leyendo).
-- ---------------------------------------------------------------------------------
SET @dml_libro_pedro   = (SELECT `libro_id` FROM `libro` WHERE `isbn` = '978-958-00-0004-4');
SET @dml_usr_daniela   = (SELECT `usuario_id` FROM `usuario` WHERE `email` = 'daniela.castro@example.com');

UPDATE `prestamo`
SET `fecha_devolucion` = '2026-10-22',
    `observaciones` = 'Préstamo renovado una vez por una semana.'
WHERE `libro_id` = @dml_libro_pedro
  AND `usuario_id` = @dml_usr_daniela
  AND `fecha_prestamo` = '2026-10-01';

-- ---------------------------------------------------------------------------------
-- UPDATE: actualiza el teléfono de un usuario que cambió de número.
-- ---------------------------------------------------------------------------------
UPDATE `usuario`
SET `telefono` = '3109998877'
WHERE `email` = 'valentina.ruiz@example.com';

-- ---------------------------------------------------------------------------------
-- DELETE: elimina la reserva de Valentina sobre "Pedro Páramo", ingresada por error.
-- Eliminar una fila que ya no existe no genera error: repetir este DELETE en una
-- segunda corrida simplemente no afecta ninguna fila.
-- ---------------------------------------------------------------------------------
DELETE FROM `reserva`
WHERE `libro_id` = (SELECT `libro_id` FROM `libro` WHERE `isbn` = '978-958-00-0004-4')
  AND `usuario_id` = (SELECT `usuario_id` FROM `usuario` WHERE `email` = 'valentina.ruiz@example.com')
  AND `fecha_reserva` = '2026-10-03';
