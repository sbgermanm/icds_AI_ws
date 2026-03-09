# ICDS UI — Architecture Document
> Generado a partir del código real del proyecto. Para uso por agentes de IA al crear nuevos componentes.

---

## 1. Stack Tecnológico

| Capa | Tecnología | Versión |
|---|---|---|
| Framework | Angular | 15.2.10 |
| UI principal (layout/menú/accordion) | **Nebular** (`@nebular/theme`) | 11.0.1 |
| UI de tablas y formularios | **PrimeNG** (`primeng`) | 15.4.1 |
| Estilos | SCSS + Bootstrap 4.3 | — |
| Gestión de estado | Servicios Angular + `BehaviorSubject` RxJS | — |
| HTTP | `HttpClient` de Angular | — |
| Exports Excel | `xlsx` 0.18.5 | — |
| Mapas | ArcGIS (`@arcgis/core`) + Leaflet | — |
| TypeScript | ~4.9.5 | — |
| Build | Angular CLI 15.2.10 + `@angular-devkit/build-angular` | — |

---

## 2. Estructura de Carpetas

```
src/
├── assets/
│   └── config/
│       └── config.json               ← configuración runtime (server, serverAppId, ...)
├── environments/
│   ├── environment.ts                ← apunta a environment.default.ts
│   ├── environment.default.ts        ← valores por defecto
│   └── environment.prod.ts           ← override producción
└── app/
    ├── app.module.ts                 ← módulo raíz, APP_INITIALIZER para config
    ├── app-routing.module.ts         ← ruta raíz → PagesComponent
    ├── config.service.ts             ← carga config.json en startup
    ├── config.types.ts               ← interfaz Config
    │
    ├── @core/                        ← lógica de negocio y modelos
    │   ├── core.module.ts
    │   ├── data/                     ← servicios de datos legacy
    │   │   ├── lookupservice.ts
    │   │   └── reportService.ts
    │   ├── model/                    ← interfaces TypeScript (DTOs)
    │   │   ├── eiOutageReport.ts
    │   │   ├── eiOutageReportFilter.ts
    │   │   ├── location.ts
    │   │   ├── opco.ts
    │   │   └── contracts/            ← contratos request/response
    │   └── services/                 ← servicios HTTP inyectables
    │       ├── ei-outage-report.service.ts
    │       ├── general-service.ts
    │       ├── monitoring-report.service.ts
    │       └── lookupserviceimpl.ts
    │
    ├── @theme/                       ← tema Nebular, estilos globales
    │   ├── styles/
    │   │   └── styles.scss           ← punto de entrada SCSS global
    │   └── components/               ← header, footer, ...
    │
    ├── common/                       ← componentes compartidos
    │   ├── shared-module/
    │   │   └── shared-module.module.ts  ← SharedModuleModule (re-exporta todo)
    │   ├── avtable/                  ← tabla genérica estándar (ngx-avtable)
    │   ├── avtableexpand/            ← tabla con filas expandibles (ngx-avtable-expanded)
    │   ├── calendar-interval/        ← selector de rango de fechas (ngx-calendar-interval)
    │   ├── location/                 ← selector de divisiones/areas (ngx-location)
    │   ├── company/                  ← selector de Operating Company (ngx-company)
    │   ├── companies/                ← multi-select de compañías (ngx-companies)
    │   ├── refresh/                  ← botón refresh + auto-refresh (ngx-refresh)
    │   ├── column-select/            ← panel show/hide columns
    │   ├── filter-reports/           ← filtro genérico para stdElectReports (ngx-filter-reports)
    │   ├── incidents-management-filter/ ← filtro avanzado de gestión de incidencias
    │   ├── incident-detail/          ← detalle de incidencia en tabs
    │   ├── summary-table/            ← tabla resumen compacta
    │   ├── indexes-banner/           ← banner de índices
    │   ├── message/                  ← wrapper de mensajes de error (ngx-message)
    │   ├── timestamp/                ← timestamp de última actualización
    │   └── ...                       ← más componentes checkboxes, graphs, etc.
    │
    ├── services/                     ← servicios de aplicación (no @core)
    │   ├── global.service.ts         ← estado global: empresa/fechas seleccionadas
    │   ├── broadcast.service.ts
    │   ├── persist.service.ts
    │   └── preference.service.ts
    │
    └── pages/                        ← páginas/módulos de la aplicación
        ├── pages.component.ts
        ├── pages.module.ts           ← importa todos los módulos de páginas
        ├── pages-routing.module.ts   ← todas las rutas bajo /pages/
        ├── pages-menu.ts             ← árbol de menú lateral NbMenuItem[]
        ├── constants.ts              ← constantes de reportes y rutas
        │
        ├── dashboard/                ← landing page con tabla PrimeNG de outages
        ├── standardElectricReports/  ← Tipo B: 3 acordeones (filtro/reporte/detalle)
        ├── ei-outage-report/         ← Tipo A: 2 acordeones (filtro/reporte)
        │   ├── ei-outage-report.component.ts
        │   ├── ei-outage-report.component.html
        │   ├── ei-outage-report.component.scss
        │   ├── ei-outage-report.module.ts
        │   └── ei-outage-report-filter/
        │       ├── ei-outage-report-filter.component.ts
        │       ├── ei-outage-report-filter.component.html
        │       └── ei-outage-report-filter.component.scss
        ├── incidents-management/     ← gestión de incidencias (Tipo B)
        ├── monitoring-reports/       ← monitoring reports
        ├── summary-reports/          ← summary reports
        ├── gas-reports/
        ├── customer-outage-time-report/
        └── ...
```

---

## 3. Configuración: Environments y Runtime Config

### Patrón de dos capas

El proyecto usa **dos capas** de configuración que nunca deben confundirse:

**Capa 1 — Angular environments** (`src/environments/`)
Solo controla flags de build Angular (optimization, sourceMap). El único valor real en prod es el server URL:

```typescript
// environment.prod.ts
export const environment: Config = {
  ...defaultEnv,
  production: true,
  server: 'https://qaxapp01.xecc.nyseg.com',
};
```

**Capa 2 — Runtime config** (`src/assets/config/config.json`)
Cargado en startup mediante `APP_INITIALIZER`. Este es el que se usa en todos los servicios:

