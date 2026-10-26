import RecurringWork from './pages/admin/RecurringWork'
import PlanningBoard from './pages/admin/PlanningBoard'
import LoginDestination from './components/auth/LoginDestination'
import Reports from './pages/admin/Reports'
import Incidents from './pages/Incidents'
import WorkAreas from './pages/admin/WorkAreas'
import {useOrganization} from './components/auth/OrganizationProvider'
import TaskCheckinMethodsConfig from './pages/admin/TaskCheckinMethodsConfig'
import { BrowserRouter, Routes, Route, Navigate, useLocation } from 'react-router-dom'
import { Toaster } from '@/components/ui/sonner'
import ProtectedRoute from '@/components/auth/ProtectedRoute'
import Login from './pages/Login'
import ResetPassword from './pages/ResetPassword'
import Overview from './pages/Overview'
import CheckinHistory from './pages/CheckinHistory'
import AdminDashboard from './pages/AdminDashboard'
import GPSLocations from './pages/admin/GPSLocations'
import TaskAccessManager from './pages/admin/TaskAccessManager'
import EmployeeManager from './pages/admin/EmployeeManager'
import EmployeeAbsences from './pages/admin/EmployeeAbsences'
import EmployeeWorkHome from './pages/EmployeeWorkHome'
import EmployeeCurrentWork from './pages/EmployeeCurrentWork'
import RoleManager from './pages/admin/RoleManager'
import Productivity from './pages/admin/Productivity'
import WorkdayManager from './pages/admin/WorkdayManager'
import WorkStation from './pages/WorkStation'
import EmployeeSettings from './pages/EmployeeSettings'
import TaskAccessLogin from './pages/employee/TaskAccessLogin'
import TaskDetailWithActions from './pages/employee/TaskDetailWithActions'
import NotFound from './pages/NotFound'
import NFCCardManager from './pages/admin/NFCCardManager'

function StationNavigation({ children }: { children: React.ReactNode }) {
  const location = useLocation()
  const configured = Boolean(sessionStorage.getItem('ase-work-station'))
  if (configured && location.pathname !== '/station') return <Navigate to="/station" replace />
  return <>{children}</>
}

function LegacyRedirect({to}: {to: string}) {const location=useLocation();return <Navigate to={to+location.search+location.hash} replace />}

