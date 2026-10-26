import { cn } from '@/lib/utils'

export const sectionTabsClass = 'ase-section-tabs flex flex-wrap gap-2 rounded-xl border p-2 shadow-sm'

export function sectionTabClass(active, className = '') {
  return cn(
    'border px-4 py-2 font-semibold transition-all',
    active
      ? '!border-blue-400 !bg-gradient-to-r !from-blue-600 !to-indigo-500 !text-white shadow-lg ring-2 ring-blue-400/25'
      : '!border-slate-600 !bg-slate-900/70 !text-slate-200 shadow-sm hover:!border-blue-400 hover:!bg-blue-950/70 hover:!text-white',
    className,
  )
}
