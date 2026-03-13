# ICDSDEV-422 — Well-Managed ETRs Report

## 1. Summary

| Field | Value |
|---|---|
| Ticket | ICDSDEV-422 |
| Module | `reportsstdelect` |
| Type | New standardized electrical report |
| Persona | Electric Operations Manager / Senior Manager |
| Scope | Electric Incidents (EI) only — active + archived |

**Goal**: Provide managers a single report that determines whether each incident's ETR (Estimated Time of Restoration) was well-managed, based on three rules: accuracy of the ETR timing, and number of ETR changes.

---

## 2. Business Rules

### Rule 1 — ETR Set Too Early
> The crew restored power **more than 15 minutes after** the ETR.

```
RESTORE_MINUS_ETR_MINUTES > 15  →  ETR_SET_TOO_EARLY = 'Y'
```
Meaning: the ETR was set too optimistically.

### Rule 2 — ETR Set Too Late
> The crew restored power **more than 90 minutes before** the ETR.

```
RESTORE_MINUS_ETR_MINUTES < -90  →  ETR_SET_TOO_LATE = 'Y'
```
Meaning: the ETR was set too conservatively.

### Rule 3 — ETR Change Limit
- An **ETR change** is counted only when the new ETR value differs from the previous one for the same incident (idempotent updates do not count).
- The **first change is free** (baseline); only the 2nd change onward counts toward the limit.
- `ETR_CHANGE_COUNT = total_distinct_changes - 1`

| Outage Duration | Allowed Counted Changes |
|---|---|
| ≤ 120 minutes | 1 |
| > 120 minutes | 2 |

```
ETR_CHANGE_COUNT > ALLOWED_CHANGES  →  ETR_CHANGE_VIOLATION = 'Y'
```

### Overall: WELL_MANAGED_ETR
```
WELL_MANAGED_ETR = 'N'  if any of:
    ETR_SET_TOO_EARLY = 'Y'
    ETR_SET_TOO_LATE  = 'Y'
    ETR_CHANGE_VIOLATION = 'Y'

WELL_MANAGED_ETR = 'Y'  otherwise
```

> **Note**: Incidents with a `NULL` ETR cannot be evaluated. These rows will show NULL for ETR-derived columns and `WELL_MANAGED_ETR = NULL` (or excluded per UX decision).

---

## 3. Report Columns

| # | Column | Description | Source |
|---|--------|-------------|--------|
| 1 | `CONT_INCIDENCIA` | Incident number | `mv_incidencia.CONT_INCIDENCIA` |
| 2 | `OPCO` | Operating company name | `mv_cara_zona.NOM_ZONA` |
| 3 | `DIVISION` | Division name | `mv_brigada.DES_BRIGADA` |
| 4 | `STAGE` | Incident stage description | `mv_tip_fase_incid.DES_TIP_FASES` |
| 5 | `CREW` | Assigned crew / engineer name | `mv_coche_incidencia.ENGINEERNAME` |
| 6 | `ETR` | Current ETR timestamp | `mv_incidencia.FEC_PREVISTA` |
| 7 | `START_TIME` | Incident start time | `mv_incidencia.FEC_INI_INCIDENCIA` |
| 8 | `RESTORE_TIME` | Actual restoration time | `mv_incidencia.MALFUNC_END` |
| 9 | `OUTAGE_MINUTES` | Outage duration in minutes | Calculated |
| 10 | `OUTAGE_HHMM` | Outage duration in HH:MM format | Calculated |
| 11 | `RESTORE_MINUS_ETR_MINUTES` | `RESTORE_TIME - ETR` in minutes (signed) | Calculated |
| 12 | `RESTORE_MINUS_ETR_HHMM` | Same in ±HH:MM format | Calculated |
| 13 | `ETR_SET_TOO_LATE` | 'Y' if restore was > 90 min before ETR | Rule 2 |
| 14 | `ETR_SET_TOO_EARLY` | 'Y' if restore was > 15 min after ETR | Rule 1 |
| 15 | `ETR_CHANGE_COUNT` | Counted ETR changes (first is free) | `OMS_SAP_OUTAGE` |
| 16 | `ALLOWED_CHANGES` | Max allowed changes per outage duration | Rule 3 |
| 17 | `ETR_CHANGE_VIOLATION` | 'Y' if ETR_CHANGE_COUNT > ALLOWED_CHANGES | Rule 3 |
| 18 | `WELL_MANAGED_ETR` | 'Y' / 'N' — overall ETR quality | All rules |

