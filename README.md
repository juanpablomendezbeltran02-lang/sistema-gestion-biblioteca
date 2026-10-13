# Sistema de Gestión de Biblioteca

Base de datos relacional para la gestión de una biblioteca. Cubre: usuarios, libros,
préstamos, reservas y multas por retraso.

Motor: MariaDB en XAMPP.

Integrantes: Yheriam Noelber Diaz Obando, Johan Stiverson Mendoza Durte, Juan Pablo
Mendez Beltran y Juan Camilo Romero.

## Tablas

| Tabla      | Descripción                                              |
|------------|----------------------------------------------------------|
| `usuario`  | Quien usa la biblioteca (estudiante, profesor o externo) |
| `libro`    | Lo que se presta                                         |
| `prestamo` | Libro que se lleva un usuario, con su fecha límite       |
| `reserva`  | Cola de espera de un libro que está prestado             |
| `multa`    | Multa por devolver tarde un préstamo                     |

Relaciones: un usuario tiene muchos préstamos, reservas y multas (1:N); un libro tiene
muchos préstamos y reservas (1:N); un préstamo tiene como máximo una multa (1:1).

## Reglas automáticas (triggers)

- Solo se presta a un usuario activo y un libro disponible.
- Al prestar un libro pasa a "Prestado"; al devolverlo vuelve a "Disponible".
- Solo se puede reservar un libro que está prestado.

## Archivos

- `SQL/biblioteca.sql`: crea la base de datos, las tablas y los triggers
- `SQL/biblioteca_insert.sql`: inserta los datos de prueba
- `SQL/commands/01_DDL.sql` a `06_TCL.sql`: ejemplos de cada tipo de comando
  (DDL, DML, DQL, VDL, DCL y TCL)
- `tests/biblioteca_pruebas.sql`: pruebas básicas
- `docs/`: artículo del diseño, diagrama entidad-relación (`MER.png`) y diagrama de tablas

## Cómo ejecutarlo

1. Iniciar MySQL en XAMPP
2. Abrir phpMyAdmin (`localhost/phpmyadmin`)
3. En la pestaña **Import** (sin entrar a ninguna base de datos), importar en orden:
   `biblioteca.sql`, luego `biblioteca_insert.sql`, luego los archivos `01` a `06`
4. Entrar a la base `biblioteca` y en **More → Designer** se ve el diseño de las tablas
5. Para revisar que todo quedó bien, ejecutar `tests/biblioteca_pruebas.sql`

Nota: `biblioteca.sql` borra y crea de nuevo la base, así que sirve para empezar de cero.

## Cómo subirlo a GitHub

```
git init
git add .
git commit -m "Base de datos del Sistema de Gestion de Biblioteca"
git branch -M main
git remote add origin https://github.com/<usuario>/sistema-gestion-biblioteca.git
git push -u origin main
```
