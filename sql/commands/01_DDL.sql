-- 01_DDL.sql - Data Definition Language (definir la estructura)
-- CREATE, ALTER, CREATE INDEX y DROP.
-- Ejecutar después de biblioteca_insert.sql.

USE biblioteca;

-- CREATE: crea una tabla de prueba
CREATE TABLE IF NOT EXISTS tabla_prueba (
    tabla_prueba_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    descripcion     VARCHAR(100) NOT NULL,
    PRIMARY KEY (tabla_prueba_id)
) ENGINE = InnoDB;

-- ALTER: agrega una columna a libro
ALTER TABLE libro ADD COLUMN IF NOT EXISTS numero_paginas SMALLINT UNSIGNED NULL;

-- ALTER: agrega una columna a prestamo
ALTER TABLE prestamo ADD COLUMN IF NOT EXISTS observaciones VARCHAR(200) NULL;

-- ALTER: amplía el tamaño del teléfono
ALTER TABLE usuario MODIFY COLUMN telefono VARCHAR(25) NOT NULL;

-- CREATE INDEX: acelera la búsqueda de libros por título
CREATE INDEX IF NOT EXISTS idx_libro_titulo ON libro (titulo);

-- DROP: elimina la tabla de prueba
DROP TABLE IF EXISTS tabla_prueba;
