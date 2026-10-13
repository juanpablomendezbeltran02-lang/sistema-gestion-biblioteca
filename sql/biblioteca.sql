-- =====================================================
-- Sistema de Gestión de Biblioteca - Base de datos
-- Motor: MariaDB (XAMPP)
-- Crea la base de datos, las tablas y los triggers.
-- OJO: si la base "biblioteca" ya existe, la borra y la crea de nuevo.
-- =====================================================

DROP DATABASE IF EXISTS biblioteca;
CREATE DATABASE biblioteca DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE biblioteca;

-- ---------- Tabla usuario ----------
CREATE TABLE usuario (
    usuario_id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre         VARCHAR(100) NOT NULL,
    tipo_usuario   ENUM('Estudiante', 'Profesor', 'Externo') NOT NULL,
    direccion      VARCHAR(150) NOT NULL,
    telefono       VARCHAR(20)  NOT NULL,
    email          VARCHAR(120) NOT NULL,
    fecha_registro DATE NOT NULL DEFAULT (CURRENT_DATE),
    estado         ENUM('Activo', 'Suspendido', 'Inactivo') NOT NULL DEFAULT 'Activo',
    PRIMARY KEY (usuario_id),
    UNIQUE (email)
) ENGINE = InnoDB;

-- ---------- Tabla libro ----------
CREATE TABLE libro (
    libro_id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    titulo           VARCHAR(200) NOT NULL,
    autor            VARCHAR(150) NOT NULL,
    isbn             VARCHAR(20)  NOT NULL,
    editorial        VARCHAR(100) NOT NULL,
    anio_publicacion SMALLINT UNSIGNED NOT NULL,
    categoria        VARCHAR(60)  NOT NULL,
    estado           ENUM('Disponible', 'Prestado', 'Mantenimiento', 'Perdido') NOT NULL DEFAULT 'Disponible',
    PRIMARY KEY (libro_id),
    UNIQUE (isbn)
) ENGINE = InnoDB;

-- ---------- Tabla prestamo ----------
CREATE TABLE prestamo (
    prestamo_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
    libro_id         INT UNSIGNED NOT NULL,
    usuario_id       INT UNSIGNED NOT NULL,
    fecha_prestamo   DATE NOT NULL,
    fecha_devolucion DATE NOT NULL,      -- fecha límite para devolver el libro
    estado           ENUM('Pendiente', 'Devuelto') NOT NULL DEFAULT 'Pendiente',
    PRIMARY KEY (prestamo_id),
    FOREIGN KEY (libro_id)   REFERENCES libro (libro_id),
    FOREIGN KEY (usuario_id) REFERENCES usuario (usuario_id),
    CHECK (fecha_devolucion >= fecha_prestamo)
) ENGINE = InnoDB;

-- ---------- Tabla reserva ----------
CREATE TABLE reserva (
    reserva_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    libro_id      INT UNSIGNED NOT NULL,
    usuario_id    INT UNSIGNED NOT NULL,
    fecha_reserva DATE NOT NULL,
    estado        ENUM('Activa', 'Atendida', 'Cancelada') NOT NULL DEFAULT 'Activa',
    PRIMARY KEY (reserva_id),
    UNIQUE (libro_id, usuario_id, fecha_reserva),
    FOREIGN KEY (libro_id)   REFERENCES libro (libro_id),
    FOREIGN KEY (usuario_id) REFERENCES usuario (usuario_id)
) ENGINE = InnoDB;

-- ---------- Tabla multa ----------
-- UNIQUE en prestamo_id: un préstamo tiene como máximo una multa (relación 1:1).
CREATE TABLE multa (
    multa_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    prestamo_id INT UNSIGNED NOT NULL,
    usuario_id  INT UNSIGNED NOT NULL,
    monto       DECIMAL(10, 2) NOT NULL,
    fecha_multa DATE NOT NULL,
    estado      ENUM('Pendiente', 'Pagada') NOT NULL DEFAULT 'Pendiente',
    motivo      VARCHAR(150) NOT NULL,
    PRIMARY KEY (multa_id),
    UNIQUE (prestamo_id),
    FOREIGN KEY (prestamo_id) REFERENCES prestamo (prestamo_id),
    FOREIGN KEY (usuario_id)  REFERENCES usuario (usuario_id),
    CHECK (monto >= 0)
) ENGINE = InnoDB;

-- =====================================================
-- TRIGGERS (reglas del negocio)
-- =====================================================
DELIMITER $$

-- Regla 1: solo se presta a un usuario Activo y un libro Disponible.
CREATE TRIGGER trg_prestamo_validar
BEFORE INSERT ON prestamo
FOR EACH ROW
BEGIN
    DECLARE v_usuario VARCHAR(20);
    DECLARE v_libro   VARCHAR(20);

    IF NEW.estado = 'Pendiente' THEN
        SELECT estado INTO v_usuario FROM usuario WHERE usuario_id = NEW.usuario_id;
        SELECT estado INTO v_libro   FROM libro   WHERE libro_id   = NEW.libro_id;

        IF v_usuario <> 'Activo' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario no esta activo.';
        END IF;
        IF v_libro <> 'Disponible' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El libro no esta disponible.';
        END IF;
    END IF;
END$$

-- Regla 2: al crear un préstamo pendiente, el libro pasa a "Prestado".
CREATE TRIGGER trg_prestamo_libro_prestado
AFTER INSERT ON prestamo
FOR EACH ROW
BEGIN
    IF NEW.estado = 'Pendiente' THEN
        UPDATE libro SET estado = 'Prestado' WHERE libro_id = NEW.libro_id;
    END IF;
END$$

-- Regla 3: al devolver el préstamo, el libro vuelve a "Disponible".
CREATE TRIGGER trg_prestamo_libro_devuelto
AFTER UPDATE ON prestamo
FOR EACH ROW
BEGIN
    IF OLD.estado = 'Pendiente' AND NEW.estado = 'Devuelto' THEN
        UPDATE libro SET estado = 'Disponible'
        WHERE libro_id = NEW.libro_id AND estado = 'Prestado';
    END IF;
END$$

-- Regla 4: solo se puede reservar un libro que está prestado.
CREATE TRIGGER trg_reserva_validar
BEFORE INSERT ON reserva
FOR EACH ROW
BEGIN
    DECLARE v_libro VARCHAR(20);
    SELECT estado INTO v_libro FROM libro WHERE libro_id = NEW.libro_id;

    IF NEW.estado = 'Activa' AND v_libro <> 'Prestado' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se reservan libros prestados.';
    END IF;
END$$

DELIMITER ;
