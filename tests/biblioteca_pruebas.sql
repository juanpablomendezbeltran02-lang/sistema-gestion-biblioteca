-- biblioteca_pruebas.sql - Pruebas básicas
-- Ejecutar después de todos los scripts. Solo lee datos.

USE biblioteca;

-- 1. Cuántas filas tiene cada tabla (ninguna debe estar en 0)
SELECT 'usuario' AS tabla, COUNT(*) AS filas FROM usuario
UNION ALL SELECT 'libro',    COUNT(*) FROM libro
UNION ALL SELECT 'prestamo', COUNT(*) FROM prestamo
UNION ALL SELECT 'reserva',  COUNT(*) FROM reserva
UNION ALL SELECT 'multa',    COUNT(*) FROM multa;

-- 2. Préstamos sin usuario o sin libro (debe dar 0)
SELECT COUNT(*) AS prestamos_huerfanos
FROM prestamo p
LEFT JOIN usuario u ON u.usuario_id = p.usuario_id
LEFT JOIN libro l   ON l.libro_id = p.libro_id
WHERE u.usuario_id IS NULL OR l.libro_id IS NULL;

-- 3. Libros con más de un préstamo pendiente (debe dar 0)
SELECT COUNT(*) AS libros_prestados_dos_veces
FROM (SELECT libro_id FROM prestamo WHERE estado = 'Pendiente' GROUP BY libro_id HAVING COUNT(*) > 1) AS t;

-- 4. Libros "Prestado" sin préstamo pendiente (debe dar 0)
SELECT COUNT(*) AS libros_mal_marcados
FROM libro
WHERE estado = 'Prestado'
  AND libro_id NOT IN (SELECT libro_id FROM prestamo WHERE estado = 'Pendiente');

-- 5. Las vistas existen y devuelven filas
SELECT COUNT(*) AS filas_v_prestamos_detalle FROM v_prestamos_detalle;
SELECT COUNT(*) AS filas_v_multas_detalle    FROM v_multas_detalle;

-- =====================================================
-- 6. Pruebas de las reglas: cada una DEBE DAR ERROR.
-- Quita los "-- " de UNA sola línea, ejecútala en la pestaña SQL y mira el mensaje.
-- =====================================================

-- Libro ya prestado (el libro 4 está prestado a Daniela):
-- INSERT INTO prestamo (libro_id, usuario_id, fecha_prestamo, fecha_devolucion) VALUES (4, 1, CURDATE(), CURDATE());

-- Usuario suspendido (Isabela es el usuario 5):
-- INSERT INTO prestamo (libro_id, usuario_id, fecha_prestamo, fecha_devolucion) VALUES (2, 5, CURDATE(), CURDATE());

-- Reservar un libro que no está prestado (el libro 1 está disponible):
-- INSERT INTO reserva (libro_id, usuario_id, fecha_reserva) VALUES (1, 1, CURDATE());

-- Fecha límite anterior a la fecha de préstamo:
-- INSERT INTO prestamo (libro_id, usuario_id, fecha_prestamo, fecha_devolucion, estado) VALUES (2, 1, '2026-10-10', '2026-10-01', 'Devuelto');

-- Dos multas para el mismo préstamo (el préstamo 2 ya tiene una):
-- INSERT INTO multa (prestamo_id, usuario_id, monto, fecha_multa, motivo) VALUES (2, 2, 1000, CURDATE(), 'Prueba');
