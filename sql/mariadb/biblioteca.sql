-- =====================================================================================
-- Base de Datos Relacional - Sistema de Gestión de Biblioteca
-- Autores: Yheriam Noelber Diaz Obando, Johan Stiverson Mendoza Durte,
--          Juan Pablo Mendez Beltran, Juan Camilo Romero
-- Fecha: 2026-10-11
-- Motor: MariaDB (XAMPP)
--
-- Este script contiene la definición completa (DDL) del modelo Entidad-Relación del
-- documento "Diseño de un Sistema Relacional para la Gestión de una Biblioteca"
-- (docs/DISENO_DE_UN_SISTEMA.pdf) y del diagrama docs/MER.png.
--
-- Entidades: usuario, libro, prestamo, reserva y multa.
--   - Un usuario realiza muchos préstamos y muchas reservas (1:N).
--   - Un libro puede ser prestado y reservado muchas veces a lo largo del tiempo (1:N).
--   - Un préstamo vencido genera, como máximo, una multa (1:1 o 1:0).
--   - Una multa pertenece también al usuario que la debe (1:N usuario -> multa).
--
-- Normalización: las tablas están en 1FN/2FN/3FN. Todos los atributos son atómicos,
-- cada tabla tiene llave primaria simple (autoincremental), y los atributos no clave
-- dependen únicamente de su llave primaria. Los atributos con pocos valores posibles
-- (tipo_usuario, estado) se modelan como ENUM.
--
-- EJECUCIÓN SEGURA / IDEMPOTENCIA:
--   Todo el script puede ejecutarse varias veces seguidas, o después de que las
--   tablas ya existan, sin error: CREATE DATABASE, cada CREATE TABLE y cada
--   CREATE TRIGGER usan IF NOT EXISTS. Si el esquema ya está creado, el script no
--   hace nada y termina sin fallar.
-- =====================================================================================

-- Crea la base de datos si no existe, con soporte completo para UTF-8.
CREATE DATABASE IF NOT EXISTS `biblioteca` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

-- Elimina la base de datos completa; se deja comentado como medida de seguridad.
-- DROP DATABASE IF EXISTS `biblioteca`;

-- Selecciona la base de datos como esquema activo para el resto de sentencias del script.
USE `biblioteca`;

-- =====================================================================================
-- BLOQUE DE COMENTARIOS: DIAGRAMA DE RELACIONES DE LA BASE DE DATOS
-- =====================================================================================
-- +-----------------+-------------+--------------------+-------------+---------------+------------------------------------------------+
-- | Tabla Origen    | Campo FK    | Tabla Destino (PK) | Campo PK    | Cardinalidad  | Descripción                                    |
-- +-----------------+-------------+--------------------+-------------+---------------+------------------------------------------------+
-- | prestamo        | usuario_id  | usuario            | usuario_id  | 1:N           | Un usuario realiza muchos préstamos.           |
-- | prestamo        | libro_id    | libro              | libro_id    | 1:N           | Un libro se presta muchas veces.               |
-- | reserva         | usuario_id  | usuario            | usuario_id  | 1:N           | Un usuario hace muchas reservas.               |
-- | reserva         | libro_id    | libro              | libro_id    | 1:N           | Un libro tiene muchas reservas.                |
-- | multa           | prestamo_id | prestamo           | prestamo_id | 1:1 (o 1:0)   | Un préstamo genera como máximo una multa.      |
-- | multa           | usuario_id  | usuario            | usuario_id  | 1:N           | Un usuario puede tener muchas multas.          |
-- +-----------------+-------------+--------------------+-------------+---------------+------------------------------------------------+

