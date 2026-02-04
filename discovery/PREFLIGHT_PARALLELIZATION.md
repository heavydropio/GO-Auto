# Preflight Parallelization Enhancement

**Purpose**: Extend GO Build's `/go:preflight` to validate environments for parallel track execution discovered during R3/R7.

---

## Why Preflight Needs Parallelization Awareness

Standard preflight validates that an environment can build a project. Parallelization-aware preflight goes further — it validates that the environment can build **multiple tracks concurrently**.

**Problems this solves**:
1. **Resource contention**: Two Workers building simultaneously may exhaust memory, CPU, or disk
2. **File conflicts**: Tracks that claim independence may actually touch shared files
3. **Environment gaps**: Track A needs PostgreSQL, Track B needs Redis — standard preflight might miss one
4. **Git worktree failures**: Parallel branches require worktree support, not all setups have it
5. **Integration point readiness**: Merge points may require specific tooling (migration runners, test harnesses)

**When parallelization preflight applies**:
- `discovery-state.json` exists with `parallelization.tracks.length > 1`
- User plans to use `/go:execute` with parallel Workers
- Project roadmap indicates concurrent phases

**When to skip**:
- No discovery state (standard preflight only)
- Single track detected (parallelization is moot)
- User explicitly requests sequential execution (`--sequential` flag)

---

## Discovery State Integration

### Reading discovery-state.json

The parallelization preflight extension reads from `discovery/discovery-state.json`:

```javascript
// Required fields for parallelization preflight
{
  "parallelization": {
    "tracks": [
      {
        "id": "TRACK-A",
        "name": "Report Generation",
        "workflows": ["WF-001", "WF-003"],
        "entities_owned": [
          { "entity": "Report", "operations": ["create", "update"] }
        ],
        "can_parallel_with": ["TRACK-B"],
        "estimated_effort": "m"
      },
      {
        "id": "TRACK-B",
        "name": "Field Data Collection",
        "workflows": ["WF-002"],
        "entities_owned": [
          { "entity": "Inspection", "operations": ["update"] },
          { "entity": "Finding", "operations": ["create"] }
        ],
        "can_parallel_with": ["TRACK-A"],
        "estimated_effort": "l"
      }
    ],
    "integration_points": [
      {
        "id": "INT-001",
        "tracks": ["TRACK-A", "TRACK-B"],
        "shared_entities": ["Inspection"],
        "timing": "Phase 3"
      }
    ]
  },
  "modules": {
    "packages": {
      "field_service": ["work_orders", "scheduling"],
      "reporting": ["reports", "exports"]
    }
  },
  "decisions": [
    {
      "id": "DEC-TECH-003",
      "category": "tech_stack",
      "title": "Database",
      "selected": "PostgreSQL"
    }
  ]
}
```

### Extraction Protocol

1. **Load discovery state**:
   ```bash
   if [ -f "discovery/discovery-state.json" ]; then
     TRACKS=$(jq '.parallelization.tracks | length' discovery/discovery-state.json)
   else
     TRACKS=0
   fi
   ```

2. **Extract track metadata**:
   - Track IDs and names
   - Workflows per track
   - Entities owned per track
   - Parallel compatibility matrix
   - Integration points and timing

3. **Extract per-track requirements**:
   - From `modules.packages` — map tracks to module dependencies
   - From `decisions` — tech stack decisions that create requirements

4. **Validate structure**:
   - Each track has at least one workflow
   - `can_parallel_with` references exist
   - Integration points reference valid tracks

---

## Parallelization-Specific Checks

### 1. Track Independence Validation

Verify that tracks marked as parallelizable are truly independent.

**Check: No write-write conflicts**

```yaml
check_id: PAR-001
name: "Entity Write Conflict Check"
description: "Verify no two parallel tracks write to the same entity"

procedure:
  for each track_pair in parallelizable_pairs:
    track_a_writes = track_a.entities_owned.filter(e => e.operations.includes('create') || e.operations.includes('update'))
    track_b_writes = track_b.entities_owned.filter(e => e.operations.includes('create') || e.operations.includes('update'))

    conflicts = intersection(track_a_writes, track_b_writes)
    if conflicts.length > 0:
      report: SOFT_BLOCKER
      message: "Tracks {track_a.id} and {track_b.id} both write to: {conflicts}"
      recommendation: "Sequence these tracks or resolve at integration point"

severity: soft_blocker
```

