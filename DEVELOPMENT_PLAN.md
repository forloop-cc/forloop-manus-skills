# ForLoop Manus Skill Development Plan

Status: Phase 0-6 complete, Phase 1 test plan designed, awaiting Manus sandbox for execution
Owner: TBD
Last updated: 2026-07-19

## 1. Purpose

Create a new Manus-native Skill project in `forloop-manus-skill/` that teaches Manus how to operate as the **ForLoop Planner** using the **ForLoop way of planning** and, where feasible, the **ForLoop CLI** as the execution interface.

This project is intentionally separate from the existing `forloop-mcp/` effort:

- `forloop-manus-skill/` = Skill-first workflow packaging for Manus
- `forloop-mcp/` = protocol bridge that exposes ForLoop Planner through MCP

The Manus Skill should make the generic Manus agent behave like `forLoopPlannerCLI`, even if Manus does not support a platform-level custom agent definition in the same way as opencode.

## 2. Goal

Deliver a portable, importable Manus Skill that:

- Encodes the role and workflow of the ForLoop planner
- Teaches Manus the ForLoop planning lifecycle end to end
- Uses the `forloop` CLI as the preferred execution mechanism when shell execution is available
- Preserves key safety boundaries and verification rules from existing ForLoop agent design
- Is structured for Manus progressive disclosure, with high-signal instructions in `SKILL.md` and larger details in bundled resources

## 3. Success Criteria

The project is successful when all of the following are true:

- A Manus user can import the skill from a folder, zip, or GitHub repo
- The skill clearly tells Manus when it should be used and what it must do first
- The skill reliably follows the ForLoop planner workflow rather than drifting into generic project planning
- The skill uses the `forloop` CLI command patterns correctly:
  - always `--output json`
  - always `--non-interactive`
  - checks exit codes
  - avoids direct `curl` or hand-built API calls
- The skill enforces the planning-only boundary:
  - no direct app implementation
  - no build/scaffold behavior
  - no destructive actions without warning
- The skill preserves the mandatory doc-folder sync and verification workflow
- The package is documented enough for manual maintenance and iteration

## 4. Non-Goals

The first version should not attempt to do all of the following:

- Replace the `forloop-mcp/` integration path
- Recreate full opencode agent semantics such as mode, temperature, or permissions
- Depend on plugin-only ForLoop tools
- Implement new server-side ForLoop APIs
- Solve every future automation scenario on day one

## 5. Key Product Decision

### 5.1 Chosen approach

Build a **primary Manus Skill** that acts like the planner brain, with the CLI reference and methodology bundled as supporting resources.

This means:

- `SKILL.md` is the source of truth for planner behavior
- bundled resources provide detailed command patterns, planning rules, and checklists
- Manus loads the planner behavior first, then loads deeper references only when needed

### 5.2 CLI installation strategy for v1

The v1 skill will use **runtime installation** for the `ForLoop CLI`.

Decision:

- Do **not** assume `forloop` is preinstalled in the Manus runtime
- Do **not** treat custom preinstalled images as part of the v1 design
- Use a mandatory **preflight check** at the start of any CLI-backed workflow
- If `forloop` is missing and the environment supports `npm`, install it at runtime
- If runtime installation is not possible, stop cleanly and fall back to guidance-only behavior rather than attempting unsafe or partial mutations

Default preflight order:

1. Check whether `forloop` is already available
2. Check whether `node` and `npm` are available
3. Check whether `jq` is available, or use fallback parsing guidance if needed
4. Install `@forloop-cc/forloop-cli` if `forloop` is missing and `npm` exists
5. Verify installation with `forloop --version`
6. Verify auth state with `forloop auth status`
7. Continue only after the environment is confirmed usable

Representative flow:

```bash
if ! command -v forloop >/dev/null 2>&1; then
  if command -v npm >/dev/null 2>&1; then
    npm install -g @forloop-cc/forloop-cli
  else
    echo "ForLoop CLI is not installed and npm is unavailable."
    exit 1
  fi
fi

forloop --version
forloop auth status
```

### 5.3 Why this approach

