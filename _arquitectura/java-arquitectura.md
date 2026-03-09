# Arquitectura del Proyecto ICDS-BE (Guía para Agentes IA)

Este documento describe la arquitectura real del proyecto para que otro agente de IA pueda crear código siguiendo exactamente los patrones existentes.

---

## 1. Stack Tecnológico

| Tecnología | Versión |
|------------|---------|
| Java | 8 |
| Spring Boot | 2.7.0 |
| Oracle JDBC | `ojdbc8` (runtime) + `ojdbc6` 11.2.0.4 |
| Build | Maven, packaging WAR |
| Lombok | 1.18.22 |
| Caffeine Cache | (Spring Boot managed) |
| MapStruct | 1.5.3.Final |

### Conexión a Oracle

- **Driver**: `oracle.jdbc.OracleDriver`
- **Connection pool**: HikariCP (auto-configurado por Spring Boot)
- **JPA**: Hibernate con `Oracle12cDialect`
- **URL formato**: `jdbc:oracle:thin:@//host:port/servicename`
- La conexión se realiza mediante `spring.datasource.*`; no hay configuración manual de `DataSource` en código para los componentes nuevos (`reportsstdelect`).

---

## 2. Estructura de Paquetes

```
src/main/java/
├── avangrid/
│   └── icds/
│       ├── config/                    # Configuración (CORS, Cache, etc.)
│       ├── error/exception/
│       ├── exception/
│       ├── fooservice/                # Servicio de ejemplo
│       │   ├── mappers/
│       │   ├── model/
│       │   ├── persistence/
│       │   ├── service/
│       │   └── web/
│       ├── greeting/
│       ├── ibusa/
│       │   └── web/
│       │       ├── contract/
│       │       └── controller/       # Controladores legacy
│       ├── mapper/
│       ├── model/
│       ├── persistence/
│       ├── reports/
│       ├── reportsstdelect/           # ⭐ Sistema de informes estandarizados
│       │   ├── controller/            # Controladores REST
│       │   ├── enums/
│       │   ├── model/                 # Request/Response DTOs
│       │   ├── repository/            # Acceso a datos
│       │   ├── rowmapper/             # Mapeo ResultSet → POJO
│       │   ├── service/
│       │   ├── sql/                   # Fragmentos SQL (Where, From, etc.)
│       │   ├── sqlbuilder/            # Constructores de SQL completos
│       │   └── util/
│       ├── service/
│       └── util/                      # LoggingNamedJdbcTemplate
└── com/
    └── icds/
        └── ibusa/
            ├── reports/               # POJOs de informe (compartidos)
            ├── dao/, data/, entity/, ...
```

---

## 3. Ejecución de Queries Oracle

### Componentes clave

- **LoggingNamedJdbcTemplate**: Wrapper sobre `NamedParameterJdbcTemplate` que registra duración y parámetros de cada query. Se inyecta en los repositorios.
- **MapSqlParameterSource**: Para parámetros nombrados (`:nombreParam`).
- **RowMapper**: Implementa `RowMapper<T>` para mapear cada fila del `ResultSet` a un POJO.

### Ejemplo completo: NyReliabilityIndexesReportRepository

```java
package avangrid.icds.reportsstdelect.repository;

import avangrid.icds.reportsstdelect.model.NyReliabilityIndexesReportRequest;
import avangrid.icds.reportsstdelect.rowmapper.NyReliabilityIndexesRowMapper;
import avangrid.icds.reportsstdelect.sqlbuilder.NyReliabilityIndexesSqlBuilder;
import avangrid.icds.util.LoggingNamedJdbcTemplate;
import com.icds.ibusa.reports.NyReliabilityIndexesReportPOJO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.stereotype.Component;

import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class NyReliabilityIndexesReportRepository {

    private final LoggingNamedJdbcTemplate jdbcTemplate;
    private final NyReliabilityIndexesSqlBuilder sqlBuilder;
    private final NyReliabilityIndexesRowMapper rowMapper;

    public List<NyReliabilityIndexesReportPOJO> getReport(NyReliabilityIndexesReportRequest request) {
        String sql = sqlBuilder.build(request);
        log.debug("SQL [NY Reliability Indexes Report]: {}", sql);
        MapSqlParameterSource params = request.buildParameters();
        return jdbcTemplate.query(sql, params, rowMapper);
    }
}
```

