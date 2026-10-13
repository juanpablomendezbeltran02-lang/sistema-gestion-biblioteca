-- =====================================================================================
-- Datos de prueba (DML) para el Sistema de Gestión de Biblioteca
-- Autores: Yheriam Noelber Diaz Obando, Johan Stiverson Mendoza Durte,
--          Juan Pablo Mendez Beltran, Juan Camilo Romero
-- Fecha: 2026-10-11
--
-- Este script inserta datos ficticios (usuarios, ISBN y fechas de ejemplo) en todas
-- las tablas creadas en biblioteca.sql. El orden respeta las llaves foráneas: primero
-- usuario y libro, luego prestamo, después multa y reserva (que dependen de prestamo).
--
-- EJECUCIÓN SEGURA / IDEMPOTENCIA:
--   Este script puede ejecutarse varias veces sobre la misma base de datos sin crear
--   filas duplicadas ni lanzar errores:
--   - No se usan IDs numéricos fijos como llave foránea: cada ID se resuelve una sola
--     vez en una variable de sesión (@usr_..., @lib_...) usando su llave natural
--     (email del usuario o ISBN del libro).
--   - usuario y libro tienen restricción UNIQUE (email / isbn), por lo que usan
--     INSERT IGNORE.
--   - prestamo, multa y reserva tienen triggers de negocio con SIGNAL, que INSERT
--     IGNORE no suprime; por eso cada fila se protege con "INSERT ... SELECT ...
--     WHERE NOT EXISTS": si ya existe, ni siquiera intenta insertarse.
--   - Todo el script debe ejecutarse en una misma sesión (las variables @... viven
--     sólo mientras dura la conexión), que es lo que ocurre al redirigir el archivo.
-- =====================================================================================

-- Selecciona el esquema donde se insertarán los datos.
USE `biblioteca`;

-- -------------------------------------------------------------------------------------
-- Tabla: usuario (UNIQUE en email -> INSERT IGNORE es suficiente)
-- -------------------------------------------------------------------------------------
INSERT IGNORE INTO `usuario` (`nombre`, `tipo_usuario`, `direccion`, `telefono`, `email`, `fecha_registro`, `estado`) VALUES
    ('Valentina Ruiz',  'Estudiante', 'Calle 45 # 12-30',     '3001112233', 'valentina.ruiz@example.com',  '2026-02-10', 'Activo'),
    ('Camilo Herrera',  'Profesor',   'Carrera 7 # 80-15',    '3002223344', 'camilo.herrera@example.com',  '2025-08-20', 'Activo'),
    ('Daniela Castro',  'Externo',    'Av. 68 # 22-10',       '3003334455', 'daniela.castro@example.com',  '2026-03-05', 'Activo'),
    ('Mateo Vargas',    'Estudiante', 'Diagonal 40 # 15-60',  '3004445566', 'mateo.vargas@example.com',    '2026-01-18', 'Activo'),
    ('Isabela Moreno',  'Estudiante', 'Calle 100 # 9-45',     '3005556677', 'isabela.moreno@example.com',  '2025-11-02', 'Suspendido');

