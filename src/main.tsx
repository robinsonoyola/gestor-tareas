import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import OrganizationProvider from './components/auth/OrganizationProvider'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <OrganizationProvider><App /></OrganizationProvider>
  </StrictMode>,
)