**Check: Integration points defined for shared entities**

```yaml
check_id: PAR-002
name: "Integration Point Coverage"
description: "Every shared entity must have a defined integration point"

procedure:
  for each entity in all_shared_entities:
    integration_point = find_integration_point_for_entity(entity)
    if not integration_point:
      report: WARNING
      message: "Entity {entity} is touched by multiple tracks but has no integration point"
      recommendation: "Define integration point or confirm tracks are truly independent"

severity: warning
```

**Check: Workflow dependency consistency**

```yaml
check_id: PAR-003
name: "Cross-Track Workflow Dependencies"
description: "Ensure no workflow in Track A depends on workflow in Track B (for parallel tracks)"

procedure:
  for each track_pair in parallelizable_pairs:
    for each workflow_a in track_a.workflows:
      for each workflow_b in track_b.workflows:
        if workflow_a.preconditions.references(workflow_b):
          report: HARD_BLOCKER
          message: "WF {workflow_a.id} depends on WF {workflow_b.id} but tracks are marked parallel"
          recommendation: "Move dependent workflow to same track or mark tracks as sequential"

severity: hard_blocker
```

### 2. Resource Requirements

Validate system can handle N parallel Workers.

**Check: Memory capacity**

```yaml
check_id: PAR-004
name: "Parallel Memory Capacity"
description: "Verify sufficient memory for N concurrent Worker processes"

procedure:
  track_count = parallelization.tracks.length
  estimated_memory_per_worker = 2GB  # Baseline, adjust per tech stack

  # Adjust for tech stack
  if decisions.includes("Node.js"): estimated_memory_per_worker = 1GB
  if decisions.includes("ML/AI"): estimated_memory_per_worker = 8GB

  required_memory = track_count * estimated_memory_per_worker
  available_memory = system.available_memory

  if available_memory < required_memory:
    report: WARNING
    message: "Parallel execution of {track_count} tracks needs ~{required_memory}GB, have {available_memory}GB"
    recommendation: "Consider sequential execution or close other applications"

thresholds:
  ok: available >= required * 1.5
  warning: available >= required
  blocker: available < required * 0.8

severity: warning | soft_blocker
```

**Check: CPU capacity**

```yaml
check_id: PAR-005
name: "Parallel CPU Capacity"
description: "Verify sufficient CPU cores for concurrent builds"

procedure:
  track_count = parallelization.tracks.length
  available_cores = system.cpu_count

  if track_count > available_cores:
    report: INFO
    message: "More tracks ({track_count}) than CPU cores ({available_cores}) - builds will contend"
    recommendation: "Consider limiting parallel Workers to {available_cores}"

severity: info | warning
```

**Check: Disk I/O for parallel writes**

```yaml
check_id: PAR-006
name: "Parallel Disk Capacity"
description: "Estimate disk usage for parallel track builds"

procedure:
  for each track in tracks:
    estimated_disk = sum(track.estimated_effort mapped to disk_estimate)
    # xs=50MB, s=100MB, m=250MB, l=500MB, xl=1GB

  total_estimated = sum(all track estimates) * 1.5  # Buffer for temp files
  available_disk = system.available_disk

  if available_disk < total_estimated:
    report: SOFT_BLOCKER
    message: "Parallel builds may need ~{total_estimated}GB, have {available_disk}GB"

severity: soft_blocker
```

### 3. File Conflict Detection

Verify no two tracks write to the same files during build.

**Check: Source file ownership**

