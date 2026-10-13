-- =====================================================================================
-- 05_DCL.sql — Data Control Language
-- Objetivo: gestionar permisos y accesos a la base de datos de la Biblioteca.
-- Incluye: creación de usuarios, GRANT de permisos, REVOKE de permisos de borrado y
-- consulta de los privilegios existentes.
--
-- CÓMO SE EJECUTA:
--   Debe correrse DESPUÉS de 04_VDL.sql, cuando la estructura, los datos y las vistas
--   ya están listos para ser consultados por otros usuarios. Requiere ejecutarse con
--   un usuario con privilegios administrativos (por defecto, `root` en XAMPP).
--
-- EJECUCIÓN SEGURA / IDEMPOTENCIA:
--   CREATE USER usa IF NOT EXISTS; GRANT vuelve a otorgar los mismos privilegios sin
--   error si ya estaban concedidos; y REVOKE DELETE es seguro de repetir siempre que
--   el usuario ya tenga al menos un privilegio otorgado en ese esquema (lo garantiza
--   el GRANT anterior en este mismo script).
--
-- NOTA: las contraseñas de este archivo son de ejemplo para un entorno de desarrollo
-- local; cámbialas si vas a usar la base de datos fuera de tu computador.
-- =====================================================================================

-- No se antepone USE porque GRANT/CREATE USER son sentencias a nivel de servidor,
-- pero los privilegios sí se otorgan explícitamente sobre el esquema `biblioteca`.

-- ---------------------------------------------------------------------------------
-- CREATE USER: usuario de aplicación de sólo lectura para reportes, válido
-- únicamente desde el host local (típico en un entorno XAMPP de desarrollo).
-- ---------------------------------------------------------------------------------
CREATE USER IF NOT EXISTS 'biblioteca_reportes'@'localhost' IDENTIFIED BY 'Reportes#2026';

-- ---------------------------------------------------------------------------------
-- GRANT: permisos de sólo lectura (SELECT) sobre todas las tablas y vistas del
-- esquema, suficiente para generar reportes sin modificar datos.
-- ---------------------------------------------------------------------------------
GRANT SELECT ON `biblioteca`.* TO 'biblioteca_reportes'@'localhost';

-- ---------------------------------------------------------------------------------
-- CREATE USER: segundo usuario con permisos operativos (lectura y escritura) para el
-- personal que atiende el mostrador de la biblioteca.
-- ---------------------------------------------------------------------------------
CREATE USER IF NOT EXISTS 'biblioteca_mostrador'@'localhost' IDENTIFIED BY 'Mostrador#2026';

-- ---------------------------------------------------------------------------------
-- GRANT: permisos de lectura, inserción y actualización, pero sin borrado, ya que el
-- personal de mostrador no debería poder eliminar el historial de préstamos.
-- ---------------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE ON `biblioteca`.* TO 'biblioteca_mostrador'@'localhost';

-- ---------------------------------------------------------------------------------
-- REVOKE: revoca explícitamente el permiso de borrado (DELETE) por si el usuario lo
-- hubiera tenido de una asignación anterior; refuerza la regla del negocio.
-- ---------------------------------------------------------------------------------
REVOKE DELETE ON `biblioteca`.* FROM 'biblioteca_mostrador'@'localhost';

-- ---------------------------------------------------------------------------------
-- FLUSH PRIVILEGES: recarga las tablas de privilegios en memoria para que los
-- cambios de GRANT/REVOKE tengan efecto inmediato.
-- ---------------------------------------------------------------------------------
FLUSH PRIVILEGES;

-- ---------------------------------------------------------------------------------
-- SHOW GRANTS: consulta los privilegios efectivos de cada usuario recién creado.
-- ---------------------------------------------------------------------------------
SHOW GRANTS FOR 'biblioteca_reportes'@'localhost';
SHOW GRANTS FOR 'biblioteca_mostrador'@'localhost';