---

## 4. Filters (Standard)

| Filter | Parameter | Type | Notes |
|--------|-----------|------|-------|
| Operating Company | `:iOpCo` | INTEGER | 0 = All NY, 1 = NYSEG, 2 = RGE, 3 = CMP |
| Start Date | `:dStartDate` | VARCHAR | `MM/DD/YYYY HH24:MI` |
| End Date | `:dEndDate` | VARCHAR | `MM/DD/YYYY HH24:MI` |
| Divisions | `:lstDivisions` | LIST | Optional; `COD_BRIGADA` list |
| Circuits / Storm Areas | `:lstCircuits` / `:lstStormAreas` | LIST | Optional; mutually exclusive |
| Notification Stages | `:lstNotifStages` | LIST\<Integer\> | Values 0–5. Stages **< 5** → query `MV_INCIDENCIA` (open). Stage **= 5** → query `MV_H_INCIDENCIA` (closed). Both groups included when list contains values from each range. |

---

## 5. Query Oracle (Parametrized)

> **Source tables**:
> - `MV_INCIDENCIA` / `MV_H_INCIDENCIA` — active and archived incidents (UNION)
> - `MV_CARA_ZONA` — OpCo name
> - `MV_BRIGADA` — division name
> - `MV_TIP_FASE_INCID` — stage description
> - `MV_COCHE_INCIDENCIA` / `MV_H_COCHE_INCIDENCIA` — crew
> - `MV_NOTIF_CODE_EG` — to filter EI only
> - `OMS_SAP_OUTAGE@REPOS_01_OMS` — ETR change history (DB link)

