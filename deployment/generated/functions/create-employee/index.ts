// supabase/functions/create-employee/index.ts
import { createClient as createClient2 } from "npm:@supabase/supabase-js@2.47.10";

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

// supabase/functions/create-employee/index.ts
Deno.serve(async (request) => {
  let headers;
  try {
    headers = cors(request);
  } catch {
    return new Response("Origen no autorizado", { status: 403 });
  }
  if (request.method === "OPTIONS") return new Response(null, { status: 204, headers });
  if (request.method !== "POST") return reply(headers, 405, { error: "M\xE9todo no permitido" });
  let accountCreated = false;
  try {
    const { caller, service, actor, organization, url, anon } = await adminContext(request);
    const body = await request.json();
    const name = String(body.full_name || "").trim(), email = String(body.email || "").trim().toLowerCase(), password = String(body.password || "");
    const whatsapp = body.whatsapp || null, role = body.role_id || null;
    if (!name || name.length > 150 || !email || email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || password.length < 8 || password.length > 1024) throw new Error("Revisa los datos del empleado");
    if (whatsapp && !/^\+?[0-9]{7,15}$/.test(whatsapp)) throw new Error("WhatsApp no v\xE1lido");
    const roles = await caller.rpc("work_roles_overview");
    if (roles.error || role && !roles.data.roles.some((item) => item.id === role && item.active)) throw new Error("Rol no disponible");
    const exists = await service.rpc("mt_identity_email_exists", { p_email: email });
    if (exists.error) throw new Error("No se pudo comprobar el correo");
    if (exists.data) throw new Error("Ese correo ya tiene una cuenta. No se modific\xF3 su identidad");
    const nonce = crypto.randomUUID();
    const signup = createClient2(url, anon, { auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false } });
    const created = await signup.auth.signUp({ email, password, options: { data: { full_name: name, ase_onboarding_nonce: nonce } } });
    if (created.error || !created.data.user?.id) throw new Error("No se pudo crear la cuenta de acceso");
    const verified = await service.auth.admin.getUserById(created.data.user.id);
    if (verified.error || verified.data.user?.user_metadata?.ase_onboarding_nonce !== nonce) throw new Error("No se confirm\xF3 una cuenta nueva");
    accountCreated = true;
    const saved = await service.rpc("mt_attach_created_employee", { p_actor: actor, p_org: organization, p_user: created.data.user.id, p_nonce: nonce, p_name: name, p_whatsapp: whatsapp, p_role: role });
    if (saved.error) throw new Error("No se confirm\xF3 el perfil del empleado");
    return reply(headers, 200, { success: true, employee: saved.data, confirmationRequired: !created.data.user.email_confirmed_at && !created.data.session });
  } catch (error) {
    return reply(headers, accountCreated ? 409 : 403, { error: accountCreated ? "La cuenta se cre\xF3 pero no se confirm\xF3 su pertenencia. No repitas el alta; requiere revisi\xF3n." : error.message, code: accountCreated ? "EMPLOYEE_PROFILE_INCOMPLETE" : "EMPLOYEE_CREATE_REJECTED" });
  }
});