```json
{
  "production": false,
  "server": "http://localhost:8081",
  "serverAppId": "icds",
  "gisServer": "...",
  "reportPageSize": 0,
  "detailIncidenlCustomersPageSize": 1000
}
```

### ConfigService — cómo se consume en servicios

```typescript
// config.service.ts
@Injectable({ providedIn: 'root' })
export class ConfigService {
  private __config: Config;

  async load(url: string) {
    this.__config = await this.httpClient.get(url).toPromise();
  }

  getProperty<T extends keyof Config>(prop: T) {
    if (this.__config?.[prop] === undefined) {
      throw new Error(`[config] property missing: [${prop}]`);
    }
    return this.__config[prop];
  }
}
```

**Patrón de construcción de URL en servicios** (usar siempre así):

```typescript
constructor(private configService: ConfigService) {
  this.apiUrl = [
    this.configService.getProperty('server'),
    this.configService.getProperty('serverAppId'),
    'api',
    'reports',
    'mi-endpoint',
  ].join('/');
  // Resultado: http://localhost:8081/icds/api/reports/mi-endpoint
}
```

---

## 4. Cómo se llama al Backend: Servicio HTTP Real y Completo

### Servicio específico de un reporte (Tipo A — nuevo patrón)

```typescript
// src/app/@core/services/ei-outage-report.service.ts
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { EiOutageReportResponse } from '../model/eiOutageReport';
import { EiOutageReportFilterData } from '../model/eiOutageReportFilter';
import { GeneralService } from './general-service';
import { ConfigService } from '../../config.service';

@Injectable()
export class EiOutageReportService {
  private readonly apiUrl: string;
  private readonly httpOptions = {
    headers: new HttpHeaders({ 'Content-Type': 'application/json' }),
  };

  constructor(private http: HttpClient, private configService: ConfigService) {
    this.apiUrl = [
      this.configService.getProperty('server'),
      this.configService.getProperty('serverAppId'),
      'api', 'reports', 'ny-reliability-indexes',
    ].join('/');
  }

  getReport(filter: EiOutageReportFilterData): Observable<EiOutageReportResponse> {
    const payload = this.buildPayload(filter);
    return this.http.post<EiOutageReportResponse>(this.apiUrl, payload, this.httpOptions);
  }

  private buildPayload(filter: EiOutageReportFilterData) {
    const locations = Array.isArray(filter.locationSelected)
      ? filter.locationSelected
      : filter.locationSelected ? [filter.locationSelected] : [];

    return {
      codeCompany: filter.opCoSelected?.idOpco ?? -1,
      filterSelection: filter.viewMode === 'STA' ? 'AREA' : 'DIVISION',
      lstDivisions: locations.map((l) => l.idLocation),
      startDate: filter.dateFrom
        ? GeneralService.formatDateTimeForRequest(filter.dateFrom) : null,
      endDate: filter.dateTo
        ? GeneralService.formatDateTimeForRequest(filter.dateTo) : null,
      lstIncidentStages: filter.stagesSelected.map((s) => parseInt(s, 10)),
    };
  }
}
```

> **Nota**: El servicio se declara como `@Injectable()` (sin `providedIn: 'root'`) y se registra en `providers` del módulo del reporte. Esto lo mantiene en el scope del módulo lazy.

### Formato de fechas para el backend

Siempre usar `GeneralService.formatDateTimeForRequest(date)` — produce `"MM/DD/YYYY hh:mm"`.

```typescript
// general-service.ts (métodos estáticos de utilidad)
static formatDateTimeForRequest(fecha: Date): string {
  return (
    [padTo2Digits(fecha.getMonth() + 1), padTo2Digits(fecha.getDate()), fecha.getFullYear()].join('/') +
    ' ' +
    [padTo2Digits(fecha.getHours()), padTo2Digits(fecha.getMinutes())].join(':')
  );
}
```

### MonitoringReportService — servicio genérico con caché y auto-refresh

Usado por los Standard Electric Reports. Rutea a distintos endpoints según `reportCode`:

```typescript
const REPORT_CODE_TO_ENDPOINT: Record<string, string> = {
  '110': 'ics-storm', '111': 'wdbd', '112': 'ics-pole-track',
  '113': 'pcs-call-oms', '114': 'ics-metric', '115': 'eo-unnest',
  '116': 'ics-veg', '119': 'ics-telecom-pole', '120': 'broken-poles',
  '121': 'unassigned-events', '122': 'unassigned-pings',
  '125': 'ny-reliability-indexes',
};
```

---

## 5. Tipos de Reporte: Dos Patrones de Componente

### Tipo A — 2 Acordeones (Filtro + Tabla)
**Ejemplo**: `ei-outage-report`

Estructura mínima:
```
pages/mi-reporte/
├── mi-reporte.component.ts       ← lógica principal
├── mi-reporte.component.html     ← 2 nb-accordion-item
├── mi-reporte.component.scss
├── mi-reporte.module.ts
└── mi-reporte-filter/
    ├── mi-reporte-filter.component.ts
    ├── mi-reporte-filter.component.html
    └── mi-reporte-filter.component.scss
```

### Tipo B — 3 Acordeones (Filtro + Reporte + Detalle con Tabs)
**Ejemplo**: `standardElectricReports`

Usa `ngx-filter-reports` (componente genérico de filtrado), `ngx-avtable` o `ngx-avtable-expanded` para la tabla, y `ngx-incident-detail` en tabs para el detalle. Solo un componente (`StdElectReportsComponent`) maneja todos los reportes con códigos 110-124, diferenciando por `queryParams.idReport`.

