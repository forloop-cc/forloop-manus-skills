# Story Patterns: Templates, Agent Assignment, and Workflows

This reference covers story types, agent assignment mapping, Creator workflow differences, and description formats. Load this when creating stories or assigning work to agents.

## Story Types

| Type | CLI Flag | Purpose | Has Assignee? | Has Points? |
|------|----------|---------|---------------|-------------|
| Implementation Task | `--type basic-task` | Code, features, bug fixes, testing, infra, file generation | Yes | Yes |
| Documentation Note | `--type basic-note` | Decisions, architecture records, meeting notes, research | No | No |
| Document Folder | _(omit `--type`)_ | Container for organizing S3 files | No | No |

## Agent Assignment Map

| Agent | Role | Story Types | Example Stories |
|-------|------|------------|----------------|
| `forLoopDeveloper` | Code implementation | Features, bug fixes, API endpoints, UI components, data models, business logic, integrations | "Implement user registration endpoint", "Build dashboard table component", "Fix pagination bug in search" |
| `forLoopTester` | Testing and quality | Unit tests, integration tests, E2E tests, QA validation, test automation | "Write unit tests for auth service", "Create integration test for payment flow", "Validate API response schemas" |
| `forLoopDevops` | Infrastructure and deployment | IaC changes, pipeline config, environment setup, monitoring, security config | "Update Terraform for new Lambda", "Configure CloudWatch alarms", "Add environment variables for staging" |
| `forLoopCreator` | File/media generation | DOCX, PDF, XLSX, PPTX, images, music, video, any binary asset generation | "Generate project report DOCX", "Create presentation deck PPTX", "Export data to Excel spreadsheet" |

### Assignment Rules

1. **One agent per story.** A story is assigned to exactly one agent. If work crosses agent boundaries, split into multiple stories.

2. **Creator + Developer = always split.** Creator generates the asset, Developer integrates it. These are always two separate stories. Example:
   - Story A: "Generate monthly report PDF" → `forLoopCreator`
   - Story B: "Add PDF report download button to dashboard" → `forLoopDeveloper`

3. **Testing is separate.** The Tester agent writes and runs tests. Don't include "and write tests" in a Developer story. Create a Tester story.

4. **DevOps after implementation.** Infrastructure stories typically depend on implementation stories being complete. Document these dependencies.

## Story Description Format

### Implementation Story (basic-task)

```markdown
## Goal
[One sentence: what this story accomplishes]

## Scope
- [Specific deliverable or change 1]
- [Specific deliverable or change 2]
- [What is explicitly NOT included]

## Acceptance Criteria
- [ ] Criterion 1 (specific, testable)
- [ ] Criterion 2
- [ ] Criterion 3

## Technical Notes
- [Relevant API endpoints, database tables, libraries]
- [Constraints or requirements to follow]

## Dependencies
- [Story #X: Title] — [nature of dependency]
- [External system or service]

## References
- [Link to relevant documentation, designs, or specifications]
```

### Testing Story (basic-task, assignee: forLoopTester)

```markdown
## Goal
[What this testing story validates]

## Scope
- [Component, feature, or system under test]
- [Test types: unit, integration, E2E, performance, security]

## Test Coverage Requirements
- [ ] [Specific scenario or edge case to test]
- [ ] [Another scenario]

## Dependencies
- [Story #X: Title] — the implementation story this tests

## Success Criteria
- Tests pass with expected coverage
- Edge cases and error paths are covered
- No flaky tests
```

### DevOps Story (basic-task, assignee: forLoopDevops)

```markdown
## Goal
[What this infrastructure change achieves]

## Scope
- [Infrastructure component to change]
- [Environment affected: dev/staging/prod]

## Configuration Changes
- [Specific Terraform/AWS/CI changes]

## Validation
- [ ] Deploy succeeds without errors
- [ ] Affected services remain healthy
- [ ] Rollback plan is documented

## Dependencies
- [Story #X: Title] — implementation that requires this infra
```

### Creator Story (basic-task, assignee: forLoopCreator)

```markdown
## Goal
[What file or asset to generate]

## Output Requirements
- **Format:** [DOCX, PDF, XLSX, PPTX, PNG, etc.]
- **Content:** [What the file should contain]
- **Style:** [Design preferences, branding, formatting]
- **Data source:** [Where to get the data for this file]

## Acceptance Criteria
- [ ] File is generated in the requested format
- [ ] File content matches the specification
- [ ] File is accessible at the expected path

## Notes
- Creator stories complete when files are generated and committed
- The Creator follows a different workflow from the code pipeline
- Generated files auto-deploy via `frontend/public/` → Vite → CI/CD
```

### Documentation Note (basic-note)

```markdown
## Context
[Background: why this note exists, what prompted it]

## Content
[The main information, organized clearly]

## Decision (if applicable)
[What was decided and why]

## Rationale
[Why this approach over alternatives]

## Implications
[What this means for the project going forward]
```

## Creator Agent Workflow (Important)

The Creator agent follows a **completely different workflow** from the code pipeline (Developer → Tester → Devops → Tester).

### Code Pipeline
```
Developer ──→ Tester ──→ Devops ──→ Tester
  (build)    (verify)   (deploy)    (validate)
```

### Creator Pipeline
```
Creator ──→ (auto-commit) ──→ (auto-deploy via CI/CD)
  (generate)     (store)          (serve)
```

**Key differences:**
- Creator has **no testing phase** — generated files are committed directly
- Creator has **no DevOps phase** — deployment is automatic
- Creator output goes to `frontend/public/` for automatic serving
- Creator stories are **typically smaller** (1-3 points) because generation is automated

### When to Use Creator vs Developer

| Scenario | Use Creator? | Use Developer? |
|----------|-------------|----------------|
| Generate a PDF report from data | Yes — generate the file | No |
| Build a page to view the report | No | Yes — build the UI |
| Create presentation slides | Yes — generate PPTX | No |
| Build slide editor UI | No | Yes — build the editor |
| Export data to Excel | Yes — generate XLSX | No |
| Build data export feature | No | Yes — build the endpoint |
| Generate chart images | Yes — generate PNG | No |
| Build interactive dashboard | No | Yes — build the UI |

**Rule of thumb:** If the output is a **binary file** (DOCX, PDF, XLSX, PPTX, image, audio, video), it's a Creator story. If the output is **code or UI**, it's a Developer story.

## Story Sequencing Guidelines

### Within a Sprint

1. **Infrastructure first.** DevOps stories that provision or configure resources should come before implementation stories that depend on them.

2. **Core features before enhancements.** Build the foundation before adding polish.

3. **Integration points early.** Stories that connect systems should start early to surface integration issues.

4. **Creator stories can run in parallel.** They have no test/DevOps phases and don't block other work.

5. **Testing stories follow implementation.** A Tester story depends on its corresponding Developer story.

### Dependency Types

| Type | Meaning | Example |
|------|---------|---------|
| **Blocks** | Story B cannot start until Story A is done | "Create database schema" blocks "Implement user model" |
| **Parallel** | Stories can be worked on simultaneously | Two independent API endpoints |
| **Enables** | Story A makes Story B possible, but B can start before A finishes | "Add auth middleware" enables "Implement protected endpoints" |
| **Tests** | A Tester story validates a Developer story | "Write tests for auth service" tests "Implement auth service" |

## Story Creation Checklist

Before creating a story, verify:
- [ ] Story has a specific, actionable title
- [ ] Correct `--type` selected (`basic-task` or `basic-note`)
- [ ] Correct `--assignee-agent` selected (if `basic-task`)
- [ ] Priority set (`low`, `medium`, `high`, `critical`)
- [ ] Points estimated (Fibonacci: 1, 2, 3, 5, 8; split if > 10)
- [ ] Description includes Goal, Scope, and Acceptance Criteria
- [ ] Dependencies documented (links to prerequisite stories)
- [ ] Sprint context matches (CLI auto-detects or explicit `--sprint`)
- [ ] Doc folder exists before story creation
- [ ] User has approved the story before creation

## Story Command Reference

### Developer Story
```bash
forloop story create \
  --title "Implement user registration endpoint" \
  --type basic-task \
  --priority high \
  --points 3 \
  --assignee-agent forLoopDeveloper \
  --description "## Goal\nCreate registration endpoint...\n\n## Scope\n- POST /api/auth/register\n..." \
  --output json --non-interactive
```

### Tester Story
```bash
forloop story create \
  --title "Write unit tests for registration flow" \
  --type basic-task \
  --priority medium \
  --points 2 \
  --assignee-agent forLoopTester \
  --description "## Goal\nValidate registration endpoint...\n\n## Test Coverage\n..." \
  --output json --non-interactive
```

### DevOps Story
```bash
forloop story create \
  --title "Add registration service to Terraform config" \
  --type basic-task \
  --priority high \
  --points 3 \
  --assignee-agent forLoopDevops \
  --description "## Goal\nProvision Lambda for registration...\n\n## Configuration\n..." \
  --output json --non-interactive
```

### Creator Story
```bash
forloop story create \
  --title "Generate monthly analytics report" \
  --type basic-task \
  --priority medium \
  --points 2 \
  --assignee-agent forLoopCreator \
  --description "## Goal\nGenerate PDF report...\n\n## Output\n- Format: PDF\n..." \
  --output json --non-interactive
```

### Documentation Note
```bash
forloop story create \
  --title "Architecture decision: Registration service design" \
  --type basic-note \
  --priority medium \
  --description "## Context\n...\n\n## Decision\n...\n\n## Rationale\n..." \
  --output json --non-interactive
```
