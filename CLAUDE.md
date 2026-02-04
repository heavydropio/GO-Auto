# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

GO-Auto is an autonomous build orchestration system for Claude Code. It's a fork of GO-Build designed for fully autonomous execution without human checkpoints. The system runs multi-phase software builds using specialized agents coordinated by a "Boss" orchestrator.

**Key Difference from GO-Build**: Auto-approves plans in Phase C, auto-retries failures with confidence-based decision making, and eliminates session handoff prompts for continuous execution.

## Installation

```bash
# Install to Claude Code plugins directory
./install.sh
```

This copies:
- Agent definitions to `~/.claude/plugins/go-auto/agents/`
- Commands to `~/.claude/commands/go-auto/`
- Templates to `~/.claude/plugins/go-auto/templates/`
- Sections to `~/.claude/plugins/go-auto/sections/`

## Command Structure

Commands are invoked as `/go:auto`, `/go:discover`, etc. Each command is defined in `commands/*.md` with:
- Arguments specification
- Prerequisites
- Execution flow
- Output artifacts

### Primary Commands

- `/go:auto [N]` - Run autonomous build for N phases (or all phases in ROADMAP.md)
- `/go:discover` - Pre-build discovery to create ROADMAP.md
- `/go:preflight` - Environment validation before build
- `/go:verify` - Final E2E verification

## Architecture

### Three-Layer System

1. **Command Layer** (`commands/`)
   - Entry points that users invoke
   - Define execution flow and prerequisites
   - Spawn agents and coordinate phases

2. **Agent Layer** (`agents/`)
   - Specialized workers with defined roles
   - All agents run as Opus (no model variation)
   - Agents include: Prebuild Planner, Build Planner, Builder, Code Reviewer, Security Reviewer, Refactor, Verifier
   - Discovery agents: Tech Architect, Entity Planner, Workflow Analyst, UI Planner, Edge Case Analyst

3. **Template Layer** (`templates/`)
   - Structured markdown templates for artifacts
   - Ensures consistent documentation across phases
   - Key templates: PHASE_PLAN_TEMPLATE.md, BUILD_GUIDE_TEMPLATE.md, HANDOFF_TEMPLATE.md

### Phase Structure (A-H)

**Phase A: Environment Review**
- Spawn: `go-prebuild-planner.md`
- Output: `BUILD_GUIDE_PHASE_N.md`
- Purpose: Inventory codebase, gather context

**Phase B: Build Planning**
- Spawn: `go-build-planner.md`
- Output: `PHASE_N_PLAN.md`
- Purpose: Create detailed task breakdown with waves (parallel execution groups)

**Phase C: Plan Review**
- **Autonomous**: Auto-validates plan structure (no human checkpoint)
- Checks: File ownership conflicts, smoke test validity, done-when criteria
- Abort if validation errors, warn if quality issues

**Phase D: Execution**
- Spawn: Multiple `go-builder.md` agents in parallel (one per task per wave)
- Auto-retry: Up to 2 attempts on failure if confidence ≥80%
- Git checkpoint after each wave

**Phase E: Code Shortening**
- Spawn: `go-refactor.md` agents
- Purpose: Reduce code complexity without changing behavior

**Phase F: Code Review**
- Spawn: `go-code-reviewer.md` + `go-security-reviewer.md` in parallel
- Auto-retry blocked reviews up to 2 times
- Abort if still blocked after retries

**Phase G: Status Update**
- Update HANDOFF.md with beads (decision tracking)
- Create git tag: `v{version}-phase-N`
- No RESTART_PROMPT (continuous execution)

**Phase H: Final Verification**
- Spawn: `go-verifier.md`
- Output: `FINAL_VERIFICATION.md` + `PROJECT_REPORT.md`

### Wave System

Tasks within a phase are organized into waves for parallel execution:
- **Wave**: Group of tasks that can run simultaneously
- **File Ownership Guarantee**: Ensures no two parallel tasks write to the same file
- **Dependencies**: Later waves depend on earlier waves completing

### Autonomous Failure Handling

When a task fails:

1. Worker invokes `systematic-debugging` skill (mandatory)
2. Returns structured failure report with confidence level (0-100%)
3. Boss evaluates:
   - **Confidence ≥80% AND fix contained**: Auto-retry (max 2 attempts)
   - **Confidence <80% OR non-contained**: Abort with full context
4. Success: Record auto-recovery in plan
5. Failure: Abort phase, preserve context for manual recovery

See `sections/FAILURE_PROTOCOL.md` for complete logic.

### Beads: Decision Tracking

Even in autonomous mode, capture key moments:

- **DD-NNN (Decision)**: Architectural choice made
- **DS-NNN (Discovery)**: Non-obvious learning
- **AS-NNN (Assumption)**: Unvalidated bet
- **FR-NNN (Friction)**: Harder than expected
- **PV-NNN (Pivot)**: Direction change

Beads are stored in HANDOFF.md and aggregated from PHASE_N_PLAN.md files.

## Key Files and Protocols

### Agent Roles

