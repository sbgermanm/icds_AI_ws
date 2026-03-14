-- ============================================================
-- ICDSDEV-422 - Well-Managed ETRs Report
-- Fecha: 2026-03-12
-- Basada en: nueva
-- ============================================================
-- Descripción:
--   Evalúa si el ETR de cada incidencia EI fue bien gestionado
--   según tres reglas de negocio:
--     R1 - ETR Too Early : restore_time > etr + 15 min
--     R2 - ETR Too Late  : restore_time < etr - 90 min
--     R3 - Change Limit  : cambios contados > límite permitido
--                          (1 si outage <= 120 min, 2 si > 120 min)
--   El primer cambio de ETR es gratis; solo el 2.o en adelante cuenta.
-- ============================================================
-- Parámetros de entrada:
--   :iOpCo         -> Código compañía (INTEGER; 0 = All NY)
--   :dStartDate    -> Fecha inicio  (VARCHAR2, 'MM/DD/YYYY HH24:MI')
--   :dEndDate      -> Fecha fin     (VARCHAR2, 'MM/DD/YYYY HH24:MI')
--   :lstDivisions  -> Lista de COD_BRIGADA (LIST<VARCHAR>, opcional)
--   :lstCircuits   -> Lista de circuitos   (LIST<VARCHAR>, opcional; mutuamente exclusivo con lstStormAreas)
--   :lstStormAreas -> Lista de IDs de storm area (LIST<VARCHAR>, opcional; mutuamente exclusivo con lstCircuits)
--   :lstIncidentStages -> Subconjunto de lstNotifStages con valores < 5
--                     (extraído por el SqlBuilder; este branch
--                      se omite en el UNION si la lista está vacía)
-- ============================================================
-- Nota: esta query documenta la versión NY.
--   Para CMP (OpCo=3) el SqlBuilder sustituye en tiempo de ejecución:
--     MV_INCIDENCIA        -> MV_INCIDENCIA_ME
--     MV_H_INCIDENCIA      -> MV_H_INCIDENCIA_ME
--     MV_CARA_ZONA         -> MV_CARA_ZONA_ME
--     @REPOS_01_OMS        -> @REPOS_02_OMS
--   El branch UNION ALL con MV_H_INCIDENCIA se incluye solo
--   cuando lstNotifStages contiene el valor 5.
-- ============================================================
WITH main_t AS (
    /* ----------------------------------------------------------
     Open incidents (NUM_FASE_INCID < 5)
     SqlBuilder injects: AND inc.NUM_FASE_INCID IN (:lstIncidentStages)
     and omits this entire branch when :lstIncidentStages is empty.
     ---------------------------------------------------------- */
    SELECT
        inc.CONT_INCIDENCIA,
        cz.NOM_ZONA AS opco,
        bri.DES_BRIGADA AS division,
        inc.NUM_FASE_INCID || '-' || stg.DES_TIP_FASES AS stage,
        NVL(coc.ENGINEERNAME, ' ') AS crew,
        inc.FEC_PREVISTA AS etr,
        inc.FEC_INI_INCIDENCIA AS start_time,
        inc.MALFUNC_END AS restore_time,
        ABS(
            ROUND(
                (
                    NVL(inc.MALFUNC_END, SYSDATE) - inc.FEC_INI_INCIDENCIA
                ) * 1440
            )
        ) AS outage_minutes,
        CASE
            WHEN inc.FEC_PREVISTA IS NULL THEN NULL
            ELSE ROUND(
                (NVL(inc.MALFUNC_END, SYSDATE) - inc.FEC_PREVISTA) * 1440
            )
        END AS restore_minus_etr_minutes
    FROM
        mv_incidencia inc
        LEFT JOIN mv_cara_zona cz ON inc.COD_ZONA = cz.COD_ZONA
        LEFT JOIN mv_brigada bri ON inc.COD_BRIGADA = bri.COD_BRIGADA
        LEFT JOIN mv_tip_fase_incid stg ON inc.NUM_FASE_INCID = stg.TIP_FASES
        LEFT JOIN mv_coche_incidencia coc ON inc.CONT_INCIDENCIA = coc.CONT_INCIDENCIA
    WHERE
        inc.INCIDENT_TYPE IN ('EI01', 'EI02', 'EI04', 'EI05')
        AND inc.CONF_PRED_FLAG != 'P'
        AND inc.IND_DEFAULT != 'S'
        AND inc.TIP_INCIDENCIA != 'CP'
        AND (
            :iOpCo = 0
            OR inc.COD_ZONA = :iOpCo
        )
        AND inc.FEC_INI_INCIDENCIA >= TO_DATE(:dStartDate, 'MM/DD/YYYY HH24:MI')
        AND inc.FEC_INI_INCIDENCIA <= TO_DATE(:dEndDate, 'MM/DD/YYYY HH24:MI')
        AND (:lstCircuits IS NULL OR inc.CIRCUIT IN (:lstCircuits))

         -- DIVISION / Storm Area filter (mutually exclusive — SqlBuilder injects one):
        -- Option A · filter by DIVISION list:
        -- AND (
        --     :lstDivisions IS NULL
        --     OR inc.COD_BRIGADA IN (:lstDivisions)
        -- )
        -- Option B · filter by storm area (uses MV_STORM_BREAKOUT_CIRCUIT_ME for CMP):
        --   AND EXISTS (SELECT 1 FROM MV_STORM_BREAKOUT_CIRCUIT sbc
        --               WHERE sbc.CIRCUIT = inc.CIRCUIT
        --                 AND sbc.ID_SB_AREA IN (:lstStormAreas))
        AND inc.NUM_FASE_INCID IN (:lstIncidentStages)
    UNION     ALL
    /* ----------------------------------------------------------
     Closed / archived incidents (NUM_FASE_INCID = 5)
     SqlBuilder appends this branch only when lstNotifStages
     contains the value 5.
     ---------------------------------------------------------- */
    SELECT
        inc.CONT_INCIDENCIA,
        cz.NOM_ZONA,
        bri.DES_BRIGADA,
        inc.NUM_FASE_INCID || '-' || stg.DES_TIP_FASES,
        NVL(coc.ENGINEERNAME, ' '),
        inc.FEC_PREVISTA,
        inc.FEC_INI_INCIDENCIA,
        inc.MALFUNC_END,
        ABS(
            ROUND(
                (
                    NVL(inc.MALFUNC_END, SYSDATE) - inc.FEC_INI_INCIDENCIA
                ) * 1440
            )
        ),
        CASE
            WHEN inc.FEC_PREVISTA IS NULL THEN NULL
            ELSE ROUND(
                (NVL(inc.MALFUNC_END, SYSDATE) - inc.FEC_PREVISTA) * 1440
            )
        END
    FROM
        mv_h_incidencia inc
        LEFT JOIN mv_cara_zona cz ON inc.COD_ZONA = cz.COD_ZONA
        LEFT JOIN mv_brigada bri ON inc.COD_BRIGADA = bri.COD_BRIGADA
        LEFT JOIN mv_tip_fase_incid stg ON inc.NUM_FASE_INCID = stg.TIP_FASES
        LEFT JOIN mv_h_coche_incidencia coc ON inc.CONT_INCIDENCIA = coc.CONT_INCIDENCIA
    WHERE
        inc.INCIDENT_TYPE IN ('EI01', 'EI02', 'EI04', 'EI05')
        AND inc.CONF_PRED_FLAG != 'P'
        AND inc.IND_DEFAULT != 'S'
        AND inc.TIP_INCIDENCIA != 'CP'
        AND (
            :iOpCo = 0
            OR inc.COD_ZONA = :iOpCo
        )
        AND inc.FEC_INI_INCIDENCIA >= TO_DATE(:dStartDate, 'MM/DD/YYYY HH24:MI')
        AND inc.FEC_INI_INCIDENCIA <= TO_DATE(:dEndDate, 'MM/DD/YYYY HH24:MI')
        AND (:lstCircuits IS NULL OR inc.CIRCUIT IN (:lstCircuits))

         -- DIVISION / Storm Area filter (mutually exclusive — SqlBuilder injects one):
        -- Option A · filter by DIVISION list:
        -- AND (
        --     :lstDivisions IS NULL
        --     OR inc.COD_BRIGADA IN (:lstDivisions)
        -- )
        -- Option B · filter by storm area (uses MV_STORM_BREAKOUT_CIRCUIT_ME for CMP):
        --   AND EXISTS (SELECT 1 FROM MV_STORM_BREAKOUT_CIRCUIT sbc
        --               WHERE sbc.CIRCUIT = inc.CIRCUIT
        --                 AND sbc.ID_SB_AREA IN (:lstStormAreas))
        AND inc.NUM_FASE_INCID IN (:lstIncidentStages)
),
/* ------------------------------------------------------------------
 ETR change history from OMS SAP outage messages (DB-link).
 The message timestamp is encoded inside the MESSAGE_ID field.
 CMP: SqlBuilder replaces @REPOS_01_OMS -> @REPOS_02_OMS.
 ------------------------------------------------------------------ */
