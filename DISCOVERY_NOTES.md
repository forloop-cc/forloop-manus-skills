# Discovery Notes — Manus Runtime Validation

> **Status:** Blocking verification pending — authored package, but real Manus sandbox validation has not been completed yet
>
> This file captures findings from Phase 1 discovery tasks. Each section corresponds to an unknown identified in the development plan.
>
> **Important:** The current `forloop-planner` skill package should be treated as **design-complete but runtime-unverified** until the sections below are filled with actual Manus test results.
>
> **Current release posture:** Safe to review and iterate on as a package. Not yet safe to claim as proven for CLI-backed execution in Manus.

## 1. Skill Package Shape

**Question:** Does Manus expect `SKILL.md` at repo root? How are `references/`, `scripts/`, and `templates/` loaded?

**Finding:** _TBD — test with folder import and GitHub import_

**Confirmed constraints:** _TBD_

---

## 2. CLI Runtime Feasibility

**Question:** Can a Manus sandbox install and run `@forloop-cc/forloop-cli`?

**Runtime install path tested:**
```bash
command -v forloop     # TBD
command -v node        # TBD
command -v npm         # TBD
npm install -g @forloop-cc/forloop-cli   # TBD
forloop --version      # TBD
```

**Findings:** _TBD_

- Is shell access broad enough? _TBD_
- Is `jq` available? _TBD_
- Are there outbound network restrictions to ForLoop APIs? _TBD_
- Is the environment persistent across steps/sessions? _TBD_

---

## 3. Auth Model

**Question:** How should users authenticate in the Manus sandbox?

**Patterns tested:**
- Inline `forloop auth login --api-key ...` — _TBD_
- Environment variables — _TBD_
- Manus secure secrets — _TBD_

**Finding:** _TBD_

---

## 4. File Persistence

**Question:** Does Manus preserve `~/.forloop/` across runs?

**Paths that matter:**
- `~/.forloop/manifest.json` — _TBD_
- `~/.forloop/sprint-{id}/plan/` — _TBD_
- `~/.forloop/sprint-{id}/task/` — _TBD_
- `~/.forloop/sprint-{id}/knowledge/` — _TBD_

**Finding:** _TBD_

**Implication:** If sessions are ephemeral, `sync-from-remote` must be mandatory at every session start.

---

## 5. Decision Gate

| Criterion | Status |
|-----------|--------|
| Runtime installation viable? | TBD |
| CLI execution reliable? | TBD |
| Auth persistence workable? | TBD |
| File persistence adequate? | TBD |

**Verdict:** ⬜ Proceed with CLI-backed design / ⬜ Fall back to guidance-only

---

## 6. Manus Sandbox Test Checklist

Use this checklist only inside a real Manus sandbox. Record the result of every step directly in this file.

### Test Recording Format

For each test, fill in:

- **Result:** PASS / FAIL / PARTIAL / NOT RUN
- **Evidence:** command output summary or Manus behavior observed
- **Notes:** anything unexpected, confusing, or risky

Recommended template:

```md
### Test N — Title
- Result:
- Evidence:
- Notes:
```

### Phase A — Import and Packaging Verification

Goal: prove that Manus can import and recognize the skill package structure correctly.

#### Test A1 — Folder Import
- Action: upload the local `forloop-manus-skill/` folder to Manus as a Skill
- Verify:
  - Manus accepts the folder
  - `SKILL.md` is recognized
  - the skill appears in the Skills library
- Result:
- Evidence:
- Notes:

#### Test A2 — GitHub Import
- Action: import the GitHub repository or repo path containing `forloop-manus-skill/`
- Verify:
  - Manus accepts the repo
  - the skill is importable from GitHub
  - no packaging errors occur because of folder layout
- Result:
- Evidence:
- Notes:

#### Test A3 — Resource Discovery
- Action: trigger `/forloop-planner` and ask it to summarize its own packaged resources
- Suggested prompt:
  - `Use /forloop-planner and tell me what references, templates, and scripts are bundled with this skill.`
- Verify:
  - Manus can see `references/`
  - Manus can see `templates/`
  - Manus can see `scripts/`
- Result:
- Evidence:
- Notes:

### Phase B — Runtime Environment Verification

Goal: validate that the Manus sandbox can support the CLI-backed path before any ForLoop mutations are attempted.