- **Boss** (you): Orchestrates phases, spawns workers, makes autonomous decisions
- **Workers**: Execute specific tasks, follow plan exactly, report detailed notes

### Agent Notes Format

Workers return structured notes with emoji prefixes:
- 🔨 Worker Notes (always required)
- 📋 Skill Decision (when skills listed in plan)
- ⚠️ Issue Found / Issue Fixed (when problems encountered)
- 🔴 Task Failed (when cannot complete)

See `sections/AGENT_NOTES_FORMAT.md` for complete specification.

### Skill System

Skills are specialized capabilities invoked during execution:
- **Mandatory**: `systematic-debugging` (on failure), `verification-before-completion` (Phase F)
- **Recommended**: `test-driven-development` (Phase D), `brainstorming` (Phase A)
- **Optional**: Can be skipped with documented justification

See `sections/SKILL_DECISION_PROTOCOL.md` for decision rules.

## Common Patterns

### Adding a New Agent

1. Create `agents/go-[agent-name].md`
2. Define frontmatter: name, description, tools, color
3. Specify role, philosophy, execution flow
4. Document boundaries and success criteria
5. Reference from appropriate command in `commands/`

### Adding a New Command

1. Create `commands/[command-name].md`
2. Define frontmatter: description, arguments
3. Document prerequisites and validation
4. Specify execution flow with agent spawning
5. Define output artifacts

### Modifying Templates

Templates in `templates/` define structure for build artifacts. When modifying:
- Maintain section headers (used by agents for parsing)
- Keep frontmatter consistent
- Update corresponding agent that uses the template

## Discovery System

Pre-build discovery (`/go:discover`) is a 7-round conversational process:

1. **Context**: Project goals, scope, constraints
2. **Entities**: Data model and relationships
3. **Workflows**: User flows and business logic
4. **Screens**: UI/UX specifications
5. **Edge Cases**: Error handling, security, performance
6. **Lock-In**: Finalize decisions
7. **Build Plan**: Generate ROADMAP.md

Discovery agents in `agents/go-discovery-*.md` are spawned in parallel to analyze different aspects. Final output is `USE_CASE.yaml` and `ROADMAP.md`.

## Git Strategy

```bash
# After each wave
git add [wave-files]
git commit -m "feat(phase-N-wM): [wave-description]"

# After each phase
git tag v[version]-phase-N

# On abort
git tag v[version]-phase-N-aborted
```

## Abort Conditions

GO-Auto aborts immediately when:
- Plan validation fails (file conflicts, missing smoke tests)
- 3 consecutive failures on same task
- Review blocked after 2 fix attempts
- Confidence <80% on suggested fix
- Security issue found

On abort: Full context preserved in PHASE_N_PLAN.md, git tag created, recovery options provided.

## Development Notes

### File Organization

```
GO-Auto/
├── SKILL.md                 # Main skill definition (loaded by Claude Code)
├── README.md                # User documentation
├── commands/                # User-invocable commands
│   ├── auto.md             # /go:auto - main autonomous command
│   ├── discover.md         # Pre-build discovery
│   ├── preflight.md        # Environment validation
│   └── verify.md           # Final verification
├── agents/                  # Agent definitions (spawned by commands)
│   ├── go-prebuild-planner.md
│   ├── go-build-planner.md
│   ├── go-builder.md       # Worker agent (runs in parallel)
│   ├── go-code-reviewer.md
│   ├── go-security-reviewer.md
│   └── go-discovery-*.md   # Discovery specialists
├── templates/               # Artifact structure templates
│   ├── PHASE_PLAN_TEMPLATE.md
│   ├── BUILD_GUIDE_TEMPLATE.md
│   └── HANDOFF_TEMPLATE.md
├── sections/                # Reusable protocol documentation
│   ├── FAILURE_PROTOCOL.md # Auto-retry logic
│   ├── SKILL_DECISION_PROTOCOL.md
│   └── AGENT_NOTES_FORMAT.md
└── discovery/               # Discovery system templates
    └── templates/
        ├── ROUND_1_CONTEXT.md
        └── ROUND_7_BUILD_PLAN.md
```

### When to Use GO-Auto vs GO-Build

**Use GO-Auto when:**
- Solid ROADMAP exists with completed discovery
- Plan structure is trusted
- Hands-off execution desired
- Single session, no breaks needed

**Use GO-Build when:**
- Complex project needing human judgment at checkpoints
- Uncertain or evolving requirements
- Multi-day builds with session breaks expected
- Human approval needed before execution phases

## Extending GO-Auto

### Custom Discovery Templates

Add module templates to `discovery/templates/MODULE_*.md` following the schema in `discovery/USE_CASE_TEMPLATE_SCHEMA.md`.

### Custom Skills

Reference skills in agent definitions and document in `sections/SKILL_DECISION_PROTOCOL.md`. Mandatory skills cannot be skipped; optional skills require justification to skip.

### Custom Phases

Modify ROADMAP.md structure. Each phase follows A-H sub-structure. Phases are sequential; sub-phases (waves) can be parallel.
