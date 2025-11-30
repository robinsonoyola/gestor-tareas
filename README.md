# 🏨 Gestor de Tareas y Dashboard Administrativo

## 🎯 Descripción del Proyecto

Este es un proyecto de aplicación web diseñado para la **gestión eficiente de tareas** y la **administración de personal y recursos**, ideal para entornos como hoteles, servicios de mantenimiento o cualquier negocio con flujo de trabajo distribuido.

Construido sobre una pila tecnológica moderna, ofrece un **Dashboard Administrativo** completo para la creación, asignación, seguimiento y análisis de tareas, así como la gestión de empleados y la generación de elementos funcionales como códigos QR.

## ✨ Características Principales

- **Gestión de Tareas:** CRUD completo (Crear, Leer, Actualizar, Eliminar) de tareas con asignación a empleados.
- **Gestión de Empleados:** Administración de la base de datos de empleados y sus roles.
- **Estadísticas y Dashboard:** Uso de **Recharts** para visualizar métricas clave del rendimiento y el estado de las tareas.
- **Autenticación Segura:** Manejo de autenticación a través de **Supabase**.
- **Interfaces Modernas:** Componentes de interfaz de usuario limpios y accesibles gracias a **Shadcn/ui** (basado en Radix).
- **Códigos QR:** Generación de códigos QR (`qrcode.react`) para vincular tareas o ubicaciones específicas.

## ⚙️ Tecnologías Utilizadas

Este proyecto utiliza una pila de desarrollo robusta y actual:

| Categoría | Tecnología | Propósito |
| :--- | :--- | :--- |
| **Frontend** | **React 19** | Biblioteca principal para construir la interfaz de usuario. |
| **Build Tool** | **Vite** | Empaquetador y servidor de desarrollo rápido de última generación. |
| **Estilos** | **Tailwind CSS v4** | Framework CSS utility-first para un diseño rápido y responsivo. |
| **UI Components** | **Shadcn/ui (Radix)** | Componentes de interfaz sin estilo (headless) y accesibles. |
| **Base de Datos** | **Supabase** | Backend-as-a-Service para BD, autenticación y almacenamiento. |
| **Visualización** | **Recharts** | Librería declarativa de gráficos para dashboards. |
| **Routing** | **React Router DOM** | Manejo de navegación en la aplicación. |
| **Notificaciones** | **Sonner** | Componente moderno para notificaciones tipo *toast*. |

## 🚀 Instalación y Ejecución Local

Sigue estos pasos para configurar y ejecutar el proyecto en tu entorno local.

### 🔧 Prerrequisitos

- [Node.js](https://nodejs.org/) (versión LTS o superior)
- [Git](https://git-scm.com/)
- Una cuenta de **Supabase** y una base de datos configurada.

---

## 1. Clonar el Repositorio

```bash
git clone <URL_DEL_REPOSITORIO>
cd react
```

## 2. Instalación de Dependencias

```bash
npm install
```

## 3. Configuración de Variables de Entorno
Crea un archivo llamado .env en el directorio raíz del proyecto (/react) y añade tus credenciales de Supabase:
```bash
VITE_SUPABASE_URL="https://your-project-ref.supabase.co"
VITE_SUPABASE_ANON_KEY="your-anon-public-key"

```
## 4. Ejecución del Proyecto
```bash
npm run dev
```