import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from '@/components/ui/sonner';
import ProtectedRoute from '@/components/auth/ProtectedRoute';
import Login from './pages/Login';
import AdminDashboard from './pages/AdminDashboard';
import QRGenerator from './pages/admin/QRGenerator';
import GPSLocations from './pages/admin/GPSLocations';
import TaskAccessManager from './pages/admin/TaskAccessManager';
import EmployeeManager from './pages/admin/EmployeeManager';
import EmployeeDashboard from './pages/EmployeeDashboard';
import EmployeeSettings from './pages/EmployeeSettings';
import TaskAccessLogin from './pages/employee/TaskAccessLogin';
import TaskDetailWithActions from './pages/employee/TaskDetailWithActions';
import NotFound from './pages/NotFound';
function App() {
    return (<BrowserRouter>
      <Routes>
        {/* ============================= */}
        {/*      RUTAS PÚBLICAS          */}
        {/* ============================= */}
        
        <Route path="/login" element={<Login />}/>
        
        {/* Ruta de acceso con código único (pública) */}
        <Route path="/task-access/:accessCode" element={<TaskAccessLogin />}/>
        
        {/* ============================= */}
        {/*      RUTAS DE ADMIN          */}
        {/* ============================= */}
        
        <Route path="/admin" element={<ProtectedRoute requireAdmin={true}>
              <AdminDashboard />
            </ProtectedRoute>}/>

        <Route path="/admin/employees" element={<ProtectedRoute requireAdmin={true}>
              <EmployeeManager />
            </ProtectedRoute>}/>

        <Route path="/admin/qr-generator" element={<ProtectedRoute requireAdmin={true}>
              <QRGenerator />
            </ProtectedRoute>}/>

        <Route path="/admin/gps-locations" element={<ProtectedRoute requireAdmin={true}>
              <GPSLocations />
            </ProtectedRoute>}/>

        <Route path="/admin/task-access-manager" element={<ProtectedRoute requireAdmin={true}>
              <TaskAccessManager />
            </ProtectedRoute>}/>
        
        {/* ============================= */}
        {/*     RUTAS DE EMPLEADO        */}
        {/* ============================= */}
        
        <Route path="/employee" element={<ProtectedRoute>
              <EmployeeDashboard />
            </ProtectedRoute>}/>

        <Route path="/employee/settings" element={<ProtectedRoute>
              <EmployeeSettings />
            </ProtectedRoute>}/>

        {/* Ruta para trabajar en la tarea (protegida) */}
        <Route path="/employee/task/:id/work" element={<ProtectedRoute>
              <TaskDetailWithActions />
            </ProtectedRoute>}/>
        
        {/* ============================= */}
        {/*      RUTAS GENERALES         */}
        {/* ============================= */}
        
        <Route path="/" element={<Navigate to="/login" replace/>}/>
        <Route path="*" element={<NotFound />}/>
      </Routes>
      
      <Toaster />
    </BrowserRouter>);
}
export default App;
