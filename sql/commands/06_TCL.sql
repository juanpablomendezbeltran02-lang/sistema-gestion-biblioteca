-- 06_TCL.sql - Transaction Control Language (transacciones)
-- START TRANSACTION, SAVEPOINT, COMMIT y ROLLBACK.

USE biblioteca;

-- Transacción 1: se confirma el cambio de teléfono, pero se deshace el de dirección
START TRANSACTION;

UPDATE usuario SET telefono = '3004445500' WHERE email = 'mateo.vargas@example.com';

SAVEPOINT despues_del_telefono;

UPDATE usuario SET direccion = 'Dirección de prueba' WHERE email = 'mateo.vargas@example.com';

-- Vuelve al SAVEPOINT: se descarta solo el cambio de dirección
ROLLBACK TO SAVEPOINT despues_del_telefono;

-- COMMIT: confirma lo que quedó (el teléfono)
COMMIT;

-- Transacción 2: se descarta todo con ROLLBACK
START TRANSACTION;

UPDATE usuario SET direccion = 'Otra dirección de prueba' WHERE email = 'valentina.ruiz@example.com';

ROLLBACK;
