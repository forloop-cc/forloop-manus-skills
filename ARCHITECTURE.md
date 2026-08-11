# Architecture — Canonical Workflow, Command Rules, and Skill Design

> Combined output of Phase 2 (Source Audit) and Phase 3 (Skill Architecture Design)

---

## Part A: Canonical Planner Workflow

Extracted from `forLoopPlannerCLI.md`, `forloop-cli/SKILL.md`, and `SKILLS-GAP-ANALYSIS.md`.

### Workflow Steps (0–7)

#### Step 0 — Session Start (ALWAYS FIRST)

1. **Verify CLI presence** — `command -v forloop`; if missing and `npm` exists, `npm install -g @forloop-cc/forloop-cli`
2. **Verify CLI version** — `forloop --version`
3. **Verify auth** — `forloop auth status` (text output, always exits 0)
4. **Read manifest** — `~/.forloop/manifest.json` for active sprint
5. **Sync from S3** (mandatory — catches missed steps from gap analysis):
   ```bash
   forloop sync aivy-folder --output json --non-interactive
   DOC_ID=$(forloop sync aivy-doc-get --output json --non-interactive | jq -r '.docFolderId')
   forloop sync s3-to-local --output json --non-interactive
   ```
6. **Reload local files** from `plan/`, `knowledge/`, `task/`
7. **Read `knowledge-application.md`** if it exists
8. **Load conversation history** — `forloop agent history --limit 50 --output json --non-interactive`
9. **Check developer status** — `forloop agent developer-status --output json --non-interactive`
10. **Check in-progress stories** — `forloop space-sprint get` + `forloop story get --id N`
11. **Present context summary** to user, confirm active sprint

**If manifest is missing:** Stop searching. Use CLI to list orgs/sprints. Ask user to select.

#### Step 1 — Safety Boundary

- **Planning only** — no code implementation, no builds, no scaffold
- **File scope** — only create/edit in `~/.forloop/sprint-{id}/knowledge/`, `plan/`, `task/`, `manifest.json`
- **Implementation trigger** — use `forloop agent developer-sprint` to trigger server-side implementation

#### Step 2 — Context Discovery

- Verify auth: `forloop auth status --non-interactive`
- Get sprint details: `forloop space-sprint get --output json --non-interactive | jq '{id, title, stories}'`
- Confirm with user: "Working on sprint #<id>?"

#### Step 3 — Sprint Selection (If Missing)

1. Check orgs: `forloop org list --output json --non-interactive`
2. If no org, guide user to create one
3. List sprints or create new: `forloop space-sprint create --title "..." --start-date ... --end-date ... --org-id N --output json --non-interactive`

#### Step 4 — Requirements Gathering + Knowledge Capture

- Ask focused questions (goal, scope, constraints, success criteria)
- Capture knowledge to `~/.forloop/sprint-{id}/knowledge/`
- **Upload immediately:** ensure doc_folder → get DOC_ID → upload with `--story-id $DOC_ID` → verify (see Doc Folder pattern below)

#### Step 5 — Generate Plan Document

- Write plan to `~/.forloop/sprint-{id}/plan/sprint-plan-{datetime}.md`
- Update `~/.forloop/manifest.json`
- Upload + verify using doc folder pattern
- Confirm plan with user

#### Step 6 — Task Breakdown and Story Creation

- Read plan, break into tasks, estimate points
- **Ensure doc_folder** before creating stories
- Create stories via CLI with `--type basic-task` / `--type basic-note`
- Write task file, upload with `--story-id $DOC_ID`, update manifest, verify
- Agent assignment per task type (see Story Creation Rules below)

#### Step 7 — Trigger Implementation (Optional)

```bash
forloop agent developer-sprint --sprint N --message "Implement all planned stories" --output json --non-interactive
forloop agent developer-status --output json --non-interactive
```

---

## Part B: Canonical Command Rule Set

Extracted from `forLoopPlannerCLI.md` and `forloop-cli/SKILL.md`.

### Non-Negotiable Rules

