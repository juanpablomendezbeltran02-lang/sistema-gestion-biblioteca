-- 04_VDL.sql - View Definition Language (vistas)
-- Una vista es una consulta guardada con nombre.

USE biblioteca;

-- Vista de préstamos con el nombre del usuario y el título del libro
CREATE OR REPLACE VIEW v_prestamos_detalle AS
SELECT p.prestamo_id, u.nombre AS usuario, l.titulo AS libro,
       p.fecha_prestamo, p.fecha_devolucion AS fecha_limite, p.estado
FROM prestamo p
INNER JOIN usuario u ON u.usuario_id = p.usuario_id
INNER JOIN libro l   ON l.libro_id = p.libro_id;

SELECT * FROM v_prestamos_detalle;

-- Vista de multas con el nombre del usuario y el libro
CREATE OR REPLACE VIEW v_multas_detalle AS
SELECT m.multa_id, u.nombre AS usuario, l.titulo AS libro,
       m.monto, m.fecha_multa, m.estado, m.motivo
FROM multa m
INNER JOIN usuario u  ON u.usuario_id = m.usuario_id
INNER JOIN prestamo p ON p.prestamo_id = m.prestamo_id
INNER JOIN libro l    ON l.libro_id = p.libro_id;

SELECT * FROM v_multas_detalle;

-- DROP VIEW (comentado para no borrar las vistas):
-- DROP VIEW IF EXISTS v_prestamos_detalle;
-- DROP VIEW IF EXISTS v_multas_detalle;
