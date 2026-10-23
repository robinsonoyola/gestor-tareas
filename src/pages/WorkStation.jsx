import StationChecklist from '@/components/checklists/StationChecklist'
import {usabilityReady} from '@/lib/workFeatures'
import {startPersonalCardReader} from '@/lib/personalCardNfc'
import { useEffect, useRef, useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent } from '@/components/ui/card'
import { CreditCard, CheckCircle, LockKeyhole } from 'lucide-react'
import { elapsedSince, stationRpc } from '@/lib/workflow'
import { supabase } from '@/lib/supabase'

export default function WorkStation() {
  const [extras,setExtras] = useState(false)
  const [sessionChecked, setSessionChecked] = useState(false)
  const [operatorSession, setOperatorSession] = useState(false)
  const [station, setStation] = useState(() => sessionStorage.getItem('ase-work-station') || '')
  const [setup, setSetup] = useState('')
  const [card, setCard] = useState('')
  const [person, setPerson] = useState(null)
  const [day, setDay] = useState(null)
  const [dayError, setDayError] = useState('')
  const [dayLoading, setDayLoading] = useState(false)
  const [showDay, setShowDay] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [confirmFinish, setConfirmFinish] = useState(false)
  const [remaining, setRemaining] = useState(10)
  const [nfcStatus, setNfcStatus] = useState('')
  const nfcController = useRef(null)
  const nfcIdentify = useRef(null)
  const input = useRef(null)
  const generation = useRef(0)
  const inFlight = useRef(false)
  const lastTicket = useRef(null)
  useEffect(() => {
    let current = true
    supabase.auth.getSession().then(({data}) => { if (current) { setOperatorSession(Boolean(data.session)); setSessionChecked(true) } })
    const {data: listener} = supabase.auth.onAuthStateChange((_event, session) => {
      if (current) { setOperatorSession(Boolean(session)); setSessionChecked(true) }
    })
    return () => { current = false; listener.subscription.unsubscribe() }
  }, [])

  useEffect(()=>{let live=true;usabilityReady().then(v=>{if(live)setExtras(v)}).catch(()=>{});return()=>{live=false}},[])
  const reset = () => { generation.current++; lastTicket.current = null; setDay(null); setDayError(''); setDayLoading(false); setShowDay(false); setPerson(null); setCard(''); setError(''); setSuccess(''); setConfirmFinish(false); setRemaining(10); input.current?.focus() }
  useEffect(() => {
    if (!person && !success && !error) return
    const interval = setInterval(() => setRemaining(n => n - 1), 1000)
    return () => clearInterval(interval)
  }, [person, success, error])
  useEffect(() => { if (remaining <= 0 && !busy) reset() }, [remaining, busy])
  const loadDay = async (ticket) => {
    const request = generation.current
    setDayLoading(true); setDayError(''); setDay(null)
    try {
      const data = await stationRpc(extras?'work_station_day_v2':'work_station_day', {p_station: station, p_ticket: ticket})
      if (request === generation.current) setDay(data)
    } catch (e) {
      if (request === generation.current) setDayError('No se pudo consultar la lista. Si falta work_station_day, instala la actualización del resumen de tablet.')
    } finally { if (request === generation.current) setDayLoading(false) }
  }
  const identifyCode = async (value,method='manual') => {
    const code = value.trim()
    if (!code || inFlight.current) return
    if (method==='pin' && (!/^\d{5}$/.test(code))) {setError('Introduce tu código personal de 5 dígitos.');setRemaining(10);return}
    if (method!=='pin' && !code.startsWith('ASE-')) {
      setError('Introduce el código de fichaje que empieza por ASE-. En administración, usa «Ver y copiar código de fichaje»; la referencia interna no sirve para identificarte.')
      setRemaining(10)
      return
    }
    inFlight.current = true; setBusy(true); setError('')
    const request = ++generation.current
    try {
      const data = await stationRpc(extras?'work_station_identify_v2':'work_station_identify', extras ? {p_station:station,p_card:code,p_method:method,p_user:null} : {p_station:station,p_card:code})
      if (data.error) throw new Error(data.error)
      if (request !== generation.current) return
      setPerson(data); lastTicket.current = data.ticket; setDay(null); setDayError(''); setShowDay(data.action === 'none'); setCard(''); setSuccess(''); setConfirmFinish(false); setRemaining(10); if (data.action === 'none') loadDay(data.ticket)
    } catch (e) { if (request === generation.current) { setError(e.message); setRemaining(8) } }
    finally { inFlight.current = false; setBusy(false) }
  }
  useEffect(() => {
    if (!extras || !station || operatorSession || person || success || busy || !/^\d{5}$/.test(card.trim())) return
    const timer = setTimeout(() => identifyCode(card,'pin'),450)
    return () => clearTimeout(timer)
  }, [card,extras,station,operatorSession,person,success])
  const identify = e => { e.preventDefault(); return identifyCode(card,/^\d{5}$/.test(card.trim())?'pin':'manual') }
  nfcIdentify.current = value => {
    if (!station || operatorSession || person || success || inFlight.current) return
    identifyCode(value,'nfc')
  }
  useEffect(() => {
    setNfcStatus('')
    return () => { nfcController.current?.abort(); nfcController.current=null }
  }, [station, operatorSession])
  const enableNfc = async () => {
    if (nfcController.current) return
    const controller = new AbortController()
    nfcController.current = controller
    setNfcStatus('Solicitando acceso NFC…')
    try {
      await startPersonalCardReader({signal:controller.signal,onCode:value=>nfcIdentify.current?.(value),onError:message=>{setError(message);setRemaining(8)}})
      if (!controller.signal.aborted) setNfcStatus('NFC preparado. Acerca la tarjeta personal del empleado.')
    } catch (failure) {
      controller.abort()
      if (nfcController.current === controller) {
        nfcController.current=null
        setNfcStatus(failure.name==='NotAllowedError' ? 'Permiso NFC denegado. Permite el acceso y vuelve a intentarlo.' : failure.message)
      }
    }
  }
  const confirm = async (action) => {
    if (inFlight.current || !person?.ticket) return
    inFlight.current = true; setBusy(true); setError('')
    try {
      const result = await stationRpc(extras?'work_station_confirm_v2':'work_station_confirm', { p_station: station, p_ticket: person.ticket, p_action: action })
      if (!result?.success || result.action !== action) throw new Error('No se confirmó el fichaje. Vuelve a intentarlo.')
      setSuccess(action === 'start' ? 'Tarea comenzada. Ya puedes abrirla en tu móvil.' : 'Tarea finalizada. Tu siguiente tarea estará disponible al identificarte de nuevo.')
      setPerson(null); setRemaining(10); setConfirmFinish(false); setShowDay(true); loadDay(lastTicket.current)
    } catch (e) { setError(e.message) }
    finally { inFlight.current = false; setBusy(false) }
  }
  const daySummary = showDay && <section className="border rounded-xl p-4 space-y-3" aria-label="Resumen temporal de tareas">
    <h2 className="text-xl font-semibold">Mis tareas del día</h2>
    {day && <p className="text-sm text-gray-500">{day.employee} · {day.date}</p>}
    {dayLoading && <p role="status">Cargando tareas…</p>}
    {dayError && <p role="alert" className="text-red-700">{dayError}</p>}
    {day?.items?.length === 0 && <p className="text-gray-600">No tienes tareas asignadas para hoy.</p>}
    {day?.items?.length > 0 && <ol className="space-y-2">{day.items.map(item => <li key={item.id} className="flex flex-wrap items-center justify-between gap-3 border rounded-lg p-3"><span>{item.priority}. {item.title}<small className="block text-gray-500">Fecha límite: {item.work_date}, fin del día (Madrid)</small></span><span className={item.state === 'active' ? 'text-blue-700' : item.state === 'completed' ? 'text-green-700' : 'text-amber-800'}>{{pending:'Pendiente',active:'En curso',completed:'Completada',blocked:'Bloqueada por incidencia'}[item.state]}{item.overdue && <small className="block text-red-700">Atrasada</small>}{item.completed_late && <small className="block text-amber-800">Fuera de plazo</small>}</span></li>)}</ol>}
    {person && <Button variant="outline" className="w-full" onClick={()=>setShowDay(false)}>Volver a mi tarea</Button>}
  </section>
  if (!sessionChecked) return <main className="min-h-screen flex items-center justify-center">Comprobando este navegador…</main>
  if (operatorSession) return <main className="ase-content min-w-0 min-h-dvh bg-gray-50 p-3 sm:p-6 flex items-center justify-center"><Card className="max-w-xl"><CardContent className="pt-6 space-y-5"><h1 className="text-2xl font-bold">Preparar tablet compartida</h1><p>Este navegador tiene una sesión personal abierta. Ciérrala antes de dejar la tablet a los empleados.</p><p className="text-sm text-gray-500">El punto utilizará su propia clave y no una cuenta de administrador. Puedes mantener la administración abierta en otro navegador o dispositivo.</p><Button onClick={async () => { const {error} = await supabase.auth.signOut({scope:'local'}); if (error) setError('No se pudo cerrar la sesión. Vuelve a intentarlo.') }}>Cerrar sesión en este navegador</Button>{error && <p role="alert">{error}</p>}</CardContent></Card></main>
  return <main className="ase-content min-w-0 min-h-dvh bg-gray-50 p-3 sm:p-6 flex flex-col items-center justify-center gap-5">
    <div className="text-center"><h1 className="text-3xl font-bold">ASE Work</h1><p className="text-gray-500 mt-2">Punto de fichaje compartido</p></div>
    {station && <div className="max-w-2xl w-full"><Button variant="outline" onClick={reset} disabled={busy}>← Atrás al inicio del punto</Button></div>}
    <div className="max-w-2xl w-full bg-amber-50 border border-amber-200 p-3 rounded-lg text-sm text-amber-900">Identificación mediante tarjeta NFC o código personal. Leer la tarjeta no comienza ni finaliza tareas.</div>
    {station && <section className="max-w-2xl w-full space-y-2" aria-label="Lector NFC">
      <Button variant="outline" onClick={enableNfc} disabled={Boolean(nfcController.current)}>Activar lector NFC</Button>
      {nfcStatus && <p role="status" className="text-sm text-gray-600">{nfcStatus}</p>}
      {!window.isSecureContext && <p className="text-sm text-gray-600">Para usar el NFC integrado, abre este punto con HTTPS. El código manual sigue disponible.</p>}
    </section>}

    {!station ? <Card className="w-full max-w-2xl"><CardContent className="pt-6 space-y-4"><LockKeyhole className="h-8 w-8 text-blue-600" /><h2 className="text-xl font-semibold">Configurar este punto</h2><p className="text-gray-500">El administrador debe introducir la clave del punto, no su contraseña personal.</p><Label htmlFor="station-key">Clave del punto</Label><Input id="station-key" type="password" value={setup} onChange={e => setSetup(e.target.value)} autoComplete="off" /><Button disabled={!setup.trim()} onClick={() => { sessionStorage.setItem('ase-work-station', setup.trim()); setStation(setup.trim()); setSetup('') }}>Continuar</Button></CardContent></Card> : <Card className="w-full max-w-2xl"><CardContent className="pt-8 space-y-6">
      {error && <p role="alert" className="bg-red-50 text-red-800 p-4 rounded-lg">{error}</p>}
      {success ? <div role="status" className="text-center space-y-4"><CheckCircle className="h-12 w-12 text-green-600 mx-auto" /><h2 className="text-2xl font-semibold">{success}</h2>{daySummary}<Button variant="outline" className="w-full" onClick={reset}>Volver al inicio del fichaje</Button></div> : person ? <>
        <div><p className="text-gray-500">Identificado como</p><h2 className="text-3xl font-bold mt-1">{person.employee}</h2></div>
        {person.title ? <div className="border rounded-xl p-5 space-y-3"><p className="text-sm text-gray-500">{person.action === 'finish' ? 'Tu tarea en curso' : 'Tu siguiente tarea'}</p><h3 className="text-2xl font-semibold">{person.title}</h3><p className="text-gray-600 whitespace-pre-wrap">{person.description || 'Sin instrucciones adicionales'}</p>{person.started_at && <p className="font-mono text-3xl text-blue-700">{elapsedSince(person.started_at)}</p>}</div> : <p>No tienes más tareas pendientes para hoy.</p>}
        {person.action === 'start' && <Button disabled={busy} className="w-full h-16 text-xl" onClick={() => confirm('start')}>{busy ? 'Guardando…' : 'Comenzar tarea'}</Button>}
        {extras&&person.action==='finish'&&<StationChecklist key={person.ticket} station={station} ticket={person.ticket} onInteract={()=>setRemaining(60)}/>}
        {person.action === 'finish' && (!confirmFinish ? <Button disabled={busy} className="w-full h-16 text-xl" onClick={() => setConfirmFinish(true)}>Finalizar tarea</Button> : <div className="border border-red-200 bg-red-50 rounded-lg p-4 space-y-4"><p>¿Confirmas que has terminado esta tarea?</p><div className="flex flex-col sm:flex-row gap-3"><Button disabled={busy} variant="destructive" onClick={() => confirm('finish')}>{busy ? 'Guardando…' : 'Sí, finalizar tarea'}</Button><Button variant="outline" disabled={busy} onClick={() => setConfirmFinish(false)}>Seguir consultando</Button></div></div>)}
        {!showDay && <Button variant="outline" disabled={busy} className="w-full" onClick={()=>{setShowDay(true); setRemaining(n=>Math.min(n,10)); loadDay(lastTicket.current)}}>Ver mis tareas del día</Button>}
        {daySummary}
        <Button variant="outline" disabled={busy} className="w-full" onClick={reset}>Volver al inicio del fichaje</Button>
      </> : <><CreditCard className="h-16 w-16 text-blue-600 mx-auto" /><h2 className="text-2xl text-center font-semibold">Identifícate con tu tarjeta</h2><p className="text-center text-gray-500">Leer la tarjeta no inicia ni finaliza ninguna tarea.</p><form onSubmit={identify} className="space-y-3"><Label htmlFor="employee-card">Código personal o de la tarjeta</Label><Input ref={input} id="employee-card" type="password" inputMode="text" maxLength={255} autoComplete="off" value={card} onChange={e => setCard(e.target.value)} disabled={busy} autoFocus /><Button disabled={busy || !card.trim()} className="w-full h-12">{busy ? 'Comprobando…' : 'Identificar empleado'}</Button></form></>}
      {(person || success || error) && <p role="status" className="text-sm text-center text-gray-500">Volverá al inicio en {Math.max(0, remaining)} segundos.</p>}
    </CardContent></Card>}
    {station && !person && !busy && <button className="text-sm text-gray-500 underline" onClick={() => { sessionStorage.removeItem('ase-work-station'); setStation(''); reset() }}>Cambiar configuración del punto</button>}
  </main>
}
