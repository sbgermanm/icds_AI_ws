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

```
Actúa como el agente definido en .cursor/rules/03-java-backend-agent.mdc

Lee el spec en _specs/ICDSDEV-422.md
Lee la query definida en _queries/ICDSDEV-422.sql
Lee la arquitectura en _arquitectura/java-arquitectura.md


Crea un nuevo report similar al ultimo que creamos (endpoint: backend/src/main/java/avangrid/icds/reportsstdelect/controller/NyReliabilityIndexesReportController.java) usando la query indicada.

La query es para cuando la opco es 0 (que es 1 OR 2), 1 o 2. Cuando la opco es 3, hay que usar las tablas alternativas indicadas en el archivo de la query. 
Ademas, la query tiene un join que une los open incidents (lstIncidentStages in 0..4) con los closed incidents (tablas _H_, lstIncidentStages-5). Programatically, crea la query en el sqlBuilder por parte y haz el union solo si hay open y closed, si no, solo el que corresponda (lstIncidentStages no puede venir vacio).
Ademas, programaticamnete, como en otros sitios, si el filtro es "DIVISION" usa la Option A, y si es AREA la opcion B
```

---

## PASO 4 — Crear componente Angular

```
Actúa como el agente definido en .cursor/rules/04-angular-frontend-agent.mdc

Lee el spec en _specs/ICDSDEV-422.md
Lee la arquitectura en _arquitectura/angular-arquitectura.md
El endpoint a usar es: /api/reports/well-managed-etr

Crea un nuevo report llamado well-managed-etr haciendo similar los que estan en frontend/src/app/pages/standardElectricReports. estos reports tienen un acordeon con tres secciones, criteria, table result y detalle. El criteria es un componente que tiene varios componentes que se habilitan o no dependiendo del repo. Mira las specs para ver cuales debes habilitar. A su vez los compoenntes de ese filtro pueden ocular filtros que no aplican, como los lstIncidentStages.
La tabla es un componenet comun para todos que se configura con las columnas que aplican en cada repo
El detalle lo mismo, como podras ver tienes varias secciones que muestran el detalle de un incidente.
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