```html
<!-- stdElectReports.component.html — estructura de 3 acordeones -->
<nb-accordion class="accent-primary">
  <nb-accordion-item [expanded]="showFilters" #accordionFilter>
    <nb-accordion-item-header>
      <nb-icon icon="funnel-outline" style="margin-right: 0.5rem"></nb-icon>
      Filtering Criteria
    </nb-accordion-item-header>
    <nb-accordion-item-body>
      <ngx-filter-reports #filterReport (searchEvent)="getReport($event)"
        [reportCode]="reportCode"></ngx-filter-reports>
    </nb-accordion-item-body>
  </nb-accordion-item>

  <nb-accordion-item #accordionReport [disabled]="showFilters" [expanded]="!showFilters">
    <nb-accordion-item-header>
      <nb-icon icon="file-text-outline" style="margin-right: 0.5rem"></nb-icon>Report
    </nb-accordion-item-header>
    <nb-accordion-item-body>
      <ngx-avtable #avdt [data]="data$ | async" [avgTableCols]="cols"
        (refreshClicked)="RefreshClicked($event)" ...></ngx-avtable>
    </nb-accordion-item-body>
  </nb-accordion-item>

  <nb-accordion-item *ngIf="!hideDetailAccordion" #accordionDetails [disabled]="isDetailsDisabled">
    <nb-accordion-item-header>
      <nb-icon icon="search-outline" style="margin-right: 0.5rem"></nb-icon>Details
    </nb-accordion-item-header>
    <nb-accordion-item-body>
      <p-tabView [(activeIndex)]="activeIndex" (onClose)="closeTab($event)" [scrollable]="true">
        <p-tabPanel *ngFor="let tab of tabs" [header]="tab.title" [closable]="true">
          <ngx-incident-detail [incidentId]="tab.title" [codCompany]="tab.company"></ngx-incident-detail>
        </p-tabPanel>
      </p-tabView>
    </nb-accordion-item-body>
  </nb-accordion-item>
</nb-accordion>
```

---

## 6. Componente Tipo A Completo — `ei-outage-report`

### 6.1 Modelo de datos

```typescript
// src/app/@core/model/eiOutageReport.ts
export interface EiOutageReportRow {
  opco: string;
  division: string;
  custServed: number;
  custOut: number;
  numCalls?: number;
  numIncidents?: number;
  pctOut: number;
  outagesOver24h: number;
  hasOutageOver24h: string;  // 'Y' | 'N'
  majorOutageFlag: string;
  majorOutageReason: string;
  summaryRow?: boolean;      // true = fila de cabecera de grupo (OpCo total)
}

export interface EiOutageReportResponse {
  lstReport: EiOutageReportRow[];
  currentDate: string;
  lNumReg?: number;
  lnumReg?: number;
}
```

```typescript
// src/app/@core/model/eiOutageReportFilter.ts
import { Location } from './location';
import { OpCo } from './opco';

export interface EiOutageReportFilterData {
  dateFrom: Date;
  dateTo: Date;
  opCoSelected: OpCo;
  locationSelected: Location | Location[];
  viewMode: 'DIV' | 'STA';
  stagesSelected: string[];
}

export const EI_STAGES = [
  { code: '1', label: 'Initiated' },
  { code: '2', label: 'Assigned' },
  { code: '3', label: 'On Site' },
  { code: '4', label: 'Power On' },
  { code: '5', label: 'Completed' },
  { code: '0', label: 'Cancelled' },
];
```

### 6.2 Componente principal (TypeScript completo)

