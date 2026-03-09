# Índice de Queries Oracle

## Queries existentes

| Ticket/Nombre | Archivo o clase | Qué hace | Tablas principales | Parámetros |
|---------------|-----------------|----------|--------------------|------------|
| ICS Storm Detailed (110) | `DefaultDetailReportRepository.java` + `IcsStormDetailedFieldsAndTablesSqlBuilder.java` + `IcsStormDetailedWhereSqlBuilder.java` | Informe detallado EI/ET por incidencia: work center, circuito, crew, ETR, daños vinculados, REDC, pole info | INCIDENCIA, COCHE_INCIDENCIA, BRIGADA, SUBSTATIONCIRCUIT, PROVINCIA, NOTIF_CODE_EG, TIP_FASE_INCID, INCIDENCIA_DAMAGES, MASTER_POLE, STORM_BREAKOUT_CIRCUIT, REDC, CARA_ZONA, ELEM_MP | iOpCo, lstDivisions, lstNotifCodes, lstNotifStages, dStartDate, dEndDate |
| WBDB Primary Report (111) | `DefaultDetailReportRepository.java` + `WbdbDetailedWhereSqlBuilder.java` | Variante del ICS Storm con filtros WBDB específicos | (mismas que ICS Storm) | (mismos) |
| Pole Track Report (112) | `DefaultDetailReportRepository.java` + `IcsPoleTrackFieldsAndTablesSqlBuilder.java` + `IcsPoleTrackWhereSqlBuilder.java` | Informe ICS Storm + número SAP de notificación (LLAMADA_PROCESADA join) | INCIDENCIA, COCHE_INCIDENCIA, LLAMADA_PROCESADA, BRIGADA, etc. | (mismos + lstCircuits) |
| PCS Call OMS (113) | `DefaultDetailReportRepository.java` + `PcsCallOmsWhereSqlBuilder.java` | ICS Storm + filtro por condado/town y clientes life-support (subquery MV_AFFECTED_CUSTOMER) | (mismas que ICS Storm) + MV_AFFECTED_CUSTOMER | iOpCo, lstDivisions, lstCounties, lstTowns, optLifeSupportCust |
| ICS Metric Detailed (114) | `DefaultDetailReportRepository.java` + `IcsMetricDetailedFieldsAndTablesSqlBuilder.java` | ICS Storm + duración del apagón (HH:MM:SS) calculada en SQL | (mismas que ICS Storm) | (mismos) |
| ICS Metric Area (1114) | `DefaultDetailReportRepository.java` + `IcsMetricAreaFieldsAndTablesSqlBuilder.java` | Variante área del ICS Metric | (mismas) | (mismos) |
| ICS Veg Management (116) | `DefaultDetailReportRepository.java` + `IcsVegDetailedWhereSqlBuilder.java` | ICS Storm filtrado por incidencias de vegetación | (mismas que ICS Storm) | (mismos) |
| ICS Telecom Pole (119) | `DefaultDetailReportRepository.java` + `IcsTelecomPoleFieldsAndTablesSqlBuilder.java` | ICS Storm + campos de poste telecom (MASTER_POLE): altura, lat/lon, clase, attachers, cruce de calles | INCIDENCIA, MASTER_POLE (pl), COCHE_INCIDENCIA, etc. | (mismos) |
| NY Reliability Indexes (125) | `NyReliabilityIndexesSqlBuilderImpl.java` | Índices de fiabilidad NY por división: clientes servidos, fuera de servicio, % afectados, apagones >24h, flags mayor outage | MV_CALC_CIRCUIT(_ME), V_ICDS_SUMMARY_DATA_CIRCUIT(_ME), MV_INCIDENCIA(_ME), MV_BRIGADA, MV_CARA_ZONA(_ME), MV_SUBSTATIONCIRCUIT(_ME), MV_STORM_BREAKOUT_CIRCUIT(_ME), MV_STORM_BREAKOUT_AREA(_ME) | iOpCo, lstDivisions, dStartDate, dEndDate, lstNotifStages |
| Broken Poles Detail | `BrokenPolesDetailSqlBuilderImpl.java` | Detalle de postes caídos: prioridad, estado, altura, clase, attachers, equipo especial | V_BP_LAST_DETAIL, BP_POLE_STATUS | (ninguno) |
| Broken Poles Main | `BrokenPolesMainSqlBuilderImpl.java` | Informe principal de postes caídos con circuitos, equipos, crew, fechas | INCIDENCIA/H_INCIDENCIA, COCHE_INCIDENCIA/H_COCHE_INCIDENCIA, LLAMADA_PROCESADA/H_LLAMADA_PROCESADA, CARA_ZONA, BRIGADA, SUBSTATIONCIRCUIT, MASTER_POLE, TIPO_DIGSAFE | iOpCo, lstDivisions, dStartDate, dEndDate, lstNotifCodes, lstNotifStages |
| EO Unnest Report (115) | `EOUnnestSqlBuilderImpl.java` | Llamadas EO sin asignar a incidencias: estado, circuito, cliente, comentarios, SONP | CUSTOMER_COMMENT, LLAMADA_PROCESADA, OMS_DISCON_CUSTS, CARA_ZONA, BRIGADA, SUBSTATIONCIRCUIT, NOTIF_CODE_EG, CRIT_CUST_CODES | iOpCo, lstDivisions, lstCircuits, dStartDate, dEndDate |
| Unassigned Events (121) | `UnassignedEventsSqlBuilderImpl.java` | Eventos AMI sin asignar a incidencias | V_UNASSIGNED_EVENTS@DBLink, BRIGADA@DBLink, SUBSTATIONCIRCUIT@DBLink, CRIT_CUST_CODES@DBLink | lstDivisions, lstCircuits, dStartDate, dEndDate |
| Unassigned Pings (122) | `UnassignedPingsSqlBuilderImpl.java` | Pings sin asignar: estado, usuario, fechas | V_UNASSIGNED_PINGS@DBLink, BRIGADA@DBLink, SUBSTATIONCIRCUIT@DBLink, CRIT_CUST_CODES@DBLink | lstDivisions, lstCircuits, dStartDate, dEndDate |
| ICS Storm Summary | `DefaultSummarySqlBuilder.java` + `IcsStormSummaryReportFromSqlBuilder.java` | Resumen de incidencias por división (abiertas + cerradas) | MV_INCIDENCIA, MV_H_INCIDENCIA, MV_NOTIF_CODE_EG, MV_BRIGADA, MV_TIP_FASE_INCID | iOpCo, lstDivisions, lstNotifCodes, lstNotifStages, dStartDate, dEndDate, bOpen, bClosed |
| ICS Metric Summary | `DefaultSummarySqlBuilder.java` (mismo flujo que ICS Storm) | Índices ICS por métrica/división | (mismas que ICS Storm) | (mismos) |
| getAllCalls | `SqlReportsQueries.java` | Conteo de llamadas EO por zona/división/condado/circuito | MV_LLAMADA_PROCESADA, MV_INCIDENCIA | iOpCo, strStartDateFrom, strStartDateTo |
| getAllIncidents | `SqlReportsQueries.java` | Conteo de incidencias por tipo (ET/EI) y región | MV_INCIDENCIA, MV_AFFECTED_CUSTOMER, MV_NOTIF_CODE_EG | iOpCo, strStartDateFrom, strStartDateTo |
| getNumCircuits | `SqlReportsQueries.java` | Conteo de circuitos afectados por incidencias EI | MV_INCIDENCIA, MV_AFFECTED_CUSTOMER, MV_NOTIF_CODE_EG | iOpCo, strStartDateFrom, strStartDateTo |
| getCustomersOut | `SqlReportsQueries.java` | Clientes fuera de servicio (confirmados o predichos) por región | MV_INCIDENCIA, MV_AFFECTED_CUSTOMER, MV_NOTIF_CODE_EG | iOpCo, strStartDateFrom, strStartDateTo |
| getETRWarnings | `SqlReportsQueries.java` | Avisos ETR (ROJO/PURPLE/PINK) por región | MV_INCIDENCIA, MV_AFFECTED_CUSTOMER, MV_NOTIF_CODE_EG | iOpCo, strStartDateFrom, strStartDateTo |
| getTotalAffectedCustomers | `SqlReportsQueries.java` | Total clientes afectados por división/condado/REDC | V_TOTAL_AFFECTED_CUSTOMERS(_ME), V_TOTAL_AFF_CUST_COUNTY(_ME), MV_CARA_ZONA, MV_BRIGADA, MV_PROVINCIA | iOpCo, strStartDateFrom, strStartDateTo |
| AdHoc Report get | `AdHocReportDAO.java` | Obtener reporte ad-hoc por ID | ICDS_US_ADHOC_REPORTS | reportId |
| AdHoc Report insert/update/delete | `AdHocReportDAO.java` | CRUD reportes ad-hoc | ICDS_US_ADHOC_REPORTS | reportId, reportName, reportDesc, reportOwner, layoutId, filterId |
| SEQ_ADHOC_REPORTS.NEXTVAL | `AdHocReportDAO.java` | Obtener siguiente ID de reporte | DUAL (secuencia) | (ninguno) |
| Circuit exist | `Circuit.java` | Verificar si existe un circuito (NY o ME) | MV_SUBSTATIONCIRCUIT, MV_SUBSTATIONCIRCUIT_ME | sCodCircuit |
| Circuit getCircuits | `Circuit.java` | Listar circuitos por compañía y división/área | MV_SUBSTATIONCIRCUIT(_ME), MV_STORM_BREAKOUT_CIRCUIT | sCodCompany, sFilterSelection, lstDivisions |
| Circuit getAreas | `Circuit.java` | Listar áreas (condados/regiones) | MV_PROVINCIA | (ninguno) |
| SapPfp getAll | `SapPfpDAO.java` | Lista PFP por zona (BOMS) | SAP_PFP, MV_CARA_ZONA, MV_CARA_ZONA_ME | iOpCo |
| SapPfp getByNum | `SapPfpDAO.java` | Obtener PFP por número | SAP_PFP | pfpBpNum |
| AffectedCustomers searchInDatabase | `AffectedCustomersByDevice.java` | Buscar request en NY o ME | ICDS_SRVC_REQUEST@DBLink | requestId |
| AffectedCustomers getDeviceInfo | `AffectedCustomersByDevice.java` | Info dispositivo (ELEM_MP) para reporte afectados | ICDS_SRVC_PARAM@DBLink, ELEM_MP@DBLink, SUBSTATIONCIRCUIT@DBLink, CARA_ZONA@DBLink, BRIGADA@DBLink | requestId, b1Name, b2Name, b3Name, elName |
| AffectedCustomers getAffCustomersList | `AffectedCustomersByDevice.java` | Clientes afectados por dispositivo | AFFECTED_CUSTOMER@DBLink, INCIDENCIA@DBLink, etc. | (varios) |
| SummaryIncidents getAllLocationCodes | `SummaryIncidents.java` | Códigos de ubicación (división/condado) | MV_BRIGADA, MV_PROVINCIA, REDC | iOpCo, sFilter |
| SummaryIncidents getAllLocationSummary | `SummaryIncidents.java` | Resumen por ubicación: llamadas, incidencias, clientes out | (consultas dinámicas) | iOpCo, sFilter |
| IncidentStages getStages | `IncidentStages.java` / `IncidentStageDAO.java` | Etapas de una incidencia | MV_INCIDENCIA, MV_H_INCIDENCIA, MV_TIP_FASE_INCID | sIncidentNo |
| IncidentDispatch getDispatchInfo | `IncidentDispatch.java` | Info despacho de incidencia | MV_COCHE_INCIDENCIA, MV_INCIDENCIA | sIncidentNo |
| IncidentScope getScope | `IncidentScope.java` | Ámbito de incidencia | MV_AMBITO_INCID, MV_INCIDENCIA | sIncidentNo |
| MassOutage sqlEtr/sqlCrewStatus | `MassOutageManagementDAO.java` | ETRs y estados de crew para popup masivo | (tablas OMS) | (varios) |
| MassOutage massUpdate (PL/SQL) | `MassOutageManagementDAO.java` | Actualización masiva vía SimpleJdbcCall | PKG_MASS_OUTAGE_MANAGEMENT | (parámetros del paquete) |
| BOMSCrewUpdate insert/select | `BOMSCrewUpdateDAO.java` | Insertar/consultar actualizaciones crew BOMS | BOMS_CREW_UPDATE | operationId, pendingId, etc. |
| PermissionPurgeBOMS | `PermissionPurgeBOMSDAO.java` | Permisos de purga BOMS | (tablas BOMS) | (varios) |
| SummaryCallBOMS | `SummaryCallBOMSDAO.java` | Resumen de llamadas BOMS | MV_LLAMADA_PROCESADA, etc. | sOpCo |
| WeatherCodes | `WeatherCodes.java` | Códigos de tiempo | MV_WEATHER_CODES | (ninguno) |
| DevicesCodes | `DevicesCodes.java` | Códigos de dispositivos | MV_DEVICE_CODES | (ninguno) |
| ActionLog write | `ActionLog.java` | Registrar acción de usuario | ICDS_ACTION_LOG | sUser, sAction |
| CustomerOutageTime ERA | `CustomerOutageTimeMultipleReport.java` + `beans.xml` (prop sql.era / sql.era.me) | Extract ERA (ZCCR3027EE): duración outage, clientes afectados, dispositivo, causa, clima | MV_H_INCIDENCIA, MV_H_AMBITO_INCID, MV_SUBSTATIONCIRCUIT, MV_NOTIF_CODE_EG, MV_BRIGADA, MV_AREA_SIGRID, MV_ELEM_MP, MV_POSICION, MV_SAP_CAUSE_CODE, MV_SAP_DEVICE_CODE, MV_SAP_WEATHER_CODE, MV_TIPO_AMBITO | iOpCo, lstDivisions, strStartDateFrom, strStartDateTo |
| ny_reliability_indexes (SQL doc) | `doc/ny_reliability_indexes_v2.sql` | Referencia SQL del informe NY Reliability | mv_calc_circuit, MV_CARA_ZONA, V_ICDS_SUMMARY_DATA_CIRCUIT, mv_incidencia, mv_brigada | :iOpCo, :lstDivisions, :dStartDate, :dEndDate, :lstNotifStages |
| Region Outage Summary (ZCCR3019EE) | `RegionOutageSummaryReport.java` | Resumen de apagones por región/división/condado/circuito: llamadas, incidencias, clientes, ETR warnings | MV_LLAMADA_PROCESADA, MV_INCIDENCIA, MV_AFFECTED_CUSTOMER, MV_NOTIF_CODE_EG, V_TOTAL_AFFECTED_CUSTOMERS(_ME), MV_CARA_ZONA, MV_BRIGADA, MV_PROVINCIA | iOpCo, strStartDateFrom, strStartDateTo |
| County Outage Summary (ZCC_OMS_OUTSUM_CNTY) | `CountyOutageSummaryReport.java` | Resumen de apagones por condado/town/carretera | (mismas que Region) | iOpCo, strStartDateFrom, strStartDateTo |
| County Circuit Outage Summary | `CountyCircuitOutageSummaryReport.java` | Resumen de apagones por condado con detalle de circuito | (mismas que Region) | iOpCo, strStartDateFrom, strStartDateTo |
| Outage Storm PSC (ZCCR3036EE) | `OutageStormPSCReport.java` | Informe PSC (Public Service Commission) de tormenta: llamadas asignadas + clientes por condado/división | (mismas que Region, bOnlyAssignedCalls=true) | iOpCo, strStartDateFrom, strStartDateTo |
| Outage Statistical Report | `OutageStatisticalReport.java` | Informe estadístico: pico clientes out, actuales, afectados, por división/condado/REDC | ICDS_US_STATISTICS, MV_INCIDENCIA, MV_AMBITO_INCID, MV_H_INCIDENCIA, MV_H_AMBITO_INCID, MV_AFFECTED_CUSTOMER, MV_H_AFFECTED_CUSTOMER, MV_BRIGADA, MV_CARA_ZONA, MV_PROVINCIA | iOpCo, strStartDateFrom, strStartDateTo, sFilterSelection |
| Outage History Report | `OutageHistoryReport.java` | Historial de incidencias: id, división, tipo, fechas, causa, afectados, updates | V_OUTAGE_COUNTS(_suffix) | iOpCo, sDateFrom, sDateTo, lstDivisions, lstIncidentStages, sIncidentType |
| Incident-Customer Report (ZCCR3023EE) | `IncidentCustomerReport.java` | Informe cliente-incidencia: EI/EO/ET abiertos/cerrados, filtros por tipo de cliente (life support, EBD, critical facility) | MV_INCIDENCIA/H_INCIDENCIA, MV_AFFECTED_CUSTOMER/H, MV_LLAMADA_PROCESADA/H, MV_COCHE_INCIDENCIA, MV_BRIGADA, MV_SUBSTATIONCIRCUIT, MV_PROVINCIA, CRIT_CUST_CODES, REDC, REDC_COUNTY_BRIDGE, INCIDENCIA_DAMAGES/H | iOpCo, lstDivisions, sDateFrom, sDateTo, lstPowerQualityCodes |
| Gas Monitoring Report | `MonitoringGasReport.java` | Incidencias de gas: crew, tiempos de respuesta, color bucket (verde/amarillo/rojo) | MV_INCIDENCIA, MV_H_INCIDENCIA, MV_BRIGADA, MV_LLAMADA_PROCESADA, MV_H_LLAMADA_PROCESADA, MV_NOTIF_CODE_EG, MV_TIP_FASE_INCID, MV_COCHE_INCIDENCIA, MV_H_COCHE_INCIDENCIA, MV_CLIENTE_SIC | iOpCo, lstDivisions, dStartDate, dEndDate, lstIncidentTypes, lstNotifCodes, lstIncidentStages |
| SAIDI/SAIFI/CAIDI Indexes (CMP) | `Indexes.java` | Índices de fiabilidad del día (SAIDI, SAIFI, CAIDI, TMED) para CMP | MV_INCIDENCIA_ME, MV_AMBITO_INCID_ME, MV_H_INCIDENCIA_ME, MV_H_AMBITO_INCID_ME, MV_CALC_CIRCUIT_ME, reliability_baseline | iOpco (hardcoded CMP=3) |
| reliability_baseline getTmed | `Indexes.java` | Obtener TMED (tiempo medio esperado) por OpCo | reliability_baseline | iOpco |
| Customers getContractsByCompany | `Customers.java` | Total de clientes/contratos por compañía | V_CIRCUIT_INFORMATION_ALL | (ninguno) |
| Customers getContractsByDivision | `Customers.java` | Total de clientes por división | V_CIRCUIT_INFORMATION_ALL | (ninguno) |
| Customers getContractsByCounty | `Customers.java` | Total contratos por condado | V_CLIENTE_SIC, V_POSICION | (ninguno) |
| Customers getContractsByCircuit | `Customers.java` | Total clientes por circuito | V_CIRCUIT_INFORMATION_ALL | (ninguno) |
| Customers getContractsByStormArea | `Customers.java` | Total clientes por storm area | V_CIRCUIT_INFORMATION, MV_STORM_BREAKOUT_CIRCUIT | (ninguno) |
| Customers getContractsByRedc | `Customers.java` | Total contratos por REDC | MV_CLIENTE_SIC, REDC_COUNTY_BRIDGE | (ninguno) |
| Customers getCustomersByCircuit | `Customers.java` | Clientes afectados por circuito (para service request) | ICDS_SRVC_PARAM@DBLink, AFFECTED_CUSTOMER@DBLink (u OMS view) | requestId, opCo, circuit |
| CustomerDAO getCustomerForParams | `CustomerDAO.java` | Buscar clientes por nombre/apellido/teléfono/contrato/meterId | MV_CLIENTE_SIC (o MV_CLIENTE_SIC_ME), OMS_DISCON_CUSTS | codZona, lastName, firstName, street, town, phone, contract, meterId, customerType |
| CustomerDAO getCustomerPending | `CustomerDAO.java` | Obtener cliente por meterId para pantalla pendiente | MV_CLIENTE_SIC(_ME) | codZona, meterId |
| CustomerDAO getAutocompleteField | `CustomerDAO.java` | Autocompletado de campo de cliente (dirección, nombre, etc.) | MV_CLIENTE_SIC(_ME) | codZona, sField, valueField |
| CallDAO getCallByCustomer | `CallDAO.java` | Historial de llamadas de un cliente (activas + históricas) | MV_LLAMADA_PROCESADA, MV_H_LLAMADA_PROCESADA | idContract (CONTRACTACCT_NUM) |