### RowMapper

```java
package avangrid.icds.reportsstdelect.rowmapper;

import com.icds.ibusa.reports.NyReliabilityIndexesReportPOJO;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Component;

import java.sql.ResultSet;
import java.sql.SQLException;

@Component
public class NyReliabilityIndexesRowMapper implements RowMapper<NyReliabilityIndexesReportPOJO> {

    @Override
    public NyReliabilityIndexesReportPOJO mapRow(ResultSet rs, int rowNum) throws SQLException {
        NyReliabilityIndexesReportPOJO row = new NyReliabilityIndexesReportPOJO();
        row.setOpco(rs.getString("OPCO"));
        row.setDivision(rs.getString("DIVISION"));
        row.setCustServed(getLong(rs, "cust_served"));
        row.setCustOut(getLong(rs, "cust_out"));
        row.setNumCalls(getLong(rs, "num_calls"));
        row.setNumIncidents(getLong(rs, "num_incidents"));
        row.setPctOut(rs.getBigDecimal("pct_out"));
        row.setOutagesOver24h(getLong(rs, "outages_over_24h"));
        row.setHasOutageOver24h(rs.getString("has_outage_over_24h"));
        row.setMajorOutageFlag(rs.getString("major_outage_flag"));
        row.setMajorOutageReason(rs.getString("major_outage_reason"));
        return row;
    }

    private static Long getLong(ResultSet rs, String column) throws SQLException {
        long v = rs.getLong(column);
        return rs.wasNull() ? null : Long.valueOf(v);
    }
}
```

### Construcción de parámetros en el Request

```java
// En NyReliabilityIndexesReportRequest
public MapSqlParameterSource buildParameters() {
    MapSqlParameterSource params = new MapSqlParameterSource();
    params.addValue("iOpCo", getNormalizedCompanyCode(), Types.INTEGER);
    params.addValue("lstDivisions", getLstDivisions());
    params.addValue("dStartDate", getStartDate(), Types.VARCHAR);
    params.addValue("dEndDate", getEndDate(), Types.VARCHAR);
    params.addValue("lstNotifStages", getLstIncidentStages());
    return params;
}
```

En el SQL se usan placeholders nombrados: `:iOpCo`, `:lstDivisions`, `:dStartDate`, `:dEndDate`, `:lstNotifStages`. Spring expande listas automáticamente en `IN (:lstDivisions)`.

---

## 4. Endpoint Completo: Ejemplo Real

### Controller (NyReliabilityIndexesReportController)

```java
package avangrid.icds.reportsstdelect.controller;

import avangrid.icds.reportsstdelect.model.NyReliabilityIndexesReportRequest;
import avangrid.icds.reportsstdelect.model.NyReliabilityIndexesReportResponse;
import avangrid.icds.reportsstdelect.service.NyReliabilityIndexesReportService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@CrossOrigin
@RestController
@Slf4j
@RequestMapping(value = "/api/reports")
@RequiredArgsConstructor
public class NyReliabilityIndexesReportController {

    private final NyReliabilityIndexesReportService nyReliabilityIndexesReportService;

    @Cacheable(cacheResolver = "cacheResolver")
    @PostMapping(value = "/ny-reliability-indexes")
    public ResponseEntity<NyReliabilityIndexesReportResponse> generateNyReliabilityIndexesReport(
            @RequestBody NyReliabilityIndexesReportRequest request) {

        log.debug("Entering generate ny-reliability-indexes report");
        try {
            NyReliabilityIndexesReportResponse response = nyReliabilityIndexesReportService.generateReport(request);
            log.debug("NY Reliability Indexes Report generated successfully. Records: {}", response.getLNumReg());
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error generating NY Reliability Indexes Report", e);
            throw new RuntimeException("Error generating NY Reliability Indexes Report: " + e.getMessage(), e);
        }
    }
}
```

