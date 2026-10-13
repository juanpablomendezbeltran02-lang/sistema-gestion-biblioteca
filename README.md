# Sistema de Gestión de Biblioteca · Base de Datos Relacional

Proyecto de base de datos relacional para la gestión de una biblioteca: usuarios,
catálogo de libros, préstamos, reservas y multas por morosidad. El diseño conceptual
está en `docs/DISENO_DE_UN_SISTEMA.pdf` (artículo en formato IEEE) y en el diagrama
`docs/MER.png`.

**Autores:** Yheriam Noelber Diaz Obando, Johan Stiverson Mendoza Durte, Juan Pablo
Mendez Beltran y Juan Camilo Romero.

Motor de base de datos: **MariaDB** sobre entorno **XAMPP**.

## Descripción del sistema

La biblioteca necesita controlar el material bibliográfico y el seguimiento de sus
usuarios. El negocio maneja la siguiente información:

- Cada **usuario** (estudiante, profesor o externo) tiene datos de contacto y el
  estado de su cuenta.
- Cada **libro** tiene ISBN, título, autor, editorial, año, categoría y su estado actual.
- Un **préstamo** registra qué usuario se lleva qué libro, la fecha de salida y la
  fecha límite de devolución.
- Una **reserva** es la cola de espera de un libro que se encuentra prestado.
- Una **multa** penaliza un préstamo con la fecha de devolución superada; un préstamo
  genera, como máximo, una multa.

### Reglas de negocio

| Regla                                                              | Cómo se implementa                              |
|--------------------------------------------------------------------|-------------------------------------------------|
| Un usuario realiza muchos préstamos y reservas (1:N).              | Llaves foráneas `usuario_id`.                   |
| Un libro se presta y se reserva muchas veces con el tiempo (1:N).  | Llaves foráneas `libro_id`.                     |
| Un préstamo genera como máximo una multa (1:1 o 1:0).              | `UNIQUE` en `multa.prestamo_id`.                |
| La fecha límite no puede ser anterior a la fecha de préstamo.      | `CHECK` en `prestamo`.                          |
| El monto de una multa no puede ser negativo.                       | `CHECK` en `multa`.                             |
| Sólo un usuario `Activo` puede tomar libros prestados.             | Trigger `trg_prestamo_validar_insert`.          |
| Un libro perdido o en mantenimiento no se presta.                  | Trigger `trg_prestamo_validar_insert`.          |
| Un libro no se presta si ya tiene un préstamo pendiente.           | Trigger `trg_prestamo_validar_insert`.          |
| `libro.estado` se mantiene sincronizado (Prestado / Disponible).   | Triggers `trg_prestamo_marcar_libro_prestado` y `trg_prestamo_liberar_libro_update`. |
| Sólo se reservan libros que están prestados.                       | Trigger `trg_reserva_libro_prestado`.           |
| La multa es del usuario del préstamo y posterior a la fecha límite.| Triggers `trg_multa_validar_insert` / `_update`.|

### Modelo (5 tablas)

| Tabla      | Llave primaria | Descripción                                          |
|------------|----------------|------------------------------------------------------|
| `usuario`  | `usuario_id`   | Lectores de la biblioteca.                           |
| `libro`    | `libro_id`     | Catálogo de libros.                                  |
| `prestamo` | `prestamo_id`  | Préstamos de libros a usuarios.                      |
| `reserva`  | `reserva_id`   | Cola de espera de libros prestados.                  |
| `multa`    | `multa_id`     | Multa por devolución tardía de un préstamo.          |

El detalle de columnas y restricciones está en `docs/diccionario_datos.md`, y el
detalle de cada relación está como bloque de comentarios en `sql/mariadb/biblioteca.sql`.

## Contenido del repositorio