---

## Tablas Oracle conocidas

| Tabla | Descripción inferida | Campos clave identificados |
|-------|----------------------|---------------------------|
| MV_INCIDENCIA | Incidencias activas (outages) NY | CONT_INCIDENCIA, COD_ZONA, COD_BRIGADA, CIRCUIT, FEC_INI_INCIDENCIA, FEC_FIN_INCIDENCIA, INCIDENT_TYPE, NUM_FASE_INCID, CONF_PRED_FLAG, NUMCUSTOUT, FEC_PREVISTA, ASSESSING_FLAG, TIP_INCIDENCIA, IND_DEFAULT |
| MV_INCIDENCIA_ME | Incidencias activas Maine (CMP) | (mismos que MV_INCIDENCIA) |
| MV_H_INCIDENCIA | Incidencias históricas/archivadas | (mismos campos) |
| MV_LLAMADA_PROCESADA | Llamadas procesadas (EO/ER/EM) | OMS_NOTIF_NUM, CONT_INCIDENCIA, COD_ZONA, COD_BRIGADA, CIRCUIT, FEC_LLAMADA, TIP_LLAMADA, NOTIF_STATUS, NOTIFICATION_CODE, BLOCKED_CALL |
| MV_H_LLAMADA_PROCESADA | Llamadas históricas | (mismos) |
| MV_AFFECTED_CUSTOMER | Clientes afectados por incidencia | CONT_INCIDENCIA, METER_NUM, CIRCUIT, CRITICAL_CUST, CODE_TOLERANCE_GROUP |
| MV_H_AFFECTED_CUSTOMER | Clientes afectados históricos | (mismos) |
| MV_BRIGADA | Divisiones/work centers | COD_BRIGADA, DES_BRIGADA, COD_ZONA |
| MV_CARA_ZONA | Compañías/OpCos | COD_ZONA, COD_OPCO, NOM_ZONA |
| MV_CARA_ZONA_ME | Compañías Maine | (mismos) |
| MV_SUBSTATIONCIRCUIT | Circuitos/substations | CIRCUIT, SUBCIRCUITTEXT, COD_BRIGADA |
| MV_SUBSTATIONCIRCUIT_ME | Circuitos Maine | (mismos) |
| MV_NOTIF_CODE_EG | Tipos de notificación (ET/EI) | NOTIF_CODE, NOTIFTYPE_CODE, NOTIF_TEXT |
| MV_TIP_FASE_INCID | Fases/estados de incidencia | COD_TIP_FASE, DES_TIP_FASES |
| MV_CALC_CIRCUIT | Clientes servidos por circuito | OPCO, DIVISION, CIRCUIT, numcustomers |
| MV_CALC_CIRCUIT_ME | Maine | (mismos) |
| V_ICDS_SUMMARY_DATA_CIRCUIT | Resumen clientes out por circuito | nom_company, nom_division_county, customers_out, CALLS, INCIDENTS, CIRCUIT_NAME, COD_COMPANY, COD_DIVISION_COUNTY |
| V_ICDS_SUMMARY_DATA_CIRCUIT_ME | Maine | (mismos) |
| MV_STORM_BREAKOUT_CIRCUIT | Circuitos por storm area | CIRCUIT, ID_SB_AREA |
| MV_STORM_BREAKOUT_AREA | Storm areas | ID_SB_AREA, SB_NAME |
| MV_COCHE_INCIDENCIA | Crew asignado a incidencia | CONT_INCIDENCIA, STATUS, ENGINEERNAME, FEC_ACTIVACION, MADE_SAFEON |
| MV_AMBITO_INCID | Ámbito/transformadores de incidencia | CONT_INCIDENCIA, CIRCUIT, COD_INSTAL_USUARIO |
| MASTER_POLE / MV_MASTER_POLE | Info poste (broken poles) | FLOC, HEIGHT, POLECLASS, ATTACHCNT, OWNER1, OWNER2 |
| V_BP_LAST_DETAIL | Vista detalle postes caídos | CONT_INCIDENCIA, COD_PRIORITY, COD_POLE_STATUS, HEIGHT, POLECLASS, ATTACHERS, SPEC_EQUIP, OWNER, DLI |
| BP_POLE_STATUS | Estados de poste | COD_POLE_STATUS, DES_POLE_STATUS |
| CUSTOMER_COMMENT | Comentarios de cliente en llamada | OMS_NOTIF_NUM, LONG_TEXT, DATE_TIME |
| OMS_DISCON_CUSTS | Desconexiones OMS (SONP) | meter_num, SONP_LOCATION |
| CRIT_CUST_CODES | Códigos cliente crítico (life support) | CRIT_CUST_CODE, CRIT_CUST_DESC |
| V_UNASSIGNED_EVENTS | Vista eventos AMI sin asignar (OMS) | I_COD_ZONA, I_COD_BRIGADA, I_CIRCUIT, METERID, EVENTTYPE, STARTTIME, RECEIVEDTIME, TOWN, ADDRESS, POLE |
| V_UNASSIGNED_PINGS | Vista pings sin asignar (OMS) | METERID, PINGSTATUS, REQUESTTIME, RESPONSETIME, PING_REQ_ID |
| V_TOTAL_AFFECTED_CUSTOMERS | Total clientes afectados por instalación | COD_OPCO, COD_DIVISION, COD_COUNTY, CUSTOMERS_OUT, START_DATE, END_DATE, COD_INSTAL_USUARIO |
| V_TOTAL_AFF_CUST_COUNTY | Por condado | COD_OPCO, COD_COUNTY, COD_REDC |
| MV_PROVINCIA | Condados | COD_PROVINCIA, DES_PROVINCIA, COD_REGION |
| REDC | Regiones REDC | COD_REDC, DES_REDC |
| REDC_COUNTY_BRIDGE | Puente condado-REDC | COD_PROVINCIA, COD_REDC |
| ELEM_MP / MV_ELEM_MP | Elementos de red (dispositivos) | B1NAME, B2NAME, B3NAME, ELNAME, CIRCUIT, LINE_ROAD, POLE |
| POSICION | Posición en red | LINE_ROAD, POLE |
| INCIDENCIA_DAMAGES / H_INCIDENCIA_DAMAGES | Daños vinculados a incidencias | ID_OUTAGE, ID_DAMAGE, IS_CURRENT |
| ICDS_US_ADHOC_REPORTS | Reportes ad-hoc usuario | REPORT_ID, REPORT_NAME, REPORT_DESC, LAYOUT_ID, FILTER_ID |
| ICDS_SRVC_REQUEST | Service requests (NY/ME) | ID_SRVC_REQUEST |
| ICDS_SRVC_PARAM | Parámetros de service request | ID_SRVC_REQUEST, PARAM_ORDER, PARAM_VALUE |
| SAP_PFP | PFP BOMS (People/Field) | COD_BRIGADA, COD_OPCO, PFP_BP_NUM, PFP_FLOC, NAME_FIRST, NAME_LAST |
| TIPO_DIGSAFE | Tipos Dig Safe | ID_DIGSAFE, DESCRIPCION |
| BOMS_CREW_UPDATE | Actualizaciones crew BOMS | OPERATION_ID, PENDING_ID |
| ICDS_ACTION_LOG | Log de acciones | ID_LOG, USER_ID, ACTION |
| MV_AMBITO_INCID | Ámbito (elementos de red) de incidencias activas | CONT_INCIDENCIA, COD_INSTAL_USUARIO, CIRCUIT, AFFECTED_CUST, FEC_HASTA |
| MV_AMBITO_INCID_ME | Ámbito de incidencias Maine | (mismos) |
| MV_H_AMBITO_INCID | Ámbito histórico | (mismos) |
| MV_H_AMBITO_INCID_ME | Ámbito histórico Maine | (mismos) |
| V_OUTAGE_COUNTS | Vista de conteo histórico de incidencias (con variantes por región) | NOTIFICATION, SERVICE_CENTER, CODING, MALFUNCTION_START_DATE_TIME, MALFUNCTION_END_DATE, MALFUNCTION_END_TIME, REQUIRED_END_DATE, REQUIRED_END_TIME, CUST_IMPACTED, CAUSE_DESCR, CAUSE_UPDATES, CREW_UPDATES, ETR_UPDATES |
| ICDS_US_STATISTICS | Estadísticas históricas de apagones para Outage Statistical Report | COD_COMPANY, COD_LOCATION, DES_COMPANY, DES_LOCATION, CUST_OUT, PEAK_DATETIME |
| V_CIRCUIT_INFORMATION_ALL | Vista unificada de circuitos (NY+CMP) con total de clientes | COD_OPCO, COD_DIVISION, COD_CIRCUIT, TOTAL_CUSTOMERS |
| V_CIRCUIT_INFORMATION | Vista de circuitos NY | COD_OPCO, COD_DIVISION, COD_CIRCUIT, TOTAL_CUSTOMERS |
| MV_CLIENTE_SIC | Datos de clientes SIC (ny) | COD_ZONA, COD_CONTRATO, CONTRACTACCT_NUM, CUPS (meter), NOMBRE, APELLIDO1, APELLIDO2, NOM_CALLE, SAP_HOUSE_NBR, NOM_POBLACION, PROVINCIA, SAP_CUST_PHONE, CODE_EG, STATUS, COD_ORG_INTERNA, latitude, longitude |
| V_CLIENTE_SIC | Vista de clientes (variante) | (mismos que MV_CLIENTE_SIC) + COD_INSTAL_USUARIO |
| V_POSICION | Posiciones (instalaciones de usuario) | CODIGO_CTM, COD_ZONA, COD_PROVINCIA |
| MV_COCHE_INCIDENCIA | Crew (vehículo/cuadrilla) en incidencia activa | CONT_INCIDENCIA, STATUS, ENGINEERNAME, FEC_ACTIVACION, MADE_SAFEON, FEC_ASIGNACION, RESTORED_ON |
| MV_H_COCHE_INCIDENCIA | Crew histórico | (mismos) |
| MV_SAP_CAUSE_CODE | Códigos de causa SAP | SAP_CAUSE_CODE, SAP_CAUSE_DESCR |
| MV_SAP_DEVICE_CODE | Códigos de dispositivo SAP | SAP_DEVICE_CODE, SAP_DEVICE_DESCR |
| MV_SAP_WEATHER_CODE | Códigos de clima SAP | SAP_WEATHER_CODE, SAP_WEATHER_DESCR |
| MV_TIPO_AMBITO | Tipos de ámbito de incidencia | COD_TIPO_AMBITO, DES_TIPO_AMBITO |
| MV_AREA_SIGRID | Áreas de trabajo SIGRID | COD_AREA, DES_AREA, COD_ZONA |
| reliability_baseline | Valores de referencia para índices de fiabilidad (TMED) | OPCO, TMED |
| MV_WEATHER_CODES | Códigos de condiciones meteorológicas | (code, description) |
| MV_DEVICE_CODES | Códigos de tipos de dispositivo de red | (code, description) |

