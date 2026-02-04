# Module Catalog: Field Service

**Module ID**: `field_service`
**Version**: 1.0
**Last Updated**: 2026-01-26

---

## Overview

Field Service covers work performed at customer locations by mobile technicians. This module addresses the unique challenges of:

- **Dispatch coordination**: Matching jobs to technicians based on skills, location, and availability
- **Mobile workforce**: Apps that work on phones/tablets in varying conditions
- **Offline-first**: Reliable operation without network connectivity
- **Inspections**: Structured data capture with photos and signatures

### When to Select This Module

Select Field Service when R1 context includes:
- Field technicians, service crews, or mobile workers
- Work orders, service tickets, or job assignments
- On-site visits to customer locations
- Mobile app requirements for field staff
- Offline or poor connectivity scenarios
- Inspections, checklists, or form capture
- GPS, routing, or territory management

### Module Dependencies

| Depends On | Reason |
|------------|--------|
| `crm.customer_management` | Work orders reference customers |
| `hr.directory` | Technicians are employees |
| `inventory` (optional) | Parts used on jobs |
| `financial.invoicing` (optional) | Billing for completed work |

---

## Package: dispatch

**Purpose**: Coordinate job assignments between dispatchers and field technicians.

### Discovery Questions (R2/R3)

**Entity Discovery (R2)**:
1. What information is tracked for each work order? (equipment, symptoms, history)
2. How do you currently assign jobs - manual, auto, or hybrid?
3. What defines technician availability? (calendar, location, skill certifications)
4. Do you have service territories or zones?
5. What priority levels exist? (emergency, same-day, scheduled)
6. Can jobs have multiple visits or appointments?

**Workflow Discovery (R3)**:
1. Walk through creating a new work order from customer call
2. What happens when a tech calls in sick?
3. How are emergency/urgent jobs handled?
4. What triggers job completion vs follow-up needed?
5. How does overtime approval work?

### Entity Templates

#### WorkOrder

```json
{
  "id": "data.field_service.work_order",
  "name": "Work Order",
  "type": "data",
  "namespace": "field_service",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Represents a service request to be performed at a customer location.",
    "attributes": [
      {"name": "work_order_number", "type": "string", "required": true, "unique": true},
      {"name": "customer_id", "type": "fk:customer", "required": true},
      {"name": "location_id", "type": "fk:service_location", "required": true},
      {"name": "priority", "type": "enum", "values": ["emergency", "urgent", "normal", "low"], "default": "normal"},
      {"name": "status", "type": "enum", "values": ["open", "assigned", "in_progress", "on_hold", "completed", "cancelled"]},
      {"name": "requested_date", "type": "datetime"},
      {"name": "scheduled_date", "type": "datetime"},
      {"name": "problem_description", "type": "text"},
      {"name": "equipment_id", "type": "fk:equipment", "required": false},
      {"name": "estimated_duration_minutes", "type": "integer"},
      {"name": "source", "type": "enum", "values": ["phone", "web", "email", "recurring", "inspection"]}
    ],
    "relationships": [
      {"type": "belongs_to", "entity": "Customer"},
      {"type": "belongs_to", "entity": "ServiceLocation"},
      {"type": "has_many", "entity": "Assignment"},
      {"type": "has_many", "entity": "WorkOrderNote"},
      {"type": "has_many", "entity": "Photo"},
      {"type": "belongs_to", "entity": "Equipment", "optional": true}
    ],
    "indexes": ["customer_id", "status", "scheduled_date", "priority"]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "field_service.dispatch",
    "created_at": "{{ISO_DATE}}",
    "updated_at": "{{ISO_DATE}}",
    "version": 1
  }
}
```

#### Assignment

```json
{
  "id": "data.field_service.assignment",
  "name": "Assignment",
  "type": "data",
  "namespace": "field_service",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Links a technician to a work order with scheduling details.",
    "attributes": [
      {"name": "work_order_id", "type": "fk:work_order", "required": true},
      {"name": "technician_id", "type": "fk:technician", "required": true},
      {"name": "scheduled_start", "type": "datetime", "required": true},
      {"name": "scheduled_end", "type": "datetime"},
      {"name": "actual_start", "type": "datetime"},
      {"name": "actual_end", "type": "datetime"},
      {"name": "status", "type": "enum", "values": ["scheduled", "en_route", "on_site", "completed", "cancelled"]},
      {"name": "travel_time_minutes", "type": "integer"},
      {"name": "sequence", "type": "integer", "description": "Order in technician's daily route"}
    ],
    "relationships": [
      {"type": "belongs_to", "entity": "WorkOrder"},
      {"type": "belongs_to", "entity": "Technician"}
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "field_service.dispatch",
    "created_at": "{{ISO_DATE}}",
    "updated_at": "{{ISO_DATE}}",
    "version": 1
  }
}
```

#### Route

```json
{
  "id": "data.field_service.route",
  "name": "Route",
  "type": "data",
  "namespace": "field_service",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "A technician's planned sequence of jobs for a day.",
    "attributes": [
      {"name": "technician_id", "type": "fk:technician", "required": true},
      {"name": "route_date", "type": "date", "required": true},
      {"name": "start_location", "type": "geo_point"},
      {"name": "end_location", "type": "geo_point"},
      {"name": "total_drive_time_minutes", "type": "integer"},
      {"name": "total_job_time_minutes", "type": "integer"},
      {"name": "status", "type": "enum", "values": ["planned", "in_progress", "completed"]}
    ],
    "relationships": [
      {"type": "belongs_to", "entity": "Technician"},
      {"type": "has_many", "entity": "Assignment", "ordered_by": "sequence"}
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "field_service.dispatch",
    "created_at": "{{ISO_DATE}}",
    "updated_at": "{{ISO_DATE}}",
    "version": 1
  }
}
```

#### Territory

```json
{
  "id": "data.field_service.territory",
  "name": "Territory",
  "type": "data",
  "namespace": "field_service",
  "tags": ["configuration"],
  "status": "discovered",

  "spec": {
    "purpose": "Geographic area assigned to technicians for routing efficiency.",
    "attributes": [
      {"name": "name", "type": "string", "required": true},
      {"name": "boundary", "type": "geo_polygon"},
      {"name": "zip_codes", "type": "array:string", "description": "Alternative to polygon"},
      {"name": "primary_technician_id", "type": "fk:technician"},
      {"name": "backup_technician_ids", "type": "array:fk:technician"}
    ],
    "relationships": [
      {"type": "has_many", "entity": "Technician"},
      {"type": "has_many", "entity": "ServiceLocation"}
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "field_service.dispatch",
    "created_at": "{{ISO_DATE}}",
    "updated_at": "{{ISO_DATE}}",
    "version": 1
  }
}
```

