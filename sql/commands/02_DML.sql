-- 02_DML.sql - Data Manipulation Language (manipular los datos)
-- INSERT, UPDATE y DELETE.
-- Ejecutar después de 01_DDL.sql.

USE biblioteca;

-- INSERT: nuevo usuario (si ya existe, no lo repite)
INSERT IGNORE INTO usuario (nombre, tipo_usuario, direccion, telefono, email, fecha_registro, estado)
VALUES ('Sofía Ramírez', 'Profesor', 'Calle 50 # 20-30', '3011122334', 'sofia.ramirez@example.com', '2026-10-05', 'Activo');

-- INSERT: Sofía reserva "Pedro Páramo" (libro 4, que está prestado)
INSERT IGNORE INTO reserva (libro_id, usuario_id, fecha_reserva, estado)
VALUES (4, (SELECT usuario_id FROM usuario WHERE email = 'sofia.ramirez@example.com'), '2026-10-06', 'Activa');

-- UPDATE: cambia el teléfono de Valentina
UPDATE usuario SET telefono = '3109998877' WHERE email = 'valentina.ruiz@example.com';

-- UPDATE: renueva el préstamo 3 (Daniela) hasta el 22 de octubre
UPDATE prestamo SET fecha_devolucion = '2026-10-22' WHERE prestamo_id = 3;

-- UPDATE: manda "La vorágine" (libro 6) a mantenimiento
UPDATE libro SET estado = 'Mantenimiento' WHERE libro_id = 6 AND estado = 'Disponible';

-- DELETE: borra la reserva de Sofía
DELETE FROM reserva
WHERE libro_id = 4 AND usuario_id = (SELECT usuario_id FROM usuario WHERE email = 'sofia.ramirez@example.com');
