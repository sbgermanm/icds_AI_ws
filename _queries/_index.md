# Índice de Queries Oracle

> El agente de queries lee este archivo antes de crear una query nueva.
> Mantenlo actualizado cada vez que añadas una query.

## Cómo añadir una entrada
```
| PROJ-XXXX | nombre-archivo.sql | Descripción breve | Tablas principales |
```

---

## Queries existentes

| Ticket | Archivo | Qué hace | Tablas principales |
|--------|---------|----------|--------------------|
| -      | -       | (aún no hay queries) | - |

---

## Tablas Oracle conocidas

> Ve añadiendo las tablas que vayas descubriendo para que el agente las reutilice

| Tabla | Descripción | Campos clave |
|-------|-------------|--------------|
| (por rellenar) | | |

---

## Patrones de query frecuentes

> Documenta aquí los patrones que se repiten para que el agente los reutilice

### Filtro de rango de fechas
```sql
-- Patrón estándar para filtrar por rango
AND V.FECHA BETWEEN :p_fecha_ini AND :p_fecha_fin
```

### Parámetro opcional (NULL = todos)
```sql
AND (:p_delegacion IS NULL OR T.ID_DELEGACION = :p_delegacion)
```

### (Añade más patrones según los vayas identificando)
