# ForLoop Methodology: Planning Way, Sizing, and Standards

This reference covers the ForLoop planning philosophy, sprint design principles, story sizing rules, knowledge capture standards, and plan quality expectations. Load this when you need methodology depth beyond the workflow in `SKILL.md`.

## The ForLoop Way

ForLoop operates on **Loop Engineering**: a structured cycle of Plan → Code → Review → Deploy → Learn.

```
┌────────────────────────────────────────────┐
│                  L O O P                    │
│                                             │
│   Plan ──→ Code ──→ Review ──→ Deploy      │
│     ↑                             │         │
│     └────────── Learn ←───────────┘         │
└────────────────────────────────────────────┘
```

As the planner, you own the **Plan** phase. The AI agents (Developer, Tester, Devops, Creator) own the remaining phases. The **Learn** phase feeds back into the next planning cycle through knowledge capture.

### Key Implications

1. **Plans must be actionable.** Vague plans produce vague code. Every story must have clear acceptance criteria that an AI agent can validate against.

2. **Knowledge compounds.** Every planning session should capture what was learned, decided, and discovered. This knowledge feeds future sessions so they start from a higher baseline.

3. **The pipeline is pre-baked.** Don't plan custom CI/CD, deployment, or infrastructure unless the user explicitly requests it. ForLoop handles deployment via AWS serverless infrastructure.

4. **Agents have specialties.** Assign work to the right agent. Don't give infrastructure tasks to the Developer. Don't give testing tasks to DevOps.

## Sprint Design Principles

### Sprint Structure

A well-designed sprint has:

- **Clear objective** — one sentence that explains what this sprint achieves
- **Defined scope** — what is in and what is explicitly out
- **Realistic capacity** — not more work than can be completed in the timeframe
- **Measurable outcomes** — stories with acceptance criteria that can be verified
- **Documented dependencies** — what must be done first, what can be parallelized

### Capacity Planning

Use these multipliers to estimate realistic capacity:

| Strategy | Multiplier | When to Use |
|----------|-----------|-------------|
| Conservative | 60% of available time | New team, unclear requirements, high uncertainty |
| Standard | 80% of available time | Established team, moderate clarity |
| Aggressive | 100% of available time | Experienced team, very clear requirements, low risk |

Available time = sprint duration × available agents

**Example:** 2-week sprint, 3 agents (Developer, Tester, Devops), standard strategy:
- Total agent-weeks: 6
- Standard capacity: 6 × 0.8 = 4.8 agent-weeks
- If average story is 3 points ≈ 1 agent-day, then ~24 points total

### Sprint Planning Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| No sprint objective | Team doesn't know what success looks like | Write one clear sentence first |
| Overfilled sprint | Stories won't be completed, morale drops | Use capacity multipliers |
| All high-priority stories | If everything is critical, nothing is | Max 30% high/critical per sprint |
| No dependencies documented | Stories created in wrong order, blocked | Document prerequisite stories |
| Copy-paste from last sprint | Context changes, carryover should be intentional | Review and re-estimate carried stories |
| Too many small stories (1pt) | Overhead of task management exceeds work | Group related 1pt stories into 2-3pt stories |
| One giant story (10+ pts) | No clear completion point, hard to track | Split into smaller deliverable stories |

## Story Sizing and Splitting

### Estimation Framework

Stories are sized using 4 dimensions (from the ForLoop Story Evaluator):

| Dimension | Scale | What It Measures |
|-----------|-------|-----------------|
| **Complexity** | 1-5 | Technical difficulty of the problem |
| **Effort** | 1-5 | Amount of work required |
| **Uncertainty** | 1-5 | How well the requirements are understood |
| **Risk** | 1-5 | Potential for failure, side effects, or rework |

### Point Mapping

| Combined Score | Story Points | Guideline |
|---------------|-------------|-----------|
| 4-6 | 1-2 | Simple bug fix, small config change, single endpoint |
| 7-10 | 3 | Standard feature, moderate complexity |
| 11-14 | 5 | Complex feature, multiple files, integration work |
| 15-18 | 8 | Major feature, new service, significant design work |
| 19-20 | **10 (MUST SPLIT)** | Too large — break into 2+ stories |