---

## Patrones de query frecuentes

### Filtro por fechas (formato MM/DD/YYYY HH24:MI)

```sql
-- Para llamadas
AND LP.FEC_LLAMADA >= TO_DATE(:dStartDate, 'MM/DD/YYYY HH24:MI')
AND LP.FEC_LLAMADA <= TO_DATE(:dEndDate, 'MM/DD/YYYY HH24:MI')

-- Para incidencias
AND inc.FEC_INI_INCIDENCIA >= TO_DATE(:dStartDate, 'MM/DD/YYYY HH24:MI')
AND inc.FEC_INI_INCIDENCIA <= TO_DATE(:dEndDate, 'MM/DD/YYYY HH24:MI')
```

### Tablas por OpCo (NY vs CMP/ME)

Para `codeCompany == 3` (CMP) se usa sufijo `_ME`; para NY (1, 2) sin sufijo:

```sql
-- Ejemplo en NyReliabilityIndexesSqlBuilderImpl
final String mvCalcCircuitTable = opCo == 3 ? "MV_CALC_CIRCUIT_ME" : "MV_CALC_CIRCUIT";
final String mvIncidenciaTable = opCo == 3 ? "MV_INCIDENCIA_ME" : "MV_INCIDENCIA";
```

Tablas con variante _ME: `MV_CALC_CIRCUIT`, `MV_INCIDENCIA`, `MV_CARA_ZONA`, `MV_SUBSTATIONCIRCUIT`, `MV_STORM_BREAKOUT_CIRCUIT`, `MV_STORM_BREAKOUT_AREA`, `V_ICDS_SUMMARY_DATA_CIRCUIT`.