-- -------------------------------------------------------------------------------------
-- Tabla: libro (UNIQUE en isbn -> INSERT IGNORE es suficiente). Los ISBN son ficticios.
-- -------------------------------------------------------------------------------------
INSERT IGNORE INTO `libro` (`titulo`, `autor`, `isbn`, `editorial`, `anio_publicacion`, `categoria`, `estado`) VALUES
    ('Cien años de soledad',                         'Gabriel García Márquez',                                '978-958-00-0001-1', 'Editorial Sudamericana',   1967, 'Novela',      'Disponible'),
    ('Don Quijote de la Mancha',                     'Miguel de Cervantes Saavedra',                          '978-958-00-0002-2', 'Francisco de Robles',      1605, 'Novela',      'Disponible'),
    ('El coronel no tiene quien le escriba',         'Gabriel García Márquez',                                '978-958-00-0003-3', 'Aguirre Editor',           1961, 'Novela',      'Disponible'),
    ('Pedro Páramo',                                 'Juan Rulfo',                                            '978-958-00-0004-4', 'Fondo de Cultura Económica', 1955, 'Novela',    'Disponible'),
    ('Rayuela',                                      'Julio Cortázar',                                        '978-958-00-0005-5', 'Editorial Sudamericana',   1963, 'Novela',      'Disponible'),
    ('La vorágine',                                  'José Eustasio Rivera',                                  '978-958-00-0006-6', 'Editorial Cromos',         1924, 'Novela',      'Disponible'),
    ('Fundamentos de Sistemas de Bases de Datos',    'Ramez Elmasri y Shamkant B. Navathe',                   '978-958-00-0007-7', 'Pearson Educación',        2018, 'Informática', 'Disponible'),
    ('Fundamentos de Bases de Datos',                'Abraham Silberschatz, Henry F. Korth y S. Sudarshan',   '978-958-00-0008-8', 'McGraw-Hill',              2014, 'Informática', 'Disponible');

-- -------------------------------------------------------------------------------------
-- Variables de sesión: resuelven cada llave foránea por su llave natural (una sola vez).
-- -------------------------------------------------------------------------------------
SET @usr_valentina = (SELECT `usuario_id` FROM `usuario` WHERE `email` = 'valentina.ruiz@example.com');
SET @usr_camilo    = (SELECT `usuario_id` FROM `usuario` WHERE `email` = 'camilo.herrera@example.com');
SET @usr_daniela   = (SELECT `usuario_id` FROM `usuario` WHERE `email` = 'daniela.castro@example.com');
SET @usr_mateo     = (SELECT `usuario_id` FROM `usuario` WHERE `email` = 'mateo.vargas@example.com');

SET @lib_cien_anios = (SELECT `libro_id` FROM `libro` WHERE `isbn` = '978-958-00-0001-1');
SET @lib_pedro      = (SELECT `libro_id` FROM `libro` WHERE `isbn` = '978-958-00-0004-4');
SET @lib_rayuela    = (SELECT `libro_id` FROM `libro` WHERE `isbn` = '978-958-00-0005-5');
SET @lib_elmasri    = (SELECT `libro_id` FROM `libro` WHERE `isbn` = '978-958-00-0007-7');

-- -------------------------------------------------------------------------------------
-- Tabla: prestamo (sin UNIQUE natural + trigger -> WHERE NOT EXISTS por libro, usuario
-- y fecha de préstamo). Los préstamos 'Pendiente' pasan el libro a 'Prestado' (trigger).
-- -------------------------------------------------------------------------------------
-- Préstamo 1: Valentina devolvió "Cien años de soledad" a tiempo.
INSERT INTO `prestamo` (`libro_id`, `usuario_id`, `fecha_prestamo`, `fecha_devolucion`, `estado`)
SELECT @lib_cien_anios, @usr_valentina, '2026-09-01', '2026-09-15', 'Devuelto'
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM `prestamo`
    WHERE `libro_id` = @lib_cien_anios AND `usuario_id` = @usr_valentina AND `fecha_prestamo` = '2026-09-01'
);

-- Préstamo 2: Camilo tiene el libro de Elmasri y ya superó la fecha límite (vencido).
INSERT INTO `prestamo` (`libro_id`, `usuario_id`, `fecha_prestamo`, `fecha_devolucion`, `estado`)
SELECT @lib_elmasri, @usr_camilo, '2026-09-10', '2026-09-24', 'Pendiente'
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM `prestamo`
    WHERE `libro_id` = @lib_elmasri AND `usuario_id` = @usr_camilo AND `fecha_prestamo` = '2026-09-10'
);