### Workflow Templates

#### Dispatch Flow

```yaml
workflow: dispatch_work_order
trigger: Work order created or rescheduled
actors: [Dispatcher, System, Technician]

steps:
  - id: 1
    name: Receive work order
    actor: System
    action: Create work order from customer request
    outputs: [work_order_id, customer_location]

  - id: 2
    name: Determine requirements
    actor: System
    action: Analyze job type, equipment, required skills
    outputs: [required_skills, estimated_duration, parts_needed]

  - id: 3
    name: Find available technicians
    actor: System
    action: Query technicians by availability, skills, proximity
    inputs: [required_skills, customer_location, requested_date]
    outputs: [candidate_technicians]
    decision_point: true
    options:
      - condition: "auto_dispatch_enabled && single_best_match"
        next: 5
      - condition: "multiple_candidates || manual_dispatch"
        next: 4

  - id: 4
    name: Dispatcher selects technician
    actor: Dispatcher
    action: Review candidates, select best fit
    screen: dispatch_board
    inputs: [candidate_technicians, work_order_details]
    outputs: [selected_technician]

  - id: 5
    name: Create assignment
    actor: System
    action: Assign work order to technician, update route
    outputs: [assignment_id]
    notifications: [technician_new_job]

  - id: 6
    name: Technician acknowledges
    actor: Technician
    action: View assignment, confirm or request change
    screen: mobile_job_detail
    decision_point: true
    options:
      - condition: "accepted"
        next: end
      - condition: "request_reschedule"
        next: 4

edge_cases:
  - name: emergency_priority
    trigger: "priority == emergency"
    behavior: Skip candidate review, assign to nearest qualified tech

  - name: no_available_techs
    trigger: "candidate_technicians.empty?"
    behavior: Alert dispatcher, suggest overtime or subcontractor

  - name: tech_running_late
    trigger: "current_job_overrun > 15_minutes"
    behavior: Notify next customer, offer reschedule options
```

#### Reassignment Flow

```yaml
workflow: reassign_work_order
trigger: Technician unavailable or job needs specialist
actors: [Dispatcher, Original_Tech, New_Tech, Customer]

steps:
  - id: 1
    name: Identify reassignment need
    actor: Dispatcher | Original_Tech
    triggers:
      - tech_called_sick
      - tech_requests_help
      - job_requires_different_skill

  - id: 2
    name: Find replacement
    actor: System
    action: Query available techs excluding original
    constraints: [same_day, required_skills, proximity]

  - id: 3
    name: Reassign
    actor: Dispatcher
    action: Move assignment to new technician
    notifications: [original_tech_removed, new_tech_assigned, customer_notified]

  - id: 4
    name: Update routes
    actor: System
    action: Reoptimize both technicians' routes
```

### Edge Case Library

| Edge Case | Risk Level | Detection | Resolution |
|-----------|------------|-----------|------------|
| Double-booking technician | High | Scheduling conflict check | Block assignment, alert dispatcher |
| Job runs into overtime | Medium | Time tracking vs schedule | Require approval, notify affected customers |
| Technician lacks required skill | High | Skill matrix validation | Suggest qualified alternatives |
| Customer not home | Medium | Technician status update | Reschedule, apply no-show policy |
| Emergency displaces scheduled job | Medium | Priority override | Auto-notify affected customers with options |
| Recurring job on holiday | Low | Calendar integration | Skip or reschedule per policy |
| Territory boundary dispute | Low | Geo-fence check | Use primary territory owner |

### AI Touchpoints

| Touchpoint | Input | Output | Value |
|------------|-------|--------|-------|
| Route optimization | Assignments, locations, traffic | Optimized sequence | Reduce drive time 15-25% |
| Smart scheduling | Skills, history, customer preferences | Best technician match | Higher first-time fix rate |
| Duration prediction | Job type, equipment age, technician | Estimated time | Accurate scheduling |
| Demand forecasting | Historical data, weather, seasonality | Staffing recommendations | Right capacity |

---

## Package: mobile

**Purpose**: Native app experience for field technicians on phones and tablets.

### Discovery Questions (R2/R3)

**Entity Discovery (R2)**:
1. What device types do technicians use? (phone, tablet, rugged device)
2. What information must techs see about each job?
3. What actions can techs take on the job? (notes, photos, parts, signatures)
4. Do techs need customer history at the job site?
5. What location tracking is required?

**Workflow Discovery (R3)**:
1. Walk through a technician's morning routine (start of day)
2. What happens when tech arrives at job site?
3. How does tech capture work performed?
4. Walk through signature capture and job completion
5. What does end-of-day look like?

### Entity Templates

#### MobileSession

```json
{
  "id": "data.field_service.mobile_session",
  "name": "Mobile Session",
  "type": "data",
  "namespace": "field_service",
  "tags": ["mobile", "tracking"],
  "status": "discovered",

  "spec": {
    "purpose": "Tracks a technician's active mobile app session for monitoring and sync.",
    "attributes": [
      {"name": "technician_id", "type": "fk:technician", "required": true},
      {"name": "device_id", "type": "string", "required": true},
      {"name": "session_start", "type": "datetime", "required": true},
      {"name": "session_end", "type": "datetime"},
      {"name": "last_sync", "type": "datetime"},
      {"name": "last_location", "type": "geo_point"},
      {"name": "battery_level", "type": "integer"},
      {"name": "app_version", "type": "string"},
      {"name": "os_version", "type": "string"}
    ],
    "relationships": [
      {"type": "belongs_to", "entity": "Technician"}
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "field_service.mobile",
    "created_at": "{{ISO_DATE}}",
    "updated_at": "{{ISO_DATE}}",
    "version": 1
  }
}
```

#### LocationPing