### Service (NyReliabilityIndexesReportService)

```java
package avangrid.icds.reportsstdelect.service;

import avangrid.icds.reportsstdelect.model.NyReliabilityIndexesReportRequest;
import avangrid.icds.reportsstdelect.model.NyReliabilityIndexesReportResponse;
import avangrid.icds.reportsstdelect.repository.NyReliabilityIndexesReportRepository;
import com.icds.ibusa.reports.NyReliabilityIndexesReportPOJO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

import static avangrid.icds.reportsstdelect.util.StdElectReportsUtils.DATE_TIME_FORMATTER;

@Slf4j
@Service
@RequiredArgsConstructor
public class NyReliabilityIndexesReportService {

    private final NyReliabilityIndexesReportRepository repository;

    public NyReliabilityIndexesReportResponse generateReport(NyReliabilityIndexesReportRequest request) {
        log.debug("Generating NY Reliability Indexes Report");
        List<NyReliabilityIndexesReportPOJO> rows = repository.getReport(request);
        List<NyReliabilityIndexesReportPOJO> rowsWithTotals = addSummaryRows(rows);
        return NyReliabilityIndexesReportResponse.builder()
                .lstReport(rowsWithTotals)
                .currentDate(LocalDateTime.now().format(DATE_TIME_FORMATTER))
                .lNumReg(rowsWithTotals.size())
                .build();
    }
    // ... addSummaryRows y helpers
}
```

### Response DTO

```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NyReliabilityIndexesReportResponse {
    private List<NyReliabilityIndexesReportPOJO> lstReport;
    private String currentDate;
    private long lNumReg;
}
```

### Patrón alternativo: Reports con Factory

Para informes que comparten lógica, se usa `ReportServiceFactory`:

```java
// Controller
final ReportService service = reportServiceFactory.getService(ReportNameEnum.EM_ER_EO_UNNEST_REPORT);
StdElectReportResponse response = service.generateReport(request, ReportNameEnum.EM_ER_EO_UNNEST_REPORT);

// Service implementa ReportService
@Override
public StdElectReportResponse generateReport(StdElectReportRequest request, ReportNameEnum reportNameEnum) {
    List<?> calls = repository.getReport(request);
    return StdElectReportResponse.builder()
            .lstReport(calls)
            .currentDate(LocalDateTime.now().format(DATE_TIME_FORMATTER))
            .lNumReg(calls.size())
            .build();
}
```

---

## 5. Protección de Endpoints

**No hay anotaciones de seguridad** (`@Secured`, `@PreAuthorize`, `@RolesAllowed`) en el proyecto. Los endpoints no están protegidos por roles ni autenticación a nivel de anotación.

- **CORS**: Configurado en `MyConfiguration` para `/api/**` con `allowedOriginPatterns("*")`, métodos GET, POST, PUT, DELETE, HEAD.

---

## 6. Convenciones de Naming

| Elemento | Convención | Ejemplo |
|----------|------------|---------|
| Paquetes | lowercase | `avangrid.icds.reportsstdelect` |
| Clases Controller | `*Controller` | `NyReliabilityIndexesReportController` |
| Clases Service | `*Service` | `NyReliabilityIndexesReportService` |
| Clases Repository | `*Repository` | `NyReliabilityIndexesReportRepository` |
| RowMapper | `*RowMapper` | `NyReliabilityIndexesRowMapper` |
| SqlBuilder | `*SqlBuilder` / `*SqlBuilderImpl` | `NyReliabilityIndexesSqlBuilderImpl` |
| Request DTO | `*Request` | `NyReliabilityIndexesReportRequest` |
| Response DTO | `*Response` | `NyReliabilityIndexesReportResponse` |
| POJO de fila | `*POJO` (en `com.icds.ibusa.reports`) | `NyReliabilityIndexesReportPOJO` |
| Endpoints | kebab-case | `/ny-reliability-indexes` |
| Atributos Request | camelCase | `codeCompany`, `lstDivisions`, `startDate` |
| Columnas SQL/alias | snake_case | `cust_served`, `num_calls` |
| Parámetros SQL | camelCase o notación húngara | `:iOpCo`, `:lstDivisions`, `:dStartDate` |