-- Préstamo 3: Daniela tiene "Pedro Páramo".
INSERT INTO `prestamo` (`libro_id`, `usuario_id`, `fecha_prestamo`, `fecha_devolucion`, `estado`)
SELECT @lib_pedro, @usr_daniela, '2026-10-01', '2026-10-15', 'Pendiente'
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM `prestamo`
    WHERE `libro_id` = @lib_pedro AND `usuario_id` = @usr_daniela AND `fecha_prestamo` = '2026-10-01'
);

-- Préstamo 4: Mateo devolvió "Rayuela" con retraso (generó una multa ya pagada).
INSERT INTO `prestamo` (`libro_id`, `usuario_id`, `fecha_prestamo`, `fecha_devolucion`, `estado`)
SELECT @lib_rayuela, @usr_mateo, '2026-09-20', '2026-10-04', 'Devuelto'
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM `prestamo`
    WHERE `libro_id` = @lib_rayuela AND `usuario_id` = @usr_mateo AND `fecha_prestamo` = '2026-09-20'
);

-- -------------------------------------------------------------------------------------
-- Tabla: multa (UNIQUE en prestamo_id, pero con trigger -> WHERE NOT EXISTS).
-- -------------------------------------------------------------------------------------
-- Multa del préstamo 2 (Camilo, vencido): pendiente de pago.
INSERT INTO `multa` (`prestamo_id`, `usuario_id`, `monto`, `fecha_multa`, `estado`, `motivo`)
SELECT
    (SELECT `prestamo_id` FROM `prestamo`
      WHERE `libro_id` = @lib_elmasri AND `usuario_id` = @usr_camilo AND `fecha_prestamo` = '2026-09-10'),
    @usr_camilo, 5000.00, '2026-09-25', 'Pendiente', 'Retraso en la devolución'
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM `multa`
    WHERE `prestamo_id` = (SELECT `prestamo_id` FROM `prestamo`
                            WHERE `libro_id` = @lib_elmasri AND `usuario_id` = @usr_camilo AND `fecha_prestamo` = '2026-09-10')
);

-- Multa del préstamo 4 (Mateo, devolución tardía): ya pagada.
INSERT INTO `multa` (`prestamo_id`, `usuario_id`, `monto`, `fecha_multa`, `estado`, `motivo`)
SELECT
    (SELECT `prestamo_id` FROM `prestamo`
      WHERE `libro_id` = @lib_rayuela AND `usuario_id` = @usr_mateo AND `fecha_prestamo` = '2026-09-20'),
    @usr_mateo, 3000.00, '2026-10-06', 'Pagada', 'Devolución tardía'
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM `multa`
    WHERE `prestamo_id` = (SELECT `prestamo_id` FROM `prestamo`
                            WHERE `libro_id` = @lib_rayuela AND `usuario_id` = @usr_mateo AND `fecha_prestamo` = '2026-09-20')
);

-- -------------------------------------------------------------------------------------
-- Tabla: reserva (UNIQUE en libro+usuario+fecha, pero con trigger -> WHERE NOT EXISTS).
-- Sólo se pueden reservar libros prestados: ambos libros tienen préstamo pendiente.
-- -------------------------------------------------------------------------------------
-- Mateo reserva el libro de Elmasri (prestado a Camilo).
INSERT INTO `reserva` (`libro_id`, `usuario_id`, `fecha_reserva`, `estado`)
SELECT @lib_elmasri, @usr_mateo, '2026-09-15', 'Activa'
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM `reserva`
    WHERE `libro_id` = @lib_elmasri AND `usuario_id` = @usr_mateo AND `fecha_reserva` = '2026-09-15'
);

-- Valentina reserva "Pedro Páramo" (prestado a Daniela).
INSERT INTO `reserva` (`libro_id`, `usuario_id`, `fecha_reserva`, `estado`)
SELECT @lib_pedro, @usr_valentina, '2026-10-03', 'Activa'
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM `reserva`
    WHERE `libro_id` = @lib_pedro AND `usuario_id` = @usr_valentina AND `fecha_reserva` = '2026-10-03'
);