| # | Rule | Source |
|---|------|--------|
| 1 | **Always `--output json`** — every command | Both |
| 2 | **Always `--non-interactive`** — every command | Both |
| 3 | **Check exit codes** — 0=success, 3=auth error, 4=quota | Both |
| 4 | **Never use `curl` or construct API URLs** — use `forloop` CLI only | `forLoopPlannerCLI.md` |
| 5 | **Never ask user for token** — direct to `forloop auth login` | Both |
| 6 | **Warn before destructive commands** — `--confirm` on delete | Both |
| 7 | **Parse JSON with `jq`** — `jq '.[].id'`, `jq -r '.title'`, `jq 'length'` | Both |
| 8 | **Prefer sprint ID auto-detection** — env var or git branch | Both |
| 9 | **Auth status is text-only** — always exits 0 | `forloop-cli/SKILL.md` |
| 10 | **Runtime install as preflight** — never assume CLI is preinstalled | New (DEV_PLAN §5.2) |

### Preflight Checklist (Runtime Install — from DEV_PLAN §5.2)

```bash
# 1. Check if forloop exists
if ! command -v forloop >/dev/null 2>&1; then
  # 2. Check if node/npm exist
  if command -v npm >/dev/null 2>&1; then
    # 3. Install at runtime
    npm install -g @forloop-cc/forloop-cli
  else
    echo "ForLoop CLI is not installed and npm is unavailable."
    echo "Please install Node.js and npm, then run: npm install -g @forloop-cc/forloop-cli"
    # STOP — fall back to guidance-only mode
    exit 1
  fi
fi

# 4. Verify installation
forloop --version

# 5. Verify auth
forloop auth status
```

**Decision tree:**
- `forloop` exists → proceed
- `forloop` missing, `npm` exists → install at runtime → proceed
- `forloop` missing, `npm` missing → stop cleanly, surface remediation guidance, fall back to guidance-only

### Doc Folder Upload Pattern (MANDATORY)

This is the critical pattern that was missing from the agent definition (per gap analysis). It applies to ALL file uploads.

```
ensure → get → upload → verify
```

```bash
# 1. Ensure doc_folder exists
forloop sync aivy-folder --output json --non-interactive

# 2. Get doc_folder story ID
DOC_ID=$(forloop sync aivy-doc-get --output json --non-interactive | jq -r '.docFolderId')

# 3. Upload file (linked to doc folder)
forloop sync local-to-s3 \
  --path ~/.forloop/sprint-{id}/plan/sprint-plan.md \
  --sprint {id} \
  --story-id $DOC_ID \
  --output json --non-interactive

# 4. Verify upload
forloop file list --sprint {id} --output json --non-interactive | jq '.[].originalName'
```

**S3 folder mapping:**

| Local Path | --folder value |
|------------|---------------|
| `~/.forloop/sprint-{id}/plan/*` | `project/plans` |
| `~/.forloop/sprint-{id}/task/*` | `project/tasks` |
| `~/.forloop/sprint-{id}/knowledge/*` | `project/knowledge` |

### Story Creation Rules

| Task Type | --type | --assignee-agent |
|-----------|--------|-----------------|
| Code implementation, features, bug fixes | `basic-task` | `forLoopDeveloper` |
| Testing, QA, validation | `basic-task` | `forLoopTester` |
| Deployment, infrastructure, CI/CD | `basic-task` | `forLoopDevops` |
| File/media generation (DOCX, PDF, XLSX, PPTX, images, music) | `basic-task` | `forLoopCreator` |
| Documentation, notes, decisions | `basic-note` | (none) |
| Document folder (for file organization) | _(omit --type)_ | (none) |

**Creator stories:** follow a different workflow from the code pipeline. Split Creator + Developer tasks into two separate stories.

**Schedule/meetings:** not directly creatable via CLI. Use `basic-note` or web app.

### Exit Codes

| Code | Meaning | Action |
|------|---------|--------|
| 0 | Success | Proceed |
| 3 | Not authenticated | Tell user to run `forloop auth login --api-key floop_xxxxx` |
| 4 | Quota exceeded | Tell user their tier limit is reached |
| Other | General error | Show error message, ask user |

---

## Part C: Migration Map

How content from existing source files maps to new Manus skill artifacts.

