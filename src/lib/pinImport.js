export function pinRowsFromTable(table) {
  if (!table.length) throw new Error('El archivo está vacío.')
  const head=table[0].map(v=>String(v??'').trim().toLowerCase())
  const employee=head.findIndex(v=>['empleado','employee','correo','email','user_id'].includes(v)),pin=head.indexOf('pin')
  if(employee<0||pin<0)throw new Error('La primera fila debe tener las columnas empleado y pin. Usa el correo o ID del empleado.')
  const rows=table.slice(1).filter(row=>row.some(v=>String(v??'').trim())).map(row=>({employee:String(row[employee]??'').trim(),pin:String(row[pin]??'').trim()}))
  if(!rows.length||rows.length>200)throw new Error('Importa entre 1 y 200 empleados.')
  return rows
}
export function parsePinCsv(text) {
  text=text.replace(/^\uFEFF/,'')
  const sep=text.split(/\r?\n/,1)[0].includes(';')?';':','
  const rows=[],row=[];let value='',quoted=false
  for(let i=0;i<text.length;i++){
    const c=text[i]
    if(c==='"'){if(quoted&&text[i+1]==='"'){value+='"';i++}else quoted=!quoted}
    else if(!quoted&&(c===sep||c==='\n'||c==='\r')){row.push(value);value='';if(c!==sep){rows.push([...row]);row.length=0;if(c==='\r'&&text[i+1]==='\n')i++}}
    else value+=c
  }
  if(quoted)throw new Error('CSV con comillas sin cerrar.')
  if(value||row.length){row.push(value);rows.push(row)}
  return pinRowsFromTable(rows)
}
async function xlsxTable(buffer) {
  const bytes=new Uint8Array(buffer),view=new DataView(buffer),entries=new Map()
  let end=-1
  for(let p=bytes.length-22;p>=Math.max(0,bytes.length-65557);p--)if(view.getUint32(p,true)===0x06054b50){end=p;break}
  if(end<0)throw new Error('El archivo no es un XLSX válido.')
  const count=view.getUint16(end+10,true);let pos=view.getUint32(end+16,true),total=0
  if(count>2000||count===65535)throw new Error('Archivo XLSX demasiado complejo.')
  for(let i=0;i<count;i++){
    if(pos+46>bytes.length||view.getUint32(pos,true)!==0x02014b50)throw new Error('Directorio XLSX inválido.')
    const flags=view.getUint16(pos+8,true),method=view.getUint16(pos+10,true),size=view.getUint32(pos+20,true),expanded=view.getUint32(pos+24,true),n=view.getUint16(pos+28,true),extra=view.getUint16(pos+30,true),comment=view.getUint16(pos+32,true),local=view.getUint32(pos+42,true)
    total+=expanded
    if(total>20*1024*1024||size===0xffffffff||local+30>bytes.length||flags&1)throw new Error('Archivo XLSX cifrado o demasiado grande.')
    const name=new TextDecoder().decode(bytes.subarray(pos+46,pos+46+n))
    if(entries.has(name))throw new Error('Entradas XLSX duplicadas.')
    entries.set(name,{method,size,expanded,local});pos+=46+n+extra+comment
  }
  async function xml(name,optional=false){
    const e=entries.get(name);if(!e){if(optional)return null;throw new Error('Faltan datos del libro XLSX.')}
    const p=e.local
    if(view.getUint32(p,true)!==0x04034b50)throw new Error('Entrada XLSX inválida.')
    const start=p+30+view.getUint16(p+26,true)+view.getUint16(p+28,true)
    if(start+e.size>bytes.length)throw new Error('Contenido XLSX incompleto.')
    let data=bytes.slice(start,start+e.size)
    if(e.method===8){
      if(typeof DecompressionStream==='undefined')throw new Error('Este navegador no puede abrir XLSX. Usa Chrome actualizado o exporta el Excel a CSV.')
      let stream
      try{stream=new Blob([data]).stream().pipeThrough(new DecompressionStream('deflate-raw'))}catch{throw new Error('Exporta el Excel a CSV o usa Chrome actualizado para importar XLSX.')}
      const reader=stream.getReader(),chunks=[];let length=0
      try{for(;;){const {done,value}=await reader.read();if(done)break;length+=value.length;if(length>20*1024*1024||length>e.expanded)throw new Error('Contenido XLSX demasiado grande.');chunks.push(value)}}finally{await reader.cancel()}
      data=new Uint8Array(length);let at=0;for(const chunk of chunks){data.set(chunk,at);at+=chunk.length}
    }else if(e.method!==0)throw new Error('Compresión XLSX no compatible.')
    if(data.length!==e.expanded)throw new Error('Tamaño XLSX incorrecto.')
    const text=new TextDecoder().decode(data)
    if(/<!DOCTYPE|<!ENTITY/i.test(text))throw new Error('XML no admitido.')
    const doc=new DOMParser().parseFromString(text,'application/xml')
    if(doc.getElementsByTagName('parsererror').length)throw new Error('XML del libro inválido.')
    return doc
  }
  const workbook=await xml('xl/workbook.xml'),rels=await xml('xl/_rels/workbook.xml.rels'),sheet=workbook.getElementsByTagName('sheet')[0]
  const rid=sheet?.getAttribute('r:id'),relation=[...rels.getElementsByTagName('Relationship')].find(r=>r.getAttribute('Id')===rid)
  const target=relation?.getAttribute('Target')
  if(!target||relation.getAttribute('TargetMode')==='External'||target.includes('..')||target.includes('://'))throw new Error('Hoja XLSX no compatible.')
  const path=target.startsWith('/')?target.slice(1):'xl/'+target
  const shared=await xml('xl/sharedStrings.xml',true),strings=shared?[...shared.getElementsByTagName('si')].map(si=>[...si.getElementsByTagName('t')].map(t=>t.textContent).join('')):[]
  const doc=await xml(path),table=[]
  for(const row of [...doc.getElementsByTagName('row')]){
    if(table.length>201)throw new Error('Importa hasta 200 empleados.')
    const cells=[]
    for(const cell of [...row.getElementsByTagName('c')]){
      if(cell.getElementsByTagName('f').length)throw new Error('El archivo debe contener valores, sin fórmulas.')
      const ref=cell.getAttribute('r')?.match(/^([A-Z]+)\d+$/)?.[1];if(!ref)throw new Error('Celda inválida.')
      let col=0;for(const c of ref)col=col*26+c.charCodeAt(0)-64
      if(col>50)throw new Error('Usa una hoja sencilla con las columnas empleado y pin.')
      const type=cell.getAttribute('t'),v=cell.getElementsByTagName('v')[0]?.textContent??''
      cells[col-1]=type==='s'?(strings[Number(v)]??''):type==='inlineStr'?[...cell.getElementsByTagName('t')].map(t=>t.textContent).join(''):v
    }
    table.push(Array.from({length:cells.length},(_,i)=>cells[i]??''))
  }
  return table
}
export async function readPinImport(file) {
  if(!file||file.size>5*1024*1024)throw new Error('El archivo no debe superar 5 MB.')
  if(/\.csv$/i.test(file.name))return parsePinCsv(await file.text())
  if(/\.xlsx$/i.test(file.name))return pinRowsFromTable(await xlsxTable(await file.arrayBuffer()))
  throw new Error('Usa Excel XLSX o CSV. El formato XLS antiguo no está admitido.')
}