---

## 7. application.yml (estructura relevante, sin credenciales)

```yaml
server:
  port: 8081
  servlet:
    context-path: /icds

caches:
  caffeines:
    - name: longTermCache
      expiryInSeconds: 604800
      maxSize: 100
    - name: default
      expiryInSeconds: 60
      maxSize: 100
    - name: nocache
      expiryInSeconds: 0
      maxSize: 0
    - name: shortcache
      expiryInSeconds: 10
      maxSize: 100

spring:
  datasource:
    url: "jdbc:oracle:thin:@//HOST:1521/SERVICE"
    username: USER
    password: PASSWORD
    driver-class-name: oracle.jdbc.OracleDriver
    hikari:
      minimum-idle: 5
      maximum-pool-size: 20
      idle-timeout: 30000
      max-lifetime: 1800000
      connection-timeout: 30000
      pool-name: ICDSHikariPool
      connection-test-query: "SELECT 1 FROM DUAL"
      validation-timeout: 5000
      leak-detection-threshold: 900000
  jpa:
    database-platform: org.hibernate.dialect.Oracle12cDialect
    hibernate:
      use-new-id-generator-mappings: false
      ddl-auto: none
  jackson:
    default-property-inclusion: NON_NULL
```

Perfiles: `application-local.yml`, `application-ora.yml`, `application-dev.yml`, `application-qa.yml`, `application-prod.yml`, `application-h2.yml`.

---

## 8. Patrones y Particularidades

### Cache dinámico con header

- Se usa `@Cacheable(cacheResolver = "cacheResolver")` en lugar de un nombre fijo.
- El header HTTP `cache-to-use` indica el cache: `default`, `longTermCache`, `nocache`, `shortcache`.
- Si no se envía el header, se usa `default`.
- Implementado en `CustomCacheResolver`.

### Tablas por OpCo (CMP vs NY)

Para `codeCompany == 3` (CMP) se usan tablas con sufijo `_ME`:

- `MV_CALC_CIRCUIT` → `MV_CALC_CIRCUIT_ME`
- `MV_INCIDENCIA` → `MV_INCIDENCIA_ME`
- `V_ICDS_SUMMARY_DATA_CIRCUIT` → `V_ICDS_SUMMARY_DATA_CIRCUIT_ME`
- `MV_CARA_ZONA` → `MV_CARA_ZONA_ME`

### SqlBuilder como componente

- Interface `XxxSqlBuilder` + `XxxSqlBuilderImpl` (con `@Component`).
- El builder recibe el Request y devuelve `String` (SQL completo).
- Se usa `StringBuilder` para construir SQL dinámicamente según filtros.

### Request con `buildParameters()`

- Los Request DTOs exponen `MapSqlParameterSource buildParameters()` para vincular el Request con los placeholders del SQL.
- Los nombres de parámetros deben coincidir exactamente con los usados en el SQL (`:nombreParam`).

### POJOs en `com.icds.ibusa.reports`

- Los modelos de fila de informe suelen estar en `com.icds.ibusa.reports` (paquete legacy).
- Los DTOs de Request/Response específicos del informe están en `avangrid.icds.reportsstdelect.model`.

### Response estándar

- `lstReport`: lista de filas.
- `currentDate`: fecha/hora de generación (`MM/dd/yyyy HH:mm`).
- `lNumReg`: número de registros.

### Lombok

- `@Data`, `@Builder`, `@NoArgsConstructor`, `@AllArgsConstructor` en DTOs.
- `@RequiredArgsConstructor` en clases que solo inyectan dependencias.
- `@Slf4j` para logging.

### Códigos de compañía normalizados

- 0 = All NY  
- 1 / 1160 = NYSEG  
- 2 / 1000 = RGE  
- 3 / 9310 = CMP  

Los Request exponen `getNormalizedCompanyCode()` para unificar estos valores.