```
sistema-gestion-biblioteca/
├── docs/
│   ├── DISENO_DE_UN_SISTEMA.pdf         # Artículo IEEE con el diseño del sistema
│   ├── MER.png                          # Diagrama Entidad-Relación
│   ├── MER.md                           # El mismo diagrama en Mermaid (GitHub lo dibuja)
│   └── diccionario_datos.md             # Diccionario de datos
├── sql/
│   └── mariadb/
│       ├── biblioteca.sql               # DDL: base de datos, tablas, constraints y triggers
│       ├── biblioteca_insert.sql        # DML: datos de prueba para todas las tablas
│       ├── check-mariadb.sql            # Script de diagnóstico del servidor MariaDB
│       └── commands/
│           ├── 01_DDL.sql               # CREATE / ALTER / DROP de ejemplo
│           ├── 02_DML.sql               # INSERT / UPDATE / DELETE de ejemplo
│           ├── 03_DQL.sql               # SELECT / JOIN / GROUP BY de ejemplo
│           ├── 04_VDL.sql               # CREATE VIEW / consulta / DROP VIEW de ejemplo
│           ├── 05_DCL.sql               # CREATE USER / GRANT / REVOKE de ejemplo
│           └── 06_TCL.sql               # START TRANSACTION / SAVEPOINT / COMMIT / ROLLBACK
├── tests/
│   └── mariadb/
│       └── biblioteca_test.sql          # Pruebas de integridad integral del proyecto
├── .gitignore
├── LICENSE
└── README.md
```

## Requisitos previos

