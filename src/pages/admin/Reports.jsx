import { useSearchParams } from "react-router-dom";
import { pivotReport } from "@/lib/reportPivot";
import { Fragment, useEffect, useMemo, useState } from "react";
import Layout from "@/components/layout/Layout";
import { Button } from "@/components/ui/button";
import {
  sectionTabClass,
  sectionTabsClass,
} from "@/components/ui/section-tabs";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent } from "@/components/ui/card";
import { workDate, workRpc } from "@/lib/workflow";
import { csvTable, excelTable, saveReport } from "@/lib/reportExport";
import ReportCharts from "./ReportCharts";
const definitions = {
  checkins: {
    name: "Fichajes",
    columns: [
      ["employee", "Empleado"],
      ["task", "Tarea"],
      ["start", "Inicio (Madrid)"],
      ["end", "Fin (Madrid)"],
      ["minutes", "Minutos"],
      ["method", "Método"],
      ["status", "Estado"],
    ],
    states: { open: "En curso", closed: "Cerrado" },
  },
  tasks: {
    name: "Tareas",
    columns: [
      ["employee", "Empleado"],
      ["task", "Tarea"],
      ["date", "Fecha planificada"],
      ["priority", "Prioridad"],
      ["status", "Estado"],
      ["result", "Resultado de la ejecución"],
    ],
    states: {
      pending: "Pendiente",
      active: "En curso",
      paused: "Pausada",
      review: "En revisión",
      completed: "Completada",
      cancelled: "Cancelada",
      blocked: "Bloqueada",
      unplanned: "Sin planificación",
    },
  },
  productivity: {
    name: "Productividad",
    columns: [
      ["employee", "Empleado"],
      ["task", "Tarea"],
      ["date", "Día"],
      ["count", "Fichajes terminados"],
      ["minutes", "Total (min)"],
      ["average", "Media (min)"],
    ],
  },
  incidents: {
    name: "Incidencias",
    columns: [
      ["employee", "Informante"],
      ["task", "Tarea"],
      ["subject", "Incidencia"],
      ["responsible", "Responsable / área"],
      ["start", "Creación (Madrid)"],
      ["updated", "Última actualización (Madrid)"],
      ["status", "Estado"],
      ["blocked", "Impide continuar"],
      ["resolution", "Solución"],
    ],
    states: {
      open: "Abierta",
      in_progress: "En atención",
      resolved: "Resuelta",
    },
  },
  closures: {
    name: "Cierres y bloqueos",
    columns: [
      ["employee", "Empleado"],
      ["task", "Tarea"],
      ["actor", "Registrado por"],
      ["start", "Fecha (Madrid)"],
      ["type", "Tipo"],
      ["reason", "Motivo"],
    ],
  },
};
const managementIndicators = {
  productivity: { name: "Productividad", kind: "productivity" },
  estimate: { name: "Tiempo estimado frente a real", kind: "productivity" },
  hours: { name: "Horas trabajadas", kind: "checkins" },
  compliance: { name: "Cumplimiento de tareas", kind: "tasks" },
  overdue: { name: "Tareas atrasadas", kind: "tasks" },
  workload: { name: "Carga de trabajo", kind: "tasks" },
  incidents: { name: "Gestión de incidencias", kind: "incidents" },
  closures: { name: "Cierres y bloqueos", kind: "closures" },
};
const defaultIndicator = {
  checkins: "hours",
  tasks: "compliance",
  productivity: "productivity",
  incidents: "incidents",
  closures: "closures",
};
const monthsBetween = (start, end) => {
  const result = [];
  const current = new Date(start?.slice(0, 7) + "-01T12:00:00Z");
  if (!Number.isFinite(current.getTime())) return result;
  for (
    let n = 0;
    n < 14 && current.toISOString().slice(0, 7) <= end?.slice(0, 7);
    n++
  ) {
    result.push(current.toISOString().slice(0, 7));
    current.setUTCMonth(current.getUTCMonth() + 1);
  }
  return result;
};
const stamp = (v) =>
  v ? new Date(v).toLocaleString("es-ES", { timeZone: "Europe/Madrid" }) : "";
