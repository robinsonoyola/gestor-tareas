import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { useEffect, useState } from "react";
import { workDate, workRpc } from "@/lib/workflow";

const colors = [
  "#2563EB",
  "#16A34A",
  "#F59E0B",
  "#9333EA",
  "#E11D48",
  "#0891B2",
  "#EA580C",
  "#65A30D",
];
const number = (value) => Number(value) || 0;
const stateLabels = {
  pending: "Pendiente",
  active: "En curso",
  paused: "Pausada",
  blocked: "Bloqueada",
  review: "En revisión",
  completed: "Completada",
  cancelled: "Cancelada",
  unplanned: "Sin planificación",
  open: "Abierto",
  closed: "Cerrado",
  in_progress: "En atención",
  resolved: "Resuelta",
};
const percent = (value, total) =>
  total
    ? `${((value / total) * 100).toLocaleString("es-ES", { maximumFractionDigits: 1 })} %`
    : "0 %";

const minutes = (value) =>
  `${number(value).toLocaleString("es-ES", { maximumFractionDigits: 1 })} min`;

function EstimateComparison({ data }) {
  const summary = data?.summary || {},
    items = data?.items || [],
    max = Math.max(
      1,
      ...items.map((item) =>
        Math.max(number(item.estimated_total), number(item.actual_total)),
      ),
    );
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 min-[420px]:grid-cols-2 lg:grid-cols-5 gap-4">
        {[
          ["Trabajos comparados", number(summary.work_count)],
          ["Tiempo estimado", minutes(summary.estimated_total)],
          ["Tiempo real", minutes(summary.actual_total)],
          ["Desviación", minutes(summary.variance)],
          [
            "Dentro de estimación",
            percent(summary.within_estimate, summary.work_count),
          ],
        ].map(([label, value]) => (
          <Card key={label}>
            <CardContent className="pt-6">
              <p className="text-sm text-gray-600">{label}</p>
              <p className="mt-2 text-2xl font-semibold">{value}</p>
            </CardContent>
          </Card>
        ))}
      </div>
      <Card>
        <CardHeader>
          <CardTitle>Estimación y tiempo real por tarea y empleado</CardTitle>
        </CardHeader>
        <CardContent className="space-y-5">
          {items.map((item) => (
            <div key={`${item.user_id}-${item.task_id}`} className="space-y-2">
              <div className="flex flex-wrap justify-between gap-2 text-sm">
                <span className="font-medium">
                  {item.task} · {item.employee}
                </span>
                <span>
                  {item.work_count} trabajos · diferencia{" "}
                  {minutes(item.variance)}
                </span>
              </div>
              <div className="space-y-1">
                <div className="flex items-center gap-2 text-xs">
                  <span className="w-20">Estimado</span>
                  <div
                    className="h-3 rounded-full bg-blue-600"
                    style={{
                      width: `${Math.max(1, (number(item.estimated_total) / max) * 100)}%`,
                    }}
                  />
                  <strong>{minutes(item.estimated_total)}</strong>
                </div>
                <div className="flex items-center gap-2 text-xs">
                  <span className="w-20">Real</span>
                  <div
                    className={`h-3 rounded-full ${number(item.variance) > 0 ? "bg-amber-500" : "bg-green-600"}`}
                    style={{
                      width: `${Math.max(1, (number(item.actual_total) / max) * 100)}%`,
                    }}
                  />
                  <strong>{minutes(item.actual_total)}</strong>
                </div>
              </div>
            </div>
          ))}
          {!items.length && (
            <p>
              No hay fichajes cerrados con tiempo estimado para estos filtros.
            </p>
          )}
          <p className="text-xs text-gray-600">
            La diferencia compara duración registrada y estimación. No mide por
            sí sola la calidad, dificultad ni desempeño de una persona.
          </p>
        </CardContent>
      </Card>
    </div>
  );
}