```typescript
// src/app/pages/ei-outage-report/ei-outage-report.component.ts
import { ChangeDetectorRef, Component, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { DecimalPipe } from '@angular/common';
import { NbAccordionItemComponent } from '@nebular/theme';
import { PrimeNGConfig, SortEvent } from 'primeng/api';
import { Table } from 'primeng/table';
import { Observable, Subscription } from 'rxjs';
import { finalize } from 'rxjs/operators';
import { EiOutageReportResponse, EiOutageReportRow } from '../../@core/model/eiOutageReport';
import { EiOutageReportFilterData } from '../../@core/model/eiOutageReportFilter';
import { EiOutageReportService } from '../../@core/services/ei-outage-report.service';
import { GeneralService } from '../../@core/services/general-service';

interface ColDef {
  header: string;
  field: string;
  filterType: string;
  hidden?: boolean;
  dataType?: string;
  textAlign?: 'left' | 'right' | 'center';
}

const DISCLOSURE_MSG = 'Disclosure: These values are not scrubbed.';
const OPCO_ORDER = ['CMP', 'ALL NY', 'NYSEG', 'RGE'];

@Component({
  selector: 'ngx-ei-outage-report',
  templateUrl: './ei-outage-report.component.html',
  styleUrls: ['./ei-outage-report.component.scss'],
  providers: [DecimalPipe],
})
export class EiOutageReportComponent implements OnInit, OnDestroy {
  @ViewChild('dt') table: Table;
  @ViewChild('accordionFilter') accordionFilter: NbAccordionItemComponent;
  @ViewChild('accordionReport') accordionReport: NbAccordionItemComponent;

  disclosureMessage = DISCLOSURE_MSG;
  reportSubheader = '';
  showFilters = true;
  data: EiOutageReportRow[] = [];
  totalFooter: EiOutageReportRow | null = null;
  headerGroupMap = new Map<string, EiOutageReportRow>();
  loading = false;
  searchText = '';
  reportFontSize = 100;
  colSelectVisible = false;
  filterData: EiOutageReportFilterData = null;
  cols: ColDef[] = [];
  allColumns: ColDef[] = [];
  private subscription = new Subscription();

  constructor(
    private eiReportService: EiOutageReportService,
    private primengConfig: PrimeNGConfig,
    private decimalPipe: DecimalPipe,
    private generalService: GeneralService,
    private cdr: ChangeDetectorRef,
  ) {}

  ngOnInit() {
    this.primengConfig.ripple = true;
    this.initColumns();
    this.updateVisibleColumns();
  }

  ngOnDestroy() { this.subscription.unsubscribe(); }

  private initColumns() {
    this.allColumns = [
      { header: 'Location',           field: 'division',         filterType: 'freeText', hidden: false, dataType: 'text'    },
      { header: '#Cust. Served',      field: 'custServed',       filterType: 'number',   hidden: false, dataType: 'number'  },
      { header: '#Cust. Out',         field: 'custOut',          filterType: 'number',   hidden: false, dataType: 'number'  },
      { header: '#Calls',             field: 'numCalls',         filterType: 'number',   hidden: false, dataType: 'number'  },
      { header: '#Incidents',         field: 'numIncidents',     filterType: 'number',   hidden: false, dataType: 'number'  },
      { header: '%Cust. Out',         field: 'pctOut',           filterType: 'number',   hidden: false, dataType: 'percent' },
      { header: '#Outages 24h+',      field: 'outagesOver24h',   filterType: 'number',   hidden: false, dataType: 'number'  },
      { header: '24h+ Indicator',     field: 'hasOutageOver24h', filterType: 'freeText', hidden: false, dataType: 'text', textAlign: 'right' },
    ];
  }

  private updateVisibleColumns() {
    this.cols = this.allColumns.filter((c) => !c.hidden);
  }

  getGroupHeader(opco: string): EiOutageReportRow | undefined {
    return this.headerGroupMap.get(opco);
  }

  getHeaderAlign(col: ColDef): 'left' | 'right' {
    return col.field === 'division' ? 'left' : 'right';
  }

  private buildDisplayData(rows: EiOutageReportRow[]): EiOutageReportRow[] {
    const withoutTotal = rows.filter((r) => r.opco !== 'TOTAL');
    this.totalFooter = rows.find((r) => r.opco === 'TOTAL') || null;

    const byOpco = new Map<string, EiOutageReportRow[]>();
    for (const row of withoutTotal) {
      const key = row.opco || 'Unknown';
      if (!byOpco.has(key)) byOpco.set(key, []);
      byOpco.get(key).push(row);
    }

    const hasNySeg = byOpco.has('NYSEG');
    const hasRge = byOpco.has('RGE');
    const includeAllNy = hasNySeg && hasRge && byOpco.has('ALL NY');
    const displayOrder = OPCO_ORDER.filter((o) =>
      o === 'ALL NY' ? includeAllNy : byOpco.has(o)
    );

    this.headerGroupMap = new Map<string, EiOutageReportRow>();
    const result: EiOutageReportRow[] = [];

    for (const opco of displayOrder) {
      const opcoRows = byOpco.get(opco) || [];
      const summary = opcoRows.find((r) => r.summaryRow === true);
      const details = opcoRows.filter((r) => !r.summaryRow);
      if (summary) {
        this.headerGroupMap.set(opco, summary);
        result.push(summary);
      }
      result.push(...details);
    }
    return result;
  }

  loadData(filter: EiOutageReportFilterData) {
    this.loading = true;
    this.filterData = filter;
    this.eiReportService
      .getReport(filter)
      .pipe(finalize(() => { this.loading = false; this.cdr.detectChanges(); }))
      .subscribe((res: EiOutageReportResponse) => {
        this.data = this.buildDisplayData(res.lstReport || []);
        this.reportSubheader = this.filterData?.opCoSelected?.nameOpco
          ? `${this.filterData.opCoSelected.nameOpco} - EI Outages` : '';
        this.updateVisibleColumns();
      });
  }

  getReport(filter: EiOutageReportFilterData) {
    this.showFilters = false;
    this.accordionFilter?.close();
    this.accordionReport?.open();
    this.loadData(filter);
  }

  manualRefresh() {
    if (this.filterData) this.loadData(this.filterData);
  }

  formatNumber(num: number): string {
    return this.decimalPipe.transform(num, '1.0-0') || '0';
  }

  formatPercent(num: number): string {
    return num != null ? this.decimalPipe.transform(num, '1.2-2') || '0' : '';
  }

  // Sort within each opco section only. Summary rows stay pinned at top.
  // IMPORTANT: With groupRowsBy active, PrimeNG passes multiSortMeta[0]=groupField, multiSortMeta[1]=clickedColumn
  customSort(event: SortEvent) {
    const multi = event.multiSortMeta ?? [];
    const columnMeta = multi.length > 1 ? multi[1] : multi[0] ?? { field: event.field, order: event.order };
    const field = columnMeta?.field;
    if (!field || field === 'opco') return;

    const order = columnMeta?.order ?? 1;
    const data = (event.data ?? this.data) as EiOutageReportRow[];
    const byOpco = new Map<string, EiOutageReportRow[]>();
    for (const row of data) {
      const key = row.opco || '';
      if (!byOpco.has(key)) byOpco.set(key, []);
      byOpco.get(key).push(row);
    }

    const compare = (a: EiOutageReportRow, b: EiOutageReportRow) => {
      const va = a[field as keyof EiOutageReportRow];
      const vb = b[field as keyof EiOutageReportRow];
      if (va == null && vb != null) return -1 * order;
      if (va != null && vb == null) return 1 * order;
      if (va == null && vb == null) return 0;
      if (typeof va === 'number' && typeof vb === 'number') return (va < vb ? -1 : va > vb ? 1 : 0) * order;
      return String(va).localeCompare(String(vb)) * order;
    };

    const result: EiOutageReportRow[] = [];
    for (const opco of OPCO_ORDER) {
      const rows = byOpco.get(opco);
      if (!rows?.length) continue;
      const summary = rows.find((r) => r.summaryRow);
      const details = rows.filter((r) => !r.summaryRow);
      details.sort(compare);
      if (summary) result.push(summary);
      result.push(...details);
    }

    // Mutate in place — critical for PrimeNG to re-render with rowGroupMode
    const target = event.data as EiOutageReportRow[];
    target.length = 0;
    target.push(...result);
    this.cdr.detectChanges();
  }

  getFooterValue(col: ColDef): any {
    if (!this.totalFooter) return '';
    if (col.field === 'division') return 'TOTAL';
    const v = this.totalFooter[col.field as keyof EiOutageReportRow];
    if (col.dataType === 'percent') return this.formatPercent(v as number);
    if (col.dataType === 'number') return this.formatNumber(v as number);
    return v ?? '';
  }

  exportToExcel() {
    const footer = this.cols.map((c) => this.getFooterValue(c));
    this.generalService.exportToExcel(
      `EI Outage Report - ${this.disclosureMessage}`,
      'EI_Outage_Report_' + GeneralService.formatDateTime(new Date()) + '.xlsx',
      this.table, footer,
    );
  }

  toggleColumnVisibility(col: ColDef) {
    col.hidden = !col.hidden;
    this.updateVisibleColumns();
    this.cdr.detectChanges();
  }

  fontSizeUp() { this.reportFontSize = Math.min(150, this.reportFontSize + 10); }
  fontSizeDown() { this.reportFontSize = Math.max(70, this.reportFontSize - 10); }
}
```

### 6.3 Template HTML completo

