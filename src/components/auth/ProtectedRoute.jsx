import OrganizationChoice from './OrganizationChoice'
import {useOrganization} from './OrganizationProvider'
import { Navigate } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'

export default function ProtectedRoute({ children, requireAdmin = false, requirePermission = null, requireAny = null }) {
  const context=useOrganization()
  const { user, userData, loading, permissionsLoading, can } = useAuth()

  if (loading || ((requirePermission || requireAny) && permissionsLoading)) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto"></div>
          <p className="mt-4 text-gray-600">Cargando...</p>
        </div>
      </div>
    )
  }

  if (!user) {
    return <Navigate to="/login" replace />
  }

  if(context?.mode==='tenant' && (!context.activeOrganizationId || context.error)) return <OrganizationChoice />

  if (requireAdmin && !userData?.is_admin) {
    return <Navigate to="/employee" replace />
  }

  if (requirePermission && !can(requirePermission)) return <Navigate to="/employee" replace />

  if (requireAny && !requireAny.some(can)) return <Navigate to="/employee" replace />
  return children
}