```yaml
check_id: PAR-007
name: "Source File Conflict Detection"
description: "Identify files that would be modified by multiple tracks"

procedure:
  for each track in tracks:
    # Map workflows to likely file paths
    track.expected_files = []
    for each workflow in track.workflows:
      # Infer from entity + module
      entity_files = map_entity_to_files(workflow.entities_write)
      module_files = map_module_to_files(track.module)
      track.expected_files.extend(entity_files, module_files)

  # Find overlaps
  for each track_pair in parallelizable_pairs:
    overlapping_files = intersection(track_a.expected_files, track_b.expected_files)
    if overlapping_files.length > 0:
      report: SOFT_BLOCKER
      message: "Tracks may conflict on files: {overlapping_files}"
      recommendation: "Use git worktrees or sequence these tracks"

severity: soft_blocker
```

**Check: Test file isolation**

```yaml
check_id: PAR-008
name: "Test File Isolation"
description: "Verify test files are track-specific"

procedure:
  # Check if test organization supports parallel execution
  if test_structure == "flat":
    report: WARNING
    message: "Flat test structure may cause conflicts during parallel execution"
    recommendation: "Consider organizing tests by feature/track"

severity: warning
```

### 4. Integration Point Readiness

Validate merge points are well-defined and tooling exists.

**Check: Integration point completeness**

```yaml
check_id: PAR-009
name: "Integration Point Definition"
description: "Each integration point has clear merge criteria"

procedure:
  for each integration_point in parallelization.integration_points:
    required_fields = ['id', 'tracks', 'shared_entities', 'timing', 'integration_type']
    missing = required_fields.filter(f => !integration_point[f])

    if missing.length > 0:
      report: WARNING
      message: "Integration point {integration_point.id} missing: {missing}"
      recommendation: "Update R3_WORKFLOWS.md with complete integration point specification"

severity: warning
```

**Check: Migration tool readiness**

```yaml
check_id: PAR-010
name: "Database Migration Support"
description: "Verify migration tools support parallel track merges"

procedure:
  if integration_points.any(ip => ip.shared_entities.length > 0):
    # Database migrations will need to merge
    migration_tool = detect_migration_tool()  # alembic, prisma, etc.

    if not migration_tool:
      report: SOFT_BLOCKER
      message: "Parallel tracks with shared entities need a migration tool"
      recommendation: "Install migration tool before parallel execution"

    # Check for migration conflicts
    existing_migrations = list_pending_migrations()
    if existing_migrations.length > 0:
      report: WARNING
      message: "{existing_migrations.length} pending migrations - apply before parallel work"

severity: soft_blocker | warning
```

---

## Environment Requirements by Track

Each track may have unique requirements based on its workflows and entities.

### Per-Track Requirement Mapping

```yaml
# Example: Discovery state maps to requirements

Track A (Report Generation):
  workflows: [WF-001, WF-003, WF-004]
  module: reporting

  inferred_requirements:
    - PDF generation library (reports → PDF export)
    - Template engine (reports → document templates)
    - Background job runner (report generation is async)

  environment_checks:
    - check: "weasyprint or wkhtmltopdf installed"
      command: "which weasyprint || which wkhtmltopdf"
      fallback: "pip install weasyprint"
    - check: "Celery or similar for async jobs"
      command: "pip show celery"
      fallback: "pip install celery"

Track B (Field Data Collection):
  workflows: [WF-002]
  module: field_service

  inferred_requirements:
    - Image processing (photo uploads)
    - Geolocation support (field coordinates)
    - Offline-capable storage (SQLite or similar for mobile)

  environment_checks:
    - check: "Pillow for image processing"
      command: "python -c 'import PIL'"
      fallback: "pip install Pillow"
    - check: "GeoJSON support"
      command: "pip show geojson"
      fallback: "pip install geojson"
```

### Track Requirement Template

```yaml
track_requirements:
  - track_id: "TRACK-A"
    name: "{{ track_name }}"

    runtime_requirements:
      - runtime: "{{ runtime }}"
        version: "{{ version }}"
        check_command: "{{ command }}"
        status: "OK | MISSING | WRONG_VERSION"

    package_requirements:
      - package: "{{ package_name }}"
        purpose: "{{ why_needed }}"
        check_command: "{{ command }}"
        install_command: "{{ install }}"
        status: "OK | MISSING"

    service_requirements:
      - service: "{{ service_name }}"
        purpose: "{{ why_needed }}"
        check_command: "{{ command }}"
        start_command: "{{ start }}"
        status: "RUNNING | STOPPED | MISSING"

    environment_variables:
      - name: "{{ VAR_NAME }}"
        purpose: "{{ why_needed }}"
        status: "SET | MISSING"

    overall_status: "READY | NOT_READY"
    blocking_issues: []
```