This follows the key lesson already visible in the ForLoop skill ecosystem:

- high-level agent instructions determine what the model actually does
- low-level command references help only after the correct workflow has been established

Therefore, the Manus package should be:

- workflow-first
- CLI-enabled
- resource-backed

not:

- CLI-reference-first
- loosely guided
- generic planning with a few commands attached

## 6. Source Material to Reuse

The new skill should be drafted primarily from these existing sources:

- `forloop-agents-skills/agents/forLoopPlannerCLI.md`
  - primary planner role, startup flow, command rules, planning lifecycle
- `forloop-agents-skills/skills/forloop-cli/SKILL.md`
  - CLI command catalog, exit code rules, command examples, auth behavior
- `forloop-opencode-plugin-planner/docs/SKILLS-GAP-ANALYSIS.md`
  - lessons about what the model skips when top-level instructions are weak
- `forloop-agents-skills/README.md`
  - framing around agents, skills, storage layout, and platform portability

These sources should be normalized into Manus-friendly material rather than copied as-is.

## 7. Major Unknowns to Validate Early

This project has several Manus-specific unknowns. These should be validated before heavy authoring work.

### 7.1 Skill package shape

Need to confirm the practical package structure Manus expects for import from GitHub or folder:

- `SKILL.md` at repo root
- optional `scripts/`
- optional `references/`
- optional `templates/`

Current official guidance strongly suggests this structure, but the implementation should verify the exact behavior during import and execution.

### 7.2 CLI runtime feasibility inside Manus

Need to confirm whether Manus can actually run the `forloop` CLI in its sandbox in a reliable way.

Questions:

- Can the skill install npm packages during execution?
- Is the environment persistent across steps or sessions?
- Can auth state be stored safely between runs?
- Is shell access broad enough for `forloop` and `jq` usage?
- Are there restrictions on outbound network access to ForLoop APIs?

This is the highest-risk dependency for the skill-first path.

Working assumption for v1:

- CLI-backed execution is the preferred path
- runtime installation via `npm install -g @forloop-cc/forloop-cli` is the intended mechanism
- preinstallation is not assumed
- every real run must begin with preflight verification

### 7.3 Auth model in the Manus sandbox

Need to confirm how the skill should instruct users to authenticate.

Possible patterns:

- ask user to run `forloop auth login --api-key ...` within the Manus environment
- use environment variables or secure secrets if Manus provides them
- avoid token persistence and request credentials per session

The first version should avoid assuming secret storage support until verified.

### 7.4 File persistence expectations

Need to validate whether Manus preserves the local skill working directory or home directory across runs.

This matters because the existing ForLoop planner assumes:

- `~/.forloop/manifest.json`
- `~/.forloop/sprint-{id}/plan/`
- `~/.forloop/sprint-{id}/task/`
- `~/.forloop/sprint-{id}/knowledge/`

If Manus sessions are ephemeral, the skill must treat sync-from-remote as mandatory at every session start.

## 8. Proposed Repository Layout

Recommended first layout for `forloop-manus-skill/`:

```text
forloop-manus-skill/
  SKILL.md
  README.md
  DEVELOPMENT_PLAN.md
  references/
    planner-role.md
    cli-reference.md
    forloop-methodology.md
    story-patterns.md
    validation-checklists.md
    troubleshooting.md
  templates/
    sprint-plan-template.md
    task-breakdown-template.md
    knowledge-note-template.md
  scripts/
    preflight.sh
    auth-check.sh
```

Notes:

- `SKILL.md` should remain compact and authoritative
- `references/` should hold large or detailed procedural content
- `templates/` should hold reusable artifacts the skill may reference
- `scripts/` should support the runtime-install strategy and should stay small, explicit, and reviewable

## 9. Deliverables

The project should produce the following artifacts.

### 9.1 Required artifacts

- `SKILL.md`
- `README.md`
- `references/planner-role.md`
- `references/cli-reference.md`
- `references/forloop-methodology.md`
- `references/story-patterns.md`
- `references/validation-checklists.md`
- `references/troubleshooting.md`

### 9.2 Optional artifacts

