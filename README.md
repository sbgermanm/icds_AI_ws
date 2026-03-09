# Setup del workspace de agentes

## 1. Conectar tus proyectos (elige una opción)

### Opción A — Symlinks (recomendado)
```bash
cd ~/Projects/mi-proyecto-agentes

ln -s /ruta/real/a/tu/backend backend
ln -s /ruta/real/a/tu/frontend frontend
```

### Opción B — Rutas absolutas
Edita `_arquitectura/paths.md` con las rutas reales.

---

## 2. Abrir en Cursor
```bash
cursor ~/Projects/mi-proyecto-agentes
```
O desde Cursor: **File → Open Folder**

---

## 3. Rellenar los archivos de arquitectura

Estos archivos son los más importantes. El agente los lee antes de generar código:

- `_arquitectura/java-arquitectura.md` → pega ejemplos reales de tu backend
- `_arquitectura/angular-arquitectura.md` → pega ejemplos reales de tu frontend

**Cuanto más detallados, mejor será el output del agente.**

---

## 4. Usar el pipeline

Los prompts están en `_prompts/pipeline-completo.md`.

Flujo normal:
1. Copia el prompt del PASO 1, pega el texto del ticket Jira, envía
2. Revisa `_specs/PROJ-XXXX.md` y ajusta si hace falta
3. Ejecuta PASO 2 → genera la query SQL
4. Ejecuta PASO 3 → genera el endpoint Java  
5. Ejecuta PASO 4 → genera el componente Angular

---

## Estructura completa del workspace

```
mi-proyecto-agentes/
├── .cursor/
│   └── rules/
│       ├── 00-pipeline-overview.mdc     ← siempre activo
│       ├── 01-jira-refiner.mdc          ← agente Jira → spec
│       ├── 02-oracle-query-agent.mdc    ← agente queries Oracle
│       ├── 03-java-backend-agent.mdc    ← agente endpoints Java
│       └── 04-angular-frontend-agent.mdc ← agente componentes Angular
│
├── _arquitectura/
│   ├── paths.md                         ← rutas de los proyectos
│   ├── java-arquitectura.md             ← ⚠️ RELLENAR
│   └── angular-arquitectura.md          ← ⚠️ RELLENAR
│
├── _specs/                              ← specs generados por el agente Jira
│   └── PROJ-XXXX.md
│
├── _queries/                            ← queries Oracle
│   ├── _index.md                        ← índice de queries
│   └── PROJ-XXXX.sql
│
├── _prompts/
│   └── pipeline-completo.md             ← prompts listos para copiar/pegar
│
├── backend -> /ruta/real/backend        ← symlink (opcional)
└── frontend -> /ruta/real/frontend      ← symlink (opcional)
```