-- =====================================================================================
-- TABLA: usuario
-- Lectores de la biblioteca (estudiantes, profesores y externos).
-- =====================================================================================
CREATE TABLE IF NOT EXISTS `usuario` (
    -- Llave primaria autoincremental.
    `usuario_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `nombre` VARCHAR(100) NOT NULL,
    -- Tipo de membresía del usuario.
    `tipo_usuario` ENUM('Estudiante', 'Profesor', 'Externo') NOT NULL,
    `direccion` VARCHAR(150) NOT NULL,
    `telefono` VARCHAR(20) NOT NULL,
    `email` VARCHAR(120) NOT NULL,
    -- Fecha de inscripción; por defecto, el día en que se registra el usuario.
    `fecha_registro` DATE NOT NULL DEFAULT (CURRENT_DATE),
    -- Estado de la cuenta; sólo un usuario 'Activo' puede tomar libros prestados.
    `estado` ENUM('Activo', 'Suspendido', 'Inactivo') NOT NULL DEFAULT 'Activo',
    PRIMARY KEY (`usuario_id`),
    -- Un mismo correo no puede pertenecer a dos usuarios.
    CONSTRAINT `uq_usuario_email` UNIQUE (`email`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci
  COMMENT = 'Lectores de la biblioteca.';

-- =====================================================================================
-- TABLA: libro
-- Catálogo de libros con su estado actual. Cada fila es un libro físico identificado
-- por su ISBN (por eso el ISBN es único).
-- =====================================================================================
CREATE TABLE IF NOT EXISTS `libro` (
    `libro_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `titulo` VARCHAR(200) NOT NULL,
    `autor` VARCHAR(150) NOT NULL,
    `isbn` VARCHAR(20) NOT NULL,
    `editorial` VARCHAR(100) NOT NULL,
    `anio_publicacion` SMALLINT UNSIGNED NOT NULL,
    `categoria` VARCHAR(60) NOT NULL,
    -- Estado actual del libro; los triggers lo pasan a 'Prestado' / 'Disponible'.
    `estado` ENUM('Disponible', 'Prestado', 'Mantenimiento', 'Perdido') NOT NULL DEFAULT 'Disponible',
    PRIMARY KEY (`libro_id`),
    CONSTRAINT `uq_libro_isbn` UNIQUE (`isbn`),
    CONSTRAINT `chk_libro_anio` CHECK (`anio_publicacion` > 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci
  COMMENT = 'Catálogo de libros de la biblioteca.';

-- =====================================================================================
-- TABLA: prestamo
-- Núcleo transaccional: resuelve la relación entre usuarios y libros. Registra la
-- fecha de salida y la fecha límite de devolución.
-- =====================================================================================
CREATE TABLE IF NOT EXISTS `prestamo` (
    `prestamo_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `libro_id` INT UNSIGNED NOT NULL,
    `usuario_id` INT UNSIGNED NOT NULL,
    -- Fecha en que el libro sale de la biblioteca.
    `fecha_prestamo` DATE NOT NULL,
    -- Fecha límite en la que el libro debe ser devuelto.
    `fecha_devolucion` DATE NOT NULL,
    -- 'Pendiente' = el libro todavía no ha sido devuelto.
    `estado` ENUM('Pendiente', 'Devuelto') NOT NULL DEFAULT 'Pendiente',
    PRIMARY KEY (`prestamo_id`),
    CONSTRAINT `fk_prestamo_libro`
        FOREIGN KEY (`libro_id`) REFERENCES `libro` (`libro_id`)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT `fk_prestamo_usuario`
        FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`usuario_id`)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    -- La fecha límite de devolución nunca puede ser anterior a la fecha de préstamo.
    CONSTRAINT `chk_prestamo_fechas` CHECK (`fecha_devolucion` >= `fecha_prestamo`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci
  COMMENT = 'Préstamos de libros a usuarios.';

-- =====================================================================================
-- TABLA: reserva
-- Cola de espera para los libros que se encuentran prestados.
-- =====================================================================================
CREATE TABLE IF NOT EXISTS `reserva` (
    `reserva_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `libro_id` INT UNSIGNED NOT NULL,
    `usuario_id` INT UNSIGNED NOT NULL,
    -- Fecha de solicitud de la reserva.
    `fecha_reserva` DATE NOT NULL,
    `estado` ENUM('Activa', 'Atendida', 'Cancelada') NOT NULL DEFAULT 'Activa',
    PRIMARY KEY (`reserva_id`),
    -- Un usuario no puede repetir la misma reserva del mismo libro en el mismo día.
    CONSTRAINT `uq_reserva_libro_usuario_fecha` UNIQUE (`libro_id`, `usuario_id`, `fecha_reserva`),
    CONSTRAINT `fk_reserva_libro`
        FOREIGN KEY (`libro_id`) REFERENCES `libro` (`libro_id`)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT `fk_reserva_usuario`
        FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`usuario_id`)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci
  COMMENT = 'Reservas de libros que se encuentran prestados.';

-- =====================================================================================
-- TABLA: multa
-- Penalización por morosidad. La relación con prestamo es 1:1 (o 1:0): el UNIQUE sobre
-- prestamo_id garantiza que un préstamo genere, como máximo, una multa.
-- =====================================================================================
CREATE TABLE IF NOT EXISTS `multa` (
    `multa_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `prestamo_id` INT UNSIGNED NOT NULL,
    `usuario_id` INT UNSIGNED NOT NULL,
    `monto` DECIMAL(10, 2) NOT NULL,
    `fecha_multa` DATE NOT NULL,
    `estado` ENUM('Pendiente', 'Pagada') NOT NULL DEFAULT 'Pendiente',
    `motivo` VARCHAR(150) NOT NULL,
    PRIMARY KEY (`multa_id`),
    CONSTRAINT `uq_multa_prestamo` UNIQUE (`prestamo_id`),
    CONSTRAINT `fk_multa_prestamo`
        FOREIGN KEY (`prestamo_id`) REFERENCES `prestamo` (`prestamo_id`)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT `fk_multa_usuario`
        FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`usuario_id`)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    -- Una multa nunca puede tener un monto negativo.
    CONSTRAINT `chk_multa_monto` CHECK (`monto` >= 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci
  COMMENT = 'Multas por devolución tardía de un préstamo.';

-- =====================================================================================
-- TRIGGER: trg_prestamo_validar_insert
-- Reglas de negocio al registrar un préstamo pendiente:
--   1. El usuario debe tener la cuenta 'Activo'.
--   2. El libro no puede estar en 'Mantenimiento' ni 'Perdido'.
--   3. El libro no puede tener ya otro préstamo pendiente (no se presta dos veces).
-- =====================================================================================
DELIMITER $$

CREATE TRIGGER IF NOT EXISTS `trg_prestamo_validar_insert`
BEFORE INSERT ON `prestamo`
FOR EACH ROW
BEGIN
    DECLARE v_estado_usuario VARCHAR(20);
    DECLARE v_estado_libro VARCHAR(20);
    DECLARE v_pendientes INT UNSIGNED;

    IF NEW.`estado` = 'Pendiente' THEN
        SELECT `estado` INTO v_estado_usuario FROM `usuario` WHERE `usuario_id` = NEW.`usuario_id`;
        SELECT `estado` INTO v_estado_libro FROM `libro` WHERE `libro_id` = NEW.`libro_id`;

        IF v_estado_usuario <> 'Activo' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El usuario no tiene la cuenta activa.';
        END IF;

        IF v_estado_libro IN ('Mantenimiento', 'Perdido') THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El libro no está disponible para préstamo.';
        END IF;

        SELECT COUNT(*) INTO v_pendientes
        FROM `prestamo`
        WHERE `libro_id` = NEW.`libro_id` AND `estado` = 'Pendiente';

        IF v_pendientes > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El libro ya se encuentra prestado.';
        END IF;
    END IF;
END$$

DELIMITER ;

-- =====================================================================================
-- TRIGGERS: trg_prestamo_marcar_libro_prestado / trg_prestamo_liberar_libro_update
-- Mantienen sincronizado libro.estado con los préstamos: al crear un préstamo
-- pendiente el libro pasa a 'Prestado'; al devolverlo, vuelve a 'Disponible'.
-- =====================================================================================
DELIMITER $$

CREATE TRIGGER IF NOT EXISTS `trg_prestamo_marcar_libro_prestado`
AFTER INSERT ON `prestamo`
FOR EACH ROW
BEGIN
    IF NEW.`estado` = 'Pendiente' THEN
        UPDATE `libro` SET `estado` = 'Prestado' WHERE `libro_id` = NEW.`libro_id`;
    END IF;
END$$

CREATE TRIGGER IF NOT EXISTS `trg_prestamo_liberar_libro_update`
AFTER UPDATE ON `prestamo`
FOR EACH ROW
BEGIN
    IF OLD.`estado` = 'Pendiente' AND NEW.`estado` = 'Devuelto' THEN
        UPDATE `libro` SET `estado` = 'Disponible'
        WHERE `libro_id` = NEW.`libro_id` AND `estado` = 'Prestado';
    END IF;
END$$

DELIMITER ;

-- =====================================================================================
-- TRIGGER: trg_reserva_libro_prestado
-- Regla de negocio: la reserva maneja una cola de espera para los títulos que se
-- encuentran prestados; no se puede reservar un libro que no tiene préstamo pendiente.
-- =====================================================================================
DELIMITER $$

CREATE TRIGGER IF NOT EXISTS `trg_reserva_libro_prestado`
BEFORE INSERT ON `reserva`
FOR EACH ROW
BEGIN
    DECLARE v_pendientes INT UNSIGNED;

    IF NEW.`estado` = 'Activa' THEN
        SELECT COUNT(*) INTO v_pendientes
        FROM `prestamo`
        WHERE `libro_id` = NEW.`libro_id` AND `estado` = 'Pendiente';

        IF v_pendientes = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Solo se pueden reservar libros que estén prestados.';
        END IF;
    END IF;
END$$

DELIMITER ;

-- =====================================================================================
-- TRIGGERS: trg_multa_validar_insert / trg_multa_validar_update
-- Reglas de negocio de las multas:
--   1. La multa debe pertenecer al mismo usuario que tiene el préstamo.
--   2. Sólo aplica a préstamos con la fecha de devolución superada
--      (fecha_multa posterior a prestamo.fecha_devolucion).
-- No se pueden expresar con CHECK porque comparan contra otra tabla.
-- =====================================================================================
DELIMITER $$

CREATE TRIGGER IF NOT EXISTS `trg_multa_validar_insert`
BEFORE INSERT ON `multa`
FOR EACH ROW
BEGIN
    DECLARE v_usuario INT UNSIGNED;
    DECLARE v_limite DATE;

    SELECT `usuario_id`, `fecha_devolucion` INTO v_usuario, v_limite
    FROM `prestamo` WHERE `prestamo_id` = NEW.`prestamo_id`;

    IF v_usuario <> NEW.`usuario_id` THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La multa debe pertenecer al usuario del préstamo.';
    END IF;

    IF NEW.`fecha_multa` <= v_limite THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La multa solo aplica a préstamos con la fecha de devolución superada.';
    END IF;
END$$

CREATE TRIGGER IF NOT EXISTS `trg_multa_validar_update`
BEFORE UPDATE ON `multa`
FOR EACH ROW
BEGIN
    DECLARE v_usuario INT UNSIGNED;
    DECLARE v_limite DATE;

    SELECT `usuario_id`, `fecha_devolucion` INTO v_usuario, v_limite
    FROM `prestamo` WHERE `prestamo_id` = NEW.`prestamo_id`;

    IF v_usuario <> NEW.`usuario_id` THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La multa debe pertenecer al usuario del préstamo.';
    END IF;

    IF NEW.`fecha_multa` <= v_limite THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La multa solo aplica a préstamos con la fecha de devolución superada.';
    END IF;
END$$

DELIMITER ;