```json
{
  "id": "data.field_service.location_ping",
  "name": "Location Ping",
  "type": "data",
  "namespace": "field_service",
  "tags": ["mobile", "tracking", "high-volume"],
  "status": "discovered",

  "spec": {
    "purpose": "GPS breadcrumb trail for technician tracking and travel time calculation.",
    "attributes": [
      {"name": "technician_id", "type": "fk:technician", "required": true},
      {"name": "timestamp", "type": "datetime", "required": true},
      {"name": "location", "type": "geo_point", "required": true},
      {"name": "accuracy_meters", "type": "float"},
      {"name": "speed_mph", "type": "float"},
      {"name": "battery_level", "type": "integer"},
      {"name": "source", "type": "enum", "values": ["gps", "wifi", "cell"]}
    ],
    "retention_policy": "30_days",
    "partition_by": "timestamp",
    "indexes": ["technician_id", "timestamp"]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "field_service.mobile",
    "created_at": "{{ISO_DATE}}",
    "updated_at": "{{ISO_DATE}}",
    "version": 1
  }
}
```

### Screen Templates

#### MobileJobList

```yaml
screen: mobile_job_list
type: list
platform: mobile
actors: [Technician]

purpose: Technician's view of today's assigned jobs in sequence order.

layout:
  header:
    - today_date
    - job_count
    - sync_status_indicator
  list_item:
    - time_window (e.g., "9:00 AM - 10:30 AM")
    - customer_name
    - address_short
    - job_type_icon
    - status_badge
  actions:
    - pull_to_refresh
    - tap_to_view_detail

states:
  - name: loading
    show: skeleton_list
  - name: empty
    show: "No jobs scheduled today"
  - name: offline
    show: cached_data + offline_banner

data_requirements:
  - assignments_for_today (ordered by sequence)
  - customer_basic_info
  - service_location_address

offline_behavior:
  cached: true
  stale_threshold: 4_hours
  sync_priority: high
```

#### MobileJobDetail

```yaml
screen: mobile_job_detail
type: detail
platform: mobile
actors: [Technician]

purpose: Full job information and action hub for technician at job site.

sections:
  - name: header
    fields:
      - work_order_number
      - status_with_actions
      - customer_name (tap for customer detail)

  - name: location
    fields:
      - full_address
      - navigation_button
      - gate_code / access_instructions

  - name: job_info
    fields:
      - problem_description
      - equipment_info
      - special_instructions
      - previous_visit_summary

  - name: actions
    buttons:
      - start_travel (shows when status=scheduled)
      - arrive_on_site (shows when status=en_route)
      - start_work (shows when status=on_site)
      - add_note
      - add_photo
      - use_parts
      - complete_job

  - name: history
    collapsible: true
    content:
      - previous_work_orders
      - customer_notes

status_transitions:
  scheduled:
    allowed: [en_route, cancelled]
    action: start_travel
  en_route:
    allowed: [on_site, scheduled]
    action: arrive_on_site
  on_site:
    allowed: [completed, on_hold]
    action: complete_job

offline_behavior:
  all_sections_cached: true
  actions_queued_offline: true
```

### Workflow Templates

#### Start of Day Flow

```yaml
workflow: technician_start_day
trigger: Technician opens app in morning
actors: [Technician, System]

steps:
  - id: 1
    name: Authentication
    actor: System
    action: Validate session, biometric or PIN
    offline_behavior: Use cached credentials if recent

  - id: 2
    name: Sync check
    actor: System
    action: Pull latest assignments, push queued changes
    outputs: [today_assignments, sync_conflicts]
    offline_behavior: Show cached data with stale indicator

  - id: 3
    name: Route review
    actor: Technician
    screen: mobile_job_list
    action: Review day's jobs, check sequence

  - id: 4
    name: Confirm start
    actor: Technician
    action: Mark day as started
    outputs: [shift_start_time, start_location]
    notifications: [dispatcher_tech_online]

offline_behavior:
  fully_functional: true
  sync_on_reconnect: true
```

#### Job Completion Flow

```yaml
workflow: complete_job
trigger: Technician finishes work at job site
actors: [Technician, Customer, System]

steps:
  - id: 1
    name: Capture work performed
    actor: Technician
    screen: work_summary_form
    inputs:
      - work_description (required)
      - parts_used (optional)
      - time_spent (auto-calculated, adjustable)
      - resolution_code (required)

  - id: 2
    name: Required photos
    actor: Technician
    screen: photo_capture
    validation: Min photos based on job type

  - id: 3
    name: Customer signature
    actor: Customer
    screen: signature_capture
    inputs:
      - signature
      - printed_name
      - customer_email (optional, for receipt)
    decision_point: true
    options:
      - condition: "customer_available"
        next: 4
      - condition: "customer_unavailable"
        next: 3b

  - id: 3b
    name: Document no signature
    actor: Technician
    action: Select reason (not home, refused, etc.)

  - id: 4
    name: Submit completion
    actor: System
    action: Queue for sync, update local status
    offline_behavior: Store locally, sync when connected

  - id: 5
    name: Navigate to next job
    actor: System
    action: Show next assignment or end of day summary

validation_rules:
  - rule: required_photos_by_job_type
    condition: "job_type.requires_photos && photos.count < job_type.min_photos"
    message: "Please add required photos before completing"

  - rule: time_reasonableness
    condition: "time_spent < 5_minutes && !quick_fix_code"
    message: "Very short job time - please verify or add note"
```

### Edge Case Library

| Edge Case | Risk Level | Detection | Resolution |
|-----------|------------|-----------|------------|
| Device battery critical | High | Battery level < 15% | Alert tech, auto-reduce sync frequency |
| App crash mid-job | High | Crash detection | Auto-save form state, restore on reopen |
| Location services disabled | Medium | Permission check | Prompt to enable, allow manual location entry |
| Large photo upload fails | Medium | Upload timeout | Retry with backoff, compress, or defer |
| Customer dispute over work | Medium | Signature refused | Document refusal reason, alert supervisor |
| Device storage full | Medium | Storage check | Alert, suggest clearing old synced data |
| Time zone mismatch | Low | Device vs server time | Use UTC internally, display in local |

### Mobile-Specific Patterns

#### Photo Capture and Compression

