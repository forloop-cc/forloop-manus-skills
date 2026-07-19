# ForLoop Manus Skill

A Manus-native Skill that teaches Manus to operate as the **ForLoop Planner** — a planning-only agent that follows the ForLoop planning lifecycle and uses the `forloop` CLI as its primary execution interface.

## Purpose

This project creates a portable, importable Manus Skill that:

- Encodes the role and workflow of the ForLoop planner
- Teaches Manus the ForLoop planning lifecycle end to end
- Uses the `forloop` CLI with runtime installation when shell access is available
- Preserves safety boundaries and verification rules from existing ForLoop agent design
- Is structured for Manus progressive disclosure

## Relationship to Other ForLoop Projects

| Project | Purpose |
|---------|---------|
| `forloop-manus-skill/` | **This project** — Skill-first workflow packaging for Manus |
| `forloop-mcp/` | Protocol bridge exposing ForLoop Planner through MCP |
| `forloop-agents-skills/` | Source material — existing agent/skill definitions for opencode |
| `forloop-opencode-plugin-planner/` | Plugin-based planner for opencode |

## Package Structure

```text
forloop-manus-skill/
  SKILL.md              # Primary skill instructions (compact, authoritative)
  README.md             # This file
  DEVELOPMENT_PLAN.md   # Full development plan
  ARCHITECTURE.md       # Canonical workflow, command rules, architecture decisions
  DISCOVERY_NOTES.md    # Manus runtime validation findings
  references/           # Detailed procedural content
    planner-role.md
    cli-reference.md
    forloop-methodology.md
    story-patterns.md
    validation-checklists.md
    troubleshooting.md
  templates/            # Reusable artifact templates
    sprint-plan-template.md
    task-breakdown-template.md
    knowledge-note-template.md
  scripts/              # Shell scripts for runtime support
    preflight.sh
    auth-check.sh
```

## Status

**Documentation package authored** — `SKILL.md`, references, templates, and runtime helper scripts are present.
**Manus runtime validation still pending** — runtime install, auth persistence, and filesystem persistence have not yet been verified in a real Manus sandbox.
**Do not treat this package as runtime-verified** until `DISCOVERY_NOTES.md` is filled with actual test results and the CLI-backed path is confirmed end to end.

## Getting Started

1. Read `DEVELOPMENT_PLAN.md` for the full project plan and success criteria
2. Read `ARCHITECTURE.md` for the canonical workflow, command rules, and skill design
3. Read `DISCOVERY_NOTES.md` to see which Manus runtime assumptions are still unverified
4. `SKILL.md` is the main deliverable for skill behavior

## License

MIT
