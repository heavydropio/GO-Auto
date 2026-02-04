# GO-Auto: Autonomous Build Orchestration

A fork of [GO-Build](https://github.com/heavydropio/GO-Build) designed for fully autonomous execution without human checkpoints.

## What's Different from GO-Build

| Aspect | GO-Build | GO-Auto |
|--------|----------|---------|
| **Phase C checkpoint** | Human approves plan ("go") | Auto-validate and proceed |
| **Failure handling** | Boss decides retry/skip/abort | Auto-retry (max 2) then abort |
| **Session breaks** | Expected, with restart prompts | None (continuous execution) |
| **RESTART_PROMPT** | Created each phase | Not created |
| **HANDOFF_PHASE_N** | Created each phase | Not created |
| **HANDOFF.md** | Full session context | Beads only (simplified) |

## When to Use GO-Auto

**Use GO-Auto when:**
- You have a solid ROADMAP and completed discovery
- You trust the plan structure
- You want hands-off execution
- Single session, no breaks needed
- Building well-understood features

**Use GO-Build when:**
- Complex project needing human judgment
- Uncertain or evolving requirements
- Multi-day builds with session breaks
- Need human approval at checkpoints

## Quick Start

```bash
# 1. Run discovery (same as GO-Build)
/go:discover

# 2. Run preflight (recommended)
/go:preflight

# 3. Run autonomous build
/go:auto          # All phases
/go:auto 3        # First 3 phases only
```

## Commands

| Command | Purpose |
|---------|---------|
| `/go:auto [N]` | Run N phases autonomously (default: all) |
| `/go:discover` | Pre-build discovery (unchanged from GO-Build) |
| `/go:preflight` | Environment validation (unchanged) |
| `/go:verify` | Final verification only (unchanged) |

## Phase Flow

```
/go:auto

Phase 1:
  A: Environment Review    → BUILD_GUIDE_PHASE_1.md
  B: Build Planning        → PHASE_1_PLAN.md
  C: Auto-Validation       → (no human checkpoint)
  D: Execution             → Workers build in parallel
  E: Code Shortening       → Refactor agents
  F: Code Review           → Auto-retry if blocked
  G: Status Update (Lite)  → Git tag, update HANDOFF.md

Phase 2:
  (repeat A-G)

...

Final:
  H: Verification          → FINAL_VERIFICATION.md + PROJECT_REPORT.md
```

## Auto-Retry Logic

When a task fails:

1. Worker invokes `systematic-debugging` (mandatory)
2. Worker returns failure report with confidence level
3. Boss evaluates:
   - **Confidence ≥ 80%** and fix is contained → Auto-retry (max 2 attempts)
   - **Confidence < 80%** → Abort and report
   - **3 failures** → Abort phase

```
Task fails → Debug → Report → Evaluate confidence
                                    ↓
                    ≥80%           <80%
                      ↓              ↓
                  Retry (max 2)   ABORT
                      ↓
              Success → Continue
              Fail    → Retry or ABORT
```

## Artifacts Created

| Artifact | When | Purpose |
|----------|------|---------|
| `BUILD_GUIDE_PHASE_N.md` | Phase A | Codebase inventory |
| `PHASE_N_PLAN.md` | Phase B | Task breakdown, execution log |
| `HANDOFF.md` | Phase G | Beads, git log, status |
| `FINAL_VERIFICATION.md` | Phase H | E2E test results |
| `PROJECT_REPORT.md` | Phase H | Build analysis |

**NOT created** (unlike GO-Build):
- ~~START_PROMPT_PHASE_1.md~~
- ~~RESTART_PROMPT_PHASE_N.md~~
- ~~HANDOFF_PHASE_N.md~~

## Abort Conditions

GO-Auto aborts immediately when:

1. Plan validation fails (file conflicts, missing smoke tests)
2. 3 consecutive failures on same task
3. Review blocked after 2 fix attempts
4. Confidence < 80% on suggested fix
5. Security issue found

On abort:
- Full context preserved in PHASE_N_PLAN.md
- Git tag created: `v{version}-phase-N-aborted`
- Recovery options provided

## Recovery After Abort

```bash
# Option 1: Fix manually, resume from current phase
# (after manual fix)
/go:auto --from-phase N

# Option 2: Switch to human-guided mode
/go:kickoff N

# Option 3: Skip to next phase (if current is non-critical)
/go:auto --from-phase N+1
```

## Directory Structure

```
GO-Auto/
├── SKILL.md                 # Main skill definition
├── README.md                # This file
├── commands/
│   ├── auto.md              # /go:auto command (NEW)
│   ├── discover.md          # Discovery (unchanged)
│   ├── preflight.md         # Preflight (unchanged)
│   ├── execute.md           # Execute (available for manual use)
│   ├── review.md            # Review (available for manual use)
│   ├── verify.md            # Verify (unchanged)
│   └── help.md              # Help
├── agents/
│   ├── go-prebuild-planner.md
│   ├── go-build-planner.md
│   ├── go-builder.md
│   ├── go-code-reviewer.md
│   ├── go-refactor.md
│   ├── go-verifier.md
│   └── ... (discovery, preflight, research agents)
├── templates/
│   ├── PHASE_PLAN_TEMPLATE.md
│   ├── BUILD_GUIDE_TEMPLATE.md
│   ├── HANDOFF_TEMPLATE.md      # Simplified for autonomous
│   ├── FINAL_VERIFICATION_TEMPLATE.md
│   └── PROJECT_REPORT_TEMPLATE.md
├── sections/
│   ├── FAILURE_PROTOCOL.md      # Updated with auto-retry
│   ├── ISSUE_RESOLUTION_PROTOCOL.md
│   ├── SKILL_DECISION_PROTOCOL.md
│   └── AGENT_NOTES_FORMAT.md
└── discovery/
    └── templates/               # Discovery templates (unchanged)
```

## Beads (Decision Tracking)

Even in autonomous mode, GO-Auto captures decisions:

| Type | Example |
|------|---------|
| DD (Decision) | "Used SQLite for simplicity" |
| DS (Discovery) | "API has undocumented rate limit" |
| AS (Assumption) | "Assumes max 1000 records" |
| FR (Friction) | "Auth took 3 retries to fix" |
| PV (Pivot) | "Switched from REST to GraphQL" |

These are stored in HANDOFF.md and help with post-build debugging.

## Installation

```bash
# Clone GO-Auto
git clone <repo-url> GO-Auto
cd GO-Auto

# Install to Claude Code plugins
cp -r . ~/.claude/plugins/go-auto/

# Or create symlink
ln -s $(pwd) ~/.claude/plugins/go-auto
```

## Comparison: Execution Time

| Project Size | GO-Build | GO-Auto |
|--------------|----------|---------|
| Small (1-2 phases) | ~30 min (with checkpoints) | ~15 min |
| Medium (3-5 phases) | ~2 hours (with breaks) | ~45 min |
| Large (6+ phases) | Multi-session | Single session (if context allows) |

*Estimates assume similar task counts. GO-Auto is faster due to no human wait time.*

## Limitations

1. **No mid-build human judgment** — If requirements are unclear, use GO-Build
2. **Confidence threshold (80%)** — Low-confidence fixes require human review
3. **Context window** — Very large builds may still hit context limits
4. **Security issues** — Always abort on security findings (no auto-fix)

## Contributing

GO-Auto is a fork of GO-Build. For the original project, see:
https://github.com/heavydropio/GO-Build

## License

Same as GO-Build.
