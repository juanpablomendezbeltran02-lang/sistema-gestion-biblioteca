-- =====================================================
-- Datos de prueba
-- Ejecutar DESPUÉS de biblioteca.sql (y una sola vez).
-- Para empezar de cero, vuelve a ejecutar biblioteca.sql.
-- =====================================================

USE biblioteca;

-- ---------- Usuarios (ids 1 a 5) ----------
INSERT INTO usuario (nombre, tipo_usuario, direccion, telefono, email, fecha_registro, estado) VALUES
('Valentina Ruiz', 'Estudiante', 'Calle 45 # 12-30',    '3001112233', 'valentina.ruiz@example.com', '2026-02-10', 'Activo'),
('Camilo Herrera', 'Profesor',   'Carrera 7 # 80-15',   '3002223344', 'camilo.herrera@example.com', '2025-08-20', 'Activo'),
('Daniela Castro', 'Externo',    'Av. 68 # 22-10',      '3003334455', 'daniela.castro@example.com', '2026-03-05', 'Activo'),
('Mateo Vargas',   'Estudiante', 'Diagonal 40 # 15-60', '3004445566', 'mateo.vargas@example.com',   '2026-01-18', 'Activo'),
('Isabela Moreno', 'Estudiante', 'Calle 100 # 9-45',    '3005556677', 'isabela.moreno@example.com', '2025-11-02', 'Suspendido');

-- ---------- Libros (ids 1 a 8). Los ISBN son inventados ----------
INSERT INTO libro (titulo, autor, isbn, editorial, anio_publicacion, categoria) VALUES
('Cien años de soledad',                      'Gabriel García Márquez',                              '978-958-00-0001-1', 'Editorial Sudamericana',      1967, 'Novela'),
('Don Quijote de la Mancha',                  'Miguel de Cervantes Saavedra',                        '978-958-00-0002-2', 'Francisco de Robles',         1605, 'Novela'),
('El coronel no tiene quien le escriba',      'Gabriel García Márquez',                              '978-958-00-0003-3', 'Aguirre Editor',              1961, 'Novela'),
('Pedro Páramo',                              'Juan Rulfo',                                          '978-958-00-0004-4', 'Fondo de Cultura Económica',  1955, 'Novela'),
('Rayuela',                                   'Julio Cortázar',                                      '978-958-00-0005-5', 'Editorial Sudamericana',      1963, 'Novela'),
('La vorágine',                               'José Eustasio Rivera',                                '978-958-00-0006-6', 'Editorial Cromos',            1924, 'Novela'),
('Fundamentos de Sistemas de Bases de Datos', 'Ramez Elmasri y Shamkant B. Navathe',                 '978-958-00-0007-7', 'Pearson Educación',          2018, 'Informática'),
('Fundamentos de Bases de Datos',             'Abraham Silberschatz, Henry F. Korth y S. Sudarshan', '978-958-00-0008-8', 'McGraw-Hill',                2014, 'Informática');

-- ---------- Préstamos (ids 1 a 4) ----------
-- 1: Valentina devolvió "Cien años de soledad" a tiempo
-- 2: Camilo tiene el libro de Elmasri y ya está vencido
-- 3: Daniela tiene "Pedro Páramo"
-- 4: Mateo devolvió "Rayuela" con retraso
INSERT INTO prestamo (libro_id, usuario_id, fecha_prestamo, fecha_devolucion, estado) VALUES
(1, 1, '2026-09-01', '2026-09-15', 'Devuelto'),
(7, 2, '2026-09-10', '2026-09-24', 'Pendiente'),
(4, 3, '2026-10-01', '2026-10-15', 'Pendiente'),
(5, 4, '2026-09-20', '2026-10-04', 'Devuelto');

-- ---------- Multas (por los préstamos 2 y 4) ----------
INSERT INTO multa (prestamo_id, usuario_id, monto, fecha_multa, estado, motivo) VALUES
(2, 2, 5000.00, '2026-09-25', 'Pendiente', 'Retraso en la devolución'),
(4, 4, 3000.00, '2026-10-06', 'Pagada',    'Devolución tardía');

-- ---------- Reservas (de libros que están prestados) ----------
INSERT INTO reserva (libro_id, usuario_id, fecha_reserva, estado) VALUES
(7, 4, '2026-09-15', 'Activa'),
(4, 1, '2026-10-03', 'Activa');
