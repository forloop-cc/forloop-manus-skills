# ForLoop CLI Reference

Full command catalog for the `forloop` CLI binary. Load this when you need specific command flags, subcommand details, or command patterns not covered in `SKILL.md`.

## Installation

### Via npm (recommended)

```bash
npm install -g @forloop-cc/forloop-cli
```

### Via Homebrew (macOS)

```bash
brew install forloop-cc/tap/forloop
```

### Verify

```bash
forloop --version
forloop --help
```

### Update

```bash
npm install -g @forloop-cc/forloop-cli@latest
```

### Uninstall

```bash
npm uninstall -g @forloop-cc/forloop-cli
```

---

## Command Pattern

Every command requires these flags:
- `--output json` — machine-parseable JSON output
- `--non-interactive` — prevents interactive prompts

Parse responses with `jq`:
```bash
RESULT=$(forloop <command> --output json --non-interactive 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "Error (exit $EXIT_CODE): $RESULT"
  exit 1
fi
echo "$RESULT" | jq '...'
```

### Exit Codes

| Code | Meaning | Action |
|------|---------|--------|
| 0 | Success | Proceed |
| 3 | Not authenticated | Direct user to: `forloop auth login --api-key floop_xxxxx` |
| 4 | Quota exceeded | Tell user their tier limit is reached |
| Other | General error | Show error message, ask user |

### Space ID Auto-Detection

The CLI auto-detects space ID from:
1. `FORLOOP_SPRINT_ID` environment variable
2. Git branch name pattern `sprint-N` (e.g., `sprint-14` → space 14)

Most commands work without explicit `--sprint` or `--id`. Only pass these flags when auto-detection fails.

---

## Authentication

### Check auth status

```bash
forloop auth status
```

Output is **plain text** (not JSON). Always exits code 0. Check the output text for "Not authenticated".

### Login

```bash
forloop auth login --api-key floop_xxxxx
```

The user must run this themselves. Never ask for their token — direct them to the command.

Required scopes: `sprint:read`, `sprint:write`, `story:read`, `story:write`, `agent:query`, `profile:read`.

