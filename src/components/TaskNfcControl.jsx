import {useEffect,useRef,useState} from 'react'
import {NfcIcon} from 'lucide-react'
import {Button} from '@/components/ui/button'
import {supabase} from '@/lib/supabase'
import {readTaskCardUid} from '@/lib/taskCardNfc'
export default function TaskNfcControl({taskId,userId,activeCheckin,checkinStatus,onChanged,onFinished,beforeFinish}) {
 const [stage,setStage]=useState('idle'),[error,setError]=useState('')
 const controller=useRef(null),generation=useRef(0),sending=useRef(false),timer=useRef(null)
 const cancel=()=>{generation.current++;clearTimeout(timer.current);controller.current?.abort();controller.current=null;setStage('idle');setError('')}
 useEffect(()=>{cancel();return()=>{generation.current++;clearTimeout(timer.current);controller.current?.abort()}},[taskId,userId,activeCheckin?.id])
 const scan=async()=>{
  if(sending.current||!taskId||!userId||checkinStatus!=='ready')return
  cancel();const request=generation.current,abort=new AbortController();controller.current=abort
  const action=activeCheckin?'checkout':'checkin',expected=activeCheckin?.id||null
  try{if(action==='checkout')await beforeFinish?.();setStage('reading');await readTaskCardUid({signal:abort.signal,onRead:async uid=>{
   if(request!==generation.current||sending.current)return
   sending.current=true;setStage('saving')
   try{
    const {data,error:failure}=await supabase.rpc('work_task_nfc_checkin',{p_card_uid:uid,p_task:taskId,p_action:action,p_expected_checkin:expected})
    if(failure)throw new Error(failure.code==='PGRST202'?'Falta activar la actualización de NFC por tarea en la base de pruebas':failure.message)
    if(!data?.success||data.type!==action||!data.checkin_id)throw new Error('No se confirmó el fichaje. Actualiza su estado antes de reintentar')
    if(request!==generation.current)return
    setStage('success')
    // Keep the scan session alive briefly while the employee removes the card.
    timer.current=setTimeout(async()=>{
     if(request!==generation.current)return
     abort.abort();setStage('idle')
     try{if(action==='checkout' && onFinished)onFinished();else await onChanged?.()}catch{setError('El fichaje se guardó, pero no se pudo actualizar la pantalla. Recarga la página.')}
    },2500)
   }catch(e){if(request===generation.current){abort.abort();setStage('idle');setError(e.message)}}finally{sending.current=false}
  },onError:message=>{if(request===generation.current){abort.abort();setStage('idle');setError(message)}}})}
  catch(e){if(request===generation.current){abort.abort();setStage('idle');if(e.name!=='AbortError')setError(e.name==='NotAllowedError'?'Permiso NFC denegado. Permite la lectura y vuelve a intentarlo':e.message)}}
 }
 const open=()=>{if(activeCheckin)setStage('confirm');else scan()}
 const overlay=stage!=='idle'
 return <div className="space-y-3">
  <Button onClick={open} disabled={overlay||checkinStatus!=='ready'} className="w-full bg-blue-600 hover:bg-blue-700" size="lg"><NfcIcon className="mr-2 h-5 w-5"/>{activeCheckin?'Finalizar tarea':'Iniciar con NFC'}</Button>
  {overlay&&<div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4"><section role="dialog" aria-modal="true" aria-label="Fichaje NFC" className="bg-white rounded-lg p-6 space-y-4 w-full max-w-md text-center">
   <NfcIcon className="h-12 w-12 text-blue-600 mx-auto"/>
   {stage==='confirm'?<><p className="font-semibold">¿Seguro que quieres finalizar tu trabajo en esta tarea?</p><Button onClick={scan}>Continuar con NFC</Button><Button variant="outline" onClick={cancel}>Cancelar</Button></>:stage==='reading'?<><p className="font-semibold">{activeCheckin?'Finalizar con NFC':'Iniciar con NFC'}</p><p>Acerca el móvil a la tarjeta asociada a esta tarea.</p><Button variant="outline" onClick={cancel}>Cancelar lectura NFC</Button></>:stage==='saving'?<p role="status">Guardando fichaje…</p>:<><p role="status" className="font-semibold">{activeCheckin?'Fichaje finalizado':'Fichaje iniciado'}</p><p>{activeCheckin?'Retira el móvil de la tarjeta. Volverás a tus tareas asignadas.':'Retira el móvil de la tarjeta. Volverás al detalle de la tarea.'}</p></>}
  </section></div>}
  {error&&<p role="alert" className="text-red-700">{error}</p>}
 </div>
}