### DB-Link para OMS (Outage Management Mode)

Cuando `accessReposMode == "DBLink"`:

- NY: `@REPOS_01_OMS` (Constants.DBLINK_NY)
- ME: `@REPOS_02_OMS` (Constants.DBLINK_ME)

```java
String sDBLink = ConnectionStringUtils.getDBLinkByOpCo(iOpCo);
String sTable = "V_UNASSIGNED_EVENTS" + sDBLink;  // V_UNASSIGNED_EVENTS@REPOS_01_OMS
```

### Filtro por tipo de incidencia (EI/ET, excluir predicciones)

```sql
AND NCE.NOTIF_CODE = INC.INCIDENT_TYPE
AND NCE.NOTIFTYPE_CODE = 'EI'
AND INC.INCIDENT_TYPE IN ('EI01', 'EI02', 'EI04', 'EI05')
AND INC.CONF_PRED_FLAG != 'P'
AND INC.IND_DEFAULT != 'S'
AND INC.TIP_INCIDENCIA != 'CP'
AND INC.NUM_FASE_INCID NOT IN (0, 4, 5)
```

### Filtro opcional por compañía

```sql
-- Si iOpCo > 0
AND INC.COD_ZONA = :iOpCo
-- Si All NY (iOpCo = 0)
AND INC.COD_ZONA in (1, 2)
```

