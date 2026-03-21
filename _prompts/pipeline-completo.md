# Prompts de uso rápido

Copia el prompt que necesites, pégalo en el chat de Cursor y ajusta el número de ticket.

---

## PASO 1 — Refinar ticket Jira → Spec

```
Actúa como el agente definido en .cursor/rules/01-jira-refiner.mdc

Ticket Jira:
---
[PEGA AQUÍ EL TEXTO DEL TICKET]
---

Genera el spec técnico en _specs/PROJ-XXXX.md
(cambia XXXX por el número real del ticket)
```

---

## PASO 2 — Crear query Oracle

```
Actúa como el agente definido en .cursor/rules/02-oracle-query-agent.mdc

Lee el spec en _specs/PROJ-XXXX.md
Lee el índice de queries en _queries/_index.md

Crea la query en _queries/PROJ-XXXX.sql
Actualiza _queries/_index.md con la nueva entrada
```

---

## PASO 3 — Crear endpoint Java

### Plantilla (cualquier ticket)

```
Actúa como el agente definido en .cursor/rules/03-java-backend-agent.mdc

Lee el spec en _specs/PROJ-XXXX.md
Lee la query definida en _queries/PROJ-XXXX.sql
Lee la arquitectura en _arquitectura/java-arquitectura.md

[INSTRUCCIONES ESPECÍFICAS DEL TICKET — sustituye este bloque]
Crea un nuevo report similar al último que creamos (endpoint: ruta/al/Controller.java existente) usando la query indicada.
...

Al terminar la implementación, añade la sección "Contrato del endpoint" al final
de _specs/PROJ-XXXX.md tal como indica la regla. El agente Angular la necesita.
```

### Ejemplo listo — ICDSDEV-422 (Well-Managed ETR)

```
Actúa como el agente definido en .cursor/rules/03-java-backend-agent.mdc

Lee el spec en _specs/ICDSDEV-422.md
Lee la query definida en _queries/ICDSDEV-422.sql
Lee la arquitectura en _arquitectura/java-arquitectura.md

Crea un nuevo report similar al último que creamos (endpoint: backend/src/main/java/avangrid/icds/reportsstdelect/controller/NyReliabilityIndexesReportController.java) usando la query indicada.

La query es para cuando la opco es 0 (que es 1 OR 2), 1 o 2. Cuando la opco es 3, hay que usar las tablas alternativas indicadas en el archivo de la query.
Además, la query tiene un join que une los open incidents (lstIncidentStages in 0..4) con los closed incidents (tablas _H_, lstIncidentStages 5). Programáticamente, crea la query en el sqlBuilder por partes y haz el UNION solo si hay open y closed; si no, solo el que corresponda (lstIncidentStages no puede venir vacío).
Además, programáticamente, como en otros sitios, si el filtro es "DIVISION" usa la Option A, y si es AREA la opción B.

Al terminar la implementación, añade la sección "Contrato del endpoint" al final
de _specs/ICDSDEV-422.md tal como indica la regla. El agente Angular la necesita.
```

---

## PASO 4 — Crear componente Angular

### Plantilla (cualquier ticket)

```
Actúa como el agente definido en .cursor/rules/04-angular-frontend-agent.mdc

Lee el spec en _specs/PROJ-XXXX.md — al final encontrarás la sección
"Contrato del endpoint" que dejó el agente Java. Úsala como fuente de verdad
para la URL, parámetros y DTO. No uses ninguna URL que no venga de ahí.

Lee la arquitectura en _arquitectura/angular-arquitectura.md

[INSTRUCCIONES ESPECÍFICAS DEL TICKET — sustituye este bloque]
Crea un nuevo report llamado XXXX haciendo similar los que están en
frontend/src/app/pages/standardElectricReports.
...
```

### Ejemplo listo — ICDSDEV-422 (Well-Managed ETR)

```
Actúa como el agente definido en .cursor/rules/04-angular-frontend-agent.mdc

Lee el spec en _specs/ICDSDEV-422.md — al final debe estar la sección
"Contrato del endpoint" (agente Java). Úsala como fuente de verdad para URL,
parámetros y DTO. Si aún no existe, usa como referencia de este ticket la URL
`/api/reports/well-managed-etr` hasta que el contrato quede documentado en el spec.

Lee la arquitectura en _arquitectura/angular-arquitectura.md

Crea un nuevo report llamado well-managed-etr haciendo similar los que están en
frontend/src/app/pages/standardElectricReports. Estos reports tienen un acordeón con tres secciones: criteria, table result y detalle. El criteria es un componente que tiene varios subcomponentes que se habilitan o no dependiendo del repo. Mira las specs para ver cuáles debes habilitar. A su vez los componentes de ese filtro pueden ocultar filtros que no aplican, como lstIncidentStages.
La tabla es un componente común para todos que se configura con las columnas que aplican en cada repo.
El detalle es igual: varias secciones que muestran el detalle de un incidente.
Integra este report en esos elementos.
```

---

## PASO EXTRA — Revisión cruzada

```
Revisa que todo es consistente para PROJ-XXXX:
- _specs/PROJ-XXXX.md (spec)
- _queries/PROJ-XXXX.sql (query)

Comprueba que los parámetros de la query coinciden con los del spec.
Indica cualquier discrepancia que encuentres.
```

Para revisar solo ICDSDEV-422, cambia `PROJ-XXXX` por `ICDSDEV-422` en el bloque anterior.