ordered AS (
    SELECT
        so.INCIDENT_NUM,
        NULLIF(TRIM(so.ETR), '') AS etr_val,
        TO_DATE(
            REGEXP_SUBSTR(so.MESSAGE_ID, '_(\d{14})_', 1, 1, NULL, 1),
            'YYYYMMDDHH24MISS'
        ) AS message_ts,
        so.MESSAGE_ID
    FROM
        OMS_SAP_OUTAGE @REPOS_01_OMS so
    WHERE
        so.INCIDENT_NUM IN (
            SELECT
                t.CONT_INCIDENCIA
            FROM
                main_t t
        )
),
/* Detect real ETR changes — idempotent updates (same value) are ignored */
lagged AS (
    SELECT
        INCIDENT_NUM,
        etr_val,
        message_ts,
        MESSAGE_ID,
        LAG(etr_val) OVER (
            PARTITION BY INCIDENT_NUM
            ORDER BY
                message_ts,
                MESSAGE_ID
        ) AS prev_etr
    FROM
        ordered
),
changes AS (
    SELECT
        INCIDENT_NUM,
        CASE
            WHEN etr_val IS NOT NULL
            AND (
                prev_etr IS NULL
                OR etr_val <> prev_etr
            ) THEN 1
            ELSE 0
        END AS is_change
    FROM
        lagged
),
change_counts AS (
    SELECT
        INCIDENT_NUM,
        GREATEST(SUM(is_change) - 1, 0) AS etr_change_count
    FROM
        changes
    GROUP BY
        INCIDENT_NUM
)
/* ------------------------------------------------------------------
 Final output
 ------------------------------------------------------------------ */