### Filtro opcional por divisiones

```sql
AND INC.COD_BRIGADA IN (:lstDivisions)
-- o para circuitos en storm area:
AND EXISTS (SELECT 1 FROM MV_STORM_BREAKOUT_CIRCUIT sbc
            WHERE sbc.CIRCUIT = inc.CIRCUIT AND sbc.ID_SB_AREA IN (:lstDivisions))
```

### CTE para clientes servidos / afectados (NY Reliability)

```sql
WITH cte_cust_served AS (
    SELECT cz.NOM_ZONA AS OPCO, cc.DIVISION, SUM(cc.numcustomers) AS cust_served
    FROM MV_CALC_CIRCUIT cc
    INNER JOIN MV_CARA_ZONA cz ON cc.OPCO = cz.COD_OPCO
    WHERE cz.COD_ZONA = :iOpCo
    GROUP BY cc.DIVISION, cz.NOM_ZONA
),
cte_cust_out AS (
    SELECT cout.nom_company, UPPER(cout.nom_division_county) AS division,
           SUM(cout.customers_out) AS cust_out
    FROM V_ICDS_SUMMARY_DATA_CIRCUIT cout
    WHERE cout.COD_COMPANY = :iOpCo
    GROUP BY cout.nom_company, cout.nom_division_county
)
-- JOIN y SELECT...
```

