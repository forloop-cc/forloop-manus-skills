# Validation Checklists

Checklists for key moments in the planning workflow. Use these to verify completeness before moving to the next step.

## 1. Runtime Install Checklist

Run at the start of every CLI-backed session. All items must pass before using any `forloop` commands.

- [ ] `command -v forloop` succeeds, OR `npm install -g @forloop-cc/forloop-cli` succeeds
- [ ] `forloop --version` prints a version number
- [ ] `forloop auth status` does NOT contain "Not authenticated"
- [ ] If auth fails, user has been directed to `forloop auth login --api-key floop_xxxxx`
- [ ] If npm is unavailable, user has been told what to install

**Decision:** ☐ Full CLI-backed mode ☐ Guidance-only mode

---

## 2. Session Startup Checklist

Run after passing the runtime install check. All items in order.

### Environment
- [ ] CLI presence confirmed (from checklist 1)
- [ ] Auth confirmed (from checklist 1)

### Context Loading
- [ ] `~/.forloop/manifest.json` read and parsed
- [ ] Active sprint ID identified
- [ ] Doc folder ensured: `forloop sync aivy-folder --output json --non-interactive`
- [ ] Doc folder ID retrieved: `DOC_ID=$(forloop sync aivy-doc-get ... | jq -r '.docFolderId')`
- [ ] S3 synced: `forloop sync s3-to-local --output json --non-interactive`
- [ ] Local files reloaded from `plan/`, `knowledge/`, `task/`
- [ ] `knowledge-application.md` read (if exists)

### Sprint Context
- [ ] `forloop sprint get` returned sprint details
- [ ] Stories loaded: `jq '.stories[] | {id, title, status, assigneeAgent}'`
- [ ] Developer status checked: `forloop agent developer-status`
- [ ] Conversation history loaded: `forloop agent history --limit 50`

### User Confirmation
- [ ] Context summary presented to user
- [ ] Active sprint confirmed by user
- [ ] User is aware of any running developer agent

---

## 3. Before-Story-Creation Checklist

Run before executing any `forloop story create` commands.

### Plan Readiness
- [ ] Plan document exists in `~/.forloop/sprint-{id}/plan/`
- [ ] Plan has been uploaded to S3 with doc folder linking
- [ ] Upload verified with `forloop file list`
- [ ] Plan approved by user

### Task Breakdown
- [ ] All tasks identified from the plan
- [ ] Each task has a clear deliverable
- [ ] Dependencies between tasks mapped
- [ ] Points estimated for each task (1, 2, 3, 5, 8; split if > 10)
- [ ] Agent assigned for each task

### Doc Folder
- [ ] Doc folder exists: `forloop sync aivy-folder` succeeded
- [ ] Doc folder ID cached: `$DOC_ID` variable is set
- [ ] Doc folder ID is valid (not empty, not "null")

### Verification
- [ ] User approved the task breakdown before story creation

---

## 4. Upload Verification Checklist

Run after EVERY file upload. This is mandatory — never skip.

### For Plan Uploads
- [ ] Plan written to `~/.forloop/sprint-{id}/plan/sprint-plan-{datetime}.md`
- [ ] Manifest updated with plan reference
- [ ] Uploaded to S3: `forloop sync local-to-s3 --path ... --story-id $DOC_ID`
- [ ] Upload exit code checked (must be 0)
- [ ] Verified: `forloop file list --sprint {id} --output json | jq '.[] | select(.originalName | contains("sprint-plan"))'`
- [ ] Verify output includes the uploaded file

### For Knowledge Uploads
- [ ] Knowledge file written to `~/.forloop/sprint-{id}/knowledge/{topic}-{date}.md`
- [ ] Uploaded to S3: `forloop sync local-to-s3 --path ... --story-id $DOC_ID`
- [ ] Upload exit code checked (must be 0)
- [ ] Verified: `forloop file list --sprint {id} --output json | jq '.[] | select(.folder == "project/knowledge")'`
- [ ] Verify output includes the uploaded file

### For Task Uploads
- [ ] Task file written to `~/.forloop/sprint-{id}/task/`
- [ ] Uploaded to S3: `forloop sync local-to-s3 --path ... --story-id $DOC_ID`
- [ ] Upload exit code checked (must be 0)
- [ ] Manifest updated with task reference
- [ ] Verified: `forloop file list --sprint {id} --output json | jq '.[] | select(.folder == "project/tasks")'`

---

## 5. Before-Completion Checklist

Run before telling the user the planning session is complete.

### Files and Sync
- [ ] All plan files uploaded to S3 and verified
- [ ] All knowledge files uploaded to S3 and verified
- [ ] All task files uploaded to S3 and verified
- [ ] `manifest.json` is up to date locally

### Stories
- [ ] All planned stories created
- [ ] Each story has correct `--type`, `--assignee-agent`, `--priority`, `--points`
- [ ] Each story has a complete description (Goal, Scope, Acceptance Criteria)
- [ ] Dependencies between stories documented
- [ ] No story > 10 points (split if found)
- [ ] User confirmed the story list

### Sprint Health
- [ ] Total points ≤ estimated capacity
- [ ] Story statuses are all `todo` (before implementation trigger)
- [ ] No orphaned stories (stories with no clear sprint context)

### Handoff
- [ ] User knows how to trigger implementation: `forloop agent developer-sprint`
- [ ] User knows how to check status: `forloop agent developer-status`
- [ ] Session summary includes: sprint link, story count, total points, key decisions

### Clean Closure
- [ ] No pending questions for the user
- [ ] No unverified uploads
- [ ] No partially written files
- [ ] Manifest.json reflects current state

---

## 6. Verification Evidence Rule

**Never claim a state without fresh evidence.** This is the iron law of verification.

| Claim | Required Evidence |
|-------|------------------|
| "Story created" | Output of `forloop sprint get | jq '.stories[]'` showing the new story |
| "File uploaded" | Output of `forloop file list | jq '.[].originalName'` showing the file |
| "Auth works" | Output of `forloop auth status` showing authenticated |
| "Sprint exists" | Output of `forloop sprint get` showing sprint details |
| "Developer triggered" | Output of `forloop agent developer-status` showing RUNNING |

**Wrong:** "The file has been uploaded to S3."
**Correct:** "Upload verified — the file appears in `forloop file list`:
```
sprint-plan-2026-07-19.md    project/plans    story_id: 101
```
"

## Permission to Proceed Gates

These are hard gates — do not proceed past them until fully checked:

### Gate 1: Planning can begin
- [ ] Runtime install checklist passed

### Gate 2: Sprint context is established
- [ ] Session startup checklist passed
- [ ] Sprint confirmed with user

### Gate 3: Stories can be created
- [ ] Plan approved by user
- [ ] Before-story-creation checklist passed

### Gate 4: Session is complete
- [ ] Before-completion checklist passed
