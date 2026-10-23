import PersonalPinManager from '@/components/PersonalPinManager'
import { useEffect, useRef, useState } from 'react'
import PlanningCalendar from './PlanningCalendar'
import { useSearchParams } from 'react-router-dom'
import { Link } from 'react-router-dom'
import { toast } from 'sonner'
import Layout from '@/components/layout/Layout'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog'
import { ArrowUp, ArrowDown, Trash2, Plus, CreditCard, Monitor, Copy } from 'lucide-react'
import { useAuth } from '@/hooks/useAuth'
import { workDate, workRpc } from '@/lib/workflow'

export default function WorkdayManager({section='planning'}) {
  const [query]=useSearchParams()
  const { isAdmin, can } = useAuth()
  const canEdit = can('planning.edit')
  const [employees, setEmployees] = useState([])
  const [user, setUser] = useState(query.get('employee')||'')
  const [date, setDate] = useState(()=>/^\d{4}-\d{2}-\d{2}$/.test(query.get('date')||'')?query.get('date'):workDate())
  const [periodMode, setPeriodMode] = useState('day')
  const [rangeStart, setRangeStart] = useState(workDate)
  const [rangeEnd, setRangeEnd] = useState(workDate)
  const [weekdays, setWeekdays] = useState([1,2,3,4,5,6,7])
  const [existingMode, setExistingMode] = useState('empty')
  const [rangeConfirm, setRangeConfirm] = useState(false)
  const [rangeResult, setRangeResult] = useState('')
  const [available, setAvailable] = useState([])
  const [selected, setSelected] = useState('')
  const [plan, setPlan] = useState([])
  const [overview, setOverview] = useState(null)
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const [loading, setLoading] = useState(true)
  const [secret, setSecret] = useState(null)
  const [credentialKey, setCredentialKey] = useState(null)
  const [existingKey, setExistingKey] = useState('')
  const [rotateApproved, setRotateApproved] = useState(false)
  const [pendingDelete, setPendingDelete] = useState(null)
  const [stationName, setStationName] = useState('Tablet principal')
  const [stationKey, setStationKey] = useState('')
  const dayDetail = useRef(null)
  const reviewRequested = useRef(section==='planning' && Boolean(query.get('date')))
  const focusDay = () => { const node=dayDetail.current; if(!node)return; const header=node.closest('main')?.querySelector('header'); node.style.scrollMarginTop=((header?.getBoundingClientRect().height||0)+16)+'px'; node.scrollIntoView({behavior:window.matchMedia?.('(prefers-reduced-motion: reduce)').matches?'auto':'smooth',block:'start'}); node.focus({preventScroll:true}) }
  const reviewDay = value => { reviewRequested.current=true; updatePeriod('day',value); if (value===date && !loading) { reviewRequested.current=false; requestAnimationFrame(focusDay) } }
  useEffect(()=>{if(reviewRequested.current && overview && !loading){reviewRequested.current=false;requestAnimationFrame(focusDay)}},[overview,loading])
  const serial = useRef(0)
  useEffect(() => {
    workRpc('work_employee_directory').then(data => {
      setEmployees(data); setUser(current=>data.some(e=>e.id===current)?current:data[0]?.id || '')
      if (!data.length) setLoading(false)
    }).catch(e=>{setError(e.message);setLoading(false)})
  }, [])
  const load = async () => {
    const request = ++serial.current
    if ((!user && !['points','rules'].includes(section)) || !date) {setLoading(false);return}
    setLoading(true); setError(''); setOverview(null); setPlan([]); setAvailable([])
    try {
      const data = await workRpc('work_admin_overview', {p_user: user || null, p_date: date})
      const assignments = section==='planning' ? await workRpc('work_planning_assignments',{p_user:user}) : []
      if (request !== serial.current) return
      setOverview(data); setPlan(data.plan || []); setAvailable(assignments || []); setSelected('')
    } catch (e) { if (request === serial.current) setError(e.message + '. Si faltan las funciones work_, instala primero el SQL del modo tablet.') }
    finally { if (request === serial.current) setLoading(false) }
  }
  useEffect(() => { load(); return () => { serial.current++ } }, [user,date,section])
  const action = async (fn) => {
    if (busy) return
    setBusy(true); setError('')
    try { await fn() } catch(e) { setError(e.message); toast.error(e.message) } finally { setBusy(false) }
  }
  const move = (index, step) => {
    const next = index + step
    if (next < 0 || next >= plan.length || plan[index].state !== 'pending' || plan[next].state !== 'pending') return
    const items = [...plan]; [items[index], items[next]] = [items[next], items[index]]; setPlan(items)
  }
  const save = () => action(async () => {
    await workRpc('work_save_plan', {p_user:user,p_date:date,p_tasks:plan.map(t => t.task_id)})
    toast.success('Planificación guardada'); await load()
  })
  const updatePeriod = (mode, value) => {
    setPeriodMode(mode); setRangeResult('')
    const base = value || rangeStart || workDate()
    if (mode === 'day') { setDate(base); setRangeStart(base); setRangeEnd(base); return }
    if (mode === 'range') { setDate(base); setRangeStart(base); if (rangeEnd < base) setRangeEnd(base); return }
    const year = base.slice(0,4), month = base.slice(5,7) || '01'
    const start = mode === 'year' ? `${year}-01-01` : `${year}-${month}-01`
    const end = mode === 'year' ? `${year}-12-31` : `${year}-${month}-${new Date(Number(year),Number(month),0).getDate()}`
    setDate(start); setRangeStart(start); setRangeEnd(end)
  }
  const rangeDays = (() => {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(rangeStart) || !/^\d{4}-\d{2}-\d{2}$/.test(rangeEnd)) return 0
    const start = new Date(rangeStart+'T12:00:00Z'), end = new Date(rangeEnd+'T12:00:00Z')
    const span = Math.round((end-start)/86400000)
    if (!Number.isFinite(span) || span<0 || span>365) return 0
    let count=0
    for(let i=0;i<=span;i++) {const d=new Date(start.getTime()+i*86400000); if(weekdays.includes(d.getUTCDay() || 7)) count++}
    return count
  })()
  const saveRange = () => action(async () => {
    const result = await workRpc('work_save_plan_range', {p_user:user,p_start:rangeStart,p_end:rangeEnd,p_tasks:plan.map(t=>t.task_id),p_weekdays:weekdays,p_existing:existingMode})
    setRangeConfirm(false)
    setRangeResult(`${result.changed} días actualizados. ${result.skipped} días conservados sin cambios.`)
    toast.success('Planificación del período guardada'); await load()
  })
  const credential = (kind) => action(async () => {
    if (kind === 'card' && overview.cards.some(c => c.user_id === user && c.active)) throw new Error('Este empleado ya tiene una tarjeta activa. Desactívala primero.')
    const name = kind === 'card' ? employees.find(e => e.id === user)?.full_name : stationName
    if (!name?.trim()) throw new Error('Introduce un nombre')
    const customKey = kind === 'station' ? stationKey.trim() : ''
    if (customKey && (customKey.length < 8 || customKey.length > 128 || /[\x00-\x1F\x7F]/.test(customKey))) throw new Error('La clave del punto debe tener entre 8 y 128 caracteres, sin saltos de línea')
    const result = customKey
      ? await workRpc('work_create_station', {p_name:name,p_token:customKey})
      : await workRpc('work_create_credential', {p_kind:kind,p_name:name,p_user:kind === 'card' ? user : null})
    if (kind === 'station') setStationKey('')
    setSecret({...result,name}); await load()
  })
  const revoke = (kind,id) => {
    if (!window.confirm('¿Desactivar esta credencial? Dejará de permitir identificarse.')) return
    action(async () => { await workRpc('work_revoke_credential', {p_kind:kind,p_id:id}); await load() })
  }
  const setCardActive = (card) => {
    if (card.active) { revoke('card', card.id); return }
    action(async () => {
      await workRpc('work_set_card_active', {p_id: card.id, p_active: true})
      toast.success('Tarjeta activada'); await load()
    })
  }
  const setStationActive = (station) => {
    if (station.active) { revoke('station', station.id); return }
    action(async () => {
      await workRpc('work_set_station_active', {p_id: station.id, p_active: true})
      toast.success('Punto de fichaje activado'); await load()
    })
  }
  const deleteCredential = () => action(async () => {
    if (!pendingDelete) return
    await workRpc('work_delete_credential', {p_kind: pendingDelete.kind, p_id: pendingDelete.id})
    if (secret?.id === pendingDelete.id) setSecret(null)
    setPendingDelete(null)
    toast.success('Se ha eliminado de la lista. El historial se conserva.')
    await load()
  })
  const copyKey = async (value, fieldId, message = 'Clave copiada') => {
    if (!value) return
    if (window.isSecureContext && navigator.clipboard?.writeText) {
      try {
        await navigator.clipboard.writeText(value)
        toast.success(message)
        return
      } catch { /* Use the selected field when clipboard permissions are unavailable. */ }
    }
    const field = document.getElementById(fieldId)
    if (!field) return
    field.focus()
    field.select()
    field.setSelectionRange(0, value.length)
    try {
      if (document.execCommand('copy')) { toast.success(message); return }
    } catch { /* Keep the key selected so the user can copy it manually. */ }
    toast.info('Mantén pulsado el valor seleccionado y elige Copiar.')
  }
  const showStationKey = (station) => action(async () => {
    const result = await workRpc('work_get_station_key', {p_id: station.id})
    setExistingKey(''); setRotateApproved(false)
    setCredentialKey({id: station.id, name: station.name, kind: 'station', ...result})
  })
  const showCardCode = (card) => action(async () => {
    const result = await workRpc('work_get_card_key', {p_id: card.id})
    setExistingKey(''); setRotateApproved(false)
    setCredentialKey({id: card.id, name: card.label, kind: 'card', ...result})
  })
  const saveOrRotateKey = (rotate) => action(async () => {
    if (!credentialKey?.id) return
    const result = await workRpc(rotate ? (credentialKey.kind === 'card' ? 'work_rotate_card_key' : 'work_rotate_station_key') : (credentialKey.kind === 'card' ? 'work_save_card_key' : 'work_save_station_key'),
      rotate ? {p_id: credentialKey.id} : {p_id: credentialKey.id, p_token: existingKey})
    setCredentialKey({...credentialKey,...result}); setExistingKey(''); setRotateApproved(false)
    toast.success(rotate ? (credentialKey.kind === 'card' ? 'Código renovado. Usa este código para identificar al empleado.' : 'Clave renovada. Actualízala en la tablet.') : 'Código guardado')
  })
  useEffect(() => {
    if (!credentialKey?.token) return
    const timer = setTimeout(() => { setCredentialKey(null); setExistingKey('') }, 60000)
    return () => clearTimeout(timer)
  }, [credentialKey?.id, credentialKey?.token])
  const setMode = () => {
    const enabled = !overview.enabled
    if (!window.confirm(enabled ? 'Se activará el fichaje exclusivo en tablet para todos los empleados. Solo podrán abrir su tarea en curso. ¿Continuar?' : 'Se volverá al flujo anterior para todos los empleados. ¿Continuar?')) return
    action(async () => { await workRpc('work_set_mode',{p_enabled:enabled}); await load(); toast.success('Modo actualizado') })
  }
  const activeFirst = (a, b) => Number(b.active) - Number(a.active)
    || (a.label || a.name || '').localeCompare(b.label || b.name || '', 'es')
    || a.id.localeCompare(b.id)
  const employeeCards = (overview?.cards || []).filter(c => c.user_id === user).sort(activeFirst)
  const stations = [...(overview?.stations || [])].sort(activeFirst)
  return <Layout>
    <Dialog open={rangeConfirm} onOpenChange={open=>{if(!busy)setRangeConfirm(open)}}>
      <DialogContent><DialogHeader><DialogTitle>Aplicar planificación a varios días</DialogTitle><DialogDescription>Se aplicarán las {plan.length} tareas de la lista, en su orden, a {rangeDays} días de {employees.find(e=>e.id===user)?.full_name}, del {rangeStart} al {rangeEnd}. {existingMode==='empty'?'Los días que ya tienen tareas se conservarán.':'Se añadirán solo las tareas que falten al final de cada día, conservando su orden e historial.'} Cada día podrá editarse después por separado.</DialogDescription></DialogHeader>
      <div className="flex gap-3 justify-end"><Button variant="outline" disabled={busy} onClick={()=>setRangeConfirm(false)}>Cancelar</Button><Button disabled={busy} onClick={saveRange}>{busy?'Guardando…':'Aplicar planificación'}</Button></div></DialogContent>
    </Dialog>
    <Dialog open={Boolean(credentialKey)} onOpenChange={(open)=>{if (!open && !busy) {setCredentialKey(null);setExistingKey('');setRotateApproved(false)}}}>
      <DialogContent><DialogHeader>
        <DialogTitle>{credentialKey?.kind==='card'?'Código de fichaje':'Clave del punto'}: {credentialKey?.name}</DialogTitle>
        <DialogDescription>Solo administración puede consultar este código. {credentialKey?.kind==='card'?'Es el código que acepta la tablet para identificar al empleado; no uses la referencia interna.':'Se utiliza para configurar el punto de fichaje.'} Se ocultará al cabo de un minuto.</DialogDescription>
      </DialogHeader>
      {credentialKey?.available ? <>
        <Label htmlFor="visible-station-key">{credentialKey.kind==='card'?'Código de fichaje del empleado':'Clave del punto'}</Label>
        <div className="flex gap-2"><Input id="visible-station-key" className="min-w-0 flex-1" value={credentialKey.token} readOnly onFocus={e=>e.target.select()} /><Button variant="outline" disabled={busy} onClick={()=>copyKey(credentialKey.token,'visible-station-key','Código copiado')}><Copy className="h-4 w-4" /> Copiar</Button></div>
        <Button variant="outline" disabled={busy} onClick={()=>setCredentialKey(null)}>Cerrar</Button>
      </> : <div className="space-y-4">
        <p className="text-sm text-gray-600">{credentialKey?.kind==='card'?'Esta tarjeta se creó antes de guardar códigos recuperables. Si conservas el código original que empieza por ASE-, introdúcelo aquí.':'Este punto se creó antes de habilitar la consulta de claves. Si guardaste su clave, introdúcela aquí.'}</p>
        <Label htmlFor="existing-station-key">Código que tienes guardado</Label><Input id="existing-station-key" type="password" autoComplete="off" value={existingKey} onChange={e=>setExistingKey(e.target.value)} />
        <Button disabled={busy || !existingKey.trim()} onClick={()=>saveOrRotateKey(false)}>Guardar código existente</Button>
        <div className="border-t pt-4 space-y-3"><p className="text-sm text-gray-600">{credentialKey?.kind==='card'?'Si no conservas el código, genera otro para esta misma tarjeta. El anterior dejará de funcionar; no se crea otra tarjeta ni se cierra la tarea en curso.':'Si generas otra clave, la anterior dejará de funcionar y tendrás que introducir la nueva en la tablet.'}</p>
          {rotateApproved ? <div className="flex flex-wrap gap-2"><Button disabled={busy} onClick={()=>saveOrRotateKey(true)}>{busy?'Generando…':'Confirmar nuevo código'}</Button><Button variant="outline" disabled={busy} onClick={()=>setRotateApproved(false)}>Cancelar</Button></div> : <Button variant="outline" disabled={busy} onClick={()=>setRotateApproved(true)}>{credentialKey?.kind==='card'?'Generar código de fichaje':'Generar nueva clave'}</Button>}
        </div>
      </div>}
      {error && <p role="alert" className="text-red-700">{error}</p>}
      </DialogContent>
    </Dialog>
    <Dialog open={Boolean(pendingDelete)} onOpenChange={(open)=>{if (!open && !busy) setPendingDelete(null)}}>
      <DialogContent><DialogHeader><DialogTitle>Eliminar {pendingDelete?.kind==='card'?'tarjeta':'punto de fichaje'}</DialogTitle><DialogDescription>Se retirará de la lista y dejará de funcionar. Sus fichajes e historial se conservarán. Para utilizarlo de nuevo tendrás que crear una nueva credencial.</DialogDescription></DialogHeader>
        <p className="font-medium">{pendingDelete?.name}</p>
        {error && <p role="alert" className="text-red-700">{error}</p>}
        <div className="flex justify-end gap-3"><Button variant="outline" disabled={busy} onClick={()=>setPendingDelete(null)}>Cancelar</Button><Button variant="destructive" disabled={busy} onClick={deleteCredential}>{busy?'Eliminando…':'Eliminar'}</Button></div>
      </DialogContent>
    </Dialog>
    <div className="max-w-6xl mx-auto space-y-6">
    <div><h1 className="text-3xl font-bold">{{planning:'Planificación',cards:'Tarjetas personales',points:'Puntos de fichaje',rules:'Modo tablet'}[section]}</h1><p className="mt-2 text-gray-500">{{planning:'Organiza las tareas, fechas y orden de cada empleado.',cards:'Identificación personal del empleado, independiente de los enlaces a tareas.',points:'Configura los dispositivos compartidos donde se confirma el trabajo.',rules:'Gestiona el inicio y fin exclusivos desde los puntos compartidos.'}[section]}</p></div>
    {section==='points' && <div className="border border-amber-200 bg-amber-50 rounded-lg p-4 text-amber-900">Identificación mediante código personal. El inicio y la finalización se confirman en la tablet. La conexión con un lector NFC físico está pendiente de configurar.</div>}
    {error && <p role="alert" className="bg-red-50 text-red-800 p-4 rounded-lg">{error}</p>}
    {['planning','cards'].includes(section) && <Card><CardContent className="pt-6 grid lg:grid-cols-3 gap-6">
      <div className="space-y-2"><Label htmlFor="work-employee">Empleado</Label><select id="work-employee" className="w-full border rounded-md bg-white p-2" value={user} disabled={busy} onChange={e=>{setSecret(null);setRangeResult('');setUser(e.target.value)}}>{employees.map(e=><option key={e.id} value={e.id}>{e.full_name}</option>)}</select></div>
      {section==='planning' && <div className="lg:col-span-2 space-y-4">
        <div className="space-y-2"><Label htmlFor="period-mode">Período de planificación</Label><select id="period-mode" className="w-full border rounded-md bg-white p-2" value={periodMode} disabled={busy} onChange={e=>updatePeriod(e.target.value)}><option value="day">Día concreto</option><option value="range">Intervalo de fechas</option><option value="month">Mes completo</option><option value="year">Año completo</option></select></div>
        {periodMode==='day' && <div className="space-y-2"><Label htmlFor="plan-day">Fecha</Label><Input id="plan-day" type="date" value={date} disabled={busy} onChange={e=>updatePeriod('day',e.target.value)} /></div>}
        {periodMode==='range' && <div className="grid sm:grid-cols-2 gap-4"><div className="space-y-2"><Label htmlFor="range-start">Desde</Label><Input id="range-start" type="date" value={rangeStart} disabled={busy} onChange={e=>updatePeriod('range',e.target.value)} /></div><div className="space-y-2"><Label htmlFor="range-end">Hasta (incluido)</Label><Input id="range-end" type="date" value={rangeEnd} disabled={busy} onChange={e=>{setRangeEnd(e.target.value);setRangeResult('')}} /></div></div>}
        {periodMode==='month' && <div className="space-y-2"><Label htmlFor="plan-month">Mes</Label><Input id="plan-month" type="month" value={rangeStart.slice(0,7)} disabled={busy} onChange={e=>{if(e.target.value)updatePeriod('month',e.target.value+'-01')}} /></div>}
        {periodMode==='year' && <div className="space-y-2"><Label htmlFor="plan-year">Año</Label><Input id="plan-year" type="number" min="1900" max="9999" defaultValue={rangeStart.slice(0,4)} disabled={busy} key={periodMode} onBlur={e=>{if(/^\d{4}$/.test(e.target.value) && Number(e.target.value)>=1900)updatePeriod('year',e.target.value+'-01-01');else e.target.value=rangeStart.slice(0,4)}} /></div>}
        {periodMode!=='day' && <>
          <fieldset disabled={busy}><legend className="text-sm font-medium mb-2">Días de la semana</legend><div className="flex flex-wrap gap-4">{['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'].map((name,i)=><label key={name} className="flex gap-2 items-center text-sm"><input type="checkbox" checked={weekdays.includes(i+1)} onChange={e=>{setWeekdays(e.target.checked?[...weekdays,i+1]:weekdays.filter(d=>d!==i+1));setRangeResult('')}} />{name}</label>)}</div></fieldset>
          <div className="space-y-2"><Label htmlFor="existing-plans">Si un día ya tiene tareas</Label><select id="existing-plans" className="w-full border rounded-md bg-white p-2" value={existingMode} disabled={busy} onChange={e=>{setExistingMode(e.target.value);setRangeResult('')}}><option value="empty">Conservar ese día y completar solo días vacíos</option><option value="append">Añadir al final las tareas que falten</option></select></div>
          <p className="text-sm text-gray-500">{rangeDays ? `${rangeDays} días seleccionados. La lista de tareas parte de la planificación del ${date}.` : 'Selecciona un intervalo válido de hasta 366 días y al menos un día de la semana.'}</p>
        </>}
        <p className="text-sm text-gray-500">Para modificar una sola fecha sin afectar a las demás, elige Día concreto.</p>
      </div>}
    </CardContent></Card>}
    {loading && <p role="status">Cargando datos…</p>}
    {section==='planning' && user && <PlanningCalendar user={user} date={date} onSelect={reviewDay} revision={overview}/>}
    {overview && <>
      {section==='planning' && <>

      {overview.overdue?.length>0 && <Card><CardHeader><CardTitle>Tareas atrasadas del empleado</CardTitle></CardHeader><CardContent className="space-y-3"><p className="text-sm text-gray-500">Estas tareas no finalizaron en su día. Revisa su fecha para reorganizar las pendientes. Los fichajes en curso deben finalizarse en la tablet.</p>{overview.overdue.map(t=><div key={t.id} className="flex flex-wrap items-center justify-between gap-3 rounded-lg border border-red-200 p-3"><div><p className="font-medium">{t.title}</p><p className="text-sm text-red-700">{t.work_date} · {t.state==='active'?'En curso fuera de plazo':'Pendiente fuera de plazo'}</p></div><Button variant="outline" disabled={busy} onClick={()=>reviewDay(t.work_date)}>Revisar este día</Button></div>)}</CardContent></Card>}
      <div ref={dayDetail} tabIndex={-1} className="scroll-mt-4"><Card><CardHeader><CardTitle>Orden de las tareas · {date}</CardTitle></CardHeader><CardContent className="space-y-4">
        <p className="text-sm text-gray-500">Las tareas deben estar previamente asignadas al empleado. Cada tarea vence al terminar el día para el que se planifica (hora de Madrid). Las iniciadas y completadas conservan su lugar e historial.</p>
        {canEdit && <div className="flex gap-3"><select aria-label="Añadir tarea asignada" value={selected} onChange={e=>setSelected(e.target.value)} className="min-w-0 flex-1 border rounded-md bg-white p-2" disabled={busy}><option value="">Selecciona una tarea</option>{available.filter(t=>!plan.some(p=>p.task_id===t.id)).map(t=><option key={t.id} value={t.id}>{t.title}</option>)}</select><Button disabled={!selected || busy} onClick={()=>{const t=available.find(t=>t.id===selected);setPlan([...plan,{task_id:t.id,title:t.title,state:'pending'}]);setSelected('')}}><Plus className="h-4 w-4" /> Añadir</Button></div>}
        {plan.length===0 && <p className="text-gray-500 p-4 border border-dashed rounded-lg">Sin tareas planificadas para este día.</p>}
        <ol className="space-y-2">{plan.map((t,index)=><li key={t.task_id} className="flex flex-wrap items-center gap-3 border rounded-lg p-3"><span className="text-gray-400">{index+1}.</span><div className="min-w-0 flex-1 basis-[calc(100%-3rem)] sm:basis-0"><p className="font-medium">{t.title}</p><p className="text-sm text-gray-500">{{pending:'Pendiente',active:'En curso',completed:'Completada',blocked:'Bloqueada por incidencia'}[t.state]}</p>{t.overdue && <p className="text-sm text-red-700">Atrasada</p>}{t.completed_late && <p className="text-sm text-amber-800">Finalizada fuera de plazo</p>}</div>{canEdit && <><Button variant="outline" size="icon" aria-label={`Subir ${t.title}`} disabled={busy || t.state!=='pending' || index===0 || plan[index-1]?.state!=='pending'} onClick={()=>move(index,-1)}><ArrowUp /></Button><Button variant="outline" size="icon" aria-label={`Bajar ${t.title}`} disabled={busy || t.state!=='pending' || index===plan.length-1 || plan[index+1]?.state!=='pending'} onClick={()=>move(index,1)}><ArrowDown /></Button><Button variant="outline" size="icon" aria-label={`Retirar ${t.title}`} disabled={busy || t.state!=='pending'} onClick={()=>setPlan(plan.filter((_,i)=>i!==index))}><Trash2 /></Button></>}</li>)}</ol>
        {canEdit && (periodMode==='day' ? <Button disabled={busy || loading || !date} onClick={save}>{busy?'Guardando…':'Guardar planificación del día'}</Button> : <Button disabled={busy || loading || !rangeDays || !plan.length} onClick={()=>setRangeConfirm(true)}>Revisar y aplicar al período</Button>)}
        {rangeResult && <p role="status" className="text-sm text-blue-800">{rangeResult}</p>}
      </CardContent></Card></div>
      </>}
      {isAdmin && <>
      {section==='cards' && <div className="space-y-5"><PersonalPinManager key={user} userId={user}/>
        <Card><CardHeader><CardTitle className="flex gap-2 items-center"><CreditCard /> Tarjeta personal</CardTitle></CardHeader><CardContent className="space-y-4">
          <p className="text-sm text-gray-500">Cada empleado puede tener una sola tarjeta activa. Las anteriores se conservan para el historial y pueden reactivarse si no hay otra activa. Puedes consultar y copiar el código desde cada tarjeta.</p>
          <Button disabled={busy || overview.cards.some(c=>c.user_id===user && c.active)} onClick={()=>credential('card')}>Crear tarjeta para este empleado</Button>
          {overview.cards.some(c=>c.user_id===user && c.active) && <p className="text-sm text-gray-500">Ya tiene una tarjeta activa. Para reemplazarla, desactívala primero.</p>}
          {employeeCards.map(c=><div key={c.id} className="flex flex-wrap justify-between gap-3 items-center border rounded-md p-3"><div><p>{c.label} · {c.active?'Activa':'Desactivada'}</p><p className="text-xs text-gray-500 mt-1">Referencia interna: {c.id.slice(0,8)}</p></div><Button variant="outline" disabled={busy} onClick={()=>showCardCode(c)}><Copy className="h-4 w-4" /> Ver y copiar código de fichaje</Button><Button variant="outline" disabled={busy || (!c.active && overview.cards.some(other=>other.user_id===user && other.active))} onClick={()=>setCardActive(c)}>{c.active?'Desactivar':'Activar'}</Button><Button variant="outline" className="text-red-600" disabled={busy} onClick={()=>{setError('');setPendingDelete({kind:'card',id:c.id,name:`${c.label} · Tarjeta ${c.id.slice(0,8)}`})}}><Trash2 className="h-4 w-4" /> Eliminar</Button></div>)}
        </CardContent></Card>
      </div>}
      {section==='points' && <div><Card><CardHeader><CardTitle className="flex gap-2 items-center"><Monitor /> Puntos de fichaje</CardTitle></CardHeader><CardContent className="space-y-4"><Label htmlFor="station-name">Nombre del punto</Label><Input id="station-name" value={stationName} onChange={e=>setStationName(e.target.value)} maxLength={100} /><Label htmlFor="station-custom-key">Clave del punto · opcional</Label><Input id="station-custom-key" type="password" autoComplete="new-password" value={stationKey} onChange={e=>setStationKey(e.target.value)} maxLength={128} /><p className="text-sm text-gray-500">Escribe tu propia clave de 8 a 128 caracteres o déjalo vacío para generar una automáticamente. Esta clave configura el punto; no es el PIN personal del empleado.</p><Button disabled={busy || !stationName.trim() || (stationKey.trim().length>0 && stationKey.trim().length<8)} onClick={()=>credential('station')}>Crear punto de fichaje</Button>{stations.map(s=><div key={s.id} className="flex flex-wrap justify-between gap-3 items-center border rounded-md p-3"><span>{s.name} · {s.active?'Activo':'Desactivado'}</span><Button variant="outline" disabled={busy} onClick={()=>showStationKey(s)}>Ver clave</Button><Button variant="outline" disabled={busy} onClick={()=>setStationActive(s)}>{s.active?'Desactivar':'Activar'}</Button><Button variant="outline" className="text-red-600" disabled={busy} onClick={()=>{setError('');setPendingDelete({kind:'station',id:s.id,name:`${s.name} · Punto ${s.id.slice(0,8)}`})}}><Trash2 className="h-4 w-4" /> Eliminar</Button></div>)}<Link className="text-blue-700 underline block" to="/station" target="_blank" rel="noreferrer">Abrir pantalla de tablet</Link></CardContent></Card>
      </div>}
      {secret && <Card><CardHeader><CardTitle>Clave creada: {secret.name}</CardTitle></CardHeader><CardContent className="space-y-3"><p className="text-sm text-gray-600">{secret.kind==='card'?'Guarda el código personal para identificar al empleado. No es el enlace de la tarea.':'Introduce esta clave en la pantalla de la tablet. No compartas una sesión de administrador con los empleados.'}</p><div className="flex gap-2"><Input id="created-credential-key" className="min-w-0 flex-1" aria-label="Clave recién creada" value={secret.token} readOnly onFocus={e=>e.target.select()} /><Button variant="outline" onClick={()=>copyKey(secret.token,'created-credential-key')}><Copy className="h-4 w-4" /> Copiar</Button></div><Button variant="outline" onClick={()=>setSecret(null)}>Ya la he guardado</Button></CardContent></Card>}
      {section==='rules' && <Card><CardHeader><CardTitle>Activación del flujo</CardTitle></CardHeader><CardContent className="space-y-4"><p>Modo tablet: <strong>{overview.enabled?'Activado':'Desactivado'}</strong></p><p className="text-gray-500 text-sm">Actívalo después de guardar los planes del día y crear tarjetas y un punto de fichaje. No se activa ni desactiva mientras existan fichajes abiertos.</p><Button variant={overview.enabled?'outline':'default'} disabled={busy} onClick={setMode}>{overview.enabled?'Desactivar modo tablet':'Activar modo tablet'}</Button></CardContent></Card>}
      </>}
    </>}
  </div></Layout>
}
