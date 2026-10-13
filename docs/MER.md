# Modelo Entidad-Relación — Sistema de Gestión de Biblioteca

La imagen del diagrama está en [`MER.png`](MER.png). Debajo está el mismo modelo en
Mermaid, que GitHub dibuja automáticamente al abrir este archivo.

```mermaid
erDiagram
    USUARIO ||--o{ PRESTAMO : "realiza"
    USUARIO ||--o{ RESERVA : "hace"
    USUARIO ||--o{ MULTA : "tiene"
    LIBRO ||--o{ PRESTAMO : "incluye"
    LIBRO ||--o{ RESERVA : "tiene"
    PRESTAMO ||--o| MULTA : "genera"

    LIBRO {
        int libro_id PK
        string titulo
        string autor
        string isbn
        string editorial
        int anio_publicacion
        string categoria
        string estado
    }

    USUARIO {
        int usuario_id PK
        string nombre
        string tipo_usuario
        string direccion
        string telefono
        string email
        date fecha_registro
        string estado
    }

    PRESTAMO {
        int prestamo_id PK
        int libro_id FK
        int usuario_id FK
        date fecha_prestamo
        date fecha_devolucion
        string estado
    }

    RESERVA {
        int reserva_id PK
        int libro_id FK
        int usuario_id FK
        date fecha_reserva
        string estado
    }

    MULTA {
        int multa_id PK
        int prestamo_id FK
        int usuario_id FK
        decimal monto
        date fecha_multa
        string estado
        string motivo
    }
```