### Fibonacci Point Scale

Points use the Fibonacci sequence: **1, 2, 3, 5, 8, 10**

- Never estimate at 0 points (nothing is zero effort)
- 10 points is the maximum — anything larger must be split
- Prefer 1-5 point stories for accurate tracking

### Story Splitting Rules

When a story is >10 points, split it along one of these axes:

1. **By endpoint/feature**: Split API endpoints or UI components into individual stories
2. **By layer**: Separate backend from frontend (e.g., API endpoint + UI component)
3. **By workflow step**: Split multi-step workflows into sequential stories
4. **By complexity gradient**: Simple part first, complex part second
5. **By agent**: Creator (generates assets) → Developer (integrates assets) — always split Creator+Developer work

**Splitting anti-pattern:** Don't split into "Part 1" and "Part 2" without clear deliverable boundaries. Each split story must have its own acceptance criteria.

### Reference Story Library

| Story Type | Typical Points | Notes |
|-----------|---------------|-------|
| Simple bug fix (1 file, 1 function) | 1 | Very localized change |
| Single REST endpoint (CRUD) | 2-3 | Standard implementation |
| UI component (form, table, modal) | 2-3 | Per component |
| Integration between two systems | 3-5 | API calls, auth, error handling |
| Auth/authentication feature | 3-5 | Security-sensitive, needs testing |
| Full page/screen with multiple components | 5-8 | Multiple endpoints + UI |
| New microservice | 8-10 | Architecture + implementation |
| File generation (Creator) | 1-3 | DOCX/PDF/XLSX generation |
| Test suite for a feature | 2-3 | Per feature being tested |
| Infrastructure/deployment change | 3-5 | Per environment or service |
| Documentation/report (basic-note) | 1 | Information capture only |

### Common Estimation Pitfalls

| Pitfall | Reality |
|---------|---------|
| "It's just a simple change" | Every change has testing, review, and integration overhead |
| "We already did something similar" | Similar ≠ identical; differences create unexpected complexity |
| "The library handles that" | Libraries need configuration, error handling, and testing |
| "It's mostly copy-paste" | Copy-paste still needs adaptation and testing |
| "We'll figure out the details later" | Uncertainty means higher risk — add points, not remove them |
| "Testing is separate" | Testing is part of the story, not a separate phase |

## Knowledge Capture Standards

### What to Capture

During requirements gathering, capture:

1. **Domain context** — business rules, terminology, user workflows
2. **Technical constraints** — systems to integrate with, technologies to use/avoid
3. **Design decisions** — architectural choices with rationale
4. **User feedback** — preferences, pain points, must-haves vs nice-to-haves
5. **Assumptions** — things you're assuming that could change

### Knowledge File Format

```markdown
# [Topic] — Knowledge Capture

**Date:** YYYY-MM-DD
**Sprint:** #[id] [title]
**Source:** Requirements gathering session

## Context
[Background information about the domain, system, or problem]

## Key Findings
- [Finding 1]
- [Finding 2]
- ...

## Decisions Made
| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| ... | ... | ... |

## Constraints
- [Constraint 1]
- ...

## Open Questions
- [Question 1] — assigned to [person/agent], due [date]

## Dependencies
- [System A] — [nature of dependency]
- ...

## Next Steps
- [Action 1]
- ...
```

### Knowledge File Naming

```
~/.forloop/sprint-{id}/knowledge/{topic}-{YYYY-MM-DD}.md
```

Examples:
- `requirements-2026-07-19.md`
- `architecture-decisions-2026-07-19.md`
- `domain-model-2026-07-19.md`

### Knowledge Lifecycle

1. **Capture** — Write to `~/.forloop/sprint-{id}/knowledge/`
2. **Upload** — Immediately upload to S3 using the doc folder pattern
3. **Reference** — Future sessions load knowledge from S3 at startup
4. **Update** — If new information contradicts captured knowledge, update the file and re-upload

### When to Capture

