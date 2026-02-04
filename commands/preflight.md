---
description: Pre-build environment validation. Checks dependencies, tools, connectivity, and security before execution.
arguments:
  - name: scope
    description: "Phase (1, A.1), track (A, B), or 'all' (default: all)"
    required: false
---

# /go:preflight [scope] — Pre-Build Validation

You are the **Boss** running preflight checks before build execution.

**Announce**: "Running preflight validation for {{ scope | default: 'all phases' }}. Checking environment, resources, connectivity, security, test readiness, and cross-phase dependencies."

## Purpose

Answer the question: "Can we actually build what we planned?"

This runs AFTER `/go:discover` (project is defined) but BEFORE `/go:kickoff` (build begins).

## Track Detection

First, read ROADMAP.md and determine if this is a multi-track project.

**Multi-track indicators**:
- "## Track A:", "## Track B:" sections
- "## Tracks Overview" table
- Phase numbers like "A.1", "B.2" (letter prefix)

**Single-track indicators**:
- "## Phase 1:", "## Phase 2:" sections
- No track prefixes

## Scope Detection

**If scope is a track letter (A, B, etc.)**: Analyze only that track's phases and tech stack
**If scope is a phase number (1, A.1, B.2)**: Analyze only that specific phase
**If scope is "all" or omitted**:
  - Single-track: Analyze all phases
  - Multi-track: Analyze ALL tracks separately, then integration points

## Multi-Track Preflight Flow

For multi-track projects, run preflight sequentially per track:

```
1. Parse ROADMAP.md for tracks
2. For each track:
   - Identify track's tech stack from description
   - Run environment checks specific to that stack
   - Generate per-track findings
3. Check integration points
4. Consolidate into single PREFLIGHT.md with track sections
```

**Example output structure**:
```markdown
# Preflight Report

## Track A: Report Generation (Web)
**Tech Stack**: Python, FastAPI, PostgreSQL
**Status**: READY
- Environment: OK
- Resources: OK

## Track B: iOS Field App
**Tech Stack**: Swift, Xcode, CoreData
**Status**: NOT READY
- Hard Blocker: Xcode not installed

## Integration Points
- I.1: Floor Plan Schema — Blocked (requires A.2, B.2)
```

## Complexity Detection

Read ROADMAP.md and detect complexity keywords:

**Complex project indicators** (any match triggers parallel agents):
- iOS, Swift, Xcode, CocoaPods
- ML, TensorFlow, PyTorch, CUDA, GPU
- Docker, Kubernetes, containers
- PostgreSQL, MongoDB, Redis, database
- AWS, GCP, Azure, cloud
- React Native, Flutter, mobile

**Simple project**: No complexity keywords detected

## Simple Project Flow (Boss-Only)

For simple projects, run inline checks without spawning agents:

### 1. Environment Check
```bash
# Detect platform
uname -a

# Check language runtimes
python3 --version 2>/dev/null || echo "Python not found"
node --version 2>/dev/null || echo "Node not found"
uv --version 2>/dev/null || echo "uv not found"

# Check key tools
git --version
```

### 2. Resources Check
```bash
# Disk space (need at least 1GB free)
df -h . | tail -1

# Memory available
vm_stat 2>/dev/null || free -h 2>/dev/null || echo "Memory check unavailable"
```

### 3. Quick Connectivity Check
```bash
# Package registry reachable
curl -s --max-time 5 -o /dev/null -w "%{http_code}" https://pypi.org/simple/ || echo "PyPI unreachable"
curl -s --max-time 5 -o /dev/null -w "%{http_code}" https://registry.npmjs.org/ || echo "npm unreachable"
```

### 4. Security Scan
```bash
# Python vulnerabilities (if applicable)
pip-audit --version 2>/dev/null && pip-audit 2>/dev/null || echo "pip-audit not installed"

# Node vulnerabilities (if applicable)
[ -f package.json ] && npm audit --audit-level=high 2>/dev/null || echo "No package.json or npm audit failed"
```

### 5. Test Readiness
```bash
# Check test framework
pytest --version 2>/dev/null || echo "pytest not installed"
[ -d tests ] && echo "tests/ directory exists" || echo "No tests/ directory"
```

Skip to "Generate Report" section.

## Complex Project Flow (Parallel Agents)

For complex projects, spawn registered preflight agents in parallel.

### Step 1: Spawn 4 Agents in Parallel

Spawn a Task agent for each, using the registered subagent files:

| Agent | subagent_type | Returns |
|-------|---------------|---------|
| GO:Preflight Environment | `GO:Preflight Environment` | Environment findings JSON |
| GO:Preflight Resources | `GO:Preflight Resources` | Resource findings JSON |
| GO:Preflight Connectivity | `GO:Preflight Connectivity` | Connectivity findings JSON |
| GO:Preflight Security | `GO:Preflight Security` | Security findings JSON |

Each agent reads ROADMAP.md (and discovery-state.json if present) to scope its checks. All four run concurrently — no dependencies between them.

**If multi-track project with discovery-state.json `"path": "full"`**, also spawn:

| Agent | subagent_type | Returns |
|-------|---------------|---------|
| GO:Preflight Parallelization | `GO:Preflight Parallelization` | PAR-001 through PAR-010 + GIT-001 through GIT-003 results |

This makes 5 parallel agents for full-path projects, 4 for light-path or legacy.

### Step 2: Spawn Consolidator (Sequential)

After all parallel agents return, spawn the consolidator:

| Agent | subagent_type | Input | Output |
|-------|---------------|-------|--------|
| GO:Preflight Consolidator | `GO:Preflight Consolidator` | All agent JSON outputs | PREFLIGHT.md, START_PROMPT_PHASE_1.md, HANDOFF.md |

The consolidator uses Sequential Thinking to detect cross-agent interactions (e.g., 3 parallel tracks but memory for only 2 concurrent sessions). It merges all findings into the final report and generates the verdict.

### Step 3: Boss Presents Verdict

Boss reads the consolidator output and presents the verdict to the user. Boss does NOT merge raw agent output itself — the consolidator handles that.

## Test Readiness Check (Boss)

Always run directly (not in agent):

```bash
# Test framework installed
pytest --version 2>/dev/null
jest --version 2>/dev/null
go test -h 2>/dev/null

# Test directory exists
[ -d tests ] || [ -d test ] || [ -d __tests__ ]

# CI configuration present
[ -f .github/workflows/*.yml ] || [ -f .gitlab-ci.yml ] || [ -f Jenkinsfile ]
```

## Cross-Phase Analysis (Boss)

Read ROADMAP.md and identify:

### Data Flow Dependencies
- Phase N output -> Phase N+1 input
- Schema dependencies between phases
- Interface contracts assumed

### Risk Areas
- Phases with external API dependencies
- Phases with database migrations
- Phases with breaking changes

## Generate Report

Create `PREFLIGHT.md` using template:
`~/.claude/plugins/general-orders/templates/PREFLIGHT_TEMPLATE.md`

### Categorize Findings

**Hard Blockers** (cannot proceed):
- Required runtime not installed (Python required, not found)
- Database unreachable (no way to test)
- Critical security vulnerability (RCE, etc.)

**Soft Blockers** (can workaround but should fix):
- Docker not installed (can mock services)
- GPU not available (can use CPU, slower)
- Minor version mismatch (3.10 vs 3.11)

**Warnings** (should address):
- Low disk space (< 5GB)
- Outdated dependencies
- Missing optional tools

**Info** (awareness only):
- Packages to be installed
- Estimated download sizes
- Platform notes

### Verdict

**READY**: No hard blockers, 0-2 soft blockers
**NOT READY**: Any hard blockers or 3+ soft blockers

## Create Start Prompt and Initialize Handoff

After generating PREFLIGHT.md, create the documents needed for Phase 1.

### Create START_PROMPT_PHASE_1.md

Using template at `~/.claude/plugins/general-orders/templates/START_PROMPT_TEMPLATE.md`:

Fill in slots from preflight findings:
- **Platform**: OS and architecture detected
- **Runtime**: Language versions found
- **Package Manager**: uv, npm, etc.
- **Key Tools**: pytest, git, etc.
- **Preflight Status**: Hard/soft blocker counts, verdict

Also fill from project docs:
- **Project name**: From PROJECT.md
- **Phase 1 goal**: From ROADMAP.md
- **Deliverables**: From ROADMAP.md Phase 1

### Initialize HANDOFF.md

Create initial HANDOFF.md with:

```markdown
# [Project Name] Handoff

**Status**: Phase 1 not yet started
**Version**: v0.0.0

## Project Summary
[From PROJECT.md]

## Preflight Notes (Cascade)

| Phase | Concern | Type | Status |
|-------|---------|------|--------|
| [phase] | [concern from preflight] | Hard/Soft | Pending |

These notes persist across phases. Phase A (Environment Review) checks this table.

## Phase History

No phases completed yet.
```

This HANDOFF.md will be updated at the end of each phase.

## Flag Handling

### --verify
Re-run all checks and update resolution status:
- Mark previously-blocked items as resolved if fixed
- Add new issues if discovered
- Update PREFLIGHT.md in place

### --generate-script
Create `fix-preflight.sh` with commands to resolve issues:
```bash
#!/bin/bash
# Auto-generated preflight fix script

# Install missing Python
brew install python@3.11

# Install pip-audit
pip install pip-audit

# etc.
```

### --strict
Treat soft blockers as hard blockers (for CI/CD pipelines)

### --quick
Skip slow checks:
- No connectivity tests
- No security scans
- No dependency size estimation

## Present to Human

```markdown
## Preflight Complete: [READY / NOT READY]

### Executive Summary
[1-2 sentences: overall status]

### Issues Found

**Hard Blockers** ([n]):
- [Issue]: [Brief resolution]

**Soft Blockers** ([n]):
- [Issue]: [Brief resolution]

**Warnings** ([n]):
- [Issue]

### Phase Readiness

| Phase | Status | Blockers |
|-------|--------|----------|
| 1 | Ready/Blocked | [list] |
| 2 | Ready/Blocked | [list] |

### Next Steps
[If READY]: Run `/go:kickoff 1` to begin Phase 1
[If NOT READY]: Address blockers above, then run `/go:preflight --verify`

### Documents Created
- PREFLIGHT.md (full report)
- START_PROMPT_PHASE_1.md (for Phase 1 kickoff)
- HANDOFF.md (initialized with preflight notes)
```

## Integration Notes

### After /go:discover
The discover command should suggest:
```
Discovery complete! Next:
1. Run /go:preflight to validate environment
2. Then /go:kickoff 1 to begin Phase 1
```

### Before /go:kickoff
Kickoff Phase A should check:
```
if PREFLIGHT.md exists:
  if has unresolved hard blockers:
    STOP - "Run /go:preflight --verify to check status"
  else:
    Proceed
else:
  Ask: "No preflight found. Run /go:preflight first, or continue anyway?"
```
