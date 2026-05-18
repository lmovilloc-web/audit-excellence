# Supabase stack example

If your project uses Supabase, the agents pick up extra recipes automatically. Here's what they check.

## Detected by

Presence of any of:
- `supabase/` directory
- `@supabase/supabase-js` in `package.json`
- `supabase/config.toml`

## Extra checks per agent

### config-auditor
- Runs `supabase secrets list --project-ref <ref>` and cross-checks names against `Deno.env.get(...)` calls in every edge function.
- Verifies `supabase/config.toml` declares `verify_jwt` per function (any function whose value is non-default must be locked here, or CLI flips it on deploy).
- Confirms `schema_migrations` table matches local `supabase/migrations/*.sql` files via `npx supabase migration list --linked`.

### observability-auditor
- Queries `pg_policies` for RLS on `edge_function_errors`, `client_errors`. Must allow INSERT for any auth user; SELECT restricted to admin.
- Verifies the `is_superadmin()` helper exists if any policy references it.

### browser-auditor
- If `capacitor.config.ts` exists, confirms every edge function's `ALLOWED_ORIGINS` includes `capacitor://localhost` and `https://localhost`.

## Direct-SQL bypass when MCP is down

If your Supabase MCP server has an expired OAuth token, you can query directly using the CLI's stored Personal Access Token:

```bash
TOKEN=$(security find-generic-password -s "Supabase CLI" -w \
  | sed 's/go-keyring-base64://' | base64 -d)

curl -s -X POST "https://api.supabase.com/v1/projects/<ref>/database/query" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"SELECT now();"}'
```

The agents fall back to this automatically when MCP is unavailable.

## Recommended permanent setup

Switch your Supabase MCP server from OAuth to a Personal Access Token so it doesn't expire mid-session.

Generate a PAT at https://supabase.com/dashboard/account/tokens, then in your project's `.mcp.json`:

```json
{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": ["-y", "@supabase/mcp-server-supabase@latest", "--access-token", "<YOUR_PAT>"]
    }
  }
}
```

PATs don't expire (unless revoked) and support multiple concurrent Claude sessions without OAuth refresh races.