```sql
WITH main_t AS (
    /* ---------------------------------------------------------------
       Open incidents — included when lstNotifStages contains any value < 5
    --------------------------------------------------------------- */
    SELECT
        inc.cont_incidencia,
        cz.NOM_ZONA                                              AS opco,
        bri.DES_BRIGADA                                          AS division,
        inc.NUM_FASE_INCID || '-' || stg.DES_TIP_FASES           AS stage,
        NVL(coc.ENGINEERNAME, ' ')                               AS crew,
        inc.fec_prevista                                         AS etr,
        inc.fec_ini_incidencia                                   AS start_time,
        inc.malfunc_end                                          AS restore_time,
        ABS(ROUND((NVL(inc.malfunc_end, SYSDATE) - inc.fec_ini_incidencia) * 1440))
                                                                 AS outage_minutes,
        CASE
            WHEN inc.fec_prevista IS NULL THEN NULL
            ELSE ROUND((NVL(inc.malfunc_end, SYSDATE) - inc.fec_prevista) * 1440)
        END                                                      AS restore_minus_etr_minutes
    FROM mv_incidencia inc
    INNER JOIN mv_notif_code_eg nce  ON inc.INCIDENT_TYPE = nce.NOTIF_CODE
    LEFT  JOIN mv_cara_zona cz       ON inc.COD_ZONA      = cz.COD_ZONA
    LEFT  JOIN mv_brigada bri        ON inc.COD_BRIGADA   = bri.COD_BRIGADA
    LEFT  JOIN mv_tip_fase_incid stg ON inc.NUM_FASE_INCID = stg.TIP_FASES
    LEFT  JOIN mv_coche_incidencia coc ON inc.CONT_INCIDENCIA = coc.CONT_INCIDENCIA
    WHERE nce.NOTIFTYPE_CODE = 'EI'
      AND inc.CONF_PRED_FLAG != 'P'
      -- OpCo filter
      AND (:iOpCo = 0 OR inc.COD_ZONA = :iOpCo)
      -- Date filter (on start_time)
      AND inc.FEC_INI_INCIDENCIA >= TO_DATE(:dStartDate, 'MM/DD/YYYY HH24:MI')
      AND inc.FEC_INI_INCIDENCIA <= TO_DATE(:dEndDate,   'MM/DD/YYYY HH24:MI')
      -- Division filter (optional)
      AND (:lstDivisions IS NULL OR inc.COD_BRIGADA IN (:lstDivisions))
      -- Circuit filter (optional)
      AND (:lstCircuits IS NULL OR inc.CIRCUIT IN (:lstCircuits))
      -- Stage filter: only stages < 5 belong to the open table
      AND inc.NUM_FASE_INCID IN (:lstOpenStages)   -- SqlBuilder extracts values < 5 from lstNotifStages

    UNION ALL

    /* ---------------------------------------------------------------
       Closed / archived incidents — included when lstNotifStages contains 5
    --------------------------------------------------------------- */
    SELECT
        inc.cont_incidencia,
        cz.NOM_ZONA,
        bri.DES_BRIGADA,
        inc.NUM_FASE_INCID || '-' || stg.DES_TIP_FASES,
        NVL(coc.ENGINEERNAME, ' '),
        inc.fec_prevista,
        inc.fec_ini_incidencia,
        inc.malfunc_end,
        ABS(ROUND((NVL(inc.malfunc_end, SYSDATE) - inc.fec_ini_incidencia) * 1440)),
        CASE
            WHEN inc.fec_prevista IS NULL THEN NULL
            ELSE ROUND((NVL(inc.malfunc_end, SYSDATE) - inc.fec_prevista) * 1440)
        END
    FROM mv_h_incidencia inc
    INNER JOIN mv_notif_code_eg nce  ON inc.INCIDENT_TYPE = nce.NOTIF_CODE
    LEFT  JOIN mv_cara_zona cz       ON inc.COD_ZONA      = cz.COD_ZONA
    LEFT  JOIN mv_brigada bri        ON inc.COD_BRIGADA   = bri.COD_BRIGADA
    LEFT  JOIN mv_tip_fase_incid stg ON inc.NUM_FASE_INCID = stg.TIP_FASES
    LEFT  JOIN mv_h_coche_incidencia coc ON inc.CONT_INCIDENCIA = coc.CONT_INCIDENCIA
    WHERE nce.NOTIFTYPE_CODE = 'EI'
      AND inc.CONF_PRED_FLAG != 'P'
      AND (:iOpCo = 0 OR inc.COD_ZONA = :iOpCo)
      AND inc.FEC_INI_INCIDENCIA >= TO_DATE(:dStartDate, 'MM/DD/YYYY HH24:MI')
      AND inc.FEC_INI_INCIDENCIA <= TO_DATE(:dEndDate,   'MM/DD/YYYY HH24:MI')
      AND (:lstDivisions IS NULL OR inc.COD_BRIGADA IN (:lstDivisions))
      AND (:lstCircuits IS NULL OR inc.CIRCUIT IN (:lstCircuits))
      -- Closed table only matches stage 5; no additional stage filter needed here
),

/* ------------------------------------------------------------------
   ETR change history from OMS SAP outage DB-link
   Rule: first ETR value establishes baseline (count it as 1 change but
         it's "free"). ETR_CHANGE_COUNT = total_changes - 1.
------------------------------------------------------------------ */
ordered AS (
    SELECT
        so.incident_num,
        NULLIF(TRIM(so.etr), '') AS etr_val,
        TO_DATE(
            REGEXP_SUBSTR(so.message_id, '_(\d{14})_', 1, 1, NULL, 1),
            'YYYYMMDDHH24MISS'
        )                        AS message_ts,
        so.message_id
    FROM OMS_SAP_OUTAGE@REPOS_01_OMS so
    WHERE so.incident_num IN (SELECT t.cont_incidencia FROM main_t t)
),

lagged AS (
    SELECT
        incident_num,
        etr_val,
        message_ts,
        message_id,
        LAG(etr_val) OVER (
            PARTITION BY incident_num
            ORDER BY message_ts, message_id
        ) AS prev_etr
    FROM ordered
),

changes AS (
    SELECT
        incident_num,
        etr_val,
        message_ts,
        message_id,
        CASE
            WHEN etr_val IS NOT NULL
             AND (prev_etr IS NULL OR etr_val <> prev_etr)
            THEN 1
            ELSE 0
        END AS is_change
    FROM lagged
),

change_counts AS (
    SELECT
        incident_num,
        GREATEST(SUM(is_change) - 1, 0) AS etr_change_count
    FROM changes
    GROUP BY incident_num
)

/* ------------------------------------------------------------------
   Final SELECT
------------------------------------------------------------------ */
SELECT
    t.cont_incidencia,
    t.opco,
    t.division,
    t.stage,
    t.crew,
    t.etr,
    t.start_time,
    t.restore_time,
    t.outage_minutes,

    LPAD(FLOOR(t.outage_minutes / 60), 2, '0') || ':' ||
    LPAD(MOD(t.outage_minutes, 60), 2, '0')                      AS outage_hhmm,

    t.restore_minus_etr_minutes,

    CASE
        WHEN t.restore_minus_etr_minutes IS NULL THEN NULL
        ELSE
            CASE WHEN t.restore_minus_etr_minutes < 0 THEN '-' ELSE '' END ||
            LPAD(FLOOR(ABS(t.restore_minus_etr_minutes) / 60), 2, '0') || ':' ||
            LPAD(MOD(ABS(t.restore_minus_etr_minutes), 60), 2, '0')
    END                                                               AS restore_minus_etr_hhmm,

    CASE WHEN t.restore_minus_etr_minutes < -90 THEN 'Y' ELSE ' ' END
                                                                  AS etr_set_too_late,

    CASE WHEN t.restore_minus_etr_minutes > 15  THEN 'Y' ELSE ' ' END
                                                                  AS etr_set_too_early,

    NVL(cc.etr_change_count, 0)                                   AS etr_change_count,

    CASE WHEN t.outage_minutes <= 120 THEN 1 ELSE 2 END           AS allowed_changes,

    CASE
        WHEN NVL(cc.etr_change_count, 0) >
             CASE WHEN t.outage_minutes <= 120 THEN 1 ELSE 2 END
        THEN 'Y' ELSE ' '
    END                                                           AS etr_change_violation,

    CASE
        WHEN t.restore_minus_etr_minutes < -90                        THEN 'N'
        WHEN t.restore_minus_etr_minutes >  15                        THEN 'N'
        WHEN NVL(cc.etr_change_count, 0) >
             CASE WHEN t.outage_minutes <= 120 THEN 1 ELSE 2 END      THEN 'N'
        ELSE 'Y'
    END                                                           AS well_managed_etr

FROM main_t t
LEFT JOIN change_counts cc ON cc.incident_num = t.cont_incidencia
ORDER BY t.cont_incidencia
```

