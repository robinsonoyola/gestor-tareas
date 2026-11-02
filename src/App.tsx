import { lazy, Suspense } from "react";
import LoginDestination from "./components/auth/LoginDestination";
import { useOrganization } from "./components/auth/OrganizationProvider";
import {
  BrowserRouter,
  Routes,
  Route,
  Navigate,
  useLocation,
} from "react-router-dom";
import { Toaster } from "@/components/ui/sonner";
import ProtectedRoute from "@/components/auth/ProtectedRoute";
import RouteErrorBoundary from "@/components/auth/RouteErrorBoundary";
import Login from "./pages/Login";
import ResetPassword from "./pages/ResetPassword";
import NotFound from "./pages/NotFound";

const RecurringWork = lazy(() => import("./pages/admin/RecurringWork"));
const PlanningBoard = lazy(() => import("./pages/admin/PlanningBoard"));
const Reports = lazy(() => import("./pages/admin/Reports"));
const Incidents = lazy(() => import("./pages/Incidents"));
const WorkAreas = lazy(() => import("./pages/admin/WorkAreas"));
const TaskCheckinMethodsConfig = lazy(() => import("./pages/admin/TaskCheckinMethodsConfig"));
const Overview = lazy(() => import("./pages/Overview"));
const CheckinHistory = lazy(() => import("./pages/CheckinHistory"));
const AdminDashboard = lazy(() => import("./pages/AdminDashboard"));
const GPSLocations = lazy(() => import("./pages/admin/GPSLocations"));
const TaskAccessManager = lazy(() => import("./pages/admin/TaskAccessManager"));
const EmployeeManager = lazy(() => import("./pages/admin/EmployeeManager"));
const AdminEmployeeAbsences = lazy(() => import("./pages/admin/EmployeeAbsences"));
const EmployeeWorkHome = lazy(() => import("./pages/EmployeeWorkHome"));
const EmployeeCurrentWork = lazy(() => import("./pages/EmployeeCurrentWork"));
const EmployeeAbsences = lazy(() => import("./pages/EmployeeAbsences"));
const RoleManager = lazy(() => import("./pages/admin/RoleManager"));
const WorkdayManager = lazy(() => import("./pages/admin/WorkdayManager"));
const TeamCalendar = lazy(() => import("./pages/admin/TeamCalendar"));
const WorkStation = lazy(() => import("./pages/WorkStation"));
const EmployeeSettings = lazy(() => import("./pages/EmployeeSettings"));
const TaskAccessLogin = lazy(() => import("./pages/employee/TaskAccessLogin"));
const TaskDetailWithActions = lazy(() => import("./pages/employee/TaskDetailWithActions"));
const NFCCardManager = lazy(() => import("./pages/admin/NFCCardManager"));

function RouteLoading() {
  return <div role="status" className="min-h-screen bg-background p-6 text-foreground">Cargando ASE Work…</div>;
}

function StationNavigation({ children }: { children: React.ReactNode }) {
  const location = useLocation();
  const configured = Boolean(sessionStorage.getItem("ase-work-station"));
  if (configured && location.pathname !== "/station")
    return <Navigate to="/station" replace />;
  return <>{children}</>;
}

function LegacyRedirect({ to }: { to: string }) {
  const location = useLocation();
  return <Navigate to={to + location.search + location.hash} replace />;
}

