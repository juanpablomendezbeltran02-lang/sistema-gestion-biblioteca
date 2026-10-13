-- =====================================================================================
-- 06_TCL.sql — Transaction Control Language
-- Objetivo: agrupar operaciones relacionadas en transacciones que aseguren la
-- integridad de los datos (COMMIT / ROLLBACK / SAVEPOINT).
-- Ejemplo del negocio: registrar un préstamo y, en la misma transacción, dejar a otro
-- usuario en la cola de espera (reserva) de ese libro, que ya quedó prestado.
--
-- CÓMO SE EJECUTA:
--   Debe correrse AL FINAL, después de 05_DCL.sql, cuando ya existen usuarios y libros
--   disponibles para poder registrar el préstamo de ejemplo.
--
-- EJECUCIÓN SEGURA / IDEMPOTENCIA:
--   Antes de insertar, se verifica en la variable de sesión @ya_existe_tcl si el libro
--   de ejemplo ya tiene un préstamo pendiente; si es así, ambos INSERT se omiten (0
--   filas afectadas, sin error), de modo que repetir el script no acumula préstamos
--   ni choca con el trigger que impide prestar un libro ya prestado. El usuario y el
--   libro se localizan por su llave natural (email e ISBN), no por un ID fijo.
-- =====================================================================================

USE `biblioteca`;

-- Usuario que se lleva el libro: Mateo Vargas. Usuario que queda en la cola: Valentina.
SET @usr_prestamo_tcl = (SELECT `usuario_id` FROM `usuario` WHERE `email` = 'mateo.vargas@example.com');
SET @usr_cola_tcl     = (SELECT `usuario_id` FROM `usuario` WHERE `email` = 'valentina.ruiz@example.com');

-- Libro de ejemplo: "El coronel no tiene quien le escriba".
SET @libro_tcl = (SELECT `libro_id` FROM `libro` WHERE `isbn` = '978-958-00-0003-3');

-- ¿El libro de ejemplo ya tiene un préstamo pendiente? Si es así, no hace falta (ni
-- conviene) volver a registrarlo.
SET @ya_existe_tcl = EXISTS (
    SELECT 1 FROM `prestamo`
    WHERE `libro_id` = @libro_tcl AND `estado` = 'Pendiente'
);

-- ---------------------------------------------------------------------------------
-- START TRANSACTION: abre una transacción para que el préstamo y la reserva se
-- registren de forma atómica; si algo falla, ninguno de los dos cambios queda aplicado.
-- ---------------------------------------------------------------------------------
START TRANSACTION;

-- Registra el préstamo (14 días de plazo) sólo si el libro aún no está prestado. El
-- trigger de la tabla pasa el libro a 'Prestado'.
INSERT INTO `prestamo` (`libro_id`, `usuario_id`, `fecha_prestamo`, `fecha_devolucion`, `estado`)
SELECT @libro_tcl, @usr_prestamo_tcl, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 DAY), 'Pendiente'
FROM DUAL
WHERE NOT @ya_existe_tcl;

-- SAVEPOINT: marca un punto de control después de registrar el préstamo, por si la
-- reserva falla y sólo se necesita deshacer esa parte.
SAVEPOINT `sp_prestamo_creado`;

-- Registra la reserva de Valentina. Sólo es válida porque el libro ya quedó prestado
-- en esta misma transacción (trigger trg_reserva_libro_prestado).
INSERT INTO `reserva` (`libro_id`, `usuario_id`, `fecha_reserva`, `estado`)
SELECT @libro_tcl, @usr_cola_tcl, CURDATE(), 'Activa'
FROM DUAL
WHERE NOT @ya_existe_tcl;

-- ---------------------------------------------------------------------------------
-- ROLLBACK TO SAVEPOINT (ejemplo comentado): si la reserva hubiera fallado, se podría
-- deshacer sólo la reserva y conservar el préstamo con este comando.
-- ---------------------------------------------------------------------------------
-- ROLLBACK TO SAVEPOINT `sp_prestamo_creado`;

-- COMMIT: confirma de manera definitiva el préstamo y la reserva (o no confirma nada
-- nuevo, si ya existían y ambos INSERT se omitieron).
COMMIT;

-- ---------------------------------------------------------------------------------
-- Segundo ejemplo: transacción que se deshace por completo con ROLLBACK, para
-- demostrar cómo se descartan cambios no confirmados. Al terminar siempre en
-- ROLLBACK, no deja ningún efecto persistente y es segura de repetir.
-- ---------------------------------------------------------------------------------
START TRANSACTION;

-- Intento de actualización de prueba que finalmente no se quiere conservar.
UPDATE `usuario`
SET `direccion` = 'Dirección temporal de prueba'
WHERE `email` = 'valentina.ruiz@example.com';

-- ROLLBACK: descarta la actualización anterior; la dirección de Valentina queda
-- exactamente igual a como estaba antes de iniciar esta transacción.
ROLLBACK;