### Combined Track Requirements Table

| Track | Runtime | Packages | Services | Env Vars | Status |
|-------|---------|----------|----------|----------|--------|
| TRACK-A | Python 3.11 | weasyprint, celery | Redis | CELERY_BROKER_URL | Ready |
| TRACK-B | Python 3.11 | Pillow, geojson | — | — | Ready |
| TRACK-C | Node 18 | sharp, pg | PostgreSQL | DATABASE_URL | Blocked |

---

## Git Worktree Support

If parallel execution uses separate branches per track, git worktrees provide isolation.

### Worktree Availability Check

```yaml
check_id: GIT-001
name: "Git Worktree Support"
description: "Verify git supports worktrees"

procedure:
  # Check git version (worktrees added in 2.5)
  git_version = exec("git --version | grep -oE '[0-9]+\.[0-9]+'")
  if git_version < 2.5:
    report: HARD_BLOCKER
    message: "Git {git_version} does not support worktrees (need 2.5+)"
    recommendation: "Upgrade git: brew install git"

  # Check if repo is bare or has worktree support disabled
  worktree_list = exec("git worktree list 2>&1")
  if worktree_list.contains("error"):
    report: HARD_BLOCKER
    message: "Git worktrees not available: {worktree_list}"

severity: hard_blocker (if using worktree strategy)
```

### Branch Creation Permissions

```yaml
check_id: GIT-002
name: "Branch Creation Permissions"
description: "Verify ability to create branches for parallel tracks"

procedure:
  # Check remote permissions
  remote_url = exec("git remote get-url origin")

  # Test branch creation (dry run)
  test_branch = "preflight-test-$(date +%s)"
  result = exec("git branch {test_branch} && git branch -d {test_branch}")

  if result.failed:
    report: SOFT_BLOCKER
    message: "Cannot create branches locally"

  # Check push permissions (if remote exists)
  if remote_url:
    push_test = exec("git push --dry-run origin HEAD 2>&1")
    if push_test.contains("Permission denied"):
      report: WARNING
      message: "No push access to remote - parallel branches will be local only"

severity: soft_blocker | warning
```

### Clean Working State

```yaml
check_id: GIT-003
name: "Clean Working Directory"
description: "Verify working directory is clean before creating worktrees"

procedure:
  status = exec("git status --porcelain")

  if status.length > 0:
    report: SOFT_BLOCKER
    message: "Uncommitted changes detected - worktrees require clean state"
    changes: status
    recommendation: "Commit or stash changes before parallel execution"

  # Check for untracked files in paths that would conflict
  untracked = status.filter(line => line.startsWith("??"))
  if untracked.any(f => f.in(expected_track_paths)):
    report: WARNING
    message: "Untracked files in track paths may cause conflicts"

severity: soft_blocker | warning
```

### Worktree Strategy Recommendation

```yaml
worktree_recommendation:
  single_track:
    strategy: "none"
    reason: "Single track doesn't need isolation"

  two_tracks:
    strategy: "recommended"
    reason: "Worktrees prevent file conflicts between tracks"
    setup: |
      git worktree add ../project-track-a track-a
      git worktree add ../project-track-b track-b

  three_plus_tracks:
    strategy: "required"
    reason: "Multiple parallel tracks need guaranteed isolation"
    setup: |
      for track in tracks:
        git worktree add ../project-{track.id} {track.branch}
```

---

## Preflight Output Enhancement

### Parallelization Readiness Section

Add this section to PREFLIGHT.md output:

```markdown
---

## Parallelization Assessment

**Discovery State**: Found (`discovery/discovery-state.json`)
**Tracks Detected**: 2
**Parallelization Ready**: YES / NO / PARTIAL

### Track Summary

| Track | Name | Workflows | Effort | Status | Blockers |
|-------|------|-----------|--------|--------|----------|
| TRACK-A | Report Generation | WF-001, WF-003, WF-004 | M | Ready | — |
| TRACK-B | Field Data Collection | WF-002 | L | Ready | — |

### Independence Validation

| Check | Status | Notes |
|-------|--------|-------|
| PAR-001: Write conflicts | PASS | No overlapping entity writes |
| PAR-002: Integration points | PASS | INT-001 covers shared entities |
| PAR-003: Workflow dependencies | PASS | No cross-track dependencies |

### Resource Assessment

| Check | Status | Notes |
|-------|--------|-------|
| PAR-004: Memory | OK | Need ~4GB, have 16GB |
| PAR-005: CPU | OK | 2 tracks, 8 cores available |
| PAR-006: Disk | OK | Need ~500MB, have 50GB |

### File Conflict Check

| Check | Status | Notes |
|-------|--------|-------|
| PAR-007: Source files | PASS | No file overlaps detected |
| PAR-008: Test isolation | WARNING | Consider organizing tests by track |

### Integration Point Readiness

| Point | Tracks | Status | Notes |
|-------|--------|--------|-------|
| INT-001 | A, B | Ready | Migration tool (Alembic) detected |

### Git Worktree Status

| Check | Status | Notes |
|-------|--------|-------|
| GIT-001: Worktree support | OK | Git 2.43.0 |
| GIT-002: Branch permissions | OK | Can create local branches |
| GIT-003: Clean working directory | OK | No uncommitted changes |

### Track-Specific Requirements

#### TRACK-A: Report Generation

| Requirement | Type | Status | Command |
|-------------|------|--------|---------|
| weasyprint | package | OK | `which weasyprint` |
| celery | package | OK | `pip show celery` |
| Redis | service | RUNNING | `redis-cli ping` |
| CELERY_BROKER_URL | env var | SET | — |

#### TRACK-B: Field Data Collection

| Requirement | Type | Status | Command |
|-------------|------|--------|---------|
| Pillow | package | OK | `python -c 'import PIL'` |
| geojson | package | MISSING | `pip install geojson` |

### Parallelization Verdict

**Overall**: READY FOR PARALLEL EXECUTION

Recommendations:
- Fix TRACK-B missing `geojson` package before starting
- Consider organizing tests by track (warning only)

If parallel execution is blocked, you can still run sequentially:
```
/go:execute 1 --sequential
```

---
```

### Parallelization Verdict Logic

```yaml
verdict_calculation:
  READY:
    conditions:
      - all_tracks_ready: true
      - no_hard_blockers: true
      - no_soft_blockers: true (or all have workarounds)
      - integration_points_defined: true
    message: "Environment supports parallel track execution"

  PARTIAL:
    conditions:
      - some_tracks_ready: true
      - some_tracks_blocked: true
    message: "Some tracks ready, others blocked. Can proceed with ready tracks."
    action: "List ready tracks and blocked tracks with reasons"

  NOT_READY:
    conditions:
      - hard_blockers_exist: true
      - OR critical_resources_missing: true
    message: "Cannot safely run parallel execution"
    action: "List blockers with resolution commands"

  SEQUENTIAL_RECOMMENDED:
    conditions:
      - parallel_possible: true
      - BUT soft_blockers_risky: true (e.g., low resources, file conflicts)
    message: "Parallel possible but sequential is safer"
    action: "Explain risks and offer choice"
```

---

## Integration with Existing Preflight

This is an **enhancement**, not a replacement. The parallelization checks run after standard preflight passes.

### Preflight Flow with Parallelization

