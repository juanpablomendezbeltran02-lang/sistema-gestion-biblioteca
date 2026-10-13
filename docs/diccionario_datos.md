# Diccionario de datos — base de datos `biblioteca`

Motor: MariaDB · Juego de caracteres: `utf8mb4` · Motor de tablas: InnoDB.
Las columnas marcadas con (*) las agrega `sql/mariadb/commands/01_DDL.sql`.

## usuario

| Columna          | Tipo                                    | Nulo | Clave | Descripción                                        |
|------------------|-----------------------------------------|------|-------|----------------------------------------------------|
| `usuario_id`     | INT UNSIGNED AUTO_INCREMENT             | No   | PK    | Identificador del usuario.                         |
| `nombre`         | VARCHAR(100)                            | No   |       | Nombre completo.                                   |
| `tipo_usuario`   | ENUM('Estudiante','Profesor','Externo') | No   |       | Tipo de membresía.                                 |
| `direccion`      | VARCHAR(150)                            | No   |       | Dirección de residencia.                           |
| `telefono`       | VARCHAR(20) → VARCHAR(25) (*)           | No   |       | Teléfono de contacto.                              |
| `email`          | VARCHAR(120)                            | No   | UNIQUE| Correo electrónico.                                |
| `fecha_registro` | DATE (por defecto, el día actual)       | No   |       | Fecha de inscripción.                              |
| `estado`         | ENUM('Activo','Suspendido','Inactivo')  | No   |       | Estado de la cuenta (sólo 'Activo' puede pedir libros). |

## libro

| Columna            | Tipo                                                    | Nulo | Clave  | Descripción                                   |
|--------------------|---------------------------------------------------------|------|--------|-----------------------------------------------|
| `libro_id`         | INT UNSIGNED AUTO_INCREMENT                             | No   | PK     | Identificador del libro.                      |
| `titulo`           | VARCHAR(200)                                            | No   | índice (*) | Título.                                   |
| `autor`            | VARCHAR(150)                                            | No   | índice (*) | Autor o autores.                          |
| `isbn`             | VARCHAR(20)                                             | No   | UNIQUE | ISBN del libro.                               |
| `editorial`        | VARCHAR(100)                                            | No   |        | Editorial.                                    |
| `anio_publicacion` | SMALLINT UNSIGNED (CHECK > 0)                           | No   |        | Año de publicación.                           |
| `categoria`        | VARCHAR(60)                                             | No   |        | Categoría o género.                           |
| `estado`           | ENUM('Disponible','Prestado','Mantenimiento','Perdido') | No   |        | Estado actual (los triggers lo sincronizan).  |
| `numero_paginas` (*) | SMALLINT UNSIGNED                                     | Sí   |        | Número de páginas.                            |

## prestamo

| Columna            | Tipo                                   | Nulo | Clave | Descripción                                      |
|--------------------|----------------------------------------|------|-------|--------------------------------------------------|
| `prestamo_id`      | INT UNSIGNED AUTO_INCREMENT            | No   | PK    | Identificador del préstamo.                      |
| `libro_id`         | INT UNSIGNED                           | No   | FK → libro.libro_id       | Libro prestado.              |
| `usuario_id`       | INT UNSIGNED                           | No   | FK → usuario.usuario_id   | Usuario que lo recibe.       |
| `fecha_prestamo`   | DATE                                   | No   |       | Fecha de salida del libro.                       |
| `fecha_devolucion` | DATE (CHECK ≥ fecha_prestamo)          | No   |       | Fecha límite de devolución.                      |
| `estado`           | ENUM('Pendiente','Devuelto')           | No   |       | 'Pendiente' = aún no devuelto.                   |
| `observaciones` (*)| VARCHAR(200)                           | Sí   |       | Notas del bibliotecario.                         |

## reserva

| Columna         | Tipo                                  | Nulo | Clave | Descripción                                      |
|-----------------|---------------------------------------|------|-------|--------------------------------------------------|
| `reserva_id`    | INT UNSIGNED AUTO_INCREMENT           | No   | PK    | Identificador de la reserva.                     |
| `libro_id`      | INT UNSIGNED                          | No   | FK → libro.libro_id     | Libro reservado.               |
| `usuario_id`    | INT UNSIGNED                          | No   | FK → usuario.usuario_id | Usuario que reserva.           |
| `fecha_reserva` | DATE                                  | No   |       | Fecha de solicitud.                              |
| `estado`        | ENUM('Activa','Atendida','Cancelada') | No   |       | Estado de la reserva.                            |

Restricción única: (`libro_id`, `usuario_id`, `fecha_reserva`).

## multa

| Columna       | Tipo                          | Nulo | Clave | Descripción                                          |
|---------------|-------------------------------|------|-------|------------------------------------------------------|
| `multa_id`    | INT UNSIGNED AUTO_INCREMENT   | No   | PK    | Identificador de la multa.                           |
| `prestamo_id` | INT UNSIGNED                  | No   | FK → prestamo.prestamo_id, UNIQUE | Préstamo que originó la multa (1:1 o 1:0). |
| `usuario_id`  | INT UNSIGNED                  | No   | FK → usuario.usuario_id | Usuario que debe la multa.             |
| `monto`       | DECIMAL(10,2) (CHECK ≥ 0)     | No   |       | Valor de la multa.                                   |
| `fecha_multa` | DATE                          | No   |       | Fecha en que se genera la multa.                     |
| `estado`      | ENUM('Pendiente','Pagada')    | No   |       | Estado de pago.                                      |
| `motivo`      | VARCHAR(150)                  | No   |       | Motivo de la multa.                                  |

## Vistas

| Vista                | Descripción                                                              |
|----------------------|--------------------------------------------------------------------------|
| `v_prestamos_detalle`| Préstamos con nombre de usuario, título del libro y días de retraso.     |
| `v_multas_detalle`   | Multas con nombre del usuario y título del libro que las originó.        |

## Triggers (reglas de negocio)

| Trigger                              | Tabla     | Cuándo        | Regla                                                                 |
|--------------------------------------|-----------|---------------|-----------------------------------------------------------------------|
| `trg_prestamo_validar_insert`        | prestamo  | BEFORE INSERT | Usuario activo, libro no perdido/en mantenimiento y no prestado ya.   |
| `trg_prestamo_marcar_libro_prestado` | prestamo  | AFTER INSERT  | Un préstamo pendiente pasa el libro a 'Prestado'.                     |
| `trg_prestamo_liberar_libro_update`  | prestamo  | AFTER UPDATE  | Al devolver el préstamo, el libro vuelve a 'Disponible'.              |
| `trg_reserva_libro_prestado`         | reserva   | BEFORE INSERT | Sólo se reservan libros que tienen un préstamo pendiente.             |
| `trg_multa_validar_insert`           | multa     | BEFORE INSERT | La multa es del usuario del préstamo y de fecha posterior al límite.  |
| `trg_multa_validar_update`           | multa     | BEFORE UPDATE | Misma validación al modificar una multa.                              |
