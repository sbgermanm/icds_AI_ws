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

Lee el spec en _specs/PROJ-XXXX.md
Lee la query en _queries/PROJ-XXXX.sql
Lee la arquitectura en _arquitectura/java-arquitectura.md

Crea el endpoint siguiendo exactamente los patrones existentes en el backend.
Cuando termines, dime la URL exacta del endpoint creado.
```

---

## PASO 4 — Crear componente Angular

```
Actúa como el agente definido en .cursor/rules/04-angular-frontend-agent.mdc

Lee el spec en _specs/PROJ-XXXX.md
Lee la arquitectura en _arquitectura/angular-arquitectura.md
El endpoint a usar es: [PEGA AQUÍ LA URL QUE DIO EL AGENTE JAVA]

Crea el componente Angular siguiendo exactamente los patrones existentes en el frontend.
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
