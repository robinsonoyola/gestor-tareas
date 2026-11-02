// supabase/functions/_shared/tenant.ts
import { createClient } from "npm:@supabase/supabase-js@2.47.10";
function cors(request) {
  const origin = request.headers.get("origin");
  const allowed = (Deno.env.get("ALLOWED_ORIGINS") || "").split(",").map((value) => value.trim()).filter(Boolean);
  if (origin && !allowed.includes(origin)) throw new Error("Origen no autorizado");
  return {
    "Access-Control-Allow-Origin": origin || "null",
    "Vary": "Origin",
    "Access-Control-Allow-Headers": "authorization,apikey,content-type,x-client-info,x-ase-organization-id",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Content-Type": "application/json"
  };
}
async function adminContext(request) {
  const url = Deno.env.get("SUPABASE_URL");
  const anon = Deno.env.get("SUPABASE_ANON_KEY");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !anon || !key) throw new Error("Configuraci\xF3n incompleta del servicio");
  const authorization = request.headers.get("authorization") || "";
  if (!authorization.startsWith("Bearer ")) throw new Error("Inicia sesi\xF3n");
  const headers = { Authorization: authorization };
  const organization = request.headers.get("x-ase-organization-id");
  if (organization) headers["x-ase-organization-id"] = organization;
  const caller = createClient(url, anon, { global: { headers }, auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false } });
  const { data: identity, error: identityError } = await caller.auth.getUser(authorization.slice(7));
  if (identityError || !identity.user) throw new Error("Sesi\xF3n no v\xE1lida");
  const { data: context, error: contextError } = await caller.rpc("mt_context");
  if (contextError || !context?.active_organization_id || !context.profile?.is_admin) throw new Error("No tienes permiso de administraci\xF3n en esta empresa");
  const service = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false } });
  return { caller, service, actor: identity.user.id, organization: context.active_organization_id, url, anon };
}
function reply(headers, status, body) {
  return new Response(JSON.stringify(body), { status, headers });
}

// supabase/functions/update-employee-email/index.ts
Deno.serve(async (request) => {
  let headers;
  try {
    headers = cors(request);
  } catch {
    return new Response("Origen no autorizado", { status: 403 });
  }
  if (request.method === "OPTIONS") return new Response(null, { status: 204, headers });
  if (request.method !== "POST") return reply(headers, 405, { error: "M\xE9todo no permitido" });
  let service, grantId;
  try {
    const context = await adminContext(request);
    service = context.service;
    const body = await request.json();
    const reserved = await context.caller.rpc("mt_prepare_email_change", { p_user: body.userId, p_email: String(body.email || "").trim().toLowerCase() });
    if (reserved.error) throw new Error(reserved.error.message);
    grantId = reserved.data;
    const target = await service.rpc("mt_email_change_grant", { p_id: grantId });
    if (target.error) throw new Error("Solicitud no disponible");
    const changed = await service.auth.admin.updateUserById(target.data.user_id, { email: target.data.email });
    if (changed.error || changed.data.user?.email?.toLowerCase() !== target.data.email) throw new Error("No se confirm\xF3 el cambio de correo");
    return reply(headers, 200, { success: true });
  } catch (error) {
    return reply(headers, 403, { error: error.message || "No se pudo cambiar el correo" });
  } finally {
    if (service && grantId) await service.rpc("mt_finish_email_change", { p_id: grantId });
  }
});
