---
name: verify-migration
description: Verify a migration claimed "applied" actually ran. Queries the database for the new objects (tables, columns, RPCs, policies) instead of trusting the operator's word. Use after every migration, never skip.
---

# Skill: verify-migration

## When to use

- Immediately after running `supabase db push` / `prisma migrate deploy` / equivalent.
- When someone says "applied" or "migration done" — verify before continuing.
- During audit, to confirm `schema_migrations` matches local files.

## The bug we're preventing

Operator says "I applied the migration." Reality: only one of three migrations ran. The other two silently no-op'd or errored. Downstream code that depends on the missing tables/RPCs fails in production days later.

## How to run

### Supabase / PostgreSQL

1. **Get the list of expected objects** from the migration file:
   ```bash
   grep -E "^CREATE (TABLE|FUNCTION|POLICY|INDEX|TYPE)" supabase/migrations/<file>.sql
   ```

2. **For each, query the DB to confirm it exists.**

   Tables:
   ```sql
   SELECT table_name FROM information_schema.tables
   WHERE table_schema = 'public' AND table_name IN ('<expected>', '<expected2>');
   ```

   Functions/RPCs:
   ```sql
   SELECT proname FROM pg_proc WHERE proname IN ('<expected>');
   ```

   Policies:
   ```sql
   SELECT policyname, cmd FROM pg_policies
   WHERE schemaname = 'public' AND tablename = '<table>';
   ```

   Columns:
   ```sql
   SELECT column_name FROM information_schema.columns
   WHERE table_schema = 'public' AND table_name = '<table>'
     AND column_name IN ('<col1>', '<col2>');
   ```

3. **Compare expected vs actual.** Anything in expected but not in actual = migration didn't fully apply.

4. **Check `schema_migrations`** (the tracking table):
   ```sql
   SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 5;
   ```
   Confirm the migration's timestamp prefix is in the list.

### How to query when MCP is down

Supabase CLI stores a Personal Access Token in macOS Keychain. You can use it directly:

```bash
TOKEN=$(security find-generic-password -s "Supabase CLI" -w \
  | sed 's/go-keyring-base64://' | base64 -d)

curl -s -X POST "https://api.supabase.com/v1/projects/<ref>/database/query" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"SELECT ..."}'
```

This bypasses the MCP server's OAuth (which expires) entirely.

## Output

```
Migration verify: 20260518060503_rate_limit_buckets.sql

Expected:
  TABLE rate_limit_buckets — ✅ exists
  FUNCTION check_and_increment_rate — 🔴 NOT FOUND
  FUNCTION rate_limit_buckets_cleanup — 🔴 NOT FOUND
  INDEX rate_limit_buckets_window_idx — ✅ exists

schema_migrations:
  20260518060503 — ✅ marked applied

DIAGNOSIS: Migration tracked as applied but only the TABLE and INDEX
created — the FUNCTIONS are missing. The file was likely run partially
(error mid-script) or the FUNCTION definitions have syntax errors.

ACTION: Re-run the function-creation SQL manually, then verify again.
```

## Anti-patterns

- Trusting `supabase migration list --linked` alone — it only tracks the *file*, not the *contents*.
- Skipping verification because "the script returned 0" — Postgres `CREATE FUNCTION ... AS $$ ... $$` can succeed with semantic errors that surface only on first call.

## Token budget

~300 tokens. SQL queries return small result sets. Total: under 1k.