- `templates/sprint-plan-template.md`
- `templates/task-breakdown-template.md`
- `templates/knowledge-note-template.md`
- `scripts/preflight.sh`
- `scripts/auth-check.sh`

### 9.3 Required operational decisions for v1

- runtime installation is the default CLI strategy
- preflight checks are mandatory before CLI-backed operations
- failure to install or verify the CLI must stop mutations and surface remediation guidance
- future preinstalled or MCP-backed execution remains an enhancement path, not a v1 dependency

## 10. Work Plan

## Phase 0: Project Setup

Objective:
Create the new workspace and establish a clean separation from other integration tracks.

Tasks:

- Create `forloop-manus-skill/`
- Add planning and project documentation
- Define the purpose of this folder in a short `README.md`
- Decide whether this project will later be split into its own repository or remain inside the monorepo during incubation

Outputs:

- folder exists
- planning document exists
- initial repository shape is agreed

Acceptance criteria:

- the project has a dedicated root folder
- the project’s purpose is clearly distinguished from `forloop-mcp/`

## Phase 1: Discovery and Validation

Objective:
Reduce Manus-specific risk before claiming the skill is runtime-ready.

Current state: **Detailed test plan complete in `DISCOVERY_NOTES.md` Sections 6–9.** Execution blocked — awaiting real Manus sandbox access.

### DISCOVERY_NOTES.md Structure

The discovery notes now contain a comprehensive 23-test verification plan organized into 7 phases:

| Phase | Focus | Tests | Risk Level |
|-------|-------|-------|------------|
| A | Import and Packaging | A1 Folder import, A2 GitHub import, A3 Resource discovery | Low |
| B | Runtime Environment | B1 Shell availability, B2 Tool check, B3 Runtime install, B4 CLI verification | Low-Med |
| C | Authentication | C1 Status before login, C2 Login flow, C3 Status after login, C4 Auth persistence | Medium |
| D | Read-Only ForLoop | D1 Org listing, D2 Sprint listing, D3 Sprint get | Medium |
| E | Filesystem and Persistence | E1 Path creation, E2 Sync to local, E3 Same-session, E4 Cross-session | Medium-High |
| F | Minimal Mutation | F1 Doc folder ensure/get, F2 Upload verification | High |
| G | Skill Behavior | G1 Preflight obedience, G2 Planning boundary, G3 Command discipline | High |

**Verification order:** Must run A → B → C → D → E → F → G (low-risk first, mutations last, avoids credentials before viability is known).

**Stop conditions (8):** Each test phase has explicit stop conditions documented in `DISCOVERY_NOTES.md` Section 8. If any stop condition is hit, record the failure and assess whether to fall back to guidance-only or MCP-backed execution.

**Sign-off criteria (11):** `DISCOVERY_NOTES.md` Section 9 lists the full sign-off checklist required before declaring the skill runtime-verified.

### Tasks

- [x] Design detailed test plan with 23 tests across 7 phases (complete)
- [x] Define stop conditions and sign-off criteria (complete)
- [x] Cross-check SKILL.md against all test expectations (complete — no gaps found)
- [ ] Execute Phase A tests (Import and Packaging) — requires Manus sandbox
- [ ] Execute Phase B tests (Runtime Environment) — requires Manus sandbox
- [ ] Execute Phase C tests (Authentication) — requires Manus sandbox
- [ ] Execute Phase D tests (Read-Only ForLoop) — requires Manus sandbox
- [ ] Execute Phase E tests (Filesystem and Persistence) — requires Manus sandbox
- [ ] Execute Phase F tests (Minimal Mutation) — requires Manus sandbox
- [ ] Execute Phase G tests (Skill Behavior) — requires Manus sandbox

### Outputs

- `DISCOVERY_NOTES.md` — detailed test plan with recording format, verification order, stop conditions, and sign-off checklist
- `TEST_RESULTS.md` — structured results tracking file ready for execution

### Acceptance criteria

- the team has a clear, executable test plan that a reviewer can follow in a Manus sandbox
- the test plan covers import, runtime, auth, read-only, persistence, writes, and behavioral boundaries
- SKILL.md has been verified against all test expectations
- the decision gate can be resolved as soon as Manus sandbox access is available