### Notes on the query
- **Table routing via `lstNotifStages`**: the `SqlBuilder` splits the incoming list into two sub-lists:
  - `lstOpenStages` = values from `lstNotifStages` where value **< 5** → used in the `MV_INCIDENCIA` branch with `AND inc.NUM_FASE_INCID IN (:lstOpenStages)`.
  - If `lstNotifStages` contains **5** → the `MV_H_INCIDENCIA` branch is appended via `UNION ALL`; otherwise that branch is omitted entirely.
  - If neither sub-list is populated (empty selection), the query returns no rows.
- `OMS_SAP_OUTAGE@REPOS_01_OMS` is accessed via DB-link. For CMP (OpCo = 3) this may need to be `OMS_SAP_OUTAGE@REPOS_02_OMS` — confirm with DBA.
- `GREATEST(..., 0)` guards against negative counts if data has anomalies.
- `restore_minus_etr_hhmm` uses NULL guard to avoid formatting errors when ETR is NULL.

---

## 6. Backend (Java) — Classes to Create

All files follow the `reportsstdelect` module pattern. Naming key: `WellManagedEtr`.

### 6.1 POJO — `WellManagedEtrReportPOJO`
**Package**: `com.icds.ibusa.reports`

```java
@Data
@NoArgsConstructor
@AllArgsConstructor
public class WellManagedEtrReportPOJO {
    private Long   contIncidencia;
    private String opco;
    private String division;
    private String stage;
    private String crew;
    private String etr;                      // formatted date string
    private String startTime;
    private String restoreTime;
    private Long   outageMinutes;
    private String outageHhmm;
    private Long   restoreMinusEtrMinutes;
    private String restoreMinusEtrHhmm;
    private String etrSetTooLate;            // 'Y' or ' '
    private String etrSetTooEarly;           // 'Y' or ' '
    private Long   etrChangeCount;
    private Integer allowedChanges;
    private String etrChangeViolation;       // 'Y' or ' '
    private String wellManagedEtr;           // 'Y' or 'N'
}
```