```yaml
photo_handling:
  capture:
    max_resolution: 2048x2048
    formats: [jpeg, heic]
    auto_rotate: true
    geo_tag: true
    timestamp_overlay: optional

  compression:
    quality: 0.8
    max_file_size_kb: 500
    wifi_quality: 0.9
    cellular_quality: 0.7

  storage:
    local_retention: 7_days
    upload_priority: by_job_date
    batch_upload: when_on_wifi

  edge_cases:
    - storage_full: Delete oldest synced photos
    - upload_failed: Retry 3x, then mark for manual review
    - camera_permission_denied: Show instructions to enable
```

#### GPS/Location Handling

```yaml
location_tracking:
  modes:
    foreground:
      interval: 30_seconds
      accuracy: high

    background:
      interval: 5_minutes
      accuracy: balanced
      significant_location_changes: true

    battery_saver:
      interval: 15_minutes
      accuracy: low

  triggers:
    high_accuracy_mode:
      - approaching_job_site
      - customer_tracking_enabled

    reduced_tracking:
      - battery_below_20_percent
      - user_preference

  privacy:
    tracking_disclosure: required
    opt_out_available: per_company_policy
    data_retention: 30_days
```

#### Battery Optimization

```yaml
battery_optimization:
  strategies:
    - name: reduce_sync_frequency
      trigger: battery < 30%
      action: Increase sync interval to 15 minutes

    - name: defer_photo_upload
      trigger: battery < 20%
      action: Queue photos, upload on charger

    - name: reduce_location_accuracy
      trigger: battery < 15%
      action: Switch to cell-tower location

    - name: critical_mode
      trigger: battery < 10%
      action: Disable background sync, location-only for active job

  notifications:
    - battery < 20%: "Low battery - connect to charger soon"
    - battery < 10%: "Critical battery - limited functionality"
```

#### Form Factor Considerations

```yaml
form_factors:
  phone:
    min_target_size: 44px
    single_column_layout: true
    bottom_navigation: true
    gesture_navigation: supported

  tablet:
    min_target_size: 44px
    two_column_layout: available
    side_navigation: optional
    split_view: supported

  rugged_device:
    large_buttons: true
    high_contrast: available
    glove_mode: supported
    hardware_button_shortcuts: configurable

  common_patterns:
    - large_touch_targets (field conditions)
    - high_contrast_mode (outdoor visibility)
    - one_handed_operation (phone)
    - offline_indicators (always visible)
```

---

## Package: offline_sync

**Purpose**: Reliable operation without network connectivity with intelligent synchronization.

### Discovery Questions (R2/R3)

**Entity Discovery (R2)**:
1. What percentage of time are technicians offline?
2. What data MUST be available offline? What's nice-to-have?
3. How large is a typical technician's data set?
4. Can multiple technicians work on the same job simultaneously?
5. How long can a technician work offline before data becomes stale?

**Workflow Discovery (R3)**:
1. What happens when tech makes changes offline that conflict with dispatch changes?
2. How should conflicts be resolved - last write wins, dispatcher wins, merge?
3. What's the acceptable sync delay for completed jobs?
4. How do you handle a tech offline for multiple days (vacation, remote area)?

### Entity Templates

#### SyncQueue

```json
{
  "id": "data.field_service.sync_queue",
  "name": "Sync Queue",
  "type": "data",
  "namespace": "field_service",
  "tags": ["offline", "system"],
  "status": "discovered",

  "spec": {
    "purpose": "Queue of local changes waiting to sync to server.",
    "attributes": [
      {"name": "id", "type": "uuid", "required": true},
      {"name": "entity_type", "type": "string", "required": true},
      {"name": "entity_id", "type": "string", "required": true},
      {"name": "operation", "type": "enum", "values": ["create", "update", "delete"], "required": true},
      {"name": "payload", "type": "json", "required": true},
      {"name": "created_at", "type": "datetime", "required": true},
      {"name": "priority", "type": "integer", "default": 5},
      {"name": "retry_count", "type": "integer", "default": 0},
      {"name": "last_error", "type": "string"},
      {"name": "status", "type": "enum", "values": ["pending", "syncing", "failed", "completed"]}
    ],
    "indexes": ["status", "priority", "created_at"]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "field_service.offline_sync",
    "created_at": "{{ISO_DATE}}",
    "updated_at": "{{ISO_DATE}}",
    "version": 1
  }
}
```

#### ConflictRecord

```json
{
  "id": "data.field_service.conflict_record",
  "name": "Conflict Record",
  "type": "data",
  "namespace": "field_service",
  "tags": ["offline", "system"],
  "status": "discovered",

  "spec": {
    "purpose": "Records sync conflicts for resolution.",
    "attributes": [
      {"name": "id", "type": "uuid", "required": true},
      {"name": "entity_type", "type": "string", "required": true},
      {"name": "entity_id", "type": "string", "required": true},
      {"name": "local_version", "type": "json", "required": true},
      {"name": "server_version", "type": "json", "required": true},
      {"name": "local_modified_at", "type": "datetime", "required": true},
      {"name": "server_modified_at", "type": "datetime", "required": true},
      {"name": "conflict_type", "type": "enum", "values": ["update_update", "update_delete", "delete_update"]},
      {"name": "resolution", "type": "enum", "values": ["pending", "local_wins", "server_wins", "merged", "manual"]},
      {"name": "resolved_by", "type": "fk:user"},
      {"name": "resolved_at", "type": "datetime"}
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "field_service.offline_sync",
    "created_at": "{{ISO_DATE}}",
    "updated_at": "{{ISO_DATE}}",
    "version": 1
  }
}
```

#### SyncLog

```json
{
  "id": "data.field_service.sync_log",
  "name": "Sync Log",
  "type": "data",
  "namespace": "field_service",
  "tags": ["offline", "audit"],
  "status": "discovered",

  "spec": {
    "purpose": "Audit trail of sync operations for troubleshooting.",
    "attributes": [
      {"name": "id", "type": "uuid", "required": true},
      {"name": "technician_id", "type": "fk:technician", "required": true},
      {"name": "device_id", "type": "string", "required": true},
      {"name": "sync_started", "type": "datetime", "required": true},
      {"name": "sync_completed", "type": "datetime"},
      {"name": "direction", "type": "enum", "values": ["push", "pull", "bidirectional"]},
      {"name": "records_pushed", "type": "integer"},
      {"name": "records_pulled", "type": "integer"},
      {"name": "conflicts_detected", "type": "integer"},
      {"name": "errors", "type": "array:string"},
      {"name": "connection_type", "type": "enum", "values": ["wifi", "cellular", "unknown"]}
    ],
    "retention_policy": "90_days"
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "field_service.offline_sync",
    "created_at": "{{ISO_DATE}}",
    "updated_at": "{{ISO_DATE}}",
    "version": 1
  }
}
```