export default function Reports() {
  const [params, setParams] = useSearchParams(),
    initialKind = definitions[params.get("kind")]
      ? params.get("kind")
      : "checkins";
  const [kind, setKind] = useState(initialKind),
    [display, setDisplay] = useState(
      params.get("mode") === "charts" ? "charts" : "data",
    ),
    [indicator, setIndicator] = useState(() => {
      const requested = params.get("indicator");
      return managementIndicators[requested]
        ? requested
        : defaultIndicator[initialKind];
    }),
    [start, setStart] = useState(() => {
      const d = new Date(workDate() + "T12:00:00Z");
      d.setUTCDate(d.getUTCDate() - 29);
      return d.toISOString().slice(0, 10);
    }),
    [end, setEnd] = useState(workDate),
    [search, setSearch] = useState(""),
    [term, setTerm] = useState(""),
    [state, setState] = useState(""),
    [method, setMethod] = useState(""),
    [data, setData] = useState(null),
    [busy, setBusy] = useState(false),
    [error, setError] = useState(""),
    [refresh, setRefresh] = useState(0),
    [sort, setSort] = useState(null),
    [page, setPage] = useState(0);
  const [scope, setScope] = useState("all"),
    [employees, setEmployees] = useState([]),
    [areas, setAreas] = useState([]),
    [directoryError, setDirectoryError] = useState("");
  useEffect(() => {
    let live = true;
    Promise.all([
      workRpc("work_report_employees"),
      workRpc("work_area_directory"),
    ])
      .then(([people, directory]) => {
        if (!live) return;
        setEmployees(people);
        setAreas(directory.areas || []);
      })
      .catch(() => {
        if (live)
          setDirectoryError(
            "Falta activar o cargar los filtros de empleados y áreas en Supabase.",
          );
      });
    return () => {
      live = false;
    };
  }, []);
  const [view, setView] = useState("pivot"),
    [rowField, setRowField] = useState("employee"),
    [columnField, setColumnField] = useState("status"),
    [metric, setMetric] = useState("rows"),
    [pivotPage, setPivotPage] = useState(0);
  useEffect(() => {
    const timer = setTimeout(() => setTerm(search.trim()), 300);
    return () => clearTimeout(timer);
  }, [search]);
  useEffect(() => {
    let live = true;
    setData(null);
    setBusy(true);
    setError("");
    setPage(0);
    const span = (new Date(end) - new Date(start)) / 86400000;
    if (!start || !end || !Number.isFinite(span) || span < 0 || span > 365) {
      setError("Selecciona un período de hasta 366 días.");
      setBusy(false);
      return;
    }
    workRpc("work_report_table_scope", {
      p_kind: kind,
      p_start: start,
      p_end: end,
      p_search: term,
      p_state: state || null,
      p_method: method || null,
      p_employee: scope.startsWith("employee:") ? scope.slice(9) : null,
      p_area: scope.startsWith("area:") ? scope.slice(5) : null,
    })
      .then((v) => {
        if (live) setData(v);
      })
      .catch((e) => {
        if (live)
          setError(
            e.message.includes("work_report_table_scope")
              ? "Activa el filtro por áreas de Informes y análisis en Supabase."
              : e.message,
          );
      })
      .finally(() => {
        if (live) setBusy(false);
      });
    return () => {
      live = false;
    };
  }, [kind, start, end, term, state, method, refresh, scope]);
  const config = definitions[kind];
  const rows = useMemo(() => {
    const list = (data?.items || []).map((r) => {
      const day =
        r.date ||
        (r.start
          ? new Intl.DateTimeFormat("sv-SE", {
              timeZone: "Europe/Madrid",
            }).format(new Date(r.start))
          : null);
      return {
        ...r,
        _sort: r,
        report_day: day,
        report_month: day?.slice(0, 7) || null,
        report_year: day?.slice(0, 4) || null,
        ...Object.fromEntries(
          ["start", "end", "updated"]
            .filter((k) => k in r)
            .map((k) => [k, stamp(r[k])]),
        ),
        method:
          { nfc: "NFC", manual: "Manual", qr: "QR" }[r.method] || r.method,
      };
    });
    if (sort)
      list.sort((a, b) => {
        const x = a._sort[sort.key],
          y = b._sort[sort.key];
        return (
          sort.direction *
          (typeof x === "number" && typeof y === "number"
            ? x - y
            : String(x ?? "").localeCompare(String(y ?? ""), "es", {
                numeric: true,
              }))
        );
      });
    return list;
  }, [data, sort]);
  const dimensions = [
    ...config.columns.filter(([key]) =>
      [
        "employee",
        "task",
        "status",
        "method",
        "date",
        "responsible",
        "type",
        "actor",
        "blocked",
      ].includes(key),
    ),
    ...[
      ["report_day", "Día"],
      ["report_month", "Mes"],
      ["report_year", "Año"],
    ],
  ];
  const measures = [
    ["rows", "Cantidad de registros"],
    ...(["checkins", "productivity"].includes(kind)
      ? [
          ["minutes", "Tiempo total (min)"],
          ["average", "Tiempo medio (min)"],
        ]
      : []),
    ...(kind === "productivity" ? [["count", "Fichajes terminados"]] : []),
  ];
  const pivot = useMemo(
    () =>
      pivotReport(rows, {
        rowField,
        columnField,
        metric,
        weighted: kind === "productivity",
        rowLabel: dimensions.find(([k]) => k === rowField)?.[1] || "Grupo",
        columnValues:
          columnField === "report_month" ? monthsBetween(start, end) : [],
      }),
    [rows, rowField, columnField, metric, kind, start, end],
  );
  useEffect(() => setPivotPage(0), [rowField, columnField, metric, data]);
  const changeKind = (key, nextIndicator = defaultIndicator[key]) => {
    setKind(key);
    setIndicator(nextIndicator);
    setParams({ kind: key, mode: display, indicator: nextIndicator });
    setState("");
    setMethod("");
    setSort(null);
    setRowField("employee");
    setColumnField(
      key === "productivity"
        ? "report_month"
        : key === "closures"
          ? "type"
          : "status",
    );
    setMetric("rows");
    setPivotPage(0);
  };
  const changeDisplay = (value) => {
    setDisplay(value);
    setParams({ kind, mode: value, indicator });
  };
  const changeIndicator = (key) => {
    const selected = managementIndicators[key];
    if (!selected) return;
    setDisplay("charts");
    changeKind(selected.kind, key);
  };
  const exportColumns = view === "pivot" ? pivot.columns : config.columns;
  const exportRows =
    view === "pivot"
      ? pivot.rows.length
        ? [...pivot.rows, pivot.total]
        : []
      : rows;
  const download = (format) => {
    if (!data || busy || search.trim() !== term || !exportRows.length) return;
    const name = `ASE-Work-${kind}-${view === "pivot" ? "dinamica-" : ""}${start}-${end}`;
    saveReport(
      format === "xlsx"
        ? excelTable(exportColumns, exportRows)
        : new Blob([csvTable(exportColumns, exportRows)], {
            type: "text/csv;charset=utf-8",
          }),
      name + "." + format,
    );
  };
  return (
    <Layout>
      <div className="max-w-7xl mx-auto space-y-6">
        <div className="flex flex-wrap justify-between gap-3">
          <div>
            <h1 className="text-3xl font-bold">Informes y análisis</h1>
            <p className="text-gray-500 mt-2">
              Consulta datos, indicadores y gráficas de tu empresa.
            </p>
          </div>
          <div className="flex flex-wrap gap-2">
            <Button
              variant="outline"
              disabled={busy || search.trim() !== term || !exportRows.length}
              onClick={() => download("xlsx")}
            >
              Descargar Excel
            </Button>
            <Button
              variant="outline"
              disabled={busy || search.trim() !== term || !exportRows.length}
              onClick={() => download("csv")}
            >
              Descargar CSV
            </Button>
          </div>
        </div>

        <div className={sectionTabsClass}>
          {Object.entries(definitions).map(([key, v]) => (
            <Fragment key={key}>
              <Button
                variant="outline"
                className={sectionTabClass(kind === key)}
                onClick={() => changeKind(key)}
              >
                {v.name}
              </Button>
            </Fragment>
          ))}
        </div>
        <div className={sectionTabsClass}>
          <Button
            variant="outline"
            className={sectionTabClass(display === "data")}
            onClick={() => changeDisplay("data")}
          >
            Datos
          </Button>
          <Button
            variant="outline"
            className={sectionTabClass(display === "charts")}
            onClick={() => changeDisplay("charts")}
          >
            Gráficas y resumen
          </Button>
        </div>
        {directoryError && (
          <p role="alert" className="text-red-700">
            {directoryError}
          </p>
        )}
        <Card>
          <CardContent className="pt-6 grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
            <div>
              <Label htmlFor="report-employee">
                Mostrar datos de · todos los informes
              </Label>
              <select
                id="report-employee"
                className="w-full border bg-white rounded-md p-2"
                value={scope}
                onChange={(e) => setScope(e.target.value)}
              >
                <option value="all">Todos los empleados</option>
                {areas.length > 0 && (
                  <optgroup label="Por área">
                    {areas.map((area) => (
                      <option key={area.id} value={`area:${area.id}`}>
                        {area.name}
                      </option>
                    ))}
                  </optgroup>
                )}
                <optgroup label="Por empleado">
                  {employees.map((person) => (
                    <option key={person.id} value={`employee:${person.id}`}>
                      {person.full_name}
                      {person.status !== "active" ? " · inactivo" : ""}
                    </option>
                  ))}
                </optgroup>
              </select>
            </div>
            <div>
              <Label htmlFor="report-search">Buscar en la tabla</Label>
              <Input
                id="report-search"
                value={search}
                maxLength={120}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Empleado, tarea, responsable…"
              />
            </div>
            <div>
              <Label htmlFor="report-start">Desde</Label>
              <Input
                id="report-start"
                type="date"
                value={start}
                onChange={(e) => setStart(e.target.value)}
              />
            </div>
            <div>
              <Label htmlFor="report-end">Hasta</Label>
              <Input
                id="report-end"
                value={end}
                type="date"
                onChange={(e) => setEnd(e.target.value)}
              />
            </div>
            {config.states && (
              <div>
                <Label htmlFor="report-state">Estado</Label>
                <select
                  id="report-state"
                  className="w-full border rounded-md bg-white p-2"
                  value={state}
                  onChange={(e) => setState(e.target.value)}
                >
                  <option value="">Todos</option>
                  {Object.entries(config.states).map(([k, v]) => (
                    <option key={k} value={k}>
                      {v}
                    </option>
                  ))}
                </select>
              </div>
            )}
            {kind === "checkins" && (
              <div>
                <Label htmlFor="report-method">Método</Label>
                <select
                  id="report-method"
                  className="w-full border rounded-md bg-white p-2"
                  value={method}
                  onChange={(e) => setMethod(e.target.value)}
                >
                  <option value="">Todos</option>
                  <option value="nfc">NFC</option>
                  <option value="manual">Manual</option>
                  <option value="qr">QR</option>
                </select>
              </div>
            )}
            <div className="flex items-end">
              <Button
                variant="outline"
                disabled={busy}
                onClick={() => setRefresh((v) => v + 1)}
              >
                Actualizar
              </Button>
            </div>
          </CardContent>
        </Card>
        {error && (
          <p role="alert" className="text-red-700">
            {error}
          </p>
        )}
        {busy && <p role="status">Cargando informe…</p>}
        {display === "charts" && (
          <Card>
            <CardContent className="pt-6 space-y-3">
              <div className="max-w-xl">
                <Label htmlFor="management-indicator">
                  Indicador de gestión
                </Label>
                <select
                  id="management-indicator"
                  className="w-full border bg-white rounded-md p-2"
                  value={indicator}
                  onChange={(event) => changeIndicator(event.target.value)}
                >
                  <optgroup label="Operación y equipo">
                    {Object.entries(managementIndicators).map(([key, item]) => (
                      <option key={key} value={key}>
                        {item.name}
                      </option>
                    ))}
                  </optgroup>
                  <optgroup label="Finanzas · pendiente del módulo económico">
                    <option disabled>Ventas</option>
                    <option disabled>Punto de equilibrio</option>
                    <option disabled>Margen y costes</option>
                  </optgroup>
                </select>
              </div>
              <p className="text-sm text-gray-600">
                Ventas, punto de equilibrio y márgenes se habilitarán cuando ASE
                Work disponga de ingresos y costes reales. No se muestran
                estimaciones inventadas.
              </p>
            </CardContent>
          </Card>
        )}
        {display === "data" && (
          <div className={sectionTabsClass}>
            <Button
              variant="outline"
              className={sectionTabClass(view === "pivot")}
              onClick={() => setView("pivot")}
            >
              Tabla dinámica
            </Button>
            <Button
              variant="outline"
              className={sectionTabClass(view === "detail")}
              onClick={() => setView("detail")}
            >
              Ver registros
            </Button>
          </div>
        )}
        {display === "data" && view === "pivot" && (
          <Card>
            <CardContent className="pt-6 space-y-4">
              <div>
                <h2 className="text-lg font-semibold">
                  Cruza los datos de tu informe
                </h2>
                <p className="text-sm text-gray-500">
                  Elige qué mostrar en filas y columnas y qué cálculo realizar.
                  Los filtros de arriba se aplican al resultado.
                </p>
              </div>
              <div className="grid sm:grid-cols-3 gap-4">
                <div>
                  <Label htmlFor="pivot-rows">Filas · agrupar por</Label>
                  <select
                    id="pivot-rows"
                    className="w-full border bg-white rounded-md p-2"
                    value={rowField}
                    onChange={(e) => setRowField(e.target.value)}
                  >
                    {dimensions.map(([k, v]) => (
                      <option key={k} value={k}>
                        {v}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <Label htmlFor="pivot-columns">Columnas · cruzar con</Label>
                  <select
                    id="pivot-columns"
                    className="w-full border bg-white rounded-md p-2"
                    value={columnField}
                    onChange={(e) => setColumnField(e.target.value)}
                  >
                    <option value="">Sin columnas</option>
                    {dimensions.map(([k, v]) => (
                      <option key={k} value={k}>
                        {v}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <Label htmlFor="pivot-metric">Valores · calcular</Label>
                  <select
                    id="pivot-metric"
                    className="w-full border bg-white rounded-md p-2"
                    value={metric}
                    onChange={(e) => setMetric(e.target.value)}
                  >
                    {measures.map(([k, v]) => (
                      <option key={k} value={k}>
                        {v}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
              <p className="text-xs text-gray-500">
                {metric === "average"
                  ? "Los totales muestran la media de todos los fichajes del grupo, no una suma de medias."
                  : metric === "rows"
                    ? "Cuenta las filas de la tabla filtrada. En Productividad cada registro ya agrupa un empleado, tarea y día."
                    : "Los totales se calculan sobre todos los datos filtrados."}{" "}
                La descarga contiene el resultado calculado de esta tabla. El
                empleado seleccionado se mantiene al cambiar de informe o vista.
              </p>
            </CardContent>
          </Card>
        )}
        {data && display === "charts" && (
          <ReportCharts
            kind={kind}
            indicator={indicator}
            scope={scope}
            rows={rows}
            start={start}
            end={end}
          />
        )}
        {data && display === "data" && view === "pivot" && (
          <Card>
            <CardContent className="pt-6 space-y-4">
              {pivot.error ? (
                <p role="alert" className="text-red-700">
                  {pivot.error}
                </p>
              ) : (
                <>
                  <p className="text-sm text-gray-500">
                    {data.total} registros de origen · {pivot.rows.length}{" "}
                    grupos
                  </p>
                  {!pivot.rows.length ? (
                    <p>No hay datos con estos filtros.</p>
                  ) : (
                    <div className="overflow-x-auto">
                      <table className="w-full text-sm text-left">
                        <thead>
                          <tr>
                            {pivot.columns.map(([key, title]) => (
                              <th key={key} className="p-3 whitespace-nowrap">
                                {title}
                              </th>
                            ))}
                          </tr>
                        </thead>
                        <tbody>
                          {pivot.rows
                            .slice(pivotPage * 50, pivotPage * 50 + 50)
                            .map((row) => (
                              <tr key={row.label} className="border-t">
                                {pivot.columns.map(([key]) => (
                                  <td
                                    key={key}
                                    className="p-3 whitespace-nowrap"
                                  >
                                    {typeof row[key] === "number"
                                      ? row[key].toLocaleString("es-ES", {
                                          maximumFractionDigits: 2,
                                        })
                                      : (row[key] ?? "—")}
                                  </td>
                                ))}
                              </tr>
                            ))}
                        </tbody>
                        <tfoot className="font-semibold border-t bg-gray-50">
                          <tr>
                            {pivot.columns.map(([key]) => (
                              <td key={key} className="p-3 whitespace-nowrap">
                                {typeof pivot.total[key] === "number"
                                  ? pivot.total[key].toLocaleString("es-ES", {
                                      maximumFractionDigits: 2,
                                    })
                                  : (pivot.total[key] ?? "—")}
                              </td>
                            ))}
                          </tr>
                        </tfoot>
                      </table>
                    </div>
                  )}
                  <div className="flex justify-between items-center gap-3">
                    <Button
                      variant="outline"
                      disabled={pivotPage === 0}
                      onClick={() => setPivotPage((v) => v - 1)}
                    >
                      Anterior
                    </Button>
                    <span>Página {pivotPage + 1}</span>
                    <Button
                      variant="outline"
                      disabled={(pivotPage + 1) * 50 >= pivot.rows.length}
                      onClick={() => setPivotPage((v) => v + 1)}
                    >
                      Siguiente
                    </Button>
                  </div>
                </>
              )}
            </CardContent>
          </Card>
        )}
        {data && display === "data" && view === "detail" && (
          <Card>
            <CardContent className="pt-6 space-y-4">
              <p className="text-sm text-gray-500">
                {data.total} filas · La descarga incluye todos los resultados
                filtrados, no solo esta página.
              </p>
              <div className="overflow-x-auto">
                <table className="w-full text-sm text-left">
                  <thead>
                    <tr>
                      {config.columns.map(([k, label]) => (
                        <th
                          key={k}
                          className="p-3 whitespace-nowrap"
                          aria-sort={
                            sort?.key === k
                              ? sort.direction === 1
                                ? "ascending"
                                : "descending"
                              : "none"
                          }
                        >
                          <button
                            onClick={() =>
                              setSort((v) => ({
                                key: k,
                                direction: v?.key === k ? -v.direction : 1,
                              }))
                            }
                          >
                            {label} ↕
                          </button>
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {rows.slice(page * 50, page * 50 + 50).map((row, i) => (
                      <tr key={i} className="border-t">
                        {config.columns.map(([k]) => (
                          <td key={k} className="p-3 max-w-sm break-words">
                            {row[k] ?? "—"}
                          </td>
                        ))}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              {!rows.length && <p>No hay datos con estos filtros.</p>}
              <div className="flex justify-between items-center gap-3">
                <Button
                  variant="outline"
                  disabled={page === 0}
                  onClick={() => setPage((v) => v - 1)}
                >
                  Anterior
                </Button>
                <span>Página {page + 1}</span>
                <Button
                  variant="outline"
                  disabled={(page + 1) * 50 >= rows.length}
                  onClick={() => setPage((v) => v + 1)}
                >
                  Siguiente
                </Button>
              </div>
              <p className="text-xs text-gray-500">
                {kind === "productivity"
                  ? "Duraciones de fichajes terminados agrupadas por empleado, tarea y día de inicio. No mide la calidad del trabajo."
                  : kind === "tasks"
                    ? "Una fila por asignación y fecha planificada; las tareas sin planificación se incluyen por su fecha de creación."
                    : "Fechas y horas de Madrid. El filtro utiliza la fecha de inicio o creación del registro."}{" "}
                Actualizado: {stamp(data.as_of)}.
              </p>
            </CardContent>
          </Card>
        )}
      </div>
    </Layout>
  );
}
