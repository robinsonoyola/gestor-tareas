import { useNavigate } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Home } from 'lucide-react'

export default function NotFound() {
  const navigate = useNavigate()

  return (
    <div className="flex items-center justify-center min-h-screen bg-gradient-to-br from-blue-400 to-cyan-400">
      <div className="text-center space-y-6 p-8">
        <div className="text-9xl"></div>
        <h1 className="text-6xl font-bold text-white">404</h1>
        <p className="text-2xl text-white">Página no encontrada</p>
        <p className="text-white/80">
          La página que buscas no existe o ha sido movida
        </p>
        <Button 
          size="lg"
          onClick={() => navigate('/')}
          className="mt-4"
        >
          <Home className="mr-2 h-4 w-4" />
          Volver al inicio
        </Button>
      </div>
    </div>
  )
}