### Offline-First Considerations

#### Data Priority Rules

```yaml
sync_priorities:
  critical: # Priority 1 - Sync immediately when connected
    - job_completion
    - customer_signature
    - emergency_notes
    - status_changes
    reason: "Revenue and safety impact"

  high: # Priority 2 - Sync within 5 minutes
    - work_notes
    - parts_used
    - time_entries
    - location_pings
    reason: "Operational visibility"

  normal: # Priority 3 - Sync within 15 minutes
    - photos
    - inspection_results
    - form_attachments
    reason: "Large payload, not blocking"

  low: # Priority 4 - Sync when on WiFi or idle
    - historical_data_requests
    - analytics_events
    - app_logs
    reason: "Non-urgent, bandwidth sensitive"

  download_priorities:
    critical:
      - today_assignments
      - customer_addresses
      - equipment_info
    high:
      - tomorrow_assignments
      - customer_history (recent)
    normal:
      - parts_catalog
      - price_lists
    low:
      - full_customer_history
      - training_materials
```

#### Conflict Resolution Strategies

```yaml
conflict_resolution:
  default_strategy: server_wins

  by_entity:
    assignment:
      strategy: server_wins
      reason: "Dispatcher has authority over scheduling"

    work_order.status:
      strategy: last_write_wins
      reason: "Real-time status is most accurate"

    work_order.notes:
      strategy: merge
      merge_type: append
      reason: "Both sets of notes are valuable"

    time_entry:
      strategy: local_wins
      reason: "Technician's actual time is authoritative"

    photo:
      strategy: local_wins
      reason: "Photos are append-only, no conflict"

    inspection.findings:
      strategy: merge
      merge_type: combine_unique
      reason: "Multiple inspectors may find different issues"

  manual_resolution_triggers:
    - conflict_affects_billing
    - conflict_on_safety_field
    - conflict_older_than_24_hours

  resolution_workflow:
    - notify_dispatcher
    - show_side_by_side_comparison
    - allow_manual_selection_or_merge
    - audit_log_resolution
```

#### Queue Management

```yaml
queue_management:
  max_queue_size: 1000_records
  max_queue_age: 7_days

  overflow_handling:
    strategy: priority_based_eviction
    evict_first: low_priority_old
    never_evict: critical_priority

  retry_policy:
    max_retries: 5
    backoff_type: exponential
    initial_delay: 30_seconds
    max_delay: 30_minutes

  stuck_record_handling:
    threshold: 3_failed_attempts
    action: flag_for_manual_review
    notification: alert_tech_and_support

  queue_health_monitoring:
    metrics:
      - queue_depth
      - oldest_pending_record
      - failure_rate
    alerts:
      - queue_depth > 500
      - oldest_record > 24_hours
      - failure_rate > 10_percent
```

#### Partial Connectivity Handling

```yaml
partial_connectivity:
  detection:
    method: heartbeat
    interval: 30_seconds
    timeout: 5_seconds

  connection_states:
    connected:
      sync: realtime
      indicators: green_dot

    weak_connection:
      detection: latency > 3s OR packet_loss > 20%
      sync: critical_only
      indicators: yellow_dot
      user_message: "Slow connection - syncing priority items only"

    offline:
      detection: heartbeat_failed
      sync: queue_all
      indicators: red_dot
      user_message: "Offline - changes saved locally"

    reconnecting:
      detection: heartbeat_restored
      sync: drain_queue
      indicators: spinning_dot
      user_message: "Back online - syncing..."

  graceful_degradation:
    - reduce_payload_size
    - compress_before_send
    - defer_non_critical
    - batch_small_requests
```

### Workflow Templates

#### Sync Flow

```yaml
workflow: sync_cycle
trigger: Timer, connectivity change, or user request
actors: [System, Technician]

steps:
  - id: 1
    name: Check connectivity
    actor: System
    action: Ping server, measure latency
    outputs: [connection_quality]

  - id: 2
    name: Determine sync scope
    actor: System
    action: Based on connection quality, decide what to sync
    decision_tree:
      connected: full_sync
      weak: critical_only
      offline: skip_to_local_queue_only

  - id: 3
    name: Push local changes
    actor: System
    action: Upload queued changes by priority
    order: critical -> high -> normal -> low

  - id: 4
    name: Handle push conflicts
    actor: System
    action: Detect conflicts, apply resolution strategy
    outputs: [conflicts_for_manual_review]

  - id: 5
    name: Pull server changes
    actor: System
    action: Download updates since last sync
    scope: technician_relevant_data_only

  - id: 6
    name: Apply server changes
    actor: System
    action: Merge server data into local database
    conflict_check: required

  - id: 7
    name: Update sync status
    actor: System
    action: Record sync log, update last_sync timestamp

  - id: 8
    name: Notify user
    actor: System
    action: Show sync result, alert on conflicts
    conditions:
      - conflicts_found: Show conflict badge
      - new_assignments: Show notification
```

### Edge Case Library

| Edge Case | Risk Level | Detection | Resolution |
|-----------|------------|-----------|------------|
| Device offline for 7+ days | High | Sync gap detection | Full re-sync with conflict review |
| Massive sync queue (1000+) | High | Queue size check | Batch sync, progress indicator |
| Server data model changed | High | Schema version mismatch | Force app update, migration |
| Timestamp drift between devices | Medium | Clock comparison | Use server timestamps, warn user |
| Duplicate record creation | Medium | Unique constraint violation | Merge with dedup logic |
| Partial sync interrupted | Medium | Incomplete sync flag | Resume from last checkpoint |
| Conflicting assignment changes | Medium | Multiple edits same record | Dispatcher-wins resolution |
| Data deleted on server while offline | Low | Tombstone detection | Mark local as deleted, archive |

---

## Package: inspections

**Purpose**: Structured data capture for assessments, checklists, and compliance documentation.

### Discovery Questions (R2/R3)

**Entity Discovery (R2)**:
1. What types of inspections do you perform?
2. Are inspection templates fixed or customizable per job type?
3. What compliance or regulatory requirements drive inspection data?
4. How are inspection findings classified? (pass/fail, severity levels)
5. What artifacts must be captured? (photos, measurements, signatures)