```
/go:preflight runs:

1. STANDARD PREFLIGHT (existing)
   ├── Environment checks
   ├── Resource assessment
   ├── Connectivity checks
   ├── Security assessment
   └── Test readiness

   → If NOT READY: Stop here, report standard blockers
   → If READY: Continue to parallelization checks

2. PARALLELIZATION EXTENSION (this template)
   ├── Load discovery-state.json
   │   └── If not found: Skip parallelization, report standard preflight only
   │
   ├── Extract parallelization data
   │   ├── Tracks
   │   ├── Integration points
   │   └── Per-track requirements
   │
   ├── Run parallelization checks
   │   ├── PAR-001 through PAR-010
   │   ├── GIT-001 through GIT-003
   │   └── Per-track requirement checks
   │
   └── Generate parallelization verdict

3. COMBINED OUTPUT
   ├── Standard PREFLIGHT.md sections
   ├── NEW: Parallelization Assessment section
   └── Updated "Next Steps" with parallel/sequential options
```

### Injection Point in Existing Template

In `templates/PREFLIGHT_TEMPLATE.md`, after the "Cross-Phase Dependencies" section and before "Resolution Commands", add:

```markdown
## Parallelization Assessment

{{ IF discovery-state.json EXISTS AND parallelization.tracks.length > 1 }}
  {{ INCLUDE parallelization assessment sections }}
{{ ELSE IF discovery-state.json EXISTS AND parallelization.tracks.length <= 1 }}
  **Parallelization**: N/A (single track detected)
{{ ELSE }}
  **Parallelization**: N/A (no discovery state found - run `/go:discover` first for parallel support)
{{ END }}
```

### Updating PREFLIGHT.md Output

The verdict section should reflect parallelization status:

```markdown
## Verdict: READY / NOT READY

**Standard Preflight**: READY
**Parallelization**: READY / PARTIAL / NOT_READY / N/A

[1-3 sentence summary including parallelization status]

Example:
"Environment is ready for build. 2 parallel tracks detected (Report Generation, Field Data Collection).
Both tracks passed independence checks and can run concurrently. Missing `geojson` package for TRACK-B
should be installed first."
```

---

## Fallback Behavior

### No discovery-state.json

```yaml
scenario: "No discovery state file"
detection: "!exists('discovery/discovery-state.json')"

behavior:
  - Run standard preflight only
  - Skip all parallelization checks
  - Do not fail — this is valid for non-discovery workflows

output:
  - Standard PREFLIGHT.md
  - Note in "Parallelization Assessment" section:
    "No discovery state found. Run `/go:discover` to enable parallelization analysis."
```

### Parallelization Disabled

```yaml
scenario: "User requests sequential execution"
detection: "--sequential flag OR parallelization.disabled = true in config"

behavior:
  - Run standard preflight only
  - Note that parallelization was skipped by request

output:
  - Standard PREFLIGHT.md
  - Note in "Parallelization Assessment" section:
    "Parallelization skipped (--sequential flag). Running standard preflight only."
```

### Single Track Detected

```yaml
scenario: "Discovery completed but only one track"
detection: "parallelization.tracks.length <= 1"

behavior:
  - Run standard preflight
  - Skip parallel-specific checks (resource multipliers, worktrees, etc.)
  - Still validate the single track's requirements

output:
  - Standard PREFLIGHT.md with track requirements
  - Note: "Single track detected — parallelization checks not applicable."
```

### Partial Discovery State

```yaml
scenario: "Discovery state exists but incomplete"
detection: "parallelization field missing OR tracks array empty"

behavior:
  - Run standard preflight
  - Warn about incomplete discovery state
  - Suggest completing R3 or R7

output:
  - Standard PREFLIGHT.md
  - Warning: "Discovery state incomplete. Run `/go:discover --resume` to complete
    parallelization analysis, or proceed with standard sequential build."
```

### Graceful Degradation Summary

| Condition | Preflight Behavior | User Action Required |
|-----------|-------------------|---------------------|
| No discovery-state.json | Standard only | None (optional: run `/go:discover`) |
| --sequential flag | Standard only | None (intentional) |
| Single track | Standard + track requirements | None |
| Incomplete discovery | Standard + warning | Optional: complete discovery |
| Parallelization checks fail | Standard + parallel blockers | Fix blockers or use --sequential |

---

## Examples

### Example 1: Project with 2 Parallel Tracks Passing Preflight