### 6.2 Request DTO — `WellManagedEtrReportRequest`
**Package**: `avangrid.icds.reportsstdelect.model`

Fields:
```
int           codeCompany      → :iOpCo   (normalized via getNormalizedCompanyCode())
String        startDate        → :dStartDate  ("MM/DD/YYYY HH24:MI")
String        endDate          → :dEndDate
List<String>  lstDivisions     → :lstDivisions
List<String>  lstCircuits      → :lstCircuits
List<Integer> lstNotifStages   → values 0–5; drives both table selection and stage filter
```

Helper methods (used by `SqlBuilder`, not bound as SQL parameters directly):
```java
// Returns values < 5 — used in the MV_INCIDENCIA branch
public List<Integer> getOpenStages()  { ... }

// Returns true if 5 is present — controls whether MV_H_INCIDENCIA branch is included
public boolean includeClosedIncidents() { ... }
```

`buildParameters()` binds `:lstOpenStages` (from `getOpenStages()`) and the standard filters. The closed-branch inclusion is handled structurally in `SqlBuilder`, not as a bind variable.

Implements `buildParameters()` returning `MapSqlParameterSource`.

### 6.3 Response DTO — `WellManagedEtrReportResponse`
**Package**: `avangrid.icds.reportsstdelect.model`

```java
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class WellManagedEtrReportResponse {
    private List<WellManagedEtrReportPOJO> lstReport;
    private String currentDate;
    private long   lNumReg;
}
```

### 6.4 SqlBuilder — `WellManagedEtrSqlBuilder` / `WellManagedEtrSqlBuilderImpl`
**Package**: `avangrid.icds.reportsstdelect.sqlbuilder`

- Interface + `@Component` implementation.
- `build(WellManagedEtrReportRequest request)` returns the full SQL string.
- Conditionally appends the UNION branch based on `bOpen` / `bClosed`.
- Resolves DB-link suffix using `ConnectionStringUtils.getDBLinkByOpCo(iOpCo)` for `OMS_SAP_OUTAGE`.
- Uses `StandardizedElectricalReportUtils.resolveTableName(...)` for `MV_INCIDENCIA` vs `MV_INCIDENCIA_ME`.

### 6.5 RowMapper — `WellManagedEtrRowMapper`
**Package**: `avangrid.icds.reportsstdelect.rowmapper`

Maps `ResultSet` → `WellManagedEtrReportPOJO`. Use `rs.getLong` / `rs.getString` with null guards.

### 6.6 Repository — `WellManagedEtrReportRepository`
**Package**: `avangrid.icds.reportsstdelect.repository`

```java
@Slf4j @Component @RequiredArgsConstructor
public class WellManagedEtrReportRepository {
    private final LoggingNamedJdbcTemplate jdbcTemplate;
    private final WellManagedEtrSqlBuilder sqlBuilder;
    private final WellManagedEtrRowMapper  rowMapper;

    public List<WellManagedEtrReportPOJO> getReport(WellManagedEtrReportRequest req) {
        String sql = sqlBuilder.build(req);
        log.debug("SQL [Well-Managed ETR Report]: {}", sql);
        return jdbcTemplate.query(sql, req.buildParameters(), rowMapper);
    }
}
```

### 6.7 Service — `WellManagedEtrReportService`
**Package**: `avangrid.icds.reportsstdelect.service`

Returns `WellManagedEtrReportResponse`. No aggregation needed (row-level report).

### 6.8 Controller — `WellManagedEtrReportController`
**Package**: `avangrid.icds.reportsstdelect.controller`

```
POST  /api/reports/well-managed-etr
```

- `@Cacheable(cacheResolver = "cacheResolver")`
- `@RequestBody WellManagedEtrReportRequest`
- Returns `ResponseEntity<WellManagedEtrReportResponse>`

---

## 7. Frontend (Angular) — Component

Follows the same structure as other standard electrical reports.

### Component name
`WellManagedEtrReportComponent`

### Route
`/reports/well-managed-etr`