**Workflow Discovery (R3)**:
1. Walk through a typical inspection from start to finish
2. How are failed items escalated or followed up?
3. Who reviews inspection results?
4. How are inspection reports delivered to customers?
5. What happens when an inspector finds something outside the checklist?

### Entity Templates

#### Inspection

```json
{
  "id": "data.field_service.inspection",
  "name": "Inspection",
  "type": "data",
  "namespace": "field_service",
  "tags": ["core-entity", "compliance"],
  "status": "discovered",

  "spec": {
    "purpose": "A completed assessment against a checklist template.",
    "attributes": [
      {"name": "id", "type": "uuid", "required": true},
      {"name": "work_order_id", "type": "fk:work_order"},
      {"name": "template_id", "type": "fk:checklist_template", "required": true},
      {"name": "technician_id", "type": "fk:technician", "required": true},
      {"name": "equipment_id", "type": "fk:equipment"},
      {"name": "location_id", "type": "fk:service_location", "required": true},
      {"name": "started_at", "type": "datetime", "required": true},
      {"name": "completed_at", "type": "datetime"},
      {"name": "status", "type": "enum", "values": ["in_progress", "completed", "requires_review"]},
      {"name": "overall_result", "type": "enum", "values": ["pass", "fail", "conditional"]},
      {"name": "reviewer_id", "type": "fk:user"},
      {"name": "reviewed_at", "type": "datetime"},
      {"name": "customer_signature", "type": "signature"},
      {"name": "gps_location", "type": "geo_point"}
    ],
    "relationships": [
      {"type": "belongs_to", "entity": "WorkOrder", "optional": true},
      {"type": "belongs_to", "entity": "ChecklistTemplate"},
      {"type": "belongs_to", "entity": "Technician"},
      {"type": "has_many", "entity": "Finding"}
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "field_service.inspections",
    "created_at": "{{ISO_DATE}}",
    "updated_at": "{{ISO_DATE}}",
    "version": 1
  }
}
```

#### ChecklistTemplate

```json
{
  "id": "data.field_service.checklist_template",
  "name": "Checklist Template",
  "type": "data",
  "namespace": "field_service",
  "tags": ["configuration", "compliance"],
  "status": "discovered",

  "spec": {
    "purpose": "Reusable inspection structure defining what to check.",
    "attributes": [
      {"name": "id", "type": "uuid", "required": true},
      {"name": "name", "type": "string", "required": true},
      {"name": "category", "type": "string"},
      {"name": "version", "type": "integer", "default": 1},
      {"name": "status", "type": "enum", "values": ["draft", "active", "archived"]},
      {"name": "equipment_types", "type": "array:string", "description": "Equipment types this applies to"},
      {"name": "estimated_duration_minutes", "type": "integer"},
      {"name": "requires_signature", "type": "boolean", "default": true},
      {"name": "requires_photos", "type": "boolean", "default": false},
      {"name": "min_photos", "type": "integer", "default": 0}
    ],
    "relationships": [
      {"type": "has_many", "entity": "ChecklistSection", "ordered_by": "sequence"}
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "field_service.inspections",
    "created_at": "{{ISO_DATE}}",
    "updated_at": "{{ISO_DATE}}",
    "version": 1
  }
}
```

#### ChecklistSection

```json
{
  "id": "data.field_service.checklist_section",
  "name": "Checklist Section",
  "type": "data",
  "namespace": "field_service",
  "tags": ["configuration"],
  "status": "discovered",

  "spec": {
    "purpose": "Grouping of related inspection items within a template.",
    "attributes": [
      {"name": "template_id", "type": "fk:checklist_template", "required": true},
      {"name": "name", "type": "string", "required": true},
      {"name": "sequence", "type": "integer", "required": true},
      {"name": "description", "type": "text"},
      {"name": "is_conditional", "type": "boolean", "default": false},
      {"name": "condition_logic", "type": "json", "description": "When to show this section"}
    ],
    "relationships": [
      {"type": "belongs_to", "entity": "ChecklistTemplate"},
      {"type": "has_many", "entity": "ChecklistItem", "ordered_by": "sequence"}
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "field_service.inspections",
    "created_at": "{{ISO_DATE}}",
    "updated_at": "{{ISO_DATE}}",
    "version": 1
  }
}
```

#### ChecklistItem

```json
{
  "id": "data.field_service.checklist_item",
  "name": "Checklist Item",
  "type": "data",
  "namespace": "field_service",
  "tags": ["configuration"],
  "status": "discovered",

  "spec": {
    "purpose": "Individual inspection point requiring response.",
    "attributes": [
      {"name": "section_id", "type": "fk:checklist_section", "required": true},
      {"name": "label", "type": "string", "required": true},
      {"name": "sequence", "type": "integer", "required": true},
      {"name": "input_type", "type": "enum", "values": ["pass_fail", "yes_no", "numeric", "text", "select", "multi_select", "photo", "signature"]},
      {"name": "options", "type": "array:string", "description": "For select/multi_select types"},
      {"name": "is_required", "type": "boolean", "default": true},
      {"name": "requires_photo_on_fail", "type": "boolean", "default": false},
      {"name": "requires_note_on_fail", "type": "boolean", "default": true},
      {"name": "numeric_min", "type": "float", "description": "For numeric type"},
      {"name": "numeric_max", "type": "float", "description": "For numeric type"},
      {"name": "numeric_unit", "type": "string", "description": "For numeric type (e.g., 'psi', 'degrees')"},
      {"name": "help_text", "type": "text"},
      {"name": "reference_image_url", "type": "string"}
    ],
    "relationships": [
      {"type": "belongs_to", "entity": "ChecklistSection"}
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "field_service.inspections",
    "created_at": "{{ISO_DATE}}",
    "updated_at": "{{ISO_DATE}}",
    "version": 1
  }
}
```

#### Finding

