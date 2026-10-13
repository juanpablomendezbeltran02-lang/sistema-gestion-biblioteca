-- 03_DQL.sql - Data Query Language (consultar datos)
-- SELECT, JOIN y GROUP BY. Solo lee datos, no modifica nada.

USE biblioteca;

-- Libros disponibles para prestar
SELECT libro_id, titulo, autor
FROM libro
WHERE estado = 'Disponible'
ORDER BY titulo;

-- Préstamos pendientes (JOIN de prestamo, usuario y libro)
SELECT p.prestamo_id, u.nombre AS usuario, l.titulo AS libro, p.fecha_prestamo, p.fecha_devolucion AS fecha_limite
FROM prestamo p
INNER JOIN usuario u ON u.usuario_id = p.usuario_id
INNER JOIN libro l   ON l.libro_id = p.libro_id
WHERE p.estado = 'Pendiente'
ORDER BY p.fecha_devolucion;

-- Préstamos vencidos que todavía no tienen multa
SELECT p.prestamo_id, u.nombre AS usuario, l.titulo AS libro, p.fecha_devolucion AS fecha_limite
FROM prestamo p
INNER JOIN usuario u ON u.usuario_id = p.usuario_id
INNER JOIN libro l   ON l.libro_id = p.libro_id
WHERE p.estado = 'Pendiente'
  AND p.fecha_devolucion < CURDATE()
  AND p.prestamo_id NOT IN (SELECT prestamo_id FROM multa);

-- GROUP BY: cuántos libros hay por categoría
SELECT categoria, COUNT(*) AS total_libros
FROM libro
GROUP BY categoria;

-- GROUP BY: cuántos libros hay en cada estado
SELECT estado, COUNT(*) AS total_libros
FROM libro
GROUP BY estado;

-- GROUP BY con suma: multas pendientes por usuario
SELECT u.nombre AS usuario, SUM(m.monto) AS total_pendiente
FROM multa m
INNER JOIN usuario u ON u.usuario_id = m.usuario_id
WHERE m.estado = 'Pendiente'
GROUP BY u.nombre;