### Decision gate

- If all Phase A–G tests pass (11 sign-off criteria met), declare the skill **runtime-verified for Manus CLI-backed use**
- If critical tests fail (stop conditions triggered), shift v1 to **workflow guidance only** and treat actual ForLoop mutations as deferred to MCP or future runtime integration
- The decision remains **pending** until Manus sandbox execution is possible

## Phase 2: Source Audit and Canonical Workflow Extraction

Objective:
Build one coherent planner model from existing ForLoop agent and skill material.

Tasks:

- Extract the planner role and behavioral rules from `forLoopPlannerCLI.md`
- Extract CLI command rules from `forloop-cli/SKILL.md`
- Extract reliability lessons from `SKILLS-GAP-ANALYSIS.md`
- Identify duplicate or conflicting instructions
- Decide what belongs in `SKILL.md` vs `references/`
- Convert opencode-specific assumptions into Manus-neutral wording

Outputs:

- canonical planner workflow outline
- canonical command rule set
- migration map from old files to new Manus artifacts

Acceptance criteria:

- there is one agreed source-of-truth workflow for the Manus skill
- critical rules are not split across too many files

## Phase 3: Skill Architecture Design

Objective:
Design the Manus skill package around progressive disclosure.

Tasks:

- Define what must appear in `SKILL.md`
- Define which detailed references are loaded on demand
- Decide whether the skill should be single-skill only or later decomposed into multiple Manus skills
- Define user-facing skill metadata:
  - name
  - description
  - scope
  - when to use
  - when not to use
- Define the expected interaction style with Manus users
- Define the preflight and fallback decision tree for CLI usage

Recommended `SKILL.md` structure:

1. Metadata
2. Role and boundaries
3. When to use this skill
4. Prerequisites
5. Runtime installation and preflight rules
6. Session startup checklist
7. Non-negotiable command rules
8. Default planning workflow
9. Story creation rules
10. File sync and verification rules
11. Failure handling
12. Out-of-scope behavior
13. References to bundled materials

Outputs:

- approved skill architecture
- final package layout decision

Acceptance criteria:

- `SKILL.md` stays compact enough for efficient loading
- critical planner behavior is present without needing deep references first

## Phase 4: Core Skill Authoring

Objective:
Draft the main Manus skill instructions.

Tasks:

- Write the planner identity in Manus-friendly language
- Encode the planning-only boundary explicitly
- Write the runtime installation policy:
  - never assume `forloop` is preinstalled
  - install at runtime when needed and supported
  - stop cleanly when install prerequisites are missing
- Write the startup routine:
  - verify CLI presence
  - install CLI if missing and `npm` is available
  - verify `node` and `npm`
  - verify `forloop --version`
  - verify auth state
  - sync remote documents
  - inspect sprint context
  - summarize findings
- Encode mandatory command rules:
  - `--output json`
  - `--non-interactive`
  - check exit codes
  - no direct `curl`
  - warn before destructive actions
- Encode the default workflow:
  - session start
  - sprint discovery
  - requirements gathering
  - knowledge capture
  - plan generation
  - task breakdown
  - story creation
  - optional developer trigger
- Encode the doc-folder upload pattern:
  - ensure
  - get
  - upload
  - verify

Outputs:

- first draft of `SKILL.md`

Acceptance criteria:

- the skill reads like a planner operating manual, not a generic command reference
- the mandatory workflow is obvious from the first read

## Phase 5: Reference Authoring

Objective:
Move depth into supporting resources without weakening core behavior.

Tasks:

- `references/planner-role.md`
  - planner philosophy
  - safety boundary
  - success definition
- `references/cli-reference.md`
  - runtime installation
  - install
  - auth
  - sprint commands
  - story commands
  - sync commands
  - agent commands
  - exit codes
- `references/forloop-methodology.md`
  - what “ForLoop way” means
  - sprint design principles
  - story sizing and splitting rules
  - knowledge capture standards
  - expected plan document quality
