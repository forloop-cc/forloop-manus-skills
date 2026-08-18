# Troubleshooting Guide

Diagnosis and remediation for common failure scenarios. Load this when a CLI command fails, auth is missing, or the environment isn't working as expected.

## Table of Contents

1. [Auth Issues](#auth-issues)
2. [CLI Not Installed / Not Found](#cli-not-installed)
3. [Runtime Install Failed](#runtime-install-failed)
4. [Missing Node.js or npm](#missing-nodejs-or-npm)
5. [Quota Errors](#quota-errors)
6. [Space Context Missing](#space-context-missing)
7. [Sync Failures](#sync-failures)
8. [Exit Code Reference](#exit-code-reference)

---

## Auth Issues

### Symptom: "Not authenticated" from `forloop auth status`

```
$ forloop auth status
Not authenticated
```

**Remediation:**
```bash
forloop auth login --api-key floop_xxxxx
```

- Token source: [forloop.cc/profile?tab=api-tokens](https://forloop.cc/profile?tab=api-tokens)
- Tokens start with `floop_`
- Required scopes: `sprint:read`, `sprint:write`, `story:read`, `story:write`, `agent:query`, `profile:read`

**If the user doesn't have a token:**
1. Go to [forloop.cc/profile?tab=api-tokens](https://forloop.cc/profile?tab=api-tokens)
2. Create a new token with the scopes listed above
3. Copy the token (it starts with `floop_`)
4. Run `forloop auth login --api-key floop_xxxxx`

### Symptom: Exit code 3 from any CLI command

Exit code 3 means "Not authenticated" on API calls. Run `forloop auth login` as above.

### Symptom: `forloop auth status` shows authenticated but commands fail

The token may have expired or been revoked. Regenerate:
1. Delete the old token at the profile page
2. Create a new token
3. Re-authenticate

---

## CLI Not Installed

### Symptom: `command -v forloop` returns nothing

```
$ which forloop
forloop not found
```

**If npm is available:**
```bash
npm install -g @forloop-cc/forloop-cli
forloop --version
forloop auth status
```

**If npm is NOT available:** See [Missing Node.js or npm](#missing-nodejs-or-npm).

### Symptom: `forloop` command exists but doesn't work

```bash
forloop --version   # Check if it runs
which forloop       # Check if it's the right binary
npm list -g @forloop-cc/forloop-cli  # Check npm install
```

Try reinstalling:
```bash
npm uninstall -g @forloop-cc/forloop-cli
npm install -g @forloop-cc/forloop-cli
```

---

## Runtime Install Failed

### Symptom: `npm install -g @forloop-cc/forloop-cli` fails

**Check network:**
```bash
npm ping
curl -s https://registry.npmjs.org/ | head -1
```

**Check npm config:**
```bash
npm config get registry
```

If the registry is incorrect or unreachable:
```bash
npm config set registry https://registry.npmjs.org/
```

**Check permissions (Linux/Mac):**
If you see `EACCES` or permission errors, the global npm directory may need fixing. Try:
```bash
npm install -g @forloop-cc/forloop-cli --unsafe-perm
```

**Fallback:** If runtime install repeatedly fails, switch to guidance-only mode.

---

## Missing Node.js or npm

### Symptom: `command -v node` returns nothing, or `command -v npm` returns nothing

**Install Node.js (includes npm):**

Recommended: Use a version manager or official installer.
- [nodejs.org](https://nodejs.org/) — Download the LTS version
- Or use nvm: `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash`

**Verify after install:**
```bash
node --version   # Should be >= 18
npm --version    # Should be >= 9
```

**Then install ForLoop CLI:**
```bash
npm install -g @forloop-cc/forloop-cli
forloop --version
forloop auth login --api-key floop_xxxxx
```

---

## Quota Errors

### Symptom: Exit code 4 from any CLI command

Exit code 4 means the user's ForLoop tier limit has been reached.

**Check current usage:**
```bash
forloop user quotas --output json --non-interactive
```

**Remediation options:**
1. **Upgrade tier** at [forloop.cc/billing](https://forloop.cc/billing)
2. **Wait for quota reset** (monthly on billing cycle)
3. **Reduce scope** — fewer stories, smaller space

**Important:** Do not try to work around quota limits. If the user cannot create stories or upload files due to quota, planning can continue in guidance-only mode, but CLI mutation commands will fail.

---

## Space Context Missing

### Symptom: No `~/.forloop/manifest.json` or manifest has no active space

**Step 1: List available orgs and spaces**
```bash
forloop org list --output json --non-interactive
forloop space-sprint list --output json --non-interactive
```

**Step 2: If org exists but no space, create one**
```bash
forloop space-sprint create \
  --title "Space N" \
  --start-date YYYY-MM-DD \
  --end-date YYYY-MM-DD \
  --org-id N \
  --output json --non-interactive
```

**Step 3: If no org exists, guide user to create one**
```bash
forloop org create --name "My Organization" --output json --non-interactive
```

Or create via the web app at [forloop.cc/organizations](https://forloop.cc/organizations).

### Symptom: Space ID auto-detection fails

Auto-detection works via `FORLOOP_SPRINT_ID` env var or git branch name (`sprint-14`).

If auto-detection fails, pass `--sprint` or `--id` explicitly:
```bash
forloop space-sprint get --id 14 --output json --non-interactive
forloop space-sprint get --sprint 14 --output json --non-interactive
```

### Symptom: Space exists but commands fail with "space not found"

The space may have been deleted or the user may not have access. Verify:
```bash
forloop space-sprint list --output json --non-interactive | jq '.[] | {id, title, status}'
```

---

## Sync Failures

### Symptom: `forloop sync aivy-folder` fails

**Check auth first:**
```bash
forloop auth status
```

**Check space context:**
```bash
forloop space-sprint get --output json --non-interactive | jq '{id, title}'
```

**If both are correct:** The doc folder may already exist but in an unexpected state. Try specifying a title:
```bash
forloop sync aivy-folder --sprint 14 --title "Aivy Plan Doc" --output json --non-interactive
```

### Symptom: `forloop sync s3-to-local` fails or returns empty

**Possible causes:**
1. No files exist in S3 for this space yet (expected for new spaces)
2. Auth token doesn't have read scope
3. Space ID is wrong

**Check:**
```bash
forloop file list --sprint 14 --output json --non-interactive
```

If no files are listed, there's nothing to sync — this is normal for new spaces.

### Symptom: `forloop sync aivy-doc-get` returns null or empty docFolderId

```bash
DOC_ID=$(forloop sync aivy-doc-get --output json --non-interactive | jq -r '.docFolderId')
if [ -z "$DOC_ID" ] || [ "$DOC_ID" = "null" ]; then
  echo "Doc folder not found — creating it"
  forloop sync aivy-folder --output json --non-interactive
  DOC_ID=$(forloop sync aivy-doc-get --output json --non-interactive | jq -r '.docFolderId')
fi
```

### Symptom: `forloop sync local-to-s3` fails with "file not found"

The local file path must exist. Verify:
```bash
ls -la ~/.forloop/sprint-14/plan/sprint-plan.md
```

If the file doesn't exist, write it first before uploading.

### Symptom: Upload succeeded but file doesn't appear in `forloop file list`

1. Check if you're looking at the right space: `--sprint N`
2. S3 may have eventual consistency — wait a moment and retry
3. Check the upload exit code — it may have returned 0 but the upload failed silently

---

## Exit Code Reference

| Code | Meaning | Immediate Action |
|------|---------|-----------------|
| 0 | Success | Continue |
| 1 | General error | Read the error message, determine cause |
| 2 | Invalid arguments | Check command syntax, flag names, required flags |
| 3 | Not authenticated | User must run `forloop auth login --api-key floop_xxxxx` |
| 4 | Quota exceeded | User must upgrade tier or wait for reset |
| 5 | Not found | Space, story, or file doesn't exist — check IDs |
| 6 | Permission denied | User doesn't have access to this resource |
| 7 | Validation error | Input data doesn't meet requirements |
| 8+ | Internal/server error | Retry; if persistent, check ForLoop status or contact support |

### How to Check Exit Codes

Always capture the exit code after every command:
```bash
RESULT=$(forloop space-sprint get --output json --non-interactive 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  case $EXIT_CODE in
    3) echo "AUTH ERROR: Please run: forloop auth login --api-key floop_xxxxx" ;;
    4) echo "QUOTA EXCEEDED: Your tier limit has been reached." ;;
    *) echo "ERROR (exit $EXIT_CODE): $RESULT" ;;
  esac
  # Stop — do not continue with a failed command
fi
echo "$RESULT" | jq '.'
```

---

## Recovery Decision Tree

```
Command fails
  │
  ├─ Check exit code
  │   ├─ 3 → Auth issue → forloop auth login
  │   ├─ 4 → Quota issue → user upgrades or waits
  │   └─ Other → Read error message
  │
  ├─ Command not found?
  │   ├─ npm available → npm install -g @forloop-cc/forloop-cli
  │   └─ npm missing → install Node.js, then install CLI
  │
  ├─ Auth status check
  │   ├─ "Not authenticated" → forloop auth login
  │   └─ Authenticated → check space context
  │
  ├─ Space context?
  │   ├─ No manifest → list orgs/spaces, user selects
  │   ├─ Wrong space → fix with --sprint N
  │   └─ Correct → retry command
  │
  └─ Still failing after all checks?
      └─ Switch to guidance-only mode
         Tell user what went wrong and what needs to happen
```

---

## Prevention Checklist

Run these before starting work to catch common issues early:

- [ ] `forloop --version` returns a version (CLI is installed)
- [ ] `forloop auth status` does not say "Not authenticated"
- [ ] `forloop space-sprint get --output json --non-interactive` returns space data (space context exists)
- [ ] `forloop user quotas --output json --non-interactive` shows available quota (not at limit)
- [ ] `jq --version` returns a version (JSON parser available)
- [ ] `~/.forloop/` directory exists and is writable