```html
<!-- ei-outage-report.component.html -->
<nb-card>
  <nb-card-header class="ei-outage-report-header">
    <div>
      <h5>EI Outage Report (Electric Incidents)</h5>
      <h6>{{ reportSubheader }}</h6>
    </div>
  </nb-card-header>

  <nb-card-body>
    <div class="disclosure-banner">
      <span class="disclosure-text">{{ disclosureMessage }}</span>
    </div>

    <nb-accordion class="accent-primary">
      <!-- Acordeón 1: Filtros -->
      <nb-accordion-item [expanded]="showFilters" #accordionFilter>
        <nb-accordion-item-header>
          <nb-icon icon="funnel-outline" style="margin-right: 0.5rem"></nb-icon>
          Filtering Criteria
        </nb-accordion-item-header>
        <nb-accordion-item-body>
          <ngx-ei-outage-report-filter
            #filterReport
            (searchEvent)="getReport($event)"
          ></ngx-ei-outage-report-filter>
        </nb-accordion-item-body>
      </nb-accordion-item>

      <!-- Acordeón 2: Tabla de resultados -->
      <nb-accordion-item #accordionReport [disabled]="showFilters" [expanded]="!showFilters">
        <nb-accordion-item-header>
          <nb-icon icon="file-text-outline" style="margin-right: 0.5rem"></nb-icon>
          Report
        </nb-accordion-item-header>
        <nb-accordion-item-body>

          <!-- Loading overlay -->
          <div *ngIf="loading" class="loading-overlay">
            <p-progressSpinner styleClass="custom-spinner"
              [style]="{ width: '60px', height: '60px' }" strokeWidth="3"
              fill="#EEEEEE" animationDuration="1s">
            </p-progressSpinner>
          </div>

          <!-- Wrapper para zoom de fuente -->
          <div class="report-zoom-container" [style.font-size.%]="reportFontSize">
            <p-table
              #dt
              [value]="data"
              styleClass="p-datatable-foos p-datatable-striped"
              [rowHover]="true"
              [loading]="loading"
              [paginator]="false"
              [resizableColumns]="true"
              columnResizeMode="expand"
              [columns]="cols"
              responsiveLayout="scroll"
              (sortFunction)="customSort($event)"
              [customSort]="true"
              sortMode="single"
              rowGroupMode="subheader"
              groupRowsBy="opco"
              [globalFilterFields]="['opco', 'division']"
            >
              <!-- Toolbar (caption) -->
              <ng-template pTemplate="caption">
                <div class="table-toolbar">
                  <div class="toolbar-left">
                    <span class="p-input-icon-left">
                      <i class="pi pi-search"></i>
                      <input type="text" pInputText [(ngModel)]="searchText"
                        (input)="dt.filterGlobal($any($event.target).value, 'contains')"
                        placeholder="Search OpCo, Division..." class="search-input"/>
                    </span>
                  </div>
                  <div class="toolbar-right">
                    <div class="font-size-controls">
                      <button pButton pRipple icon="pi pi-minus" class="p-button-text p-button-sm"
                        (click)="fontSizeDown()" pTooltip="Decrease font size"></button>
                      <span class="font-size-label">{{ reportFontSize }}%</span>
                      <button pButton pRipple icon="pi pi-plus" class="p-button-text p-button-sm"
                        (click)="fontSizeUp()" pTooltip="Increase font size"></button>
                    </div>
                    <button pButton pRipple icon="pi pi-list" class="p-button-text"
                      (click)="colSelectVisible = !colSelectVisible" pTooltip="Column selection"></button>
                    <button pButton pRipple icon="pi pi-file-excel"
                      (click)="exportToExcel()" pTooltip="Export to Excel"></button>
                    <ngx-refresh [refreshDisabled]="loading" (refreshEvent)="manualRefresh()"></ngx-refresh>
                  </div>
                </div>
                <!-- Panel de selección de columnas -->
                <div class="column-select-panel" *ngIf="colSelectVisible">
                  <div class="col-select-title">Show/Hide Columns</div>
                  <div *ngFor="let col of allColumns" class="col-select-item">
                    <p-checkbox [binary]="true" [ngModel]="!col.hidden"
                      (ngModelChange)="toggleColumnVisibility(col)"></p-checkbox>
                    <label>{{ col.header }}</label>
                  </div>
                </div>
              </ng-template>

              <!-- Cabecera de tabla -->
              <ng-template pTemplate="header" let-columns>
                <tr>
                  <th style="width: 0.5rem"></th>
                  <th *ngFor="let col of columns"
                    pResizableColumn pSortableColumn="{{ col.field }}"
                    [hidden]="col.hidden"
                    [style.text-align]="getHeaderAlign(col)">
                    {{ col.header }}
                    <p-sortIcon field="{{ col.field }}"></p-sortIcon>
                  </th>
                  <th style="width: 0.5rem"></th>
                </tr>
              </ng-template>

              <!-- Cabecera de grupo (subtotales OpCo del servidor, summaryRow:true) -->
              <ng-template pTemplate="groupheader" let-rowData let-columns="columns">
                <tr style="background-color: #f2fcda" *ngIf="getGroupHeader(rowData.opco) as item">
                  <td style="width: 0.5rem"></td>
                  <td *ngFor="let col of columns"
                    [hidden]="col.hidden" [ngSwitch]="col.dataType"
                    [style.text-align]="col.textAlign ?? ((col.dataType === 'number' || col.dataType === 'percent') ? 'right' : 'left')">
                    <strong>
                      <span *ngSwitchCase="'number'">{{ formatNumber(item[col.field]) }}</span>
                      <span *ngSwitchCase="'percent'">{{ formatPercent(item[col.field]) }}</span>
                      <span *ngSwitchDefault>{{ col.field === 'division' ? item.opco : item[col.field] }}</span>
                    </strong>
                  </td>
                  <td style="width: 0.5rem"></td>
                </tr>
              </ng-template>

              <!-- Filas de detalle (solo !summaryRow) -->
              <ng-template pTemplate="body" let-rowData let-columns="columns">
                <tr *ngIf="!rowData.summaryRow" class="p-selectable-row">
                  <td style="width: 1rem"></td>
                  <td *ngFor="let col of columns"
                    [ngSwitch]="col.dataType" [hidden]="col.hidden"
                    [style.text-align]="col.textAlign ?? ((col.dataType === 'number' || col.dataType === 'percent') ? 'right' : 'left')">
                    <span *ngSwitchCase="'number'">{{ formatNumber(rowData[col.field]) }}</span>
                    <span *ngSwitchCase="'percent'">{{ formatPercent(rowData[col.field]) }}</span>
                    <span *ngSwitchDefault>{{ rowData[col.field] }}</span>
                  </td>
                  <td style="width: 0.5rem"></td>
                </tr>
              </ng-template>

              <!-- Footer con totales del servidor -->
              <ng-template pTemplate="footer">
                <tr>
                  <td style="width: 1rem"></td>
                  <td *ngFor="let col of cols"
                    [hidden]="col.hidden"
                    [style.text-align]="col.textAlign ?? ((col.dataType === 'number' || col.dataType === 'percent') ? 'right' : 'left')">
                    <strong>{{ getFooterValue(col) }}</strong>
                  </td>
                  <td style="width: 0.5rem"></td>
                </tr>
              </ng-template>

              <ng-template pTemplate="emptymessage">
                <tr><td colspan="10">No data found.</td></tr>
              </ng-template>
            </p-table>
          </div>

        </nb-accordion-item-body>
      </nb-accordion-item>
    </nb-accordion>
  </nb-card-body>
</nb-card>
```

