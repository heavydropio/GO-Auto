---
description: Show General Orders commands and usage guide.
---

# General Orders — Command Reference

## Overview

General Orders (GO) is a unified build orchestration system for complex multi-phase projects.

## Commands

### Project Setup
| Command | Description |
|---------|-------------|
| `/go:discover` | Guided conversation about your project. Routes to light path (focused builds) or full path (complex projects with R2-R7) |
| `/go:preflight [scope]` | Validate environment before build. Scope: phase (1, A.1), track (A, B), or "all" |

### Execution
| Command | Description |
|---------|-------------|
| `/go:kickoff <phase>` | Full orchestration: review → plan → approve → execute |
| `/go:execute <phase>` | Execute a phase plan (Phase D only) |
| `/go:review <phase>` | Code shortening + code review (Phases E-F) |

### Finalization
| Command | Description |
|---------|-------------|
| `/go:status <phase>` | Version bump, git tag, handoff docs (Phase G) |
| `/go:verify <phase>` | E2E tests + project report (Phase H) |

### Utility
| Command | Description |
|---------|-------------|
| `/go:help` | Show this help |

## Typical Workflow

```bash
# New project
/go:discover                # Guided conversation about your project
/go:preflight               # Validate environment

# For each phase
/go:kickoff 1               # Full Phase 1 orchestration
/go:review 1                # Shorten and review
/go:status 1                # Finalize Phase 1
/go:verify 1                # Final verification

# Repeat for next phases
/go:kickoff 2
# ...
```

## Quick Reference

### Phase Structure
| Phase | Name | Purpose |
|-------|------|---------|
| A | Environment Review | Gather context |
| B | Build Planning | Create detailed plan |
| C | Plan Review | Boss approves (human checkpoint) |
| D | Execution | Workers build in parallel |
| E | Code Shortening | Reduce without breaking |
| F | Code Review | Quality gates |
| G | Status Update | Version, tag, handoff |
| H | Final Verification | E2E + report |

### Key Documents
| Document | Purpose |
|----------|---------|
| `PROJECT.md` | Vision and scope |
| `REQUIREMENTS.md` | What to build |
| `ROADMAP.md` | Phase breakdown |
| `PREFLIGHT.md` | Environment validation report |
| `PHASE_X_PLAN.md` | Detailed execution plan |
| `BUILD_GUIDE_PHASE_X.md` | Context for planning |
| `HANDOFF.md` | Cross-session continuity |

### Agent Note Emojis
| Emoji | Meaning |
|-------|---------|
| 🔨 | Worker notes |
| ✂️ | Shortening notes |
| 🔍 | Review notes |
| ⚠️ | Issue found/fixed/deferred |
| 📋 | Skill decision |
| ✅ | Boss approved |
| 🔴 | Task failed |
| 🟢 | Failure resolved |

## Plugin Location

Templates and protocols at: `~/.claude/plugins/general-orders/`

## More Information

Read the skill file: `~/.claude/plugins/general-orders/SKILL.md`