### Oracle OUTER JOIN (+) sintaxis legacy

```sql
AND LLA.COD_BRIGADA = BRI.COD_BRIGADA (+)
AND LLA.CIRCUIT = SC.CIRCUIT (+)
```

### Formateo de fechas en SELECT

```sql
TO_CHAR(INC.FEC_INI_INCIDENCIA, 'MM/DD/YYYY hh24:mi:ss') AS MALFUNCTION_START
TO_CHAR(SYSDATE, 'MM/DD/YYYY hh24:mi:ss') AS CURRENT_DATE
```

### NVL para nulls

```sql
NVL(INC.NUMCUSTOUT, 0) AS CUSTOMERS_OUT
NVL(SC.SUBCIRCUITTEXT, ' ') AS DES_CIRCUIT
```

### SQL en archivos externos (beans.xml, properties)

Algunas queries largas (p. ej. ERA) viven en `beans.xml` como properties:

```xml
<prop key="sql.era"><![CDATA[
  WITH cte_era AS (
    SELECT AI.CONT_INCIDENCIA, INC.COD_ZONA, ...
    FROM mv_h_incidencia inc
    INNER JOIN mv_h_ambito_incid ai ON INC.CONT_INCIDENCIA = ai.cont_incidencia
    ...
  ) SELECT ...
]]></prop>
```

