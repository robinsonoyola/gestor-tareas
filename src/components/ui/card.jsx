import * as React from "react";
import { cn } from "@/lib/utils";
function Card({ className, ...props }) {
    return (<div data-slot="card" className={cn("bg-card text-card-foreground min-w-0 max-w-full flex flex-col gap-6 rounded-xl border py-6 shadow-sm", className)} {...props}/>);
}
function CardHeader({ className, ...props }) {
    return (<div data-slot="card-header" className={cn("@container/card-header grid auto-rows-min grid-rows-[auto_auto] min-w-0 items-start gap-2 px-4 sm:px-6 has-data-[slot=card-action]:grid-cols-[1fr_auto] [.border-b]:pb-6", className)} {...props}/>);
}
function CardTitle({ className, ...props }) {
    return (<div data-slot="card-title" className={cn("min-w-0 leading-snug font-semibold [overflow-wrap:anywhere]", className)} {...props}/>);
}
function CardDescription({ className, ...props }) {
    return (<div data-slot="card-description" className={cn("min-w-0 text-muted-foreground text-sm [overflow-wrap:anywhere]", className)} {...props}/>);
}
function CardAction({ className, ...props }) {
    return (<div data-slot="card-action" className={cn("col-start-2 row-span-2 row-start-1 self-start justify-self-end", className)} {...props}/>);
}
function CardContent({ className, ...props }) {
    return (<div data-slot="card-content" className={cn("min-w-0 px-4 sm:px-6", className)} {...props}/>);
}
function CardFooter({ className, ...props }) {
    return (<div data-slot="card-footer" className={cn("flex flex-wrap items-center gap-2 min-w-0 px-4 sm:px-6 [.border-t]:pt-6", className)} {...props}/>);
}
export { Card, CardHeader, CardFooter, CardTitle, CardAction, CardDescription, CardContent, };
