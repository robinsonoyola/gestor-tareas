import {useEffect,useState} from 'react'
import {Button} from '@/components/ui/button'
import {Input} from '@/components/ui/input'
import {Label} from '@/components/ui/label'
import {randomId} from '@/lib/randomId'

const storageKey='ase-work-board-views-v1'
const read=()=>{try{const value=JSON.parse(localStorage.getItem(storageKey)||'[]');return Array.isArray(value)?value.filter(item=>item&&typeof item.id==='string'&&typeof item.name==='string').slice(0,12):[]}catch{return[]}}

export default function BoardSavedViews({value,onApply}){
 const [items,setItems]=useState(read),[selected,setSelected]=useState(''),[name,setName]=useState(''),[message,setMessage]=useState('')
 useEffect(()=>{try{localStorage.setItem(storageKey,JSON.stringify(items))}catch{}},[items])
 const save=()=>{const clean=name.trim().replace(/\s+/g,' ');if(clean.length<2||clean.length>40){setMessage('Escribe un nombre de 2 a 40 caracteres.');return}const existing=items.find(item=>item.name.toLocaleLowerCase('es')===clean.toLocaleLowerCase('es'));const entry={id:existing?.id||randomId(),name:clean,filters:value};setItems(current=>[entry,...current.filter(item=>item.id!==entry.id)].slice(0,12));setSelected(entry.id);setName('');setMessage('Vista guardada en este dispositivo.')}
 const apply=id=>{setSelected(id);const item=items.find(value=>value.id===id);if(item){onApply(item.filters);setMessage(`Vista aplicada: ${item.name}.`)}}
 const remove=()=>{if(!selected)return;const item=items.find(value=>value.id===selected);if(!item||!window.confirm(`¿Eliminar la vista “${item.name}”?`))return;setItems(current=>current.filter(value=>value.id!==selected));setSelected('');setMessage('Vista eliminada.')}
 return <section className="rounded-xl border p-4 space-y-3" aria-label="Vistas guardadas del tablero"><div><h2 className="font-semibold">Vistas guardadas</h2><p className="text-xs text-gray-500">Guarda los filtros actuales en este dispositivo. No modifica tareas ni estados.</p></div><div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)_auto_auto]"><div><Label htmlFor="board-saved-view">Abrir vista</Label><select id="board-saved-view" className="w-full rounded-md border bg-white p-2" value={selected} onChange={event=>apply(event.target.value)}><option value="">Selecciona una vista</option>{items.map(item=><option key={item.id} value={item.id}>{item.name}</option>)}</select></div><div><Label htmlFor="board-view-name">Nombre de la vista actual</Label><Input id="board-view-name" value={name} maxLength={40} onChange={event=>setName(event.target.value)} placeholder="Ej.: Bloqueadas esta semana"/></div><div className="flex items-end"><Button type="button" variant="outline" className="w-full" onClick={save}>Guardar vista</Button></div><div className="flex items-end"><Button type="button" variant="outline" className="w-full" disabled={!selected} onClick={remove}>Eliminar</Button></div></div>{message&&<p role="status" className="text-xs text-blue-700">{message}</p>}</section>
}