---

## 7. Gestión de Filtros

### Patrón del componente de filtro

Cada reporte tiene su propio componente de filtro. El patrón es siempre el mismo:

1. **`@Output() searchEvent`** emite el objeto filter tipado al componente padre.
2. **`ngOnInit()`** pre-selecciona empresa y fechas desde `GlobalService`.
3. **Validación** en `isFilterOk()` antes de emitir.
4. **`resetFilter()`** restaura los valores por defecto del global state.

```typescript
// Patrón filter component
@Component({ selector: 'ngx-mi-reporte-filter', ... })
export class MiReporteFilterComponent implements OnInit {
  @Output() searchEvent = new EventEmitter<MiReporteFilterData>();
  @ViewChild('compDates') compDates: CalendarIntervalComponent;
  @ViewChild('compLocation') compLocation: LocationComponent;

  selectedCia: OpCo;
  dateFrom: Date;
  dateTo: Date;
  selectedDivisions: Location | Location[] = [];

  constructor(private globalService: GlobalService, private cdr: ChangeDetectorRef) {}

  ngOnInit() {
    const globalCompany = this.globalService.getCompany();
    this.selectedCia = globalCompany?.idOpco >= 0
      ? globalCompany : { idOpco: -1, nameOpco: 'Select Op. Company' };
    this.dateFrom = this.globalService.dateFrom ?? new Date(new Date().setHours(0, 0, 0, 0));
    this.dateTo   = this.globalService.dateTo   ?? new Date(new Date().setHours(23, 59, 59, 0));
    this.cdr.detectChanges();
  }

  getReport() {
    if (this.isFilterOk()) {
      this.searchEvent.emit(this.mapSelectionsToFilterReportData());
    }
  }
}
```

### Componentes de filtro disponibles en `SharedModuleModule`

| Selector | Clase | Uso |
|---|---|---|
| `ngx-company` | `CompanyComponent` | Dropdown selector de OpCo (empresa) |
| `ngx-companies` | `CompaniesComponent` | Multi-select de varias empresas |
| `ngx-location` | `LocationComponent` | Lista de divisiones o storm areas, con toggle DIV/STA |
| `ngx-calendar-interval` | `CalendarIntervalComponent` | Selector de rango de fechas From/To |
| `ngx-incident-status` | `IncidentStatusComponent` | Checkbox multi-select de estados de incidencia |
| `ngx-incident-type` | `IncidentTypeComponent` | Multi-select tipos de incidencia |
| `ngx-county-town` | `CountyTownComponent` | Selector county/town |
| `ngx-notification-code` | `NotificationCodeComponent` | Código de notificación |
| `ngx-period-over` | `PeriodOverComponent` | Período de tiempo (horas) |

### Template de filtro estándar

```html
<ngx-message #comMessage [errorMessage]="msgError"></ngx-message>

<nb-card class="filterCard" accent="secondary">
  <nb-card-body>
    <div class="filters">
      <!-- 1. Empresa -->
      <div class="filter-item">
        <ngx-company #compOpco
          (selectedOptionChange)="onSelectedCompanyChange($event)"
          [selectedCompany]="selectedCia">
        </ngx-company>
      </div>

      <!-- 2. Divisiones / Storm Areas -->
      <div class="filter-item">
        <ngx-location #compLocation
          [opcoSelected]="selectedCia"
          [(selectedLocations)]="selectedDivisions"
          [reportChanged]="reportCode"
          [showLocType]="true"
          [multipleSelection]="true">
        </ngx-location>
      </div>

      <!-- 3. Fechas -->
      <div class="filter-item">
        <ngx-calendar-interval #compDates
          (selectedDatesChange)="onDateSelection($event)"
          (errorDatesMessage)="onDatesError($event)"
          [showVertical]="true"
          [dateFrom]="dateFrom"
          [dateTo]="dateTo">
        </ngx-calendar-interval>
      </div>

      <!-- 4. Botones -->
      <div class="filter-button">
        <button pButton class="p-button-secondary" label="Reset"
          icon="pi pi-eraser" (click)="resetFilter()"></button>
        <button pButton type="button" icon="pi pi-search"
          label="Search" (click)="getReport()"></button>
      </div>
    </div>
  </nb-card-body>
</nb-card>
```

---

## 8. Componentes Compartidos de Tabla

### `ngx-avtable` — tabla estándar para Standard Electric Reports

Selector: `ngx-avtable`. Inputs principales:

```html
<ngx-avtable
  #avdt
  [reportType]="reportType"            <!-- string, ej: 'STD_ELECT' -->
  [reportCode]="reportCode"            <!-- number -->
  [avgTableCols]="cols"               <!-- array de {header, field, filterType} -->
  [data]="data$ | async"              <!-- datos como array -->
  [dataKey]="'numIncident'"           <!-- campo clave para selección -->
  [showSelectionCheckbox]="true"
  [showIncidentPackageButton]="true"
  [showMapButton]="true"
  [showRefreshButton]="true"
  [showTotalsRow]="false"
  [rowTotals]="rowTotals"
  [filterReport]="filterReport"       <!-- ref al FilterReportsComponent -->
  [reportName]="reportName"
  (linkClick)="linkClick($event)"
  (refreshClicked)="RefreshClicked($event)"
  (mapClicked)="mapClicked($event)"
  (pdfClicked)="pdfClicked($event)"
></ngx-avtable>
```

### `ngx-avtable-expanded` — tabla con grupos expandibles (ICS Storm, ICS Veg)

Mismos inputs que `ngx-avtable` pero sin los botones específicos de incident package.

### `ngx-refresh` — botón refresh con auto-refresh

