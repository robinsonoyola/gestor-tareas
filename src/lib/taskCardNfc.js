export function normalizeTaskCardUid(value) {
 const uid=String(value || '').replace(/[\s:-]/g,'').toLowerCase()
 if(!/^(?:[0-9a-f]{2}){4,16}$/.test(uid)) throw new Error('El UID debe contener el número de serie físico de la tarjeta, por ejemplo 04:A1:B2:C3:D4:E5:F6')
 return uid
}
export async function readTaskCardUid({signal,onRead,onError,Reader=globalThis.NDEFReader,secure=globalThis.isSecureContext}) {
 if(!secure) throw new Error('Abre esta página con HTTPS para leer la tarjeta NFC')
 if(!Reader) throw new Error('Este navegador no permite leer NFC. Usa el Android compatible de pruebas')
 if(signal?.aborted) throw new DOMException('Lectura cancelada','AbortError')
 const reader=new Reader();let handled=false
 const cleanup=()=>{reader.onreading=null;reader.onreadingerror=null}
 signal?.addEventListener('abort',cleanup,{once:true})
 reader.onreading=event=>{if(handled||signal?.aborted)return;handled=true;cleanup();try{onRead(normalizeTaskCardUid(event.serialNumber))}catch(e){onError(e.message)}}
 reader.onreadingerror=()=>{if(handled||signal?.aborted)return;handled=true;cleanup();onError('No se pudo leer la tarjeta. Retírala y vuelve a intentarlo')}
 try{await reader.scan({signal})}catch(e){cleanup();throw e}
 return cleanup
}
