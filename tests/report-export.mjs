import assert from "node:assert/strict";
import { csvTable, excelTable } from "../src/lib/reportExport.js";
import { pivotReport } from "../src/lib/reportPivot.js";

const columns = [
  ["employee", "Empleado"],
  ["task", "Tarea"],
  ["minutes", "Minutos"],
  ["note", "Observación"],
];
const rows = [
  {
    employee: "Ángela Muñoz",
    task: "=HYPERLINK(\"https://example.invalid\")",
    minutes: 12.5,
    note: 'Texto con "comillas"; punto y coma\ny salto',
  },
  { employee: "José", task: "+SUM(A1:A2)", minutes: 7, note: "Limpieza" },
];

const csv = csvTable(columns, rows);
assert.equal(csv.charCodeAt(0), 0xfeff, "CSV must include UTF-8 BOM");
assert.match(csv, /Ángela Muñoz/u, "CSV must preserve accented text");
assert.match(csv, /"'=HYPERLINK/u, "CSV must neutralize spreadsheet formulas");
assert.match(csv, /"'\+SUM/u, "CSV must neutralize plus-prefixed formulas");
assert.match(csv, /"Texto con ""comillas""; punto y coma\ny salto"/u);
assert.equal(csv.split("\r\n").length, 3, "Embedded newlines must remain inside the cell");

const workbook = excelTable(columns, rows);
assert.equal(
  workbook.type,
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
);
const bytes = new Uint8Array(await workbook.arrayBuffer());
assert.equal(String.fromCharCode(bytes[0], bytes[1]), "PK", "XLSX must be a ZIP file");
const rawWorkbook = new TextDecoder().decode(bytes);
assert.match(rawWorkbook, /Ángela Muñoz/u, "XLSX must preserve accented text");
assert.match(rawWorkbook, /<v>12.5<\/v>/u, "Numbers must be numeric cells");
assert.doesNotMatch(rawWorkbook, /<f>/u, "User values must never become formulas");
assert.match(rawWorkbook, /&quot;comillas&quot;/u, "XML-sensitive text must be escaped");

const pivot = pivotReport(
  [
    { employee: "Ana", status: "Completada", count: 2, minutes: 30 },
    { employee: "Ana", status: "Completada", count: 1, minutes: 30 },
    { employee: "Juan", status: "Pendiente", count: 4, minutes: 80 },
  ],
  {
    rowField: "employee",
    columnField: "status",
    metric: "average",
    weighted: true,
    rowLabel: "Empleado",
  },
);
assert.equal(pivot.error, "");
assert.equal(pivot.rows.find((row) => row.label === "Ana").total, 20);
assert.equal(pivot.total.total, 20);

console.log("PASS report export: CSV, XLSX and weighted pivot validated");