**Scenario**: Inspection app with Report Generation and Field Data Collection tracks.

**discovery-state.json** (relevant excerpt):
```json
{
  "parallelization": {
    "tracks": [
      {
        "id": "TRACK-A",
        "name": "Report Generation",
        "workflows": ["WF-001", "WF-003", "WF-004"],
        "entities_owned": [
          { "entity": "Report", "operations": ["create", "update"] },
          { "entity": "InspectionTemplate", "operations": ["create", "update"] }
        ],
        "can_parallel_with": ["TRACK-B"],
        "estimated_effort": "m"
      },
      {
        "id": "TRACK-B",
        "name": "Field Data Collection",
        "workflows": ["WF-002"],
        "entities_owned": [
          { "entity": "Inspection", "operations": ["update"] },
          { "entity": "Finding", "operations": ["create"] },
          { "entity": "Photo", "operations": ["create"] }
        ],
        "can_parallel_with": ["TRACK-A"],
        "estimated_effort": "l"
      }
    ],
    "integration_points": [
      {
        "id": "INT-001",
        "tracks": ["TRACK-A", "TRACK-B"],
        "shared_entities": ["Inspection"],
        "timing": "After TRACK-B field sync",
        "integration_type": "handoff"
      }
    ]
  }
}
```

**Preflight Output**:

```markdown
## Parallelization Assessment

**Discovery State**: Found
**Tracks Detected**: 2
**Parallelization Ready**: YES

### Track Summary

| Track | Name | Workflows | Effort | Status |
|-------|------|-----------|--------|--------|
| TRACK-A | Report Generation | 3 | M | Ready |
| TRACK-B | Field Data Collection | 1 | L | Ready |

### Independence Validation

| Check | Status |
|-------|--------|
| Entity write conflicts | PASS - No overlap (Report/Template vs Inspection/Finding/Photo) |
| Integration points | PASS - INT-001 covers Inspection handoff |
| Workflow dependencies | PASS - No cross-track dependencies |

### Resource Assessment

| Resource | Required | Available | Status |
|----------|----------|-----------|--------|
| Memory | ~4 GB | 16 GB | OK |
| CPU cores | 2 | 8 | OK |
| Disk space | ~750 MB | 50 GB | OK |

### Git Worktree Status

| Check | Status |
|-------|--------|
| Git version | 2.43.0 (OK) |
| Branch permissions | OK |
| Working directory | Clean |

### Parallelization Verdict

**READY FOR PARALLEL EXECUTION**

Both tracks can run concurrently:
- TRACK-A (Report Generation): Office-based, template/report focused
- TRACK-B (Field Data Collection): Mobile, inspection data focused

Integration point INT-001 handles Inspection entity handoff after field sync.

Recommended execution:
```bash
/go:execute 1  # Phase 1 sets up shared foundation
# Then parallel:
/go:execute 2 --track TRACK-A &
/go:execute 2 --track TRACK-B &
```
```

---

### Example 2: Project Where Parallelization is Blocked

**Scenario**: E-commerce app where two tracks both modify the same Order entity.

**discovery-state.json** (problematic):
```json
{
  "parallelization": {
    "tracks": [
      {
        "id": "TRACK-A",
        "name": "Order Processing",
        "workflows": ["WF-001", "WF-002"],
        "entities_owned": [
          { "entity": "Order", "operations": ["create", "update"] },
          { "entity": "Payment", "operations": ["create"] }
        ],
        "can_parallel_with": ["TRACK-B"]
      },
      {
        "id": "TRACK-B",
        "name": "Inventory Management",
        "workflows": ["WF-003", "WF-004"],
        "entities_owned": [
          { "entity": "Order", "operations": ["update"] },
          { "entity": "Inventory", "operations": ["update"] }
        ],
        "can_parallel_with": ["TRACK-A"]
      }
    ],
    "integration_points": []
  }
}
```

**Preflight Output**:

```markdown
## Parallelization Assessment

**Discovery State**: Found
**Tracks Detected**: 2
**Parallelization Ready**: NO

### Track Summary

| Track | Name | Workflows | Status | Blockers |
|-------|------|-----------|--------|----------|
| TRACK-A | Order Processing | 2 | Blocked | PAR-001, PAR-002 |
| TRACK-B | Inventory Management | 2 | Blocked | PAR-001, PAR-002 |

### Independence Validation

| Check | Status | Details |
|-------|--------|---------|
| PAR-001: Entity write conflicts | **FAIL** | Both tracks write to `Order` entity |
| PAR-002: Integration points | **FAIL** | No integration point for `Order` conflict |
| PAR-003: Workflow dependencies | PASS | |

### Hard Blockers

#### PAR-001: Write-Write Conflict on Order Entity

**Problem**:
- TRACK-A writes to Order (create, update)
- TRACK-B writes to Order (update)

Both tracks modifying the same entity during parallel execution will cause:
- Migration conflicts (both generate Order migrations)
- Race conditions (both update Order state)
- Test failures (both assume Order ownership)

**Resolution Options**:

1. **Sequence the tracks** (safest):
   ```bash
   # Build TRACK-A first (creates Order)
   /go:execute 2 --track TRACK-A
   # Then TRACK-B (updates Order)
   /go:execute 2 --track TRACK-B
   ```

2. **Define integration point** (if truly parallel):
   Update `discovery/R3_WORKFLOWS.md` to add:
   ```yaml
   integration_points:
     - point_id: INT-001
       tracks: [TRACK-A, TRACK-B]
       shared_entities: [Order]
       integration_type: sync
       timing: "After each Order state change"
       acceptance_criteria:
         - "Order status transitions are atomic"
         - "Inventory updates wait for payment confirmation"
   ```
   Then re-run `/go:preflight`.

3. **Redesign tracks** (recommended if frequent conflict):
   Move Order-related workflows to a single track:
   - TRACK-A: Order Processing + Order-related Inventory
   - TRACK-B: Non-Order Inventory (stock counts, reorder)

#### PAR-002: Missing Integration Point

**Problem**: Shared entity `Order` has no defined integration point.

**Resolution**: Add integration point as shown above, or acknowledge tracks are sequential.

### Parallelization Verdict

**NOT READY - HARD BLOCKERS PRESENT**

Tracks marked as parallel (`can_parallel_with`) but discovery analysis shows write conflicts.

**Recommended**: Run sequentially for now:
```bash
/go:execute --sequential
```

Or update R3_WORKFLOWS.md to either:
1. Remove `can_parallel_with` (acknowledge sequential)
2. Add integration point for Order entity
3. Redesign track boundaries

---
```

---

## Quick Reference

### Parallelization Check IDs

| ID | Name | Severity |
|----|------|----------|
| PAR-001 | Entity write conflicts | soft_blocker |
| PAR-002 | Integration point coverage | warning |
| PAR-003 | Workflow dependencies | hard_blocker |
| PAR-004 | Memory capacity | warning/soft_blocker |
| PAR-005 | CPU capacity | info/warning |
| PAR-006 | Disk capacity | soft_blocker |
| PAR-007 | Source file conflicts | soft_blocker |
| PAR-008 | Test file isolation | warning |
| PAR-009 | Integration point definition | warning |
| PAR-010 | Migration tool readiness | soft_blocker |
| GIT-001 | Worktree support | hard_blocker* |
| GIT-002 | Branch permissions | soft_blocker |
| GIT-003 | Clean working directory | soft_blocker |

*Hard blocker only if worktree strategy is required.

### Severity Definitions

| Level | Meaning | Action |
|-------|---------|--------|
| hard_blocker | Cannot proceed with parallel execution | Must fix or use --sequential |
| soft_blocker | Can proceed but problems likely | Should fix, has workarounds |
| warning | Awareness item | Note for build phase |
| info | FYI only | No action needed |

### Commands

```bash
# Standard preflight (includes parallelization if discovery exists)
/go:preflight

# Skip parallelization checks
/go:preflight --sequential

# Verify parallelization after fixes
/go:preflight --verify

# View parallelization status only
/go:preflight --parallel-only
```
