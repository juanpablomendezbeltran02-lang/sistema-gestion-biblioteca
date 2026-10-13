-- 05_DCL.sql - Data Control Language (permisos)
-- CREATE USER, GRANT y REVOKE. Se ejecuta con el usuario root de XAMPP.
-- Las contraseñas son de ejemplo, solo para uso local.

-- Usuario de reportes: solo puede leer
CREATE USER IF NOT EXISTS 'biblioteca_reportes'@'localhost' IDENTIFIED BY 'Reportes#2026';
GRANT SELECT ON biblioteca.* TO 'biblioteca_reportes'@'localhost';

-- Usuario de mostrador: puede leer, insertar y actualizar, pero no borrar
CREATE USER IF NOT EXISTS 'biblioteca_mostrador'@'localhost' IDENTIFIED BY 'Mostrador#2026';
GRANT SELECT, INSERT, UPDATE, DELETE ON biblioteca.* TO 'biblioteca_mostrador'@'localhost';
REVOKE DELETE ON biblioteca.* FROM 'biblioteca_mostrador'@'localhost';

FLUSH PRIVILEGES;

-- Ver los permisos de cada usuario
SHOW GRANTS FOR 'biblioteca_reportes'@'localhost';
SHOW GRANTS FOR 'biblioteca_mostrador'@'localhost';
