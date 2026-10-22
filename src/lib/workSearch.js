const normalize = value => String(value).normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().trim()
export function parseWorkSearch(query) {
  let text = normalize(query)
  let state=null,kind=null
  if (/\bincidencias?\b/.test(text)) kind='incidents'
  else if (/\b(tareas?|actividades?)\b/.test(text)) kind='tasks'
  else if (/\b(empleados?|personas?|trabajadores?)\b/.test(text)) kind='people'
  for(const [pattern,value] of [[/\b(en curso|en progreso|en atencion|iniciad[ao]s?|trabajando)\b/g,'active'],[/\b(pendientes?|por hacer|abiertas?)\b/g,'pending'],[/\b(completad[ao]s?|terminad[ao]s?|finalizad[ao]s?|resueltas?)\b/g,'completed'],[/\b(bloquead[ao]s?)\b/g,'blocked']]) {
    if(pattern.test(text)){state=value;text=text.replace(pattern,' ')}
  }
  const terms=text.replace(/\b(tareas?|actividades?|incidencias?|empleados?|personas?|trabajadores?|las?|los?|de|del|al|buscar|ver|mostrar|muestrame|que|estan?|estoy|una?|un|el|en|con|para|todo[as]?)\b/g,' ').split(/\s+/).filter(Boolean).slice(0,10)
  return {p_terms:terms,p_state:state,p_kind:kind}
}
