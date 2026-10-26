import { useState, useEffect, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { ArrowLeft, Check, ShieldCheck } from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { requestPasswordReset } from '@/lib/passwordRecovery'

export default function Login() {
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [loginError,setLoginError]=useState('')
  const [loginStalled,setLoginStalled]=useState(false)
  const signingIn=useRef(false)
  const [resetMode, setResetMode] = useState(false)
  const [resetMessage, setResetMessage] = useState('')
  const [resetError, setResetError] = useState('')
  const [resetCooldown, setResetCooldown] = useState(0)
  const [credentials, setCredentials] = useState({
    email: '',
    password: ''
  })

  useEffect(() => {
    if (resetCooldown <= 0) return
    const timer = setTimeout(() => setResetCooldown(value => Math.max(0, value - 1)), 1000)
    return () => clearTimeout(timer)
  }, [resetCooldown])

  const toggleRecovery = () => {
    setResetMode(value => !value)
    setResetMessage('')
    setResetError('')
    setCredentials(value => ({ ...value, password: '' }))
  }

  const handleResetRequest = async (event) => {
    event.preventDefault()
    if (loading || resetCooldown > 0) return
    setLoading(true)
    setResetMessage('')
    setResetError('')
    try {
      await requestPasswordReset(credentials.email)
      setResetMessage('Si existe una cuenta con ese email, recibirás un enlace para elegir una contraseña nueva. Revisa también la carpeta de spam.')
      setResetCooldown(60)
    } catch (error) {
      console.error('Error requesting recovery:', error?.code || 'unknown')
      setResetError('No se pudo solicitar el enlace. Comprueba el email y vuelve a intentarlo más tarde.')
    } finally {
      setLoading(false)
    }
  }

  const handleLogin = async (e) => {
    e.preventDefault()
    if(signingIn.current||loginStalled)return
    signingIn.current=true;setLoading(true);setLoginError('')
    let timer
    try {
      const deadline=new Promise((_,reject)=>{timer=setTimeout(()=>reject(Object.assign(new Error('El acceso está tardando demasiado. Recarga esta pantalla y vuelve a intentarlo.'),{code:'login_timeout'})),20000)})
      const {data,error}=await Promise.race([supabase.auth.signInWithPassword({email:credentials.email.trim(),password:credentials.password}),deadline])
      if(error)throw error
      if(!data?.user)throw new Error('No se confirmó la sesión')
      // The organization provider owns company/permission loading. Do not race a second mt_context request here.
      toast.success('Inicio de sesión correcto')
      navigate('/login/complete',{replace:true})
    } catch(error) {
      console.error('Error logging in:',error?.code||'unknown')
      if(error?.code==='login_timeout')setLoginStalled(true)
      const message=error?.code==='login_timeout'?error.message:error?.code==='invalid_credentials'||error?.message==='Invalid login credentials'?'Correo o contraseña incorrectos.':error?.name==='AbortError'||error?.message?.includes('AbortError')?'La sesión cambió durante el acceso. Vuelve a intentarlo.':'No se pudo completar el acceso. Comprueba la conexión y vuelve a intentarlo.'
      setLoginError(message)
    } finally {
      clearTimeout(timer);signingIn.current=false;setLoading(false)
    }
  }

  return (
    <main className="ase-login-shell">
      <div className="ase-login-grid" aria-hidden="true" />
      <div className="ase-login-orb ase-login-orb-one" aria-hidden="true" />
      <div className="ase-login-orb ase-login-orb-two" aria-hidden="true" />

      <section className="ase-login-intro">
        <div className="ase-login-brand">
          <span className="ase-login-logo"><img src="/ase-icon.svg" alt="" width="58" height="58" /></span>
          <span><strong>ASE Work</strong><small>Gestión operativa</small></span>
        </div>
        <div className="ase-login-copy">
          <span className="ase-login-eyebrow">El trabajo, bajo control</span>
          <h1>Tu equipo sabe qué hacer. Tú sabes cómo avanza.</h1>
          <p>Planifica, coordina y supervisa la operación diaria desde un único espacio.</p>
          <ul>
            <li><Check size={16} /> Tareas, tiempos e incidencias en tiempo real</li>
            <li><Check size={16} /> Responsabilidades y prioridades bien definidas</li>
            <li><Check size={16} /> Acceso seguro desde ordenador, tablet o móvil</li>
          </ul>
        </div>
        <p className="ase-login-intro-foot"><ShieldCheck size={15} /> Entorno protegido para tu empresa</p>
      </section>

      <section className="ase-login-access" aria-label={resetMode ? 'Recuperar contraseña' : 'Iniciar sesión'}>
        <div className="ase-login-card">
          <header className="ase-login-card-head">
            <div className="ase-login-card-icon"><img src="/ase-icon.svg" alt="ASE Work" width="44" height="44" /></div>
            <span className="ase-login-secure"><span /> Acceso seguro</span>
            <h2>{resetMode ? 'Recupera tu acceso' : 'Bienvenido a ASE Work'}</h2>
            <p>{resetMode ? 'Te enviaremos un enlace para elegir una contraseña nueva.' : 'Introduce tus datos para entrar en tu espacio de trabajo.'}</p>
          </header>

          <form onSubmit={resetMode ? handleResetRequest : handleLogin} className="ase-login-form">
            <div className="space-y-2">
              <Label htmlFor="email">Correo electrónico</Label>
              <Input
                id="email"
                type="email"
                value={credentials.email}
                onChange={(e) => setCredentials(prev => ({ ...prev, email: e.target.value }))}
                placeholder="nombre@empresa.com"
                required
                autoComplete="email"
                autoFocus
              />
            </div>

            {!resetMode && <div className="space-y-2">
              <div className="ase-login-label-row">
                <Label htmlFor="password">Contraseña</Label>
                <button type="button" onClick={toggleRecovery} disabled={loading}>¿La has olvidado?</button>
              </div>
              <Input
                id="password"
                type="password"
                value={credentials.password}
                onChange={(e) => setCredentials(prev => ({ ...prev, password: e.target.value }))}
                placeholder="Introduce tu contraseña"
                required
                autoComplete="current-password"
              />
            </div>}

            {!resetMode&&loginError&&<p role="alert" className="ase-login-message ase-login-message-error">{loginError}</p>}
            {!resetMode&&loginStalled&&<Button type="button" variant="outline" className="w-full" onClick={()=>window.location.reload()}>Recargar acceso</Button>}
            {resetMessage && <p role="status" className="ase-login-message ase-login-message-success">{resetMessage}</p>}
            {resetError && <p role="alert" className="ase-login-message ase-login-message-error">{resetError}</p>}

            <Button type="submit" disabled={loading || (!resetMode && loginStalled) || (resetMode && resetCooldown > 0)} className="ase-login-submit">
              {loading ? <><span className="ase-login-spinner" />{resetMode ? 'Solicitando enlace…' : 'Iniciando sesión…'}</> :
                resetMode ? (resetCooldown > 0 ? `Puedes volver a solicitarlo en ${resetCooldown}s` : 'Enviar enlace de recuperación') : 'Entrar en ASE Work'}
            </Button>
          </form>

          {resetMode && <button type="button" onClick={toggleRecovery} disabled={loading} className="ase-login-back">
            <ArrowLeft size={15} /> Volver a iniciar sesión
          </button>}

          <footer className="ase-login-card-foot">
            <ShieldCheck size={15} /> Tus datos viajan cifrados y protegidos
          </footer>
        </div>
        <p className="ase-login-device-note">ASE Work · Gestión clara para equipos que avanzan</p>
      </section>
    </main>
  )
}