```html
<ngx-refresh
  [refreshDisabled]="loading"
  (refreshEvent)="manualRefresh()">
</ngx-refresh>
```

Soporta auto-refresh a 1, 5, 10, 25 minutos. Muestra barra de progreso.

### `p-progressSpinner` — spinner de carga

Patrón de loading overlay sobre el cuerpo del acordeón:

```html
<!-- En el scss del componente: -->
<!-- .loading-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%;
     display: flex; align-items: center; justify-content: center; z-index: 10; background: rgba(255,255,255,0.7); } -->
<!-- nb-accordion-item-body .nb-accordion-item-body-inner { position: relative; } -->

<div *ngIf="loading" class="loading-overlay">
  <p-progressSpinner styleClass="custom-spinner"
    [style]="{ width: '60px', height: '60px' }"
    strokeWidth="3" fill="#EEEEEE" animationDuration="1s">
  </p-progressSpinner>
</div>
```

---

## 9. Routing

### Añadir una nueva ruta

Hay **3 lugares** que siempre deben actualizarse al añadir un nuevo reporte:

**1. `src/app/pages/constants.ts`** — añadir la constante de ruta:
```typescript
export class Constants {
  static readonly MI_NUEVO_REPORTE = 'mi-nuevo-reporte';
  static readonly N_MI_NUEVO_REPORTE = 999; // código numérico si aplica
  // ...
}
```

**2. `src/app/pages/pages-routing.module.ts`** — añadir la ruta:
```typescript
import { MiNuevoReporteComponent } from './mi-nuevo-reporte/mi-nuevo-reporte.component';

export const routes: Routes = [
  {
    path: '',
    component: PagesComponent,
    children: [
      // ... rutas existentes ...
      {
        path: Constants.MI_NUEVO_REPORTE,
        component: MiNuevoReporteComponent,
      },
    ],
  },
];
```

**3. `src/app/pages/pages-menu.ts`** — añadir al árbol de menú:
```typescript
export const MENU_ITEMS: NbMenuItem[] = [
  // ...
  {
    title: 'Monitoring Reports',
    children: [
      {
        title: 'SUMMARY REPORTS',
        children: [
          // ... otros items ...
          {
            title: 'Mi Nuevo Reporte',
            link: '/pages/' + Constants.MI_NUEVO_REPORTE,
          },
        ],
      },
    ],
  },
];
```

**4. `src/app/pages/pages.module.ts`** — importar el módulo:
```typescript
import { MiNuevoReporteModule } from './mi-nuevo-reporte/mi-nuevo-reporte.module';

@NgModule({
  imports: [
    // ...
    MiNuevoReporteModule,
  ],
})
export class PagesModule {}
```

### Standard Electric Reports — patrón alternativo

Estos reportes no crean un componente nuevo. Usan un único `StdElectReportsComponent` que recibe el código por `queryParams`:

```typescript
// pages-routing.module.ts
{
  path: 'standardElectricReports_' + Constants.ICS_STORM_REPORT,
  component: StdElectReportsComponent,
},
// pages-menu.ts
{
  title: 'ICS Storm',
  link: '/pages/standardElectricReports_' + Constants.ICS_STORM_REPORT,
  queryParams: { idReport: Constants.ICS_STORM_REPORT },
},
```

---

## 10. Módulo de un Reporte Nuevo

### `mi-nuevo-reporte.module.ts` — template

```typescript
import { NgModule } from '@angular/core';
import {
  NbCardModule, NbAccordionModule, NbIconModule,
} from '@nebular/theme';
import { ThemeModule } from '../../@theme/theme.module';
import { SharedModuleModule } from '../../common/shared-module/shared-module.module';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { TableModule } from 'primeng/table';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { CheckboxModule } from 'primeng/checkbox';
import { TooltipModule } from 'primeng/tooltip';
import { ProgressSpinnerModule } from 'primeng/progressspinner';

import { MiNuevoReporteComponent } from './mi-nuevo-reporte.component';
import { MiNuevoReporteFilterComponent } from './mi-nuevo-reporte-filter/mi-nuevo-reporte-filter.component';
import { MiNuevoReporteService } from '../../@core/services/mi-nuevo-reporte.service';

@NgModule({
  imports: [
    CommonModule,
    FormsModule,
    ThemeModule,
    SharedModuleModule,    // ← incluye ngx-company, ngx-location, ngx-calendar-interval, ngx-refresh, etc.
    NbCardModule,
    NbAccordionModule,
    NbIconModule,
    TableModule,           // p-table
    ButtonModule,          // pButton
    InputTextModule,       // pInputText
    CheckboxModule,        // p-checkbox
    TooltipModule,         // pTooltip
    ProgressSpinnerModule, // p-progressSpinner
  ],
  declarations: [MiNuevoReporteComponent, MiNuevoReporteFilterComponent],
  providers: [MiNuevoReporteService],
})
export class MiNuevoReporteModule {}
```

> **Regla**: `SharedModuleModule` es suficiente para tener acceso a todos los componentes de filtro (`ngx-company`, `ngx-location`, `ngx-calendar-interval`, `ngx-refresh`, `ngx-message`, etc.). No hace falta importar sus módulos individuales.

---

## 11. Convenciones de Naming

### Archivos y carpetas
- Kebab-case para carpetas y archivos: `ei-outage-report/`, `ei-outage-report.component.ts`
- Sufijos estándar Angular: `.component.ts`, `.service.ts`, `.module.ts`, `.model.ts`
- Modelos en `@core/model/`: nombre en camelCase del tipo, ej: `eiOutageReport.ts`
- Servicios en `@core/services/`: `ei-outage-report.service.ts`

### Selectores de componentes
- Prefix `ngx-` para todos los componentes personalizados: `ngx-ei-outage-report`, `ngx-company`, `ngx-refresh`

### Constantes
- En `constants.ts` clase `Constants` con `static readonly`
- String de ruta: `MI_REPORT = 'mi-report'`
- Número de código: `N_MI_REPORT = 999`

### Interfaces de modelos
- PascalCase: `EiOutageReportRow`, `EiOutageReportResponse`, `EiOutageReportFilterData`
- Archivo: `eiOutageReport.ts` (camelCase sin guiones)

### Interfaces de datos de filtro
- Sufijo `FilterData`: `EiOutageReportFilterData`
- Archivo separado: `eiOutageReportFilter.ts`