Se accede con `AppProperties.getProperties().getProperty(Constants.SQL_ERA)`.

### Resolución dinámica de tablas (StandardizedElectricalReportUtils)

```java
String tableName = StandardizedElectricalReportUtils.resolveTableName(
    "INCIDENCIA", opCo, isOutgMng, accessReposMode);
// NY + mat view: MV_INCIDENCIA
// CMP + mat view: MV_INCIDENCIA_ME
// Outage Mgmt + DBLink: INCIDENCIA@REPOS_01_OMS o INCIDENCIA@REPOS_02_OMS
```

### Filtro "hoy" con TRUNC(SYSDATE)

Usado en `Indexes.java` para limitar datos del día en curso:

```sql
AND INC.FEC_INI_INCIDENCIA >= TRUNC(SYSDATE)
AND INC.FEC_INI_INCIDENCIA <  TRUNC(SYSDATE) + 1
```

### CTEs anidadas para SAIDI/SAIFI/CAIDI (Indexes.java)

Patrón de ventanas analíticas con CTE para calcular duraciones y afectados, combinando incidencias activas e históricas:

```sql
WITH current_incidents AS (
    SELECT INC.CONT_INCIDENCIA,
           ((TRUNC(NVL(AI.FEC_HASTA, SYSDATE), 'MI') - TRUNC(INC.FEC_INI_INCIDENCIA, 'MI')) * 1440) AS DURATION_MINUTES,
           SUM(AI.AFFECTED_CUST) OVER (PARTITION BY INC.CONT_INCIDENCIA, AI.FEC_HASTA) AS TOTAL_AFFECTED_CUST
    FROM MV_INCIDENCIA_ME INC
    JOIN MV_AMBITO_INCID_ME AI ON INC.CONT_INCIDENCIA = AI.CONT_INCIDENCIA
    WHERE INC.NUM_FASE_INCID IN (1,2,3,4)
    AND INC.INCIDENT_TYPE IN ('EI01', 'EI02', 'EI04')
    AND INC.REAL_NUMCUSTOUT > 0
    AND INC.CONF_PRED_FLAG != 'P'
),
TotalCustomers AS (
    SELECT OPCO, SUM(NUMCUSTOMERS) AS TOTAL_CUSTOMERS FROM MV_CALC_CIRCUIT_ME GROUP BY OPCO
)
SELECT SUM(incidents.TOTAL_AFFECTED_CUST) / MAX(tc.TOTAL_CUSTOMERS) AS SAIFI, ...
```

