import { cn } from '@/lib/utils'

export const sectionTabsClass = 'flex flex-wrap gap-2 rounded-xl border border-blue-200 bg-gradient-to-r from-blue-50 via-indigo-50 to-sky-50 p-2 shadow-sm'

export function sectionTabClass(active, className = '') {
  return cn(
    'border px-4 py-2 font-semibold transition-all',
    active
      ? '!border-blue-700 !bg-gradient-to-r !from-blue-600 !to-indigo-600 !text-white shadow-md ring-2 ring-blue-200'
      : '!border-blue-200 !bg-white/90 !text-blue-800 shadow-sm hover:!border-blue-400 hover:!bg-blue-100 hover:!text-blue-950',
    className,
  )
}