```json
{
  "id": "data.field_service.finding",
  "name": "Finding",
  "type": "data",
  "namespace": "field_service",
  "tags": ["core-entity", "compliance"],
  "status": "discovered",

  "spec": {
    "purpose": "Individual inspection result for a checklist item.",
    "attributes": [
      {"name": "inspection_id", "type": "fk:inspection", "required": true},
      {"name": "checklist_item_id", "type": "fk:checklist_item", "required": true},
      {"name": "response_value", "type": "string", "required": true},
      {"name": "result", "type": "enum", "values": ["pass", "fail", "na", "deferred"]},
      {"name": "severity", "type": "enum", "values": ["info", "minor", "major", "critical"]},
      {"name": "notes", "type": "text"},
      {"name": "corrective_action", "type": "text"},
      {"name": "follow_up_required", "type": "boolean", "default": false},
      {"name": "follow_up_work_order_id", "type": "fk:work_order"},
      {"name": "recorded_at", "type": "datetime", "required": true}
    ],
    "relationships": [
      {"type": "belongs_to", "entity": "Inspection"},
      {"type": "belongs_to", "entity": "ChecklistItem"},
      {"type": "has_many", "entity": "Photo"}
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "field_service.inspections",
    "created_at": "{{ISO_DATE}}",
    "updated_at": "{{ISO_DATE}}",
    "version": 1
  }
}
```

#### Photo

```json
{
  "id": "data.field_service.photo",
  "name": "Photo",
  "type": "data",
  "namespace": "field_service",
  "tags": ["artifact", "mobile"],
  "status": "discovered",

  "spec": {
    "purpose": "Image captured during field service work.",
    "attributes": [
      {"name": "id", "type": "uuid", "required": true},
      {"name": "work_order_id", "type": "fk:work_order"},
      {"name": "inspection_id", "type": "fk:inspection"},
      {"name": "finding_id", "type": "fk:finding"},
      {"name": "technician_id", "type": "fk:technician", "required": true},
      {"name": "captured_at", "type": "datetime", "required": true},
      {"name": "gps_location", "type": "geo_point"},
      {"name": "caption", "type": "string"},
      {"name": "category", "type": "enum", "values": ["before", "after", "issue", "documentation"]},
      {"name": "file_path", "type": "string", "required": true},
      {"name": "thumbnail_path", "type": "string"},
      {"name": "file_size_bytes", "type": "integer"},
      {"name": "sync_status", "type": "enum", "values": ["pending", "uploading", "uploaded", "failed"]}
    ],
    "relationships": [
      {"type": "belongs_to", "entity": "WorkOrder", "optional": true},
      {"type": "belongs_to", "entity": "Inspection", "optional": true},
      {"type": "belongs_to", "entity": "Finding", "optional": true},
      {"type": "belongs_to", "entity": "Technician"}
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "field_service.inspections",
    "created_at": "{{ISO_DATE}}",
    "updated_at": "{{ISO_DATE}}",
    "version": 1
  }
}
```

### Screen Templates

#### InspectionForm

```yaml
screen: inspection_form
type: form
platform: mobile
actors: [Technician]

purpose: Step-through inspection capture with validation.

layout:
  header:
    - template_name
    - progress_indicator (e.g., "Section 2 of 5")
    - elapsed_time

  body:
    type: paginated_sections
    navigation: swipe_or_buttons

  section_view:
    - section_name
    - section_instructions
    - items_list

  item_types:
    pass_fail:
      display: large_toggle_buttons
      colors: green/red

    yes_no:
      display: toggle_buttons

    numeric:
      display: number_input
      validation: min/max
      unit_label: shown

    text:
      display: multiline_input
      character_limit: shown

    select:
      display: radio_buttons_or_dropdown
      threshold: 5_items_for_dropdown

    multi_select:
      display: checkboxes

    photo:
      display: camera_button_with_preview

  footer:
    - previous_section_button
    - next_section_button
    - save_progress_button

validation:
  on_next_section:
    - required_items_answered
    - numeric_in_range
    - photos_attached_if_required

  on_complete:
    - all_required_items_answered
    - signature_captured_if_required
    - minimum_photos_attached

offline_behavior:
  fully_functional: true
  auto_save: every_30_seconds
  resume_on_reopen: true
```

#### ReportPreview

```yaml
screen: report_preview
type: document
platform: mobile_and_web
actors: [Technician, Customer, Manager]

purpose: Preview inspection report before generating PDF.

sections:
  - header:
      - company_logo
      - report_title
      - inspection_date
      - inspector_name

  - summary:
      - overall_result (pass/fail/conditional)
      - items_passed_count
      - items_failed_count
      - critical_findings_highlight

  - details_by_section:
      - section_name
      - items_with_results
      - photos_embedded
      - notes_displayed

  - signatures:
      - inspector_signature
      - customer_signature
      - timestamp_for_each

  - footer:
      - follow_up_recommendations
      - next_inspection_due
      - contact_information

actions:
  - generate_pdf
  - email_to_customer
  - save_to_work_order
  - print (web only)
```

### Workflow Templates

#### Inspection Flow

```yaml
workflow: perform_inspection
trigger: Technician starts inspection from work order
actors: [Technician, System, Customer]

steps:
  - id: 1
    name: Load template
    actor: System
    action: Retrieve checklist template for job type
    offline: Use cached template

  - id: 2
    name: Begin inspection
    actor: Technician
    screen: inspection_form
    action: Record start time, GPS location

  - id: 3
    name: Complete sections
    actor: Technician
    action: Answer items, capture photos, add notes
    loop: for_each_section
    validation: required_items_per_section

  - id: 4
    name: Handle findings
    actor: System
    action: Flag failed items, calculate severity
    decision_point: true
    options:
      - condition: "has_critical_findings"
        next: 4b
      - condition: "no_critical_findings"
        next: 5

  - id: 4b
    name: Document critical findings
    actor: Technician
    action: Add detailed notes, photos for critical items
    required: true

  - id: 5
    name: Review summary
    actor: Technician
    screen: inspection_summary
    action: Verify all items, check completeness

  - id: 6
    name: Capture signature
    actor: Customer
    screen: signature_capture
    decision_point: true
    options:
      - condition: "customer_present"
        action: capture_signature
      - condition: "customer_absent"
        action: document_reason

  - id: 7
    name: Complete inspection
    actor: System
    action: Mark complete, queue for sync
    outputs: [inspection_id, sync_queue_item]

  - id: 8
    name: Generate report
    actor: System
    action: Create PDF, attach to work order
    offline: Queue for generation when online

follow_up_triggers:
  - critical_finding: Create follow-up work order
  - equipment_at_end_of_life: Create replacement quote
  - regulatory_failure: Alert compliance manager
```