### Features to implement (standard)
| Feature | Notes |
|---------|-------|
| Filter panel | OpCo, Start/End dates, Division, Circuit/Storm Area, Notification Stages (multi-select 0–5; stages < 5 = open incidents, stage 5 = closed incidents) |
| User-customizable report | Like other standard electrical reports — uses existing ad-hoc/layout persistence |
| Multi-column sorting | Client-side or server-side |
| Export to Excel | Existing Excel export service |
| Refresh / Auto-refresh | Standard pattern |
| Report size magnifying glass | Standard zoom control |
| Column selection | Column visibility toggle |
| Drill into incident | Click on `CONT_INCIDENCIA` → opens incident detail panel/page |
| View on map | Opens incident on OMS map — same as other standard reports |
| Search bar | Client-side filter on visible rows |

### Grid columns to display (default visible)

| Column | Label | Align | Notes |
|--------|-------|-------|-------|
| `contIncidencia` | Incident # | center | Clickable → drill-in + map |
| `opco` | OpCo | left | |
| `division` | Division | left | |
| `stage` | Stage | left | |
| `crew` | Crew | left | |
| `etr` | ETR | center | Date |
| `startTime` | Start Time | center | Date |
| `restoreTime` | Restore Time | center | Date |
| `outageMinutes` | Outage Min | right | |
| `outageHhmm` | Outage HH:MM | center | |
| `restoreMinusEtrMinutes` | Restore−ETR (min) | right | Signed |
| `restoreMinusEtrHhmm` | Restore−ETR HH:MM | center | Signed |
| `etrSetTooLate` | ETR Too Late | center | Highlight 'Y' in red |
| `etrSetTooEarly` | ETR Too Early | center | Highlight 'Y' in red |
| `etrChangeCount` | ETR Changes | right | |
| `allowedChanges` | Allowed Changes | right | |
| `etrChangeViolation` | Change Violation | center | Highlight 'Y' in amber |
| `wellManagedEtr` | Well-Managed | center | 'Y' = green, 'N' = red |

### Endpoint
```
POST /icds/api/reports/well-managed-etr
```

---

## 8. Open Questions / Risks

| # | Question | Owner |
|---|----------|-------|
| Q1 | For CMP (OpCo=3), should `OMS_SAP_OUTAGE` use `@REPOS_02_OMS`? Confirm DB-link name with DBA. | DBA |
| Q2 | Should incidents without an ETR (`FEC_PREVISTA IS NULL`) be included in the report with blank ETR columns, or excluded entirely? | Business |
| Q3 | `lstNotifStages` filter: if the list is empty (no stages selected), should the report return empty or default to all stages? | UX |
| Q4 | Is `MV_COCHE_INCIDENCIA` always a 1:1 with `CONT_INCIDENCIA`, or can there be multiple crew rows? If multiple, take the latest assignment. | DBA |
| Q5 | Storm Area filter: confirm whether it maps to `MV_STORM_BREAKOUT_CIRCUIT` or a separate filter field. | Dev |

---

## 9. Sample Data (from ticket)

| CONT_INCIDENCIA | ETR | START_TIME | RESTORE_TIME | OUTAGE_MIN | RESTORE−ETR_MIN | TOO_LATE | TOO_EARLY | ETR_CHANGES | ALLOWED | VIOLATION | WELL_MANAGED |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1532427 | 10-FEB-26 17:00 | 10-FEB-26 14:58 | 12-FEB-26 11:56 | 2698 | 2577 | Y | | 1 | 2 | N | N |
| 1532454 | 12-FEB-26 13:45 | 12-FEB-26 12:06 | 12-FEB-26 12:33 | 27 | -71 | | | 0 | 1 | | Y |
| 1532457 | 12-FEB-26 14:15 | 12-FEB-26 12:36 | 12-FEB-26 12:43 | 8 | -91 | Y | | 0 | 1 | | N |
| 1532459 | 12-FEB-26 14:00 | 12-FEB-26 12:49 | 12-FEB-26 13:53 | 63 | -7 | | | 2 | 1 | Y | N |

> Incident 1532427: `RESTORE_MINUS_ETR = +2577` min (restored 2577 min AFTER ETR) → ETR_SET_TOO_EARLY = Y. Duration 2698 min > 120 → allowed_changes = 2; etr_change_count = 1 → no violation. WELL_MANAGED = N (due to too early).