### Cálculo de duración en minutos/horas (TRUNC para evitar segundos)

```sql
((TRUNC(NVL(AI.FEC_HASTA, SYSDATE), 'MI') - TRUNC(INC.FEC_INI_INCIDENCIA, 'MI')) * 1440) AS DURATION_MINUTES
((TRUNC(NVL(AI.FEC_HASTA, SYSDATE), 'MI') - TRUNC(INC.FEC_INI_INCIDENCIA, 'MI')) * 24)   AS DURATION_HOURS
```

### Paginación Oracle (FETCH FIRST)

En búsquedas de clientes con muchos resultados potenciales:

```sql
ORDER BY APELLIDO1
OFFSET 0 ROWS FETCH FIRST 100 ROWS ONLY
```

### Búsqueda de cliente con LIKE insensible a mayúsculas

```sql
AND UPPER(NVL(cli.NOMBRE,' ')) LIKE '%' || UPPER(:firtName) || '%'
AND cli.APELLIDO1                LIKE '%' || UPPER(:lastName) || '%'
AND cli.contractacct_num         LIKE '%' || :contract || '%'
AND cli.CUPS                     LIKE '%' || :meterId || '%'
```

### Gas color bucket (alertas por tiempo de respuesta)

```sql
CASE
  WHEN (NVL(COC.FEC_ACTIVACION,SYSDATE) - INC.FEC_INI_INCIDENCIA)*60*24 >= 30
   AND (NVL(COC.FEC_ACTIVACION,SYSDATE) - COC.FEC_ASIGNACION)*60*24 <= 60
    THEN 'GAS_YELLOW'
  WHEN (NVL(COC.FEC_ACTIVACION,SYSDATE) - INC.FEC_INI_INCIDENCIA)*60*24 > 60
    THEN 'GAS_RED'
END AS GAS_COLOR_BUCKET
```

### Resolución dinámica de tablas activo/histórico por región (IncidentDetails.buildDetailTables)

Patrón usado en `CallDAO`, `CustomerDAO`, `IncidentCustomerReport`:

```java
// IncidentDetails.buildDetailTables() devuelve un Map<String,String>
// con los nombres de tabla correctos según iOpCo e isOutageManagement
Map<String, String> mapTables = buildDetailTables();
String sLLamada = mapTables.get("LLAMADA_PROCESADA");   // MV_LLAMADA_PROCESADA o variante
String sClientSIC = mapTables.get("CLIENTE_SIC");        // MV_CLIENTE_SIC o MV_CLIENTE_SIC_ME
// Tablas clave: LLAMADA_PROCESADA, H_LLAMADA_PROCESADA, CLIENTE_SIC,
//               SUBSTATIONCIRCUIT, BRIGADA, PROVINCIA, CRIT_CUST_CODES, OMS_DISCON_CUSTS
```

### DECODE para LEFT JOIN implícito (Oracle legacy)

```sql
decode(sonp.CONTRACT_ACCOUNT_NUM, null, '', 'X') as sonp
-- Equivale a: CASE WHEN sonp.CONTRACT_ACCOUNT_NUM IS NULL THEN '' ELSE 'X' END
```

### Patrón modular de SqlBuilders (reportsstdelect module)

Los informes del módulo `reportsstdelect` se construyen ensamblando 4 fragmentos SQL, cada uno con su propia interfaz Spring `@Component`:

| Interfaz | Responsabilidad |
|---|---|
| `FieldsAndTablesSqlBuilder` | SELECT + FROM |
| `WhereSqlBuilder` | WHERE |
| `SummaryReportGroupOrOrderSqlBuilder` | GROUP BY / ORDER BY |
| `WithSpecialIndSqlBuilder` | CTE o subqueries especiales |

El `SqlBuilderFactory` selecciona la implementación correcta para cada `ReportNameEnum` y los encadena. Para añadir un nuevo informe "Detailed" basta con crear implementaciones de cada interfaz y anotarlas con `@Component`. El `DefaultDetailReportRepository` los ejecuta (vivo + histórico como UNION).

```java
// Flujo de ensamblaje (simplificado):
DetailedSqlBuilder builder = sqlBuilderFactory.getDetailedSqlBuilder(reportNameEnum);
String sql = builder.build(request, archived); // llama a fields+where+order
```

### Duración de outage en formato HH:MM:SS (ICS Metric)

```sql
CASE WHEN NCE.NOTIFTYPE_CODE = 'EI'
THEN
  TRUNC((NVL(INC.MALFUNC_END,SYSDATE) - INC.FEC_INI_INCIDENCIA) * 24)
  || ':' || lpad(TRUNC(MOD((NVL(INC.MALFUNC_END,SYSDATE) - INC.FEC_INI_INCIDENCIA) * 24*60, 60)), 2,'0')
  || ':' || lpad(TRUNC(MOD((NVL(INC.MALFUNC_END,SYSDATE) - INC.FEC_INI_INCIDENCIA) * 24*60*60, 60)), 2,'0')
ELSE ' '
END AS outage_duration_in_hours
```

### Filtro life-support con subquery correlacionada (PCS Call OMS)

```sql
AND (SELECT COUNT(AC.CONT_INCIDENCIA)
     FROM MV_AFFECTED_CUSTOMER AC
     WHERE AC.CONT_INCIDENCIA = INC.CONT_INCIDENCIA
     AND AC.CRITICAL_CUST IN ('0001', 'M', 'J')) > 0
```