### Edge Case Library

| Edge Case | Risk Level | Detection | Resolution |
|-----------|------------|-----------|------------|
| Template version changed mid-inspection | High | Version mismatch | Complete with old version, flag for review |
| Required photo not captured | High | Validation check | Block completion until photo added |
| Inspection interrupted (app crash, battery) | Medium | Incomplete inspection | Auto-save, resume on reopen |
| Numeric value out of expected range | Medium | Validation | Warning, require confirmation or note |
| Conditional section logic error | Medium | Runtime evaluation | Show section anyway, log error |
| Customer refuses to sign | Medium | No signature captured | Document reason, require note |
| Photo won't upload (too large) | Medium | Upload failure | Auto-compress and retry |
| Equipment not found at location | Low | Tech indication | Allow inspection of alternative or skip |

### AI Touchpoints

| Touchpoint | Input | Output | Value |
|------------|-------|--------|-------|
| Anomaly detection | Inspection results, history | Flagged unusual findings | Catch missed issues |
| Photo analysis | Captured images | Suggested findings | Assist inspector |
| Predictive maintenance | Historical inspections | Failure predictions | Prevent breakdowns |
| Report summarization | Full inspection data | Executive summary | Save reviewer time |

---

## Integration Points

### GPS and Mapping APIs

```yaml
gps_integration:
  primary_use_cases:
    - technician_location_tracking
    - navigation_to_job_site
    - geo_fencing_for_arrival_detection
    - route_optimization

  providers:
    google_maps:
      services: [directions, geocoding, places, distance_matrix]
      pricing_consideration: per_request

    apple_maps:
      services: [directions, geocoding]
      ios_only: true

    mapbox:
      services: [directions, geocoding, optimization]
      offline_maps: available

    here:
      services: [routing, geocoding, fleet_telematics]
      commercial_fleet: strong

  implementation_notes:
    - cache_geocoded_addresses
    - batch_distance_matrix_calls
    - prefer_offline_maps_for_field_areas
    - respect_rate_limits

  offline_considerations:
    - pre_download_route_maps
    - cache_customer_locations
    - store_last_known_addresses
```

### Equipment Databases

```yaml
equipment_integration:
  data_sources:
    internal_asset_database:
      sync_frequency: daily
      fields: [serial_number, model, install_date, warranty_status]

    manufacturer_apis:
      use_cases: [warranty_lookup, parts_catalog, service_bulletins]
      authentication: api_key_per_manufacturer

    iot_sensors:
      use_cases: [real_time_status, predictive_alerts]
      protocols: [mqtt, rest_api]

  entity_mapping:
    equipment:
      fields:
        - serial_number (unique identifier)
        - model_number
        - manufacturer
        - install_date
        - last_service_date
        - warranty_expiration
        - location_id
        - customer_id
        - status [active, inactive, decommissioned]

  offline_access:
    cache_strategy: customer_equipment_for_assigned_jobs
    refresh_trigger: job_assignment
    stale_threshold: 24_hours
```

### External Service Integrations

```yaml
common_integrations:
  crm_systems:
    - salesforce
    - hubspot
    - dynamics_365
    sync: customer_and_contact_data
    direction: bidirectional

  erp_systems:
    - sap
    - oracle
    - netsuite
    sync: work_orders, invoices, parts
    direction: bidirectional

  accounting:
    - quickbooks
    - xero
    sync: invoices, payments
    direction: push_to_accounting

  communication:
    - twilio (sms_notifications)
    - sendgrid (email)
    - push_notification_services

  document_storage:
    - aws_s3
    - google_cloud_storage
    - azure_blob
    use: photo_and_document_storage

  weather:
    - openweathermap
    - weather_gov
    use: scheduling_impact_alerts
```

---

## Appendix: Entity Relationship Diagram

```
┌─────────────────┐       ┌─────────────────┐
│    Customer     │───────│ ServiceLocation │
└────────┬────────┘       └────────┬────────┘
         │                         │
         │    ┌────────────────────┤
         │    │                    │
         ▼    ▼                    ▼
┌─────────────────┐       ┌─────────────────┐
│    WorkOrder    │───────│    Equipment    │
└────────┬────────┘       └─────────────────┘
         │
    ┌────┴────┬───────────────┐
    │         │               │
    ▼         ▼               ▼
┌────────┐ ┌────────┐  ┌─────────────┐
│Assign- │ │  Note  │  │ Inspection  │
│  ment  │ └────────┘  └──────┬──────┘
└───┬────┘                    │
    │                    ┌────┴────┐
    ▼                    ▼         ▼
┌────────┐          ┌────────┐ ┌────────┐
│  Tech  │          │Finding │ │ Photo  │
└───┬────┘          └────────┘ └────────┘
    │
    ▼
┌─────────────────┐
│     Route       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  LocationPing   │
└─────────────────┘

Sync Layer:
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  SyncQueue  │  │ ConflictRec │  │  SyncLog    │
└─────────────┘  └─────────────┘  └─────────────┘
```

---

## Quick Reference

### Package Summary

| Package | Core Entities | Key Screens | Primary Edge Cases |
|---------|---------------|-------------|-------------------|
| dispatch | WorkOrder, Assignment, Route, Territory | DispatchBoard, MapView, TechSchedule | Emergency jobs, tech unavailable, overtime |
| mobile | MobileSession, LocationPing | MobileJobList, JobDetail, ChecklistCapture | Battery, offline, large uploads |
| offline_sync | SyncQueue, ConflictRecord, SyncLog | SyncStatus, ConflictResolution | Conflicts, partial sync, stale data |
| inspections | Inspection, ChecklistTemplate, Finding, Photo | InspectionForm, PhotoCapture, ReportPreview | Required photos, conditional questions, PDF |

### Discovery Round Mapping

| Round | Focus | Field Service Specifics |
|-------|-------|------------------------|
| R2 | Entities | Work orders, assignments, inspections, sync entities |
| R3 | Workflows | Dispatch flow, job completion, sync cycle, inspection flow |
| R4 | Screens | Mobile-first designs, offline indicators, touch-friendly |
| R5 | Edge Cases | Offline scenarios, conflict resolution, battery optimization |
| R6 | AI | Route optimization, smart scheduling, anomaly detection |
| R7 | Build Plan | Mobile and offline infrastructure first |