SELECT
    t.CONT_INCIDENCIA,
    t.opco,
    t.division,
    t.stage,
    t.crew,
    t.etr,
    t.start_time,
    t.restore_time,
    t.outage_minutes,
    LPAD(FLOOR(t.outage_minutes / 60), 2, '0') || ':' || LPAD(MOD(t.outage_minutes, 60), 2, '0') AS outage_hhmm,
    t.restore_minus_etr_minutes,
    -- Nested CASE ensures NULL propagates correctly when ETR is absent
    CASE
        WHEN t.restore_minus_etr_minutes IS NULL THEN NULL
        ELSE CASE
            WHEN t.restore_minus_etr_minutes < 0 THEN '-'
            ELSE ''
        END || LPAD(
            FLOOR(ABS(t.restore_minus_etr_minutes) / 60),
            2,
            '0'
        ) || ':' || LPAD(
            MOD(ABS(t.restore_minus_etr_minutes), 60),
            2,
            '0'
        )
    END AS restore_minus_etr_hhmm,
    CASE
        WHEN t.restore_minus_etr_minutes < -90 THEN 'Y'
        ELSE ' '
    END AS etr_set_too_late,
    CASE
        WHEN t.restore_minus_etr_minutes > 15 THEN 'Y'
        ELSE ' '
    END AS etr_set_too_early,
    NVL(cc.etr_change_count, 0) AS etr_change_count,
    CASE
        WHEN t.outage_minutes <= 120 THEN 1
        ELSE 2
    END AS allowed_changes,
    CASE
        WHEN NVL(cc.etr_change_count, 0) > CASE
            WHEN t.outage_minutes <= 120 THEN 1
            ELSE 2
        END THEN 'Y'
        ELSE ' '
    END AS etr_change_violation,
    -- 'N' if any rule is violated; 'Y' otherwise (NULL ETR -> treated as 'Y')
    CASE
        WHEN t.restore_minus_etr_minutes < -90 THEN 'N'
        WHEN t.restore_minus_etr_minutes > 15 THEN 'N'
        WHEN NVL(cc.etr_change_count, 0) > CASE
            WHEN t.outage_minutes <= 120 THEN 1
            ELSE 2
        END THEN 'N'
        ELSE 'Y'
    END AS well_managed_etr
FROM
    main_t t
    LEFT JOIN change_counts cc ON cc.INCIDENT_NUM = t.CONT_INCIDENCIA
ORDER BY
    t.CONT_INCIDENCIA