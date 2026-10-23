import {Navigate} from 'react-router-dom'
import {useAuth} from '@/hooks/useAuth'
export default function LoginDestination() {
 const {userData,can}=useAuth()
 const management=userData?.is_admin||['tasks.view','planning.view','reports.view','checkins.view'].some(can)
 return <Navigate to={management?'/admin':'/employee'} replace />
}