function App() {
  const context=useOrganization()
  const scopeKey=context?.mode+':'+context?.user?.id+':'+context?.activeOrganizationId
  return (
    <BrowserRouter>
      <StationNavigation key={scopeKey}>
      <Routes>
        {/* ============================= */}
        {/*      RUTAS PÚBLICAS          */}
        {/* ============================= */}

        <Route path="/incidents" element={<ProtectedRoute><Incidents/></ProtectedRoute>}/>
        <Route path="/admin/team/areas" element={<ProtectedRoute requireAdmin><WorkAreas/></ProtectedRoute>}/>
        <Route path="/login" element={<Login />} />
        <Route path="/login/complete" element={<ProtectedRoute><LoginDestination /></ProtectedRoute>} />
        <Route path="/station" element={<WorkStation />} />
        <Route path="/admin" element={<ProtectedRoute requireAny={['tasks.view','planning.view','reports.view','checkins.view']}><Overview /></ProtectedRoute>} />
        <Route path="/admin/tasks" element={<ProtectedRoute requirePermission="tasks.view"><AdminDashboard /></ProtectedRoute>} />
        <Route path="/admin/planning/recurrences" element={<ProtectedRoute requirePermission="planning.view"><RecurringWork /></ProtectedRoute>} />
        <Route path="/admin/planning/board" element={<ProtectedRoute requirePermission="planning.view"><PlanningBoard /></ProtectedRoute>} />
        <Route path="/admin/planning" element={<ProtectedRoute requirePermission="planning.view"><WorkdayManager key="planning" /></ProtectedRoute>} />
        <Route path="/admin/checkins" element={<ProtectedRoute requirePermission="checkins.view"><CheckinHistory /></ProtectedRoute>} />
        <Route path="/admin/checkins/points" element={<ProtectedRoute requireAdmin><WorkdayManager key="points" section="points" /></ProtectedRoute>} />
        <Route path="/admin/reports" element={<ProtectedRoute requirePermission="reports.view"><Reports /></ProtectedRoute>} />
        <Route path="/admin/productivity" element={<ProtectedRoute requirePermission="reports.view"><Productivity /></ProtectedRoute>} />
        <Route path="/admin/team" element={<ProtectedRoute requireAdmin><EmployeeManager /></ProtectedRoute>} />
        <Route path="/admin/team/roles" element={<ProtectedRoute requireAdmin><RoleManager /></ProtectedRoute>} />
        <Route path="/admin/team/absences" element={<ProtectedRoute requireAdmin><EmployeeAbsences /></ProtectedRoute>} />
        <Route path="/admin/access" element={<ProtectedRoute requireAdmin><TaskAccessManager /></ProtectedRoute>} />
        <Route path="/admin/access/qr" element={<LegacyRedirect to="/admin/access" />} />
        <Route path="/admin/access/cards" element={<ProtectedRoute requireAdmin><WorkdayManager key="cards" section="cards" /></ProtectedRoute>} />
        <Route path="/admin/access/task-cards" element={<ProtectedRoute requireAdmin><NFCCardManager /></ProtectedRoute>} />
        <Route path="/admin/settings" element={<ProtectedRoute requireAdmin><GPSLocations /></ProtectedRoute>} />
        <Route path="/admin/settings/methods" element={<ProtectedRoute requireAdmin><TaskCheckinMethodsConfig /></ProtectedRoute>} />
        <Route path="/admin/settings/tablet" element={<ProtectedRoute requireAdmin><WorkdayManager key="rules" section="rules" /></ProtectedRoute>} />
        <Route path="/employee/history" element={<ProtectedRoute><CheckinHistory personal /></ProtectedRoute>} />
        <Route path="/admin/roles" element={<LegacyRedirect to="/admin/team/roles" />} />
        <Route path="/admin/workday" element={<LegacyRedirect to="/admin/planning" />} />
        <Route path="/reset-password" element={<ResetPassword />} />

        {/* Ruta de acceso con código único (pública) */}
        <Route path="/task-access/:accessCode" element={<TaskAccessLogin />} />

        {/* ============================= */}
        {/*      RUTAS DE ADMIN          */}
        {/* ============================= */}

        <Route path="/admin/employees" element={<LegacyRedirect to="/admin/team" />} />
        <Route path="/admin/qr-generator" element={<LegacyRedirect to="/admin/access/qr" />} />
        <Route path="/admin/gps-locations" element={<LegacyRedirect to="/admin/settings" />} />
        <Route path="/admin/task-access-manager" element={<LegacyRedirect to="/admin/access" />} />
        <Route path="/admin/checkin-methods" element={<LegacyRedirect to="/admin/settings/methods" />} />
        <Route path="/admin/nfc-cards" element={<LegacyRedirect to="/admin/access/task-cards" />} />
        {/* ============================= */}
        {/*     RUTAS DE EMPLEADO        */}
        {/* ============================= */}

        <Route
          path="/employee"
          element={
            <ProtectedRoute>
              <EmployeeCurrentWork />
            </ProtectedRoute>
          }
        />

        <Route path="/employee/tasks" element={<ProtectedRoute><EmployeeWorkHome /></ProtectedRoute>} />

        <Route
          path="/employee/settings"
          element={
            <ProtectedRoute>
              <EmployeeSettings />
            </ProtectedRoute>
          }
        />

        {/* Ruta para trabajar en la tarea (protegida) */}
        <Route
          path="/employee/task/:id/work"
          element={
            <ProtectedRoute>
              <TaskDetailWithActions />
            </ProtectedRoute>
          }
        />

        {/* ============================= */}
        {/*      RUTAS GENERALES         */}
        {/* ============================= */}

        <Route path="/" element={<Navigate to="/login" replace />} />
        <Route path="*" element={<NotFound />} />
      </Routes>
      </StationNavigation>

      <Toaster />
    </BrowserRouter>
  )
}

export default App