function App() {
  const context = useOrganization();
  const scopeKey =
    context?.mode +
    ":" +
    context?.user?.id +
    ":" +
    context?.activeOrganizationId;
  return (
    <BrowserRouter>
      <StationNavigation key={scopeKey}>
        <RouteErrorBoundary key={scopeKey}>
        <Suspense fallback={<RouteLoading />}>
        <Routes>
          {/* ============================= */}
          {/*      RUTAS PÚBLICAS          */}
          {/* ============================= */}

          <Route
            path="/incidents"
            element={
              <ProtectedRoute>
                <Incidents />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/team/areas"
            element={
              <ProtectedRoute requireAdmin>
                <WorkAreas />
              </ProtectedRoute>
            }
          />
          <Route path="/login" element={<Login />} />
          <Route
            path="/login/complete"
            element={
              <ProtectedRoute>
                <LoginDestination />
              </ProtectedRoute>
            }
          />
          <Route path="/station" element={<WorkStation />} />
          <Route
            path="/admin"
            element={
              <ProtectedRoute
                requireAny={[
                  "tasks.view",
                  "planning.view",
                  "reports.view",
                  "checkins.view",
                ]}
              >
                <Overview />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/tasks"
            element={
              <ProtectedRoute requirePermission="tasks.view">
                <AdminDashboard />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/planning/recurrences"
            element={
              <ProtectedRoute requirePermission="planning.view">
                <RecurringWork />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/planning/board"
            element={
              <ProtectedRoute requirePermission="planning.view">
                <PlanningBoard />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/planning/team-calendar"
            element={
              <ProtectedRoute requirePermission="planning.view">
                <TeamCalendar />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/planning"
            element={
              <ProtectedRoute requirePermission="planning.view">
                <WorkdayManager key="planning" />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/checkins"
            element={
              <ProtectedRoute requirePermission="checkins.view">
                <CheckinHistory />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/checkins/points"
            element={
              <ProtectedRoute requireAdmin>
                <WorkdayManager key="points" section="points" />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/reports"
            element={
              <ProtectedRoute requirePermission="reports.view">
                <Reports />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/productivity"
            element={
              <ProtectedRoute requirePermission="reports.view">
                <Navigate
                  to="/admin/reports?kind=productivity&mode=charts"
                  replace
                />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/team"
            element={
              <ProtectedRoute requireAdmin>
                <EmployeeManager />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/team/roles"
            element={
              <ProtectedRoute requireAdmin>
                <RoleManager />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/team/absences"
            element={
              <ProtectedRoute requireAdmin>
                <AdminEmployeeAbsences />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/access"
            element={
              <ProtectedRoute requireAdmin>
                <TaskAccessManager />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/access/qr"
            element={<LegacyRedirect to="/admin/access" />}
          />
          <Route
            path="/admin/access/cards"
            element={
              <ProtectedRoute requireAdmin>
                <WorkdayManager key="cards" section="cards" />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/access/task-cards"
            element={
              <ProtectedRoute requireAdmin>
                <NFCCardManager />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/settings"
            element={
              <ProtectedRoute requireAdmin>
                <GPSLocations />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/settings/methods"
            element={
              <ProtectedRoute requireAdmin>
                <TaskCheckinMethodsConfig />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/settings/tablet"
            element={
              <ProtectedRoute requireAdmin>
                <WorkdayManager key="rules" section="rules" />
              </ProtectedRoute>
            }
          />
          <Route
            path="/employee/history"
            element={
              <ProtectedRoute>
                <CheckinHistory personal />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/roles"
            element={<LegacyRedirect to="/admin/team/roles" />}
          />
          <Route
            path="/admin/workday"
            element={<LegacyRedirect to="/admin/planning" />}
          />
          <Route path="/reset-password" element={<ResetPassword />} />

          {/* Ruta de acceso con código único (pública) */}
          <Route
            path="/task-access/:accessCode"
            element={<TaskAccessLogin />}
          />

          {/* ============================= */}
          {/*      RUTAS DE ADMIN          */}
          {/* ============================= */}

          <Route
            path="/admin/employees"
            element={<LegacyRedirect to="/admin/team" />}
          />
          <Route
            path="/admin/qr-generator"
            element={<LegacyRedirect to="/admin/access/qr" />}
          />
          <Route
            path="/admin/gps-locations"
            element={<LegacyRedirect to="/admin/settings" />}
          />
          <Route
            path="/admin/task-access-manager"
            element={<LegacyRedirect to="/admin/access" />}
          />
          <Route
            path="/admin/checkin-methods"
            element={<LegacyRedirect to="/admin/settings/methods" />}
          />
          <Route
            path="/admin/nfc-cards"
            element={<LegacyRedirect to="/admin/access/task-cards" />}
          />
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

          <Route
            path="/employee/tasks"
            element={
              <ProtectedRoute>
                <EmployeeWorkHome />
              </ProtectedRoute>
            }
          />
          <Route
            path="/employee/absences"
            element={
              <ProtectedRoute>
                <EmployeeAbsences />
              </ProtectedRoute>
            }
          />

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
        </Suspense>
        </RouteErrorBoundary>
      </StationNavigation>

      <Toaster />
    </BrowserRouter>
  );
}

export default App;