- `references/story-patterns.md`
  - implementation stories
  - notes
  - creator stories
  - tester stories
  - agent assignment mapping
- `references/validation-checklists.md`
  - runtime install checklist
  - startup checklist
  - before-completion checklist
  - upload verification checklist
- `references/troubleshooting.md`
  - auth issues
  - missing sprint context
  - CLI missing
  - runtime install failed
  - missing `node` or `npm`
  - quota errors
  - sync failures

Outputs:

- complete reference set

Acceptance criteria:

- `SKILL.md` can remain concise because the references carry detailed depth
- the references are task-oriented and easy to navigate

## Phase 6: Template and Script Support

Objective:
Add reusable artifacts only where they improve execution reliability.

Tasks:

- Draft plan and task templates that match ForLoop planning outputs
- Add shell scripts that support the runtime-install and preflight flow if sandbox tests prove stable execution value
- Keep script count intentionally small
- Ensure scripts are safe, inspectable, and easy to review

Recommended rule:

- Prefer instructions over scripts unless scripts materially reduce repeated failure

Possible scripts:

- `scripts/preflight.sh`
  - verify `forloop`
  - verify `node`
  - verify `npm`
  - verify `jq`
  - install `forloop` via npm when missing
  - verify `forloop --version`
  - print auth status
- `scripts/auth-check.sh`
  - run `forloop auth status`
  - print user-facing remediation guidance

Outputs:

- optional support scripts
- templates for consistent output generation

Acceptance criteria:

- any script included is justified by real execution value
- no script hides important workflow logic that belongs in `SKILL.md`

## Phase 7: Manual Validation in Manus

Objective:
Validate the skill in the real Manus environment with realistic planner tasks.

Test scenarios:

- Scenario 1: user asks to inspect current sprint and summarize context
- Scenario 2: user asks to create a sprint plan from vague requirements
- Scenario 3: user asks to break a plan into stories with proper agent assignment
- Scenario 4: user asks to upload plan or knowledge documents
- Scenario 5: user asks for an action that is out of scope, such as writing app code
- Scenario 6: auth missing or CLI unavailable
- Scenario 7: sprint context missing and must be discovered
- Scenario 8: CLI is not installed and must be installed at runtime
- Scenario 9: `npm` is unavailable, so the skill must stop cleanly and explain the limitation

What to evaluate:

- Does Manus trigger the skill correctly?
- Does it follow startup checks before acting?
- Does it keep the planning-only boundary?
- Does it use the right CLI flags every time?
- Does it follow the runtime-install decision tree correctly?
- Does it preserve the doc-folder upload workflow?
- Does it avoid generic drift?
- Does it recover gracefully from auth or environment failures?

Outputs:

- manual test log
- issue list
- refined wording for weak sections

Acceptance criteria:

- the skill behaves consistently across several realistic planning tasks
- failure cases are understandable and recoverable

## Phase 8: Packaging and Distribution

Objective:
Prepare the skill for actual use and sharing.

Tasks:

- confirm Manus import works from local folder
- confirm Manus import works from GitHub repo if public sharing is desired
- add installation and usage instructions to `README.md`
- define versioning strategy for skill updates
- define release checklist

Suggested distribution options:

- monorepo incubation first
- later extract to standalone repo if the package stabilizes

Outputs:

- importable package
- usage guide
- release process

Acceptance criteria:

- a reviewer can import and use the skill without needing hidden setup knowledge

## 11. Content Strategy for `SKILL.md`

The `SKILL.md` should optimize for the first 30 seconds of model understanding.

The top of the file should immediately communicate:

- who the skill is for
- what role it plays
- what it must not do
- what it must do first
- how it interacts with ForLoop

Recommended opening emphasis:

- "You are a planning-only ForLoop planner."
- "Use the `forloop` CLI as the primary interface when shell access is available."
- "Do not implement application code."
- "Always start by verifying CLI/auth/context."
- "Always verify uploads and state-changing operations."

## 12. Proposed First-Version Scope

To keep v1 focused, the recommended scope is:

- planning-only workflow
- sprint discovery
- requirements gathering
- knowledge capture guidance
- sprint plan generation guidance
- task breakdown guidance
- story creation guidance
- optional developer trigger guidance
- CLI command patterns and troubleshooting

Explicitly defer from v1:

- advanced multi-skill orchestration
- deep automation with many helper scripts
- non-planning domains
- full parity with opencode subagents
- direct MCP integration inside the skill package

## 13. Risks and Mitigations

### Risk 1: Manus runtime cannot reliably run the CLI

Mitigation:

- validate in Phase 1 before deep authoring
- validate the runtime installation path, not just CLI execution after install
- keep v1 able to degrade into workflow guidance if needed
- preserve `forloop-mcp/` as an alternate execution path

### Risk 2: The skill becomes too large and loses focus

Mitigation:

- keep `SKILL.md` concise
- push large command catalogs into `references/`
- write one primary skill instead of many small ones in v1

### Risk 3: Instructions drift from real ForLoop behavior

Mitigation:

- source from existing planner and CLI artifacts
- preserve mandatory rules from current agent design
- validate with real planning scenarios

### Risk 4: Auth and persistence assumptions are wrong

Mitigation:

- treat authentication and persistence as explicit discovery tasks
- avoid hidden assumptions in the skill text
- include troubleshooting and fallback instructions

### Risk 5: Runtime installation is slow or flaky

Mitigation:

- keep the install path minimal and explicit
- check for existing `forloop` before attempting install
- fail fast when `node` or `npm` is missing
- document a future move to pre-baked or MCP-backed execution if runtime friction stays high

### Risk 6: The skill becomes a generic PM assistant

Mitigation:

- define the ForLoop-specific planning philosophy clearly
- encode exact artifacts, sync rules, and story patterns
- keep the planning-only boundary visible

## 14. Recommended Milestones

Milestone 1: Discovery design complete (test plan ready)

- 23-test verification plan designed across 7 phases (A–G)
- Stop conditions and sign-off criteria defined
- SKILL.md cross-checked against test expectations — no gaps found
- ⬜ Awaiting Manus sandbox access for execution

Milestone 2: Architecture locked ✅ Complete

- package layout agreed
- source-of-truth workflow extracted (ARCHITECTURE.md)
- `SKILL.md` outline approved (13 sections)

Milestone 3: Authoring complete ✅ Complete

- `SKILL.md` drafted (404 lines, 12 sections)
- supporting references drafted (6 files, 1,774 lines total)
- templates drafted (3 files) and scripts drafted (2 files, syntax-verified)

Milestone 4: Validation complete ⬜ Pending

- Manus manual tests designed, not yet executed
- ⬜ 11 sign-off criteria must pass before declaring runtime-verified
- ⬜ runtime installation behavior must be validated in real Manus runs

## 15. Recommended Immediate Next Steps

The next implementation steps should be:

1. ✅ Add `README.md` to `forloop-manus-skill/` describing project purpose and scope
2. ✅ Create `DISCOVERY_NOTES.md` with detailed test plan (completed — now 451 lines with 23-test verification plan)
3. ✅ Draft the runtime-install preflight checklist and fallback decision tree (completed in SKILL.md §4 and ARCHITECTURE.md)
4. ✅ Create placeholder files under `references/` and full content (completed — 6 reference files, 1,774 lines)
5. ✅ Draft the first `SKILL.md` (completed — 404 lines, 12 sections)
6. ⬜ Run a real Manus import and execution spike (blocked — requires Manus sandbox access)
7. ⬜ Execute test plan Phases A–G from `DISCOVERY_NOTES.md` (blocked — requires Manus sandbox access)
8. ⬜ Record results in `TEST_RESULTS.md` and resolve the decision gate

## 16. Final Recommendation

The Manus skill should be treated as a **planner operating manual** with bundled execution references, not as a raw CLI cookbook.

The best v1 is:

- one primary Manus skill
- workflow-first instructions
- CLI-enabled through runtime installation and preflight verification
- reference-backed for depth
- validated early against Manus runtime constraints

That approach gives the highest chance that Manus will consistently behave like `forLoopPlanner`, even without native custom-agent support.
