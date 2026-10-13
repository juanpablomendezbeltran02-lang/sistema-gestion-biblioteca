-- =====================================================================================
-- 01_DDL.sql — Data Definition Language
-- Objetivo: definir y modificar la estructura de la base de datos de la Biblioteca.
-- Incluye: CREATE, ALTER (agregar/modificar columnas), CREATE INDEX y DROP (eliminar
-- una tabla de prueba).
--
-- CÓMO SE EJECUTA:
--   Debe correrse DESPUÉS de sql/mariadb/biblioteca.sql (las tablas base ya deben
--   existir) y ANTES de 02_DML.sql, porque aquí se agregan columnas que los scripts
--   siguientes pueden utilizar.
--
-- EJECUCIÓN SEGURA / IDEMPOTENCIA:
--   Todas las sentencias usan IF [NOT] EXISTS (CREATE TABLE, ADD COLUMN, CREATE INDEX,
--   DROP TABLE), por lo que este script puede ejecutarse varias veces seguidas sin
--   error: si la columna, el índice o la tabla ya existen, la sentencia simplemente no
--   hace nada en vez de fallar.
-- =====================================================================================

-- Selecciona el esquema del proyecto como base de datos activa.
USE `biblioteca`;

-- ---------------------------------------------------------------------------------
-- CREATE: crea una tabla nueva de prueba para demostrar el comando CREATE TABLE.
-- ---------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tabla_prueba` (
    `tabla_prueba_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `descripcion` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`tabla_prueba_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci
  COMMENT = 'Tabla temporal usada únicamente para demostrar sentencias DDL.';

-- ---------------------------------------------------------------------------------
-- ALTER: agrega una columna a `libro` para registrar el número de páginas.
-- ---------------------------------------------------------------------------------
ALTER TABLE `libro`
    ADD COLUMN IF NOT EXISTS `numero_paginas` SMALLINT UNSIGNED NULL
    COMMENT 'Número de páginas del libro (opcional).';

-- ---------------------------------------------------------------------------------
-- ALTER: agrega una columna a `prestamo` para anotar observaciones del bibliotecario
-- (por ejemplo, renovaciones o el estado en que se entregó el libro).
-- ---------------------------------------------------------------------------------
ALTER TABLE `prestamo`
    ADD COLUMN IF NOT EXISTS `observaciones` VARCHAR(200) NULL
    COMMENT 'Notas del bibliotecario sobre el préstamo (opcional).';

-- ---------------------------------------------------------------------------------
-- ALTER: modifica el tamaño máximo del campo `telefono` de `usuario`, ya que
-- 20 caracteres se quedaban cortos para números con indicativo internacional.
-- ---------------------------------------------------------------------------------
ALTER TABLE `usuario`
    MODIFY COLUMN `telefono` VARCHAR(25) NOT NULL
    COMMENT 'Teléfono de contacto del usuario, incluye indicativo internacional.';

-- ---------------------------------------------------------------------------------
-- CREATE INDEX: índices para acelerar las búsquedas más frecuentes del negocio:
-- buscar libros por título y buscar libros por autor.
-- ---------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS `idx_libro_titulo` ON `libro` (`titulo`);
CREATE INDEX IF NOT EXISTS `idx_libro_autor` ON `libro` (`autor`);

-- ---------------------------------------------------------------------------------
-- DROP: elimina la tabla de prueba creada al inicio del script, ya que sólo servía
-- para demostrar el comando CREATE TABLE y no forma parte del modelo final.
-- ---------------------------------------------------------------------------------
DROP TABLE IF EXISTS `tabla_prueba`;