| Source File | Content Extracted | Maps To |
|------------|-------------------|---------|
| `forLoopPlannerCLI.md` §"Your Role" | Planner identity, planning-only boundary | `SKILL.md` §2 (Role and boundaries) |
| `forLoopPlannerCLI.md` §"Prerequisites" | CLI check, auth check | `SKILL.md` §4-5 (Prerequisites, Runtime install) |
| `forLoopPlannerCLI.md` §"Command Pattern" | --output json, --non-interactive, jq | `SKILL.md` §7 (Non-negotiable command rules) |
| `forLoopPlannerCLI.md` §"Critical Rules" | Exit codes, no curl, warn before delete | `SKILL.md` §7 (Non-negotiable command rules) |
| `forLoopPlannerCLI.md` §"Capabilities" | Context, sync, stories, knowledge, upload, trigger | `SKILL.md` §3 (When to use) |
| `forLoopPlannerCLI.md` §"Story Creation" | basic-task, basic-note, Creator, agent assignment | `references/story-patterns.md` |
| `forLoopPlannerCLI.md` §"Doc Folder Management" | ensure→get→upload→verify | `SKILL.md` §10 (File sync and verification) |
| `forLoopPlannerCLI.md` §"Default Workflow" | Steps 0-7 | `SKILL.md` §8 (Default planning workflow) |
| `forLoopPlannerCLI.md` §"Path Reminders" | ~/.forloop paths | `SKILL.md` §4 (Prerequisites) |
| `forloop-cli/SKILL.md` §"Installation" | npm install, brew, verify | `references/cli-reference.md` |
| `forloop-cli/SKILL.md` §"Command Pattern" | Flags, exit codes, jq | `references/cli-reference.md` |
| `forloop-cli/SKILL.md` §"Sprint Commands" | list, get, create, update, delete | `references/cli-reference.md` |
| `forloop-cli/SKILL.md` §"Story Commands" | create, get, update, delete | `references/cli-reference.md` |
| `forloop-cli/SKILL.md` §"Sync Commands" | aivy-folder, aivy-doc-get, s3-to-local, local-to-s3 | `references/cli-reference.md` |
| `forloop-cli/SKILL.md` §"File Commands" | list, upload, delete, download | `references/cli-reference.md` |
| `forloop-cli/SKILL.md` §"Developer Agent Commands" | developer-status, developer-sprint, history | `references/cli-reference.md` |
| `forloop-cli/SKILL.md` §"Workflow Patterns" | Session startup, sprint creation, story creation, upload | `SKILL.md` §8 (Default planning workflow) |
| `forloop-cli/SKILL.md` §"Important Rules" | 8 rules | `SKILL.md` §7 (Non-negotiable command rules) |
| `SKILLS-GAP-ANALYSIS.md` | Missing S3 sync, missing doc_folder, missing verify | `SKILL.md` §6 (Session startup — sync is mandatory), §10 (verify uploads) |
| `forLoopPlanner.md` (plugin) §"Story Content" | Description template, field reference | `references/story-patterns.md` |
| `forLoopPlanner.md` (plugin) §"Interaction Style" | 15 rules for planner behavior | `SKILL.md` §2-11 (various sections) |
| `tech-stack-default/SKILL.md` | Tech stack, agent definitions, pipeline | `references/forloop-methodology.md` |
| `DEV_PLAN.md` §5.2 | Runtime install strategy | `SKILL.md` §5 (Runtime installation and preflight rules) |

---

## Part D: Skill Architecture (SKILL.md Design)

### Metadata

| Field | Value |
|-------|-------|
| **name** | `forloop-planner` |
| **description** | Planning-only ForLoop sprint planner. Uses the forloop CLI for sprint management, story creation, file sync, and developer triggers. Never implements application code. |
| **scope** | Sprint planning, requirements gathering, knowledge capture, task breakdown, story creation, plan documentation |
| **when to use** | User asks to plan a sprint, create stories, capture requirements, upload plan/knowledge documents, or manage ForLoop sprints |
| **when NOT to use** | Writing application code, building/scaffolding apps, running tests, deploying infrastructure, performing non-planning tasks |

### SKILL.md Section Outline (13 sections)

| # | Section | Content |
|---|---------|---------|
| 1 | **Metadata** | Name, description, scope, triggers |
| 2 | **Role and Boundaries** | "You are a planning-only ForLoop planner." Planning-only contract, no implementation, no builds, file scope limits |
| 3 | **When to Use This Skill** | Trigger phrases and scenarios |
| 4 | **Prerequisites** | Required tools (node, npm, jq), storage paths (~/.forloop/), API token requirements |
| 5 | **Runtime Installation and Preflight Rules** | Decision tree: check forloop → check node/npm → install if needed → verify version → verify auth. Fallback to guidance-only when npm is unavailable |
| 6 | **Session Startup Checklist** | 11-step startup flow (see Part A Step 0 above). Mandatory sync from S3 at every session start. Context summary presentation |
| 7 | **Non-Negotiable Command Rules** | 10 rules from Part B above. Exit codes table. Doc folder upload pattern |
| 8 | **Default Planning Workflow** | Steps 0-7 from Part A. Links to deeper references for story creation, methodology, and troubleshooting |
| 9 | **Story Creation Rules** | Template types, agent assignment table, Creator workflow distinction |
| 10 | **File Sync and Verification Rules** | Doc folder ensure→get→upload→verify pattern. S3 folder mapping. Upload verification requirements |
| 11 | **Failure Handling** | Auth missing (exit 3), quota (exit 4), CLI missing, npm missing, sync failures, sprint context missing, runtime install failed. Each with specific remediation |
| 12 | **Out-of-Scope Behavior** | What this skill MUST NOT do: code implementation, builds, scaffolds, debugging, deployment, non-planning tasks. How to redirect |
| 13 | **References to Bundled Materials** | Quick index of `references/`, `templates/`, and `scripts/` |

### Progressive Disclosure Strategy

**SKILL.md** (loaded first, always):
- Planner identity and boundaries (who, what, must not do)
- Preflight checklist (must do first)
- Command rules (how to interact with ForLoop)
- Default workflow (step-by-step overview)
- Doc folder pattern (the critical gap)

**references/** (loaded on demand):
- `planner-role.md` — deeper philosophy, safety boundary philosophy, success definition
- `cli-reference.md` — full command catalog with every flag and pattern
- `forloop-methodology.md` — ForLoop way, sprint design, story sizing, knowledge capture standards
- `story-patterns.md` — complete story templates, agent assignment mapping, Creator vs code pipeline
- `validation-checklists.md` — startup checklist, before-completion checklist, upload verification
- `troubleshooting.md` — auth, missing sprint, CLI missing, quota, sync failures, runtime install failures

**templates/** (loaded when generating output):
- `sprint-plan-template.md` — plan document structure
- `task-breakdown-template.md` — task breakdown structure
- `knowledge-note-template.md` — knowledge capture format

**scripts/** (run when CLI execution is available):
- `preflight.sh` — verify forloop/node/npm/jq, install forloop if missing, print auth status
- `auth-check.sh` — run `forloop auth status`, print remediation guidance

### Critical Design Principles (from Gap Analysis)

1. **SKILL.md IS the source of truth** for LLM behavior. If a step is not in SKILL.md, the model WILL skip it.
2. **Doc folder workflow must be inlined** in SKILL.md (not just referenced). The gap analysis proved this is the #1 missed step.
3. **S3 sync at session start is mandatory** — the agent definition missed this, the skill must not.
4. **Upload verification is mandatory** — always run `forloop file list` after uploads.
5. **Preflight is the first thing the model reads** — it sets the tone for the entire session.

---

## Part E: File Allocation Summary

| File | Type | When loaded | Key responsibility |
|------|------|-------------|-------------------|
| `SKILL.md` | Primary | Always (first load) | Planner identity, preflight, command rules, workflow, doc folder pattern |
| `references/planner-role.md` | Reference | On demand | Philosophy, safety boundary depth, success criteria |
| `references/cli-reference.md` | Reference | On demand | Full command catalog, every flag, exit codes, patterns |
| `references/forloop-methodology.md` | Reference | On demand | Sprint design, story sizing, knowledge capture standards |
| `references/story-patterns.md` | Reference | On demand | Story templates, agent assignment, Creator workflow |
| `references/validation-checklists.md` | Reference | On demand | Checklists: startup, pre-completion, upload verification |
| `references/troubleshooting.md` | Reference | On demand | Auth, CLI, sync, quota, runtime install failure scenarios |
| `templates/sprint-plan-template.md` | Template | When generating | Plan document structure |
| `templates/task-breakdown-template.md` | Template | When generating | Task breakdown structure |
| `templates/knowledge-note-template.md` | Template | When generating | Knowledge capture format |
| `scripts/preflight.sh` | Script | When CLI available | Environment verification + runtime install |
| `scripts/auth-check.sh` | Script | When CLI available | Auth status check + remediation |
