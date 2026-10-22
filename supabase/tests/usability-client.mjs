import fs from 'node:fs';
import assert from 'node:assert/strict';
const root=new URL('../../',import.meta.url).pathname.replace(/^\/(\w:)/,'$1');
async function moduleAt(path){return import('data:text/javascript;base64,'+Buffer.from(fs.readFileSync(root+'src/lib/'+path,'utf8')).toString('base64'))}
const {parseWorkSearch:search}=await moduleAt('workSearch.js');
assert.deepEqual(search('tarea iniciada'),{p_terms:[],p_state:'active',p_kind:'tasks'});
assert.deepEqual(search('INCIDENCIAS pendientes'),{p_terms:[],p_state:'pending',p_kind:'incidents'});
assert.deepEqual(search('piscina Juan'),{p_terms:['piscina','juan'],p_state:null,p_kind:null});
assert.deepEqual(search('Tareas en curso de María'),{p_terms:['maria'],p_state:'active',p_kind:'tasks'});
assert.equal(search('incidencias resueltas').p_state,'completed');
assert.equal(search('empleado Pedro').p_kind,'people');
const {parsePinCsv,readPinImport}=await moduleAt('pinImport.js');
assert.deepEqual(parsePinCsv('\uFEFFempleado;pin\r\nworker@example.test;00123\r\n'),[{employee:'worker@example.test',pin:'00123'}]);
assert.deepEqual(parsePinCsv('email,pin\n"worker@example.test","01234"'),[{employee:'worker@example.test',pin:'01234'}]);
assert.throws(()=>parsePinCsv('nombre,codigo\n"Worker",12345'),/columnas/);
assert.throws(()=>parsePinCsv('email,pin\n"sin terminar'),/comillas/);
await assert.rejects(readPinImport({size:6*1024*1024,name:'data.xlsx'}),/5 MB/);
await assert.rejects(readPinImport({size:1,name:'data.xls'}),/XLS/);
console.log('PASS: phrase search, accents, state filters, CSV quoting and leading zero PINs, file size/type limits.');
