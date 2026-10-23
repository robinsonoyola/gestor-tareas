const label=value=>value===null||value===undefined||value===''?'Sin datos':String(value)
const bucket=()=>({rows:0,minutes:0,weight:0,validWeight:0})
function add(target,row,weighted){target.rows++;const weight=weighted?Math.max(0,Number(row.count)||0):1;target.weight+=weight;const minutes=row.minutes===null||row.minutes===undefined?NaN:Number(row.minutes);if(Number.isFinite(minutes)){target.minutes+=minutes;target.validWeight+=weight}}
const value=(b,metric)=>!b?(metric==='average'?null:0):metric==='minutes'?Math.round(b.minutes*100)/100:metric==='average'?(b.validWeight?Math.round(b.minutes/b.validWeight*100)/100:null):metric==='count'?b.weight:b.rows
export function pivotReport(rows,{rowField,columnField,metric='rows',weighted=false,rowLabel='Grupo',maxColumns=100,columnValues=[]}){
 const names=[...new Set([...columnValues.map(label),...rows.map(r=>columnField?label(r[columnField]):'Resultado')])].sort((a,b)=>a.localeCompare(b,'es',{numeric:true}))
 if(names.length>maxColumns)return {error:'Hay demasiadas columnas. Reduce las fechas o elige otra agrupación.',columns:[],rows:[],total:null}
 const groups=new Map(),totals=new Map(),all=bucket()
 for(const row of rows){const name=label(row[rowField]),column=columnField?label(row[columnField]):'Resultado';if(!groups.has(name))groups.set(name,{cells:new Map(),total:bucket()});const group=groups.get(name);if(!group.cells.has(column))group.cells.set(column,bucket());if(!totals.has(column))totals.set(column,bucket());add(group.cells.get(column),row,weighted);add(group.total,row,weighted);add(totals.get(column),row,weighted);add(all,row,weighted)}
 const columns=columnField?[['label',rowLabel],...names.map((name,i)=>['col_'+i,name]),['total','Total general']]:[['label',rowLabel],['total','Resultado']]
 const result=[...groups].sort(([a],[b])=>a.localeCompare(b,'es',{numeric:true})).map(([name,group])=>({label:name,...Object.fromEntries(names.map((n,i)=>['col_'+i,value(group.cells.get(n),metric)])),total:value(group.total,metric)}))
 const total={label:'Total general',...Object.fromEntries(names.map((n,i)=>['col_'+i,value(totals.get(n),metric)])),total:value(all,metric)}
 return {columns,rows:result,total,error:''}
}
