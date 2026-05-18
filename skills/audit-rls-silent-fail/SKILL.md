---
name: audit-rls-silent-fail
description: Find Supabase / PostgREST .delete() / .update() / .insert() calls that don't check the result count, which lets RLS silently drop the operation. Catches the "button does nothing, no error" class of bug.
---

# Skill: audit-rls-silent-fail

## When to use

- During observability audit.
- After a user reports "I clicked X but nothing happened, no error."
- Before launch.

## The bug we're preventing

```ts
// BAD — RLS denies the delete, returns no error, no rows changed
await supabase.from('files').delete().eq('id', fileId)

// GOOD — { count: 'exact' } reports row count; we react if 0
const { error, count } = await supabase.from('files')
  .delete({ count: 'exact' }).eq('id', fileId)
if (error) toast.error(error.message)
if (count === 0) toast.error('Nothing was deleted (permissions?)')
```

PostgREST returns `204 No Content` for a delete that matched 0 rows — the supabase-js client treats it as success. Without `count: 'exact'`, you can't tell.

Same applies to `.update()` and (in some PostgREST configs) `.insert()`.

## How to run

1. **Find all writes.**
   ```bash
   grep -rEn "\.from\([^)]+\)\.(delete|update|insert)\(" src/ | head -100
   ```

2. **For each match, check the next 3-5 lines** for:
   - `count: 'exact'` in the call, AND
   - A check on the returned `count` (or `data.length`).

3. **Flag any that don't check.** They are silent-failure landmines.

## Output

```
RLS silent-fail audit
Writes scanned: 47
Vulnerable: 6

src/pages/teacher/TeacherStudentDetailPage.tsx:143
  await supabase.from('bake_context').delete().eq('id', fileId)
  → Fix: add { count: 'exact' } + check count

src/components/EditProfile.tsx:88
  await supabase.from('profiles').update({ ... }).eq('id', userId)
  → Fix: capture { data } and assert data.length > 0
...
```

## Why this matters

A teacher clicks "delete file" and nothing happens. No toast, no console error, no SQL row deleted. They blame the app. The actual cause: an RLS policy that doesn't allow this user, this row, this verb — PostgREST returns success and the frontend treats it as success.

## Token budget

~250 tokens prompt + bounded grep. Total: under 1k.