- [XAMPP](https://www.apachefriends.org/) con el módulo **MySQL/MariaDB** habilitado
  (se necesita MariaDB 10.2 o superior).
- Cliente `mariadb` (o `mysql`) disponible en la terminal. Ruta típica según sistema
  operativo:
  - **Windows:** `C:\xampp\mysql\bin\mariadb.exe`
  - **macOS:** `/Applications/XAMPP/xamppfiles/bin/mariadb`
  - **Linux:** `/opt/lampp/bin/mariadb`
- Visual Studio Code con la extensión "MySQL" o "SQLTools" (opcional, para editar).
- Git y una cuenta de GitHub (opcional, para control de versiones).

## Ejecución paso a paso en XAMPP MariaDB

Todos los ejemplos usan la misma conexión en los tres sistemas operativos
(`-u root -p -h 127.0.0.1 -P 3306 --default-character-set=utf8mb4`); sólo cambia la
ruta del binario y cómo el shell redirige la entrada estándar. Por defecto, XAMPP
configura el usuario `root` **sin contraseña**: cuando el comando pida `Enter password:`,
basta con presionar Enter.

### 1. Iniciar los servicios

**Windows y macOS:** abre el **Panel de Control de XAMPP** y arranca el módulo
**MySQL**. Verifica que el estado quede en verde ("Running").

**Linux:** `sudo /opt/lampp/lampp start`

### 2. Verificar la conexión (opcional)

El script `sql/mariadb/check-mariadb.sql` es de sólo lectura y muestra la versión del
servidor, su configuración, los motores disponibles y, si ya existe, el contenido de
la base `biblioteca`. Ejecútalo con `--force` para que no se detenga en las secciones
que dependen de que la base ya exista:

```bash
mariadb -u root -p -h 127.0.0.1 -P 3306 --default-character-set=utf8mb4 \
    --force < sql/mariadb/check-mariadb.sql
```

### 3. Ejecutar los scripts en orden

El orden de ejecución **es obligatorio**, porque cada script depende de que la
estructura o los datos del anterior ya existan.

**Windows (PowerShell)** — PowerShell no admite `<` para redirigir un archivo a la
entrada estándar, por lo que se usa `Get-Content` junto con una función auxiliar:

```powershell
function Invoke-BibliotecaScript($Path) {
    Get-Content $Path -Encoding UTF8 | & "C:\xampp\mysql\bin\mariadb.exe" -u root -p -h 127.0.0.1 -P 3306 --default-character-set=utf8mb4
}

Invoke-BibliotecaScript "sql\mariadb\biblioteca.sql"            # 1. Base de datos, tablas, constraints y triggers
Invoke-BibliotecaScript "sql\mariadb\biblioteca_insert.sql"     # 2. Datos de prueba
Invoke-BibliotecaScript "sql\mariadb\commands\01_DDL.sql"       # 3. CREATE / ALTER / DROP de ejemplo
Invoke-BibliotecaScript "sql\mariadb\commands\02_DML.sql"       # 4. INSERT / UPDATE / DELETE de ejemplo
Invoke-BibliotecaScript "sql\mariadb\commands\03_DQL.sql"       # 5. SELECT / JOIN / GROUP BY de ejemplo
Invoke-BibliotecaScript "sql\mariadb\commands\04_VDL.sql"       # 6. CREATE VIEW / consulta / DROP VIEW de ejemplo
Invoke-BibliotecaScript "sql\mariadb\commands\05_DCL.sql"       # 7. CREATE USER / GRANT / REVOKE de ejemplo
Invoke-BibliotecaScript "sql\mariadb\commands\06_TCL.sql"       # 8. START TRANSACTION / SAVEPOINT / COMMIT / ROLLBACK
```

**macOS:**

```bash
run_mariadb() {
    /Applications/XAMPP/xamppfiles/bin/mariadb -u root -p -h 127.0.0.1 -P 3306 --default-character-set=utf8mb4 "$@"
}

run_mariadb < sql/mariadb/biblioteca.sql            # 1. Base de datos, tablas, constraints y triggers
run_mariadb < sql/mariadb/biblioteca_insert.sql     # 2. Datos de prueba
run_mariadb < sql/mariadb/commands/01_DDL.sql       # 3. CREATE / ALTER / DROP de ejemplo
run_mariadb < sql/mariadb/commands/02_DML.sql       # 4. INSERT / UPDATE / DELETE de ejemplo
run_mariadb < sql/mariadb/commands/03_DQL.sql       # 5. SELECT / JOIN / GROUP BY de ejemplo
run_mariadb < sql/mariadb/commands/04_VDL.sql       # 6. CREATE VIEW / consulta / DROP VIEW de ejemplo
run_mariadb < sql/mariadb/commands/05_DCL.sql       # 7. CREATE USER / GRANT / REVOKE de ejemplo
run_mariadb < sql/mariadb/commands/06_TCL.sql       # 8. START TRANSACTION / SAVEPOINT / COMMIT / ROLLBACK
```

**Linux:**

```bash
run_mariadb() {
    /opt/lampp/bin/mariadb -u root -p -h 127.0.0.1 -P 3306 --default-character-set=utf8mb4 "$@"
}

run_mariadb < sql/mariadb/biblioteca.sql            # 1. Base de datos, tablas, constraints y triggers
run_mariadb < sql/mariadb/biblioteca_insert.sql     # 2. Datos de prueba
run_mariadb < sql/mariadb/commands/01_DDL.sql       # 3. CREATE / ALTER / DROP de ejemplo
run_mariadb < sql/mariadb/commands/02_DML.sql       # 4. INSERT / UPDATE / DELETE de ejemplo
run_mariadb < sql/mariadb/commands/03_DQL.sql       # 5. SELECT / JOIN / GROUP BY de ejemplo
run_mariadb < sql/mariadb/commands/04_VDL.sql       # 6. CREATE VIEW / consulta / DROP VIEW de ejemplo
run_mariadb < sql/mariadb/commands/05_DCL.sql       # 7. CREATE USER / GRANT / REVOKE de ejemplo
run_mariadb < sql/mariadb/commands/06_TCL.sql       # 8. START TRANSACTION / SAVEPOINT / COMMIT / ROLLBACK
```

> Si prefieres usar `cmd.exe` en Windows en vez de PowerShell, la redirección `<`
> funciona igual que en macOS/Linux:
> `C:\xampp\mysql\bin\mariadb.exe -u root -p -h 127.0.0.1 -P 3306 --default-character-set=utf8mb4 < sql\mariadb\biblioteca.sql`

#### Ejecución segura: se puede repetir sin miedo

Los scripts están escritos para poder ejecutarse varias veces sin errores ni datos
duplicados:

- Toda `CREATE DATABASE`, `CREATE TABLE`, `CREATE TRIGGER`, `ADD COLUMN` y
  `CREATE INDEX` usa `IF [NOT] EXISTS`.
- `biblioteca_insert.sql` localiza cada llave foránea por su llave natural (email del
  usuario, ISBN del libro) en vez de un ID numérico fijo, y protege cada fila con
  `INSERT IGNORE` (tablas con `UNIQUE`) o `WHERE NOT EXISTS` (tablas con trigger de
  negocio, como `prestamo`, `multa` y `reserva`).
- `02_DML.sql` y `06_TCL.sql` localizan sus registros por llave natural y verifican
  si el dato de ejemplo ya existe antes de insertarlo.
- `03_DQL.sql` y `04_VDL.sql` son de sólo lectura o usan `CREATE OR REPLACE VIEW`.
- `05_DCL.sql` usa `CREATE USER IF NOT EXISTS`; repetir el `GRANT`/`REVOKE` no falla.

### 4. Verificar la instalación desde phpMyAdmin (opcional)

1. Abre `http://localhost/phpmyadmin` con XAMPP en ejecución.
2. Selecciona la base de datos `biblioteca` en el panel izquierdo.
3. Confirma que existan las 5 tablas del modelo, las vistas `v_prestamos_detalle` y
   `v_multas_detalle`, y que la pestaña **Triggers** muestre los seis disparadores de
   reglas de negocio.

### 5. Ejecutar las pruebas de integridad

`tests/mariadb/biblioteca_test.sql` verifica de punta a punta que el despliegue fue
correcto: existencia de las 5 tablas, las 2 vistas y los 6 triggers, datos cargados,
ausencia de registros huérfanos, cumplimiento de cada regla de negocio (intentando
inserciones que el motor debe rechazar), consistencia de las vistas y permisos de los
usuarios creados en `05_DCL.sql`. Debe ejecutarse **con la bandera `--force`**, porque
intencionalmente provoca errores esperados y necesita que la conexión continúe
después de cada uno:

**Windows (PowerShell):**

```powershell
Get-Content tests\mariadb\biblioteca_test.sql -Encoding UTF8 | & "C:\xampp\mysql\bin\mariadb.exe" -u root -p -h 127.0.0.1 -P 3306 --default-character-set=utf8mb4 --force biblioteca
```

**macOS:**

```bash
/Applications/XAMPP/xamppfiles/bin/mariadb -u root -p -h 127.0.0.1 -P 3306 --default-character-set=utf8mb4 \
    --force biblioteca < tests/mariadb/biblioteca_test.sql
```

**Linux:**

```bash
/opt/lampp/bin/mariadb -u root -p -h 127.0.0.1 -P 3306 --default-character-set=utf8mb4 \
    --force biblioteca < tests/mariadb/biblioteca_test.sql
```

El resultado es una tabla con una fila por prueba (`PASS`/`FAIL`) y un resumen final
con el total de pruebas aprobadas. Las pruebas no dejan datos residuales.

## Cómo subir este proyecto a GitHub

1. Crea un repositorio vacío en GitHub (por ejemplo `sistema-gestion-biblioteca`), sin
   README ni `.gitignore`.
2. Abre esta carpeta en Visual Studio Code (**Archivo → Abrir carpeta**) y en la
   terminal integrada ejecuta (los comandos son iguales en Windows, macOS y Linux):

```bash
git init
git add .
git commit -m "Primer commit: base de datos del Sistema de Gestión de Biblioteca"
git branch -M main
git remote add origin https://github.com/<usuario>/sistema-gestion-biblioteca.git
git push -u origin main
```

## Licencia

Este proyecto se distribuye bajo licencia MIT. Véase el archivo [LICENSE](LICENSE).