Capture knowledge whenever:
- The user explains a business rule or domain concept
- A design decision is made (with rationale)
- A constraint is identified
- The user corrects a misunderstanding
- Requirements change from the original plan

**Never defer knowledge capture.** The best time to capture is immediately after the information is shared. Deferred capture means lost information.

## Plan Document Standards

### Plan Structure

Every sprint plan should follow this structure:

```markdown
# Sprint Plan — Sprint #[id]: [Title]

**Date:** YYYY-MM-DD
**Organization:** [org name] (#[id])
**Duration:** [start] → [end]

## 1. Sprint Objective
[One sentence: what success looks like for this sprint]

## 2. Scope

### In Scope
- [Item 1]
- ...

### Out of Scope (Explicit)
- [Item 1] — deferred to sprint #[id]
- ...

## 3. Deliverables
| Deliverable | Type | Owner | Acceptance Criteria |
|------------|------|-------|---------------------|
| ... | ... | ... | ... |

## 4. Story Breakdown
| # | Story | Points | Agent | Dependencies |
|---|-------|--------|-------|-------------|
| 1 | ... | 3 | Developer | None |
| 2 | ... | 5 | Developer | Story 1 |
| ... | ... | ... | ... | ... |

**Total points:** [N]
**Estimated capacity:** [N] (based on [conservative/standard/aggressive] × [N] agents × [N] weeks)

## 5. Timeline
| Week | Focus | Key Stories |
|------|-------|------------|
| 1 | ... | ... |
| 2 | ... | ... |

## 6. Risks and Mitigations
| Risk | Impact | Likelihood | Mitigation |
|------|--------|-----------|------------|
| ... | High/Med/Low | High/Med/Low | ... |

## 7. Dependencies
| Depends On | For Story | Status |
|-----------|-----------|--------|
| ... | ... | Ready/Pending/Blocked |

## 8. Knowledge Captured
- [Link to knowledge file 1]
- ...

## 9. Assumptions
- [Assumption 1]
- ...

## 10. Approval
- [ ] Plan reviewed with user
- [ ] Scope confirmed
- [ ] Stories ready for creation
```

### Plan Naming

```
~/.forloop/sprint-{id}/plan/sprint-plan-{YYYY-MM-DD}.md
```

### Plan Quality Checklist

A plan is ready for story creation when:
- [ ] Sprint objective is one clear sentence
- [ ] Scope boundaries are explicit (in and out)
- [ ] Every deliverable has acceptance criteria
- [ ] Total points fit within estimated capacity
- [ ] Stories have dependencies listed
- [ ] Risks are identified with mitigations
- [ ] User has reviewed and approved the plan
- [ ] Plan is uploaded to S3 and verified

### Plan Anti-Patterns

| Bad Plan Smell | Fix |
|---------------|-----|
| Objectives section is empty or generic | Write a specific, measurable objective |
| No "Out of Scope" section | Explicitly list what's NOT in this sprint |
| Stories have no points | Estimate every story |
| No dependencies documented | Map prerequisite relationships |
| Total points > capacity × 2 | Reduce scope or split into multiple sprints |
| All stories are the same size | Real work varies; 3s and 5s should dominate |
| No acceptance criteria | Add testable criteria for each deliverable |

## Default Technology Assumptions

When planning web development work, assume the ForLoop default stack:

- **Frontend:** React 18+ with Vite, TypeScript
- **Backend:** AWS Lambda (Node.js 20), API Gateway
- **Database:** DynamoDB
- **Infrastructure:** Terraform, AWS (managed by ForLoop)
- **CI/CD:** Pre-configured GitHub Actions pipeline (managed by ForLoop)
- **Authentication:** JWT via ForLoop auth service
- **Storage:** S3 for files, DynamoDB for data
- **Multi-tenant:** All resources are tenant-isolated per organization

**Do not plan:** custom deployment pipelines, infrastructure provisioning, database schema migrations (auto-handled), authentication system design (pre-built).

**Do plan:** API endpoints, UI components, business logic, data models within DynamoDB patterns, file upload workflows, integration patterns.