#### Test B1 — Shell Availability
- Action: ask the skill to check basic shell execution support
- Suggested prompt:
  - `Use /forloop-planner and run environment preflight checks only. Do not mutate anything.`
- Verify:
  - shell commands can run
  - skill does not skip preflight
- Result:
- Evidence:
- Notes:

#### Test B2 — Runtime Tool Check
- Action: inspect the availability of required tools
- Commands to verify:
  - `command -v forloop`
  - `command -v node`
  - `command -v npm`
  - `command -v jq`
- Verify:
  - which tools are already present
  - whether missing tools are reported accurately
- Result:
- Evidence:
- Notes:

#### Test B3 — Runtime Installation
- Action: if `forloop` is missing and `npm` exists, allow the skill to install it
- Command path:
  - `npm install -g @forloop-cc/forloop-cli`
- Verify:
  - installation succeeds or fails clearly
  - failure messaging is actionable
  - Manus does not block package installation unexpectedly
- Result:
- Evidence:
- Notes:

#### Test B4 — CLI Verification
- Action: run CLI verification only
- Commands to verify:
  - `forloop --version`
  - `forloop --help`
- Verify:
  - installed CLI is callable
  - version output is normal
- Result:
- Evidence:
- Notes:

### Phase C — Authentication Verification

Goal: verify how the Manus sandbox handles the ForLoop auth flow.

#### Test C1 — Auth Status Before Login
- Action: run:
  - `forloop auth status`
- Verify:
  - output is plain text as expected
  - unauthenticated state is recognized correctly
- Result:
- Evidence:
- Notes:

#### Test C2 — Login Flow
- Action: authenticate using a real low-risk token
- Preferred approach:
  - paste a scoped token only when needed for the test
  - use the least privilege token that still satisfies planner read/write requirements
- Command:
  - `forloop auth login --api-key floop_xxxxx`
- Verify:
  - login succeeds
  - token is stored where expected
  - the skill does not echo or leak the token in plain output
- Result:
- Evidence:
- Notes:

#### Test C3 — Auth Status After Login
- Action: rerun:
  - `forloop auth status`
- Verify:
  - authenticated state is recognized correctly
  - output remains stable across repeated checks
- Result:
- Evidence:
- Notes:

#### Test C4 — Auth Persistence
- Action: start a fresh Manus task or fresh skill invocation after authenticating
- Verify:
  - whether authentication persists within the same task
  - whether authentication persists across separate tasks
  - whether Manus sandbox resets state between runs
- Result:
- Evidence:
- Notes:

### Phase D — Read-Only ForLoop Verification

Goal: test safe platform interaction before any writes.

#### Test D1 — Organization Listing
- Action:
  - `forloop org list --output json --non-interactive`
- Verify:
  - command succeeds
  - JSON output is returned
  - no hidden interactivity appears
- Result:
- Evidence:
- Notes:

#### Test D2 — Sprint Listing
- Action:
  - `forloop space-sprint list --output json --non-interactive`
- Verify:
  - command succeeds
  - response shape matches expectations
  - skill can summarize the results correctly
- Result:
- Evidence:
- Notes:

#### Test D3 — Sprint Get
- Action:
  - `forloop space-sprint get --output json --non-interactive`
  - or use explicit `--id` if needed
- Verify:
  - auto-detection works when expected
  - explicit sprint selection works when auto-detection does not
- Result:
- Evidence:
- Notes:

### Phase E — Filesystem and Persistence Verification

Goal: determine whether the local ForLoop working state is persistent enough for the skill design.

#### Test E1 — Local Path Creation
- Action: inspect:
  - `~/.forloop/`
  - `~/.forloop/manifest.json`
  - `~/.forloop/sprint-{id}/`
- Verify:
  - directories can be created and read
  - the skill can safely access the intended local path structure
- Result:
- Evidence:
- Notes:

#### Test E2 — Sync to Local
- Action:
  - `forloop sync aivy-folder --output json --non-interactive`
  - `forloop sync s3-to-local --output json --non-interactive`
- Verify:
  - files are downloaded
  - expected directories are populated
  - manifest updates behave as expected
- Result:
- Evidence:
- Notes:

#### Test E3 — Same-Session Persistence
- Action: create or sync files, then trigger the skill again in the same Manus task
- Verify:
  - files remain present
  - skill can reuse local state in the same session
- Result:
- Evidence:
- Notes:

#### Test E4 — Cross-Session Persistence
- Action: start a new Manus task after creating local state
- Verify:
  - whether `~/.forloop/` persists across tasks
  - whether session reset removes local state
- Result:
- Evidence:
- Notes:

### Phase F — Minimal Mutation Verification

Goal: prove the write path only after read-only and auth checks pass.

#### Test F1 — Doc Folder Ensure/Get
- Action:
  - `forloop sync aivy-folder --output json --non-interactive`
  - `forloop sync aivy-doc-get --output json --non-interactive`
- Verify:
  - doc folder exists or is created successfully
  - `docFolderId` is returned and parseable
- Result:
- Evidence:
- Notes:

#### Test F2 — Upload Verification
- Action:
  - create a harmless test note under `~/.forloop/sprint-{id}/knowledge/`
  - run `forloop sync local-to-s3 --path ... --story-id $DOC_ID --output json --non-interactive`
  - run `forloop file list --sprint {id} --output json --non-interactive`
- Verify:
  - upload succeeds
  - uploaded file appears in verification output
  - the skill follows ensure -> get -> upload -> verify
- Result:
- Evidence:
- Notes:

### Phase G — Skill Behavior Verification

Goal: prove the Manus skill follows the intended planner workflow rather than generic assistant behavior.

#### Test G1 — Preflight Obedience
- Action: ask the skill to inspect sprint context
- Verify:
  - it starts with preflight and auth/context checks
  - it does not jump directly into planning actions
- Result:
- Evidence:
- Notes:

#### Test G2 — Planning Boundary
- Action: ask the skill to implement code directly
- Suggested prompt:
  - `Use /forloop-planner to build the feature and write the code for me.`
- Verify:
  - the skill refuses implementation work
  - it redirects to planning/story creation instead
- Result:
- Evidence:
- Notes:

#### Test G3 — Proper Command Discipline
- Action: ask the skill to perform a simple read-only operation
- Verify:
  - it uses `--output json`
  - it uses `--non-interactive`
  - it avoids `curl`
  - it handles errors explicitly
- Result:
- Evidence:
- Notes:

---

## 7. Recommended Verification Order

Run the tests in this exact order:

1. `A` import and package shape
2. `B` runtime environment and installation
3. `C` authentication
4. `D` read-only ForLoop commands
5. `E` filesystem and persistence
6. `F` minimal mutation path
7. `G` skill behavior and boundary checks

Why this order:

- It keeps the earliest steps low risk
- It avoids using real credentials before basic runtime viability is known
- It avoids mutations until the environment, auth, and read-only flows are proven
- It gives a clear stop point when a prerequisite fails

---

## 8. Stop Conditions

Stop the verification sequence and mark the project as **not yet runtime-ready** if any of these occur:

- Manus cannot import the package reliably
- Manus cannot see `SKILL.md` or bundled resources
- shell execution is unavailable or inconsistent
- `npm` installation is blocked or unreliable
- `forloop --version` cannot be executed reliably after install
- authentication cannot be completed safely
- `~/.forloop/` is unusable for the required workflow
- non-interactive CLI commands behave interactively in practice

If a stop condition is hit, record:

- the exact step that failed
- the observed Manus behavior
- whether the issue is likely permanent or environment-specific
- whether the fallback should be guidance-only or MCP-backed

---

## 9. Final Sign-Off Checklist

Mark the skill CLI-backed and runtime-verified only when all of the following are true:

- [ ] Manus imports the package cleanly
- [ ] `SKILL.md` is discovered and triggerable
- [ ] `references/`, `templates/`, and `scripts/` are accessible as expected
- [ ] `forloop` can be installed or is already available
- [ ] `forloop --version` succeeds
- [ ] authentication works safely
- [ ] at least one read-only CLI workflow succeeds
- [ ] at least one minimal write workflow succeeds with verification
- [ ] `~/.forloop/` behavior is understood for same-session and cross-session usage
- [ ] the skill respects planning-only boundaries
- [ ] the skill consistently uses the required CLI command discipline

**Sign-off decision:** ⬜ Runtime-verified for Manus CLI-backed use / ⬜ Not yet verified
