import {Button} from '@/components/ui/button'

const options=[['all','Todas'],['urgent','Urgentes'],['overdue','Vencidas'],['today','Para hoy'],['evidence','Evidencias pendientes']]

export const matchesQuickFilter=(item,value,today)=>{
 if(value==='urgent')return item.importance==='urgent'
 if(value==='overdue')return item.overdue===true
 if(value==='today')return item.work_date===today
 if(value==='evidence')return Number(item.evidence_required)>Number(item.evidence_provided)
 return true
}

export default function BoardQuickFilters({value,onChange,items,today}){
 return <section aria-label="Filtros rápidos del tablero" className="space-y-2"><p className="text-sm font-medium">Filtros rápidos</p><div className="flex gap-2 overflow-x-auto pb-1">{options.map(([key,label])=><Button key={key} type="button" size="sm" variant={value===key?'default':'outline'} className="shrink-0" onClick={()=>onChange(key)}>{label} · {items.filter(item=>matchesQuickFilter(item,key,today)).length}</Button>)}</div></section>
}