Token source: [forloop.cc/profile?tab=api-tokens](https://forloop.cc/profile?tab=api-tokens)

---

## Space Commands

### List spaces

```bash
forloop space-sprint list --output json --non-interactive
forloop space-sprint list --org-id 2 --output json --non-interactive
forloop space-sprint list --include-system-org --output json --non-interactive
```

Returns: `[{ "id": 14, "title": "...", "status": "active", "startDate": "...", "endDate": "..." }]`

### Get space details

```bash
forloop space-sprint get --output json --non-interactive               # auto-detects
forloop space-sprint get --id 14 --output json --non-interactive       # explicit
forloop space-sprint get --id 14 --no-files --output json --non-interactive  # stories only
```

Returns space object with embedded `stories` array and `files` array (by default).

### Create space

```bash
forloop space-sprint create \
  --title "Space 15: API Redesign" \
  --start-date 2026-06-15 \
  --end-date 2026-06-28 \
  --output json --non-interactive

# Optional flags:
#   --description "Focus on..."
#   --private
#   --org-id 2
```

Returns: `{ "id": 15, "title": "...", "startDate": "...", "endDate": "..." }`

### Update space

```bash
forloop space-sprint update --id 14 --title "Updated Title" --output json --non-interactive
```

Partial updates: only pass flags you want to change.

### Delete space

```bash
forloop space-sprint delete --id 14 --confirm --output json --non-interactive
```

**Requires `--confirm`.** Warn the user before running.

---

## Sub-Sprint (Iteration) Management

### `space-sprint sub-sprint list`

List all iterations within a space.

```bash
forloop space-sprint sub-sprint list --sprint-id $SPRINT_ID --output json --non-interactive
```

| Flag | Type | Required | Description |
|------|------|----------|-------------|
| `--sprint-id` | number | Yes | Space ID |

**JSON output:**
```json
[
  {
    "id": 1,
    "sprintId": 10,
    "title": "My Space — Iteration 1",
    "startDate": "2026-08-01T00:00:00.000Z",
    "endDate": "2026-08-14T00:00:00.000Z",
    "status": "completed",
    "order": 0
  },
  {
    "id": 2,
    "title": "Iteration 2 — Payment Integration",
    "startDate": "2026-08-15T00:00:00.000Z",
    "endDate": "2026-08-28T00:00:00.000Z",
    "status": "in_progress",
    "order": 1
  }
]
```

### `space-sprint sub-sprint create`

Create a new iteration. The previously active iteration is auto-completed.

```bash
forloop space-sprint sub-sprint create \
  --sprint-id $SPRINT_ID \
  --start-date 2026-08-15 \
  --end-date 2026-08-28 \
  --title "Iteration 2" \
  --output json --non-interactive
```

| Flag | Type | Required | Description |
|------|------|----------|-------------|
| `--sprint-id` | number | Yes | Space ID |
| `--start-date` | string | Yes | Start date (YYYY-MM-DD) |
| `--end-date` | string | Yes | End date (YYYY-MM-DD) |
| `--title` | string | No | Iteration title (auto-generates if omitted) |

**JSON output:** Single sub-sprint object (same shape as list items).

### `space-sprint sub-sprint update`

Update an iteration title, dates, or status.

```bash
forloop space-sprint sub-sprint update \
  --id $SUB_SPRINT_ID \
  --status completed \
  --output json --non-interactive
```

| Flag | Type | Required | Description |
|------|------|----------|-------------|
| `--id` | number | Yes | Sub-sprint ID |
| `--title` | string | No | New title |
| `--start-date` | string | No | New start date |
| `--end-date` | string | No | New end date |
| `--status` | string | No | `planned`, `in_progress`, or `completed` |

### `space-sprint sub-sprint delete`

Soft-delete an iteration.

```bash
forloop space-sprint sub-sprint delete --id $SUB_SPRINT_ID --confirm \
  --output json --non-interactive
```

| Flag | Type | Required | Description |
|------|------|----------|-------------|
| `--id` | number | Yes | Sub-sprint ID |
| `--confirm` | flag | Yes | Safety confirmation |

**JSON output:** `{ "success": true }`

---

## Story Commands

### List stories (via space-sprint get)

Stories are embedded in space output:
```bash
forloop space-sprint get --output json --non-interactive | jq '.stories[] | {id, title, status, assigneeAgent}'
```

### Create story from template

#### Implementation task (basic-task)

```bash
forloop story create \
  --title "Implement login API endpoint" \
  --type basic-task \
  --sprint 14 \
  --priority high \
  --points 3 \
  --assignee-agent forLoopDeveloper \
  --description "## Goal\n...\n\n## Scope\n...\n\n## Acceptance Criteria\n..." \
  --output json --non-interactive
```

Priority options: `low`, `medium`, `high`, `critical`
Points: Fibonacci values 1, 2, 3, 5, 8, 10

#### Documentation note (basic-note)

```bash
forloop story create \
  --title "Architecture decision: JWT auth" \
  --type basic-note \
  --sprint 14 \
  --priority medium \
  --description "## Context\n...\n\n## Decision\n...\n\n## Rationale\n..." \
  --output json --non-interactive
```

`basic-note` does not take `--assignee-agent` or `--points`.

#### Document folder (omit --type)

```bash
forloop story create \
  --title "Project Documents" \
  --sprint 14 \
  --output json --non-interactive
```

Omitting `--type` creates a `doc_folder` story by default.

### Get story details

```bash
forloop story get --id 78 --output json --non-interactive
forloop story get --id 78 --no-comments --output json --non-interactive
```

Returns: `{ "id": 78, "title": "...", "status": "todo", "description": "...", "comments": [...] }`

### Update story

```bash
forloop story update --id 78 --status done --output json --non-interactive
forloop story update --id 78 --priority critical --points 5 --output json --non-interactive
```

Partial updates: only pass the fields you want to change.

### Delete story

```bash
forloop story delete --id 78 --confirm --output json --non-interactive
```

**Requires `--confirm`.** Warn the user before running.

---

## Template Commands

### List available templates

```bash
forloop template list --output json --non-interactive
```

Returns: `[{ "id": 1, "name": "Basic Task", "slug": "basic-task" }, { "id": 2, "name": "Basic Note", "slug": "basic-note" }]`

---

## File Commands

### List files in space

```bash
forloop file list --sprint 14 --output json --non-interactive
```

Returns: `[{ "id": 42, "originalName": "sprint-plan.md", "folder": "project/plans", "storyId": 101 }]`

### Upload file

```bash
forloop file upload \
  --path ./requirements.md \
  --sprint 14 \
  --output json --non-interactive

# Optional:
#   --description "Requirements doc"
#   --folder project/docs
#   --story-id 101
```

### Delete file

```bash
forloop file delete --id 42 --confirm --output json --non-interactive
```

**Requires `--confirm`.**

### Get download URL

```bash
forloop file download --id 42 --output json --non-interactive
```

Returns: `{ "url": "https://presigned-url..." }`

### Create folder

```bash
forloop folder create --title "Planning Docs" --sprint 14 --output json --non-interactive
```

---

## Sync Commands

### Ensure doc folder exists

```bash
forloop sync aivy-folder --output json --non-interactive
forloop sync aivy-folder --sprint 14 --title "Aivy Plan Doc" --output json --non-interactive
```

Creates the doc folder if it doesn't exist. Idempotent — safe to run multiple times.

### Get doc folder ID

```bash
forloop sync aivy-doc-get --output json --non-interactive
forloop sync aivy-doc-get --sprint 14 --output json --non-interactive
```

Returns: `{ "docFolderId": 101, "exists": true }`

Parse: `jq -r '.docFolderId'`

### Download from S3 to local

```bash
forloop sync s3-to-local --output json --non-interactive
forloop sync s3-to-local --sprint 14 --output json --non-interactive
```

Downloads `plan/`, `task/`, and `knowledge/` files to `~/.forloop/sprint-{id}/`.

### Upload from local to S3

```bash
forloop sync local-to-s3 \
  --path ~/.forloop/sprint-14/plan/sprint-plan.md \
  --output json --non-interactive

# Optional:
#   --sprint 14
#   --folder project/plans
#   --story-id 101
```

Auto-infers remote folder from local path:
- `plan/` → `project/plans`
- `task/` → `project/tasks`
- `knowledge/` → `project/knowledge`

---

## User Commands

### Get profile

```bash
forloop user profile --output json --non-interactive
```

### Check quotas

```bash
forloop user quotas --output json --non-interactive
forloop org quotas --org-id 2 --output json --non-interactive
```

---

## Organization Commands

### List organizations

```bash
forloop org list --output json --non-interactive
forloop org list --owned-only --output json --non-interactive
```

### Get organization

```bash
forloop org get --id 2 --output json --non-interactive
```

### Create organization

```bash
forloop org create --name "Engineering" --output json --non-interactive
```

### Update organization

```bash
forloop org update --id 2 --name "New Name" --output json --non-interactive
```

### Delete organization

```bash
forloop org delete --id 2 --confirm --output json --non-interactive
```

**Requires `--confirm`.**

---

## Agent Commands

### Check developer status

```bash
forloop agent developer-status --output json --non-interactive
forloop agent developer-status --sprint 14 --output json --non-interactive
```

Returns: `{ "status": "RUNNING", "elapsed": "5m", "stories": { "done": 3, "in_progress": 2, "total": 8 } }`

Status values: `RUNNING`, `IDLE`, `COMPLETED`, `FAILED`

### Trigger developer

```bash
forloop agent developer-sprint \
  --sprint 14 \
  --message "Implement remaining stories" \
  --output json --non-interactive
```

### View conversation history

```bash
forloop agent history --output json --non-interactive
forloop agent history --sprint 14 --limit 50 --output json --non-interactive
```

---

## Workflow Patterns

### Session startup

```bash
# 1. Verify auth
forloop auth status

# 2. Ensure doc folder
forloop sync aivy-folder --output json --non-interactive

# 3. Sync from S3
forloop sync s3-to-local --output json --non-interactive

# 4. Load space context
forloop space-sprint get --output json --non-interactive | jq '.stories'

# 5. Check developer
forloop agent developer-status --output json --non-interactive
```

### Space creation

```bash
# 1. Check orgs
forloop org list --output json --non-interactive | jq '.[] | {id, name}'

# 2. Create space
forloop space-sprint create \
  --title "Space 15" \
  --start-date 2026-07-01 \
  --end-date 2026-07-14 \
  --org-id 2 \
  --output json --non-interactive

# 3. Verify
forloop space-sprint get --output json --non-interactive | jq '{id, title, startDate, endDate}'
```

### Story creation (full flow)

```bash
# 1. Ensure doc folder
forloop sync aivy-folder --output json --non-interactive
DOC_ID=$(forloop sync aivy-doc-get --output json --non-interactive | jq -r '.docFolderId')

# 2. Create story
forloop story create \
  --title "Implement user registration" \
  --type basic-task \
  --priority high \
  --points 5 \
  --assignee-agent forLoopDeveloper \
  --output json --non-interactive

# 3. Verify stories in space
forloop space-sprint get --output json --non-interactive | jq '.stories[] | {id, title, status}'
```

### Upload workflow

```bash
# 1. Write local file
cat > ~/.forloop/sprint-14/plan/sprint-plan.md << 'EOF'
# Space Plan
...
EOF

# 2. Ensure doc folder and get ID
forloop sync aivy-folder --output json --non-interactive
DOC_ID=$(forloop sync aivy-doc-get --output json --non-interactive | jq -r '.docFolderId')

# 3. Upload with doc folder linking
forloop sync local-to-s3 \
  --path ~/.forloop/sprint-14/plan/sprint-plan.md \
  --story-id $DOC_ID \
  --output json --non-interactive

# 4. Verify
forloop file list --sprint 14 --output json --non-interactive | jq '.[] | select(.originalName | contains("sprint-plan"))'
```
