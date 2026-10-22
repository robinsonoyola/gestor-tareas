import * as React from "react";
import { Eye, EyeOff } from "lucide-react";
import { cn } from "@/lib/utils";
const Input = React.forwardRef(function Input({ className, type, ...props }, ref) {
    const [visible,setVisible] = React.useState(false)
    const inputType = type === 'password' && visible ? 'text' : type
    const field =
    (<input ref={ref} type={inputType} data-slot="input" className={cn("file:text-foreground placeholder:text-muted-foreground selection:bg-primary selection:text-primary-foreground dark:bg-input/30 border-input h-9 w-full min-w-0 rounded-md border bg-transparent px-3 py-1 text-base shadow-xs transition-[color,box-shadow] outline-none file:inline-flex file:h-7 file:border-0 file:bg-transparent file:text-sm file:font-medium disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50 md:text-sm", "focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]", "aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive", className, type === "password" && "pr-12")} {...props}/>);
    if (type !== 'password') return field
    return <span className="relative block min-w-0 w-full">{field}<button type="button" aria-label={visible ? 'Ocultar contraseña' : 'Mostrar contraseña'} aria-pressed={visible} disabled={props.disabled} onClick={()=>setVisible(value=>!value)} className="absolute right-2 top-1/2 -translate-y-1/2 p-1 text-gray-600 hover:text-gray-900 disabled:opacity-50">{visible ? <EyeOff size={18}/> : <Eye size={18}/>}</button></span>
});
export { Input };