export default function ReportCharts({
  kind,
  indicator,
  scope,
  rows,
  start,
  end,
}) {
  const [estimateData, setEstimateData] = useState(null),
    [estimateError, setEstimateError] = useState(""),
    [estimateBusy, setEstimateBusy] = useState(false);
  useEffect(() => {
    if (indicator !== "estimate") return;
    let live = true;
    setEstimateBusy(true);
    setEstimateError("");
    workRpc("work_report_estimate_variance", {
      p_start: start,
      p_end: end,
      p_employee: scope?.startsWith("employee:") ? scope.slice(9) : null,
      p_area: scope?.startsWith("area:") ? scope.slice(5) : null,
    })
      .then((value) => {
        if (live) setEstimateData(value);
      })
      .catch((error) => {
        if (live) setEstimateError(error.message);
      })
      .finally(() => {
        if (live) setEstimateBusy(false);
      });
    return () => {
      live = false;
    };
  }, [indicator, scope, start, end]);
  const today = workDate(),
    total = rows.length;
  const sum = (key) =>
    rows.reduce(
      (value, row) => value + number(row._sort?.[key] ?? row[key]),
      0,
    );
  const statusCounts = rows.reduce((result, row) => {
    const key =
      row._sort?._state || row._sort?.status || row.status || "Sin estado";
    result[key] = (result[key] || 0) + 1;
    return result;
  }, {});
  const completed = rows.filter(
    (row) =>
      ["completed", "Completada", "Resuelta", "closed", "Cerrado"].includes(
        row._sort?._state,
      ) || ["Completada", "Resuelta", "Cerrado"].includes(row.status),
  ).length;
  const overdue =
    kind === "tasks"
      ? rows.filter(
          (row) =>
            row.report_day &&
            row.report_day < today &&
            ["pending", "active", "paused", "blocked", "review"].includes(
              row._sort?._state,
            ),
        ).length
      : 0;
  const blocked =
    kind === "tasks"
      ? rows.filter((row) => row._sort?._state === "blocked").length
      : kind === "incidents"
        ? rows.filter((row) => String(row.blocked).toLowerCase() === "sí")
            .length
        : 0;
  const open =
    kind === "checkins"
      ? rows.filter((row) => row._sort?._state === "open").length
      : kind === "incidents"
        ? rows.filter((row) => row._sort?._state !== "resolved").length
        : kind === "tasks"
          ? rows.filter(
              (row) => !["completed", "cancelled"].includes(row._sort?._state),
            ).length
          : 0;
  const analyticalRows =
    indicator === "overdue"
      ? rows.filter(
          (row) =>
            row.report_day &&
            row.report_day < today &&
            ["pending", "active", "paused", "blocked", "review"].includes(
              row._sort?._state,
            ),
        )
      : indicator === "workload"
        ? rows.filter(
            (row) => !["completed", "cancelled"].includes(row._sort?._state),
          )
        : rows;
  const workCount = kind === "productivity" ? sum("count") : completed;
  const minutes = sum("minutes");
  const cards =
    kind === "tasks"
      ? [
          ["Registros", total],
          ["Trabajo abierto", open],
          ["Vencidas", overdue],
          ["Bloqueadas", blocked],
          ["Completadas", completed],
          ["Cumplimiento", percent(completed, total)],
        ]
      : kind === "incidents"
        ? [
            ["Incidencias", total],
            ["Abiertas", open],
            ["Bloquean trabajo", blocked],
            ["Resueltas", completed],
            ["Resolución", percent(completed, total)],
          ]
        : kind === "checkins"
          ? [
              ["Fichajes", total],
              ["Abiertos ahora", open],
              ["Cerrados", completed],
              [
                "Tiempo registrado",
                `${(minutes / 60).toLocaleString("es-ES", { maximumFractionDigits: 1 })} h`,
              ],
            ]
          : kind === "productivity"
            ? [
                ["Grupos analizados", total],
                ["Trabajos terminados", workCount],
                [
                  "Tiempo total",
                  `${(minutes / 60).toLocaleString("es-ES", { maximumFractionDigits: 1 })} h`,
                ],
                [
                  "Media por trabajo",
                  workCount
                    ? `${(minutes / workCount).toLocaleString("es-ES", { maximumFractionDigits: 1 })} min`
                    : "—",
                ],
              ]
            : [
                ["Registros", total],
                [
                  "Cierres",
                  rows.filter((row) =>
                    String(row.type).toLowerCase().includes("cierre"),
                  ).length,
                ],
                [
                  "Bloqueos",
                  rows.filter((row) =>
                    String(row.type).toLowerCase().includes("bloque"),
                  ).length,
                ],
              ];
  const visibleCards =
    indicator === "overdue"
      ? cards.filter(([label]) =>
          ["Registros", "Trabajo abierto", "Vencidas"].includes(label),
        )
      : indicator === "workload"
        ? cards.filter(([label]) =>
            ["Registros", "Trabajo abierto", "Bloqueadas"].includes(label),
          )
        : cards;
  const groupKey =
    kind === "incidents"
      ? "responsible"
      : kind === "closures"
        ? "type"
        : "employee";
  const groups = Object.entries(
    analyticalRows.reduce((result, row) => {
      const key = row[groupKey] || "Sin asignar";
      result[key] =
        (result[key] || 0) +
        (kind === "productivity" ? number(row._sort?.count ?? row.count) : 1);
      return result;
    }, {}),
  )
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10);
  const maxGroup = Math.max(1, ...groups.map(([, value]) => value));
  const days = Object.entries(
    analyticalRows.reduce((result, row) => {
      const day = row.report_day;
      if (day)
        result[day] =
          (result[day] || 0) +
          (kind === "productivity" ? number(row._sort?.count ?? row.count) : 1);
      return result;
    }, {}),
  ).sort(([a], [b]) => a.localeCompare(b));
  const maxDay = Math.max(1, ...days.map(([, value]) => value)),
    width = Math.max(700, days.length * 38);
  if (indicator === "estimate") {
    if (estimateBusy) return <p role="status">Calculando comparación…</p>;
    if (estimateError)
      return (
        <p role="alert" className="text-red-700">
          {estimateError}
        </p>
      );
    return <EstimateComparison data={estimateData} />;
  }
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 min-[420px]:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4">
        {visibleCards.map(([label, value]) => (
          <Card key={label}>
            <CardContent className="pt-6">
              <p className="text-sm text-gray-600">{label}</p>
              <p className="mt-2 text-2xl font-semibold">{value}</p>
            </CardContent>
          </Card>
        ))}
      </div>
      <div className="grid lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>
              {indicator === "overdue"
                ? "Tareas atrasadas por empleado"
                : indicator === "workload"
                  ? "Carga activa por empleado"
                  : kind === "incidents"
                    ? "Incidencias por responsable"
                    : kind === "closures"
                      ? "Registros por tipo"
                      : "Carga por empleado"}
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {groups.map(([label, value], index) => (
              <div key={label}>
                <div className="mb-1 flex justify-between gap-3 text-sm">
                  <span className="break-words">{label}</span>
                  <strong>{value.toLocaleString("es-ES")}</strong>
                </div>
                <div className="h-4 overflow-hidden rounded-full bg-gray-100">
                  <div
                    className="h-full rounded-full"
                    style={{
                      width: `${(value / maxGroup) * 100}%`,
                      background: colors[index % colors.length],
                    }}
                  />
                </div>
              </div>
            ))}
            {!groups.length && <p>No hay datos con estos filtros.</p>}
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle>Distribución por estado</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {Object.entries(statusCounts)
              .sort((a, b) => b[1] - a[1])
              .map(([label, value], index) => (
                <div
                  key={label}
                  className="flex items-center justify-between gap-3 rounded-lg border p-3"
                >
                  <span>
                    <span
                      className="mr-2 inline-block h-3 w-3 rounded-full"
                      style={{ background: colors[index % colors.length] }}
                    />
                    {stateLabels[label] || label}
                  </span>
                  <strong>
                    {value} · {percent(value, total)}
                  </strong>
                </div>
              ))}
            {!total && <p>No hay datos con estos filtros.</p>}
          </CardContent>
        </Card>
      </div>
      <Card>
        <CardHeader>
          <CardTitle>Evolución del período</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="overflow-x-auto">
            <svg
              viewBox={`0 0 ${width} 230`}
              style={{ width, height: 230 }}
              role="img"
              aria-label={`Evolución de registros entre ${start} y ${end}`}
            >
              <line
                x1="50"
                y1="180"
                x2={width - 30}
                y2="180"
                stroke="#CBD5E1"
              />
              <polyline
                fill="none"
                stroke="#2563EB"
                strokeWidth="3"
                points={days
                  .map(
                    ([day, value], index) =>
                      `${60 + index * ((width - 100) / Math.max(1, days.length - 1))},${180 - (value / maxDay) * 140}`,
                  )
                  .join(" ")}
              />
              {days.map(([day, value], index) => {
                const x =
                    60 + index * ((width - 100) / Math.max(1, days.length - 1)),
                  y = 180 - (value / maxDay) * 140;
                return (
                  <g key={day}>
                    <circle
                      cx={x}
                      cy={y}
                      r="5"
                      fill="#2563EB"
                      stroke="white"
                      strokeWidth="2"
                    >
                      <title>
                        {day}: {value}
                      </title>
                    </circle>
                    <text
                      x={x}
                      y="210"
                      textAnchor="middle"
                      fontSize="9"
                      fill="#667085"
                    >
                      {day.slice(8)}/{day.slice(5, 7)}
                    </text>
                  </g>
                );
              })}
            </svg>
          </div>
          <p className="text-xs text-gray-600">
            Los valores corresponden a los mismos datos y filtros de la tabla.
            El indicador muestra gestión operativa, no una valoración automática
            de las personas.
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