---

## 12. Patrones Especiales No Obvios

### 1. Sorting con `rowGroupMode` en PrimeNG

Cuando `p-table` tiene `rowGroupMode="subheader"` y `groupRowsBy`, PrimeNG emite en `sortFunction` el evento con `multiSortMeta: [groupMeta, columnMeta]`. **Siempre usar `multiSortMeta[1]`** para el campo de ordenación real:

```typescript
customSort(event: SortEvent) {
  const multi = event.multiSortMeta ?? [];
  const columnMeta = multi.length > 1 ? multi[1] : multi[0];
  const field = columnMeta?.field;
  if (!field || field === 'opco') return; // guard

  // Mutar el array in-place, NO reasignar this.data
  const target = event.data as EiOutageReportRow[];
  target.length = 0;
  target.push(...result);
  this.cdr.detectChanges(); // forzar re-render
}
```

### 2. Estructura de datos para groupheader

El backend devuelve filas con `summaryRow: true` para los totales de OpCo. El componente debe:
1. Extraer la fila `opco === 'TOTAL'` para el footer global.
2. Poner las filas `summaryRow: true` **primero** en su grupo (son el trigger del `groupheader`).
3. Guardar en un `Map<string, row>` para acceso por `opco` desde el template.

```html
<!-- En groupheader template: getGroupHeader() busca en el Map -->
<ng-template pTemplate="groupheader" let-rowData let-columns="columns">
  <tr *ngIf="getGroupHeader(rowData.opco) as item">
    <!-- renderizar item (la fila summary), NO rowData -->
  </tr>
</ng-template>

<!-- En body template: saltarse las filas summary -->
<ng-template pTemplate="body" let-rowData>
  <tr *ngIf="!rowData.summaryRow">
    ...
  </tr>
</ng-template>
```

### 3. Zoom de fuente en tablas PrimeNG

El `[style.font-size.%]` debe aplicarse en un wrapper `div`, no en `p-table`. Además, necesita `::ng-deep` en el SCSS para que los elementos internos de PrimeNG hereden:

```html
<div class="report-zoom-container" [style.font-size.%]="reportFontSize">
  <p-table ...>...</p-table>
</div>
```

```scss
// en el .scss del componente
::ng-deep .report-zoom-container {
  .p-datatable, .p-datatable-thead > tr > th, .p-datatable-tbody > tr > td {
    font-size: inherit !important;
  }
}
```

### 4. Pre-selección de filtros con GlobalService

```typescript
// siempre en ngOnInit del componente de filtro
ngOnInit() {
  const globalCompany = this.globalService.getCompany();
  this.selectedCia = globalCompany?.idOpco >= 0
    ? globalCompany : { idOpco: -1, nameOpco: 'Select Op. Company' };
  this.dateFrom = this.globalService.dateFrom ?? new Date(new Date().setHours(0, 0, 0, 0));
  this.dateTo   = this.globalService.dateTo   ?? new Date(new Date().setHours(23, 59, 59, 0));
  this.cdr.detectChanges();
}
```

### 5. Accordion abierto/cerrado programáticamente

```typescript
@ViewChild('accordionFilter') accordionFilter: NbAccordionItemComponent;
@ViewChild('accordionReport') accordionReport: NbAccordionItemComponent;

// Al hacer submit del filtro:
this.accordionFilter.close();
this.accordionReport.open();
// El template enlaza: [disabled]="showFilters" [expanded]="!showFilters"
```

### 6. Exportación a Excel

Usa `GeneralService.exportToExcel()`. Requiere `@ViewChild('dt') table: Table` de PrimeNG. El método toma la referencia a la tabla, extrae columnas visibles, aplica selección si existe, y genera `.xlsx`:

```typescript
exportToExcel() {
  const footer = this.cols.map((c) => this.getFooterValue(c));
  this.generalService.exportToExcel(
    'Título del Reporte',
    'nombre_archivo_' + GeneralService.formatDateTime(new Date()) + '.xlsx',
    this.table,
    footer,
  );
}
```

### 7. `SharedModuleModule` vs módulos individuales

`SharedModuleModule` re-exporta **todo**: componentes de filtro, `ngx-avtable`, `ngx-refresh`, etc. Importar solo ese módulo es suficiente en casi todos los casos. No importar `FormsModule`, `CommonModule`, ni módulos PrimeNG individualmente si ya se importa `SharedModuleModule` (aunque es seguro hacerlo también).

### 8. `p-table` con datos agrupados — estructura de `[value]`

La array `[value]` debe contener tanto las filas de summary como las de detalle, intercaladas en el orden correcto:
```
[summaryRow_CMP, detail_CMP_1, detail_CMP_2, summaryRow_NYSEG, detail_NYSEG_1, ...]
```
PrimeNG lee `groupRowsBy="opco"` y usa el primer cambio de valor de `opco` para disparar `groupheader`. Por eso la fila de summary debe ser la primera de su grupo.

---

## 13. Checklist para Crear un Nuevo Reporte Tipo A

1. [ ] Crear carpeta `src/app/pages/mi-reporte/`
2. [ ] Crear interfaces en `src/app/@core/model/miReporte.ts` y `miReporteFilter.ts`
3. [ ] Crear servicio en `src/app/@core/services/mi-reporte.service.ts` (`@Injectable()` sin `providedIn`)
4. [ ] Crear `mi-reporte.component.ts` + `html` + `scss`
5. [ ] Crear subcarpeta `mi-reporte-filter/` con su propio componente
6. [ ] Crear `mi-reporte.module.ts` con imports necesarios y `providers: [MiReporteService]`
7. [ ] Añadir constante en `constants.ts`
8. [ ] Añadir ruta en `pages-routing.module.ts`
9. [ ] Añadir entrada de menú en `pages-menu.ts`
10. [ ] Importar el módulo en `pages.module.ts`

## 14. Checklist para Crear un Nuevo Reporte Tipo B (con detalle)

Igual que Tipo A, más:
- El componente principal necesita `@ViewChild('accordionDetails') accordionDetails`
- Implementar `linkClick(rowData)` que abre el tercerr acordeón y añade un tab a `tabs[]`
- Usar `ngx-incident-detail` o componente de detalle específico dentro de `p-tabView`
- Importar `TabViewModule`, `IncidentDetailModule` en el módulo del reporte
