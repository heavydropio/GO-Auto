# Module Catalog: Administrative

**Module ID**: `administrative`
**Version**: 1.0
**Last Updated**: 2026-01-26

---

## Overview

The Administrative module covers foundational operational capabilities that nearly every application requires: calendars, contacts, task management, and system settings. These are "horizontal" features that cut across business domains.

### When to Use This Module

Select this module when R1 context includes:
- Any mention of scheduling, appointments, or meetings
- Contact management or address book requirements
- Task tracking, to-do lists, or reminders
- User preferences or system configuration
- Multi-user systems requiring personalization

### Module Trigger Phrases

| Phrase | Maps To |
|--------|---------|
| "schedule", "calendar", "appointment", "meeting", "booking" | calendar |
| "contact", "address book", "directory", "people" | contacts |
| "to-do", "task list", "reminders", "assignments" | tasks |
| "settings", "preferences", "configuration", "options" | settings |

### Typical Actors

| Actor | Calendar | Contacts | Tasks | Settings |
|-------|----------|----------|-------|----------|
| End User | view, create | view, create | manage own | personal prefs |
| Office Manager | manage team | bulk import | assign | team defaults |
| Admin | configure | manage groups | templates | system config |
| System | sync, notify | dedupe | auto-assign | migration |

---

## Package: Calendar

**Namespace**: `administrative.calendar`

### Purpose

Manage time-based events including one-time appointments, recurring events, and multi-participant meetings with availability checking.

### Discovery Questions (R2/R3)

**Entity Discovery (R2)**
- "What types of events do users schedule?" (appointments, meetings, deadlines, reminders)
- "Do events have attendees, or are they personal only?"
- "Are there recurring events? What patterns?" (daily, weekly, monthly, custom)
- "Do events belong to a single calendar or multiple calendars per user?"
- "What event details matter?" (location, video link, attachments, notes)
- "Do events have statuses?" (confirmed, tentative, cancelled)

**Workflow Discovery (R3)**
- "How do users check availability before scheduling?"
- "What happens when scheduling conflicts arise?"
- "Do events need approval before confirmation?"
- "How are attendees invited and how do they respond?"
- "What notifications do users receive?" (reminders, changes, cancellations)
- "Can users delegate calendar management to others?"

### Entity Templates

#### Event

```json
{
  "id": "data.calendar.event",
  "name": "Calendar Event",
  "type": "data",
  "namespace": "calendar",
  "tags": ["core-entity", "administrative"],
  "status": "discovered",

  "spec": {
    "purpose": "Represents a scheduled time block with optional attendees and recurrence.",
    "acceptance_criteria": [
      { "id": "AC-1", "description": "CRUD operations for events", "verification_method": "automated" },
      { "id": "AC-2", "description": "Support for all-day events", "verification_method": "automated" },
      { "id": "AC-3", "description": "Timezone-aware date handling", "verification_method": "automated" },
      { "id": "AC-4", "description": "Conflict detection with other events", "verification_method": "automated" }
    ],
    "fields": {
      "required": [
        { "name": "id", "type": "uuid", "description": "Unique identifier" },
        { "name": "title", "type": "string", "max_length": 255 },
        { "name": "start_at", "type": "datetime", "description": "Event start (with timezone)" },
        { "name": "end_at", "type": "datetime", "description": "Event end (with timezone)" },
        { "name": "calendar_id", "type": "uuid", "foreign_key": "Calendar" },
        { "name": "created_by", "type": "uuid", "foreign_key": "User" }
      ],
      "optional": [
        { "name": "description", "type": "text" },
        { "name": "location", "type": "string" },
        { "name": "video_link", "type": "url" },
        { "name": "is_all_day", "type": "boolean", "default": false },
        { "name": "status", "type": "enum", "values": ["confirmed", "tentative", "cancelled"] },
        { "name": "visibility", "type": "enum", "values": ["public", "private", "busy_only"] },
        { "name": "recurrence_rule_id", "type": "uuid", "foreign_key": "RecurrenceRule" },
        { "name": "parent_event_id", "type": "uuid", "description": "For recurring instance exceptions" },
        { "name": "reminder_minutes", "type": "integer[]", "description": "e.g., [15, 60] for 15min and 1hr" }
      ]
    },
    "relationships": [
      { "entity": "Calendar", "type": "belongs_to", "field": "calendar_id" },
      { "entity": "Attendee", "type": "has_many", "foreign_key": "event_id" },
      { "entity": "RecurrenceRule", "type": "belongs_to", "optional": true }
    ],
    "indexes": [
      { "fields": ["calendar_id", "start_at"], "type": "btree" },
      { "fields": ["created_by"], "type": "btree" },
      { "fields": ["start_at", "end_at"], "type": "btree", "purpose": "conflict detection" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "administrative.calendar",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Attendee

```json
{
  "id": "data.calendar.attendee",
  "name": "Event Attendee",
  "type": "data",
  "namespace": "calendar",
  "tags": ["supporting-entity", "administrative"],
  "status": "discovered",

  "requires": ["data.calendar.event"],

  "spec": {
    "purpose": "Links users or external contacts to events with response tracking.",
    "acceptance_criteria": [
      { "id": "AC-1", "description": "Track attendee response status", "verification_method": "automated" },
      { "id": "AC-2", "description": "Support both user and external email attendees", "verification_method": "automated" },
      { "id": "AC-3", "description": "Mark required vs optional attendees", "verification_method": "automated" }
    ],
    "fields": {
      "required": [
        { "name": "id", "type": "uuid" },
        { "name": "event_id", "type": "uuid", "foreign_key": "Event" },
        { "name": "response_status", "type": "enum", "values": ["pending", "accepted", "declined", "tentative"] }
      ],
      "optional": [
        { "name": "user_id", "type": "uuid", "foreign_key": "User", "description": "Internal user" },
        { "name": "email", "type": "email", "description": "External attendee email" },
        { "name": "display_name", "type": "string" },
        { "name": "is_organizer", "type": "boolean", "default": false },
        { "name": "is_required", "type": "boolean", "default": true },
        { "name": "responded_at", "type": "datetime" }
      ]
    },
    "constraints": [
      { "type": "check", "condition": "user_id IS NOT NULL OR email IS NOT NULL", "description": "Must have user or email" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "administrative.calendar",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### RecurrenceRule

```json
{
  "id": "data.calendar.recurrence_rule",
  "name": "Recurrence Rule",
  "type": "data",
  "namespace": "calendar",
  "tags": ["supporting-entity", "administrative"],
  "status": "discovered",

  "spec": {
    "purpose": "Defines recurrence patterns for repeating events (RFC 5545 compatible).",
    "acceptance_criteria": [
      { "id": "AC-1", "description": "Support daily, weekly, monthly, yearly frequencies", "verification_method": "automated" },
      { "id": "AC-2", "description": "Support by-day patterns (e.g., MO,WE,FR)", "verification_method": "automated" },
      { "id": "AC-3", "description": "Generate occurrences within date range", "verification_method": "automated" },
      { "id": "AC-4", "description": "Handle exceptions (skipped/modified instances)", "verification_method": "automated" }
    ],
    "fields": {
      "required": [
        { "name": "id", "type": "uuid" },
        { "name": "frequency", "type": "enum", "values": ["daily", "weekly", "monthly", "yearly"] },
        { "name": "interval", "type": "integer", "default": 1, "description": "Every N frequency units" }
      ],
      "optional": [
        { "name": "by_day", "type": "string[]", "description": "e.g., ['MO', 'WE', 'FR']" },
        { "name": "by_month_day", "type": "integer[]", "description": "e.g., [1, 15] for 1st and 15th" },
        { "name": "by_month", "type": "integer[]", "description": "e.g., [1, 6, 12] for Jan, Jun, Dec" },
        { "name": "count", "type": "integer", "description": "End after N occurrences" },
        { "name": "until", "type": "date", "description": "End by date" },
        { "name": "exceptions", "type": "date[]", "description": "Dates to skip" }
      ]
    },
    "constraints": [
      { "type": "check", "condition": "NOT (count IS NOT NULL AND until IS NOT NULL)", "description": "Cannot have both count and until" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "administrative.calendar",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Calendar

```json
{
  "id": "data.calendar.calendar",
  "name": "Calendar",
  "type": "data",
  "namespace": "calendar",
  "tags": ["core-entity", "administrative"],
  "status": "discovered",

  "spec": {
    "purpose": "Container for events, supports multiple calendars per user (personal, work, shared).",
    "acceptance_criteria": [
      { "id": "AC-1", "description": "Users can have multiple calendars", "verification_method": "automated" },
      { "id": "AC-2", "description": "Calendars can be shared with permissions", "verification_method": "automated" },
      { "id": "AC-3", "description": "Calendars have color coding for UI", "verification_method": "manual" }
    ],
    "fields": {
      "required": [
        { "name": "id", "type": "uuid" },
        { "name": "name", "type": "string", "max_length": 100 },
        { "name": "owner_id", "type": "uuid", "foreign_key": "User" },
        { "name": "color", "type": "string", "description": "Hex color for display" }
      ],
      "optional": [
        { "name": "description", "type": "text" },
        { "name": "is_default", "type": "boolean", "default": false },
        { "name": "timezone", "type": "string", "description": "IANA timezone identifier" },
        { "name": "visibility", "type": "enum", "values": ["private", "shared", "public"] }
      ]
    },
    "relationships": [
      { "entity": "Event", "type": "has_many", "foreign_key": "calendar_id" },
      { "entity": "CalendarShare", "type": "has_many", "foreign_key": "calendar_id" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "administrative.calendar",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### Schedule Event

```yaml
workflow:
  id: "workflow.calendar.schedule_event"
  name: "Schedule Event"
  trigger: "User initiates event creation"

  steps:
    - step: 1
      action: "Open event form"
      screen: "EventForm"
      inputs: ["title", "start_at", "end_at", "attendees"]

    - step: 2
      action: "Check availability"
      condition: "attendees.length > 0"
      service: "AvailabilityService.checkConflicts"
      outputs: ["conflicts", "suggested_times"]

    - step: 3
      action: "Display conflicts if any"
      condition: "conflicts.length > 0"
      ui_action: "Show conflict dialog with alternatives"
      user_choices: ["proceed_anyway", "select_alternative", "cancel"]

    - step: 4
      action: "Create event"
      service: "EventService.create"

    - step: 5
      action: "Send invitations"
      condition: "attendees.length > 0"
      service: "NotificationService.sendInvites"

    - step: 6
      action: "Schedule reminders"
      condition: "reminder_minutes is set"
      service: "ReminderService.scheduleReminders"

  ai_touchpoints:
    - location: "step 2"
      capability: "Smart time suggestions based on attendee patterns and preferences"
    - location: "step 1"
      capability: "Auto-populate meeting details from email/chat context"
```

#### Handle Recurring Event Exception

```yaml
workflow:
  id: "workflow.calendar.recurring_exception"
  name: "Modify Recurring Event Instance"
  trigger: "User edits single instance of recurring event"

  steps:
    - step: 1
      action: "Prompt for scope"
      ui_action: "Show dialog"
      user_choices:
        - "this_instance": "Only this event"
        - "this_and_future": "This and all future events"
        - "all_instances": "All events in series"

    - step: 2a
      condition: "choice == this_instance"
      action: "Create exception event"
      service: "EventService.createException"
      note: "Creates new event linked to parent with modified details"

    - step: 2b
      condition: "choice == this_and_future"
      action: "Split recurrence"
      service: "RecurrenceService.splitAt"
      note: "End original series, create new series from this date"

    - step: 2c
      condition: "choice == all_instances"
      action: "Update base event"
      service: "EventService.updateRecurring"

    - step: 3
      action: "Notify attendees of change"
      condition: "attendees affected"
      service: "NotificationService.sendUpdate"
```

### Edge Case Library

| Edge Case | Description | Handling Strategy |
|-----------|-------------|-------------------|
| **Timezone changes** | User travels to different timezone | Store all times in UTC; display in user's current or event's timezone; allow per-event timezone override |
| **DST transitions** | Recurring event spans daylight saving change | Use IANA timezone rules; event at "9 AM local" stays at 9 AM even when offset changes |
| **Recurring conflicts** | New recurring event conflicts with existing | Check N occurrences ahead (configurable); warn but allow if desired |
| **All-day events** | Span full day in any timezone | Store as date-only (no time component); render based on viewer's timezone |
| **Orphaned recurrence** | Delete recurring parent | Cascade delete all future occurrences; keep past as standalone |
| **Invite loops** | Circular invitations between systems | Detect duplicate events by external ID + dedup |
| **Past event edits** | User modifies past event | Allow with audit log; disable attendee notifications for past events |
| **Multi-calendar conflicts** | Same user double-booked across calendars | Aggregate view shows all calendars; optional cross-calendar conflict detection |

### AI Touchpoints

| Touchpoint | Location | Capability | Implementation Notes |
|------------|----------|------------|---------------------|
| **Smart Scheduling** | Event creation | Suggest optimal times based on attendee calendars, work hours, and past patterns | Requires access to free/busy data; respect privacy settings |
| **Meeting Duration Prediction** | Event creation | Predict duration based on title, attendees, and similar past events | Train on org's meeting history; default to 30/60min fallback |
| **Auto-Summary** | After event | Generate meeting summary from notes/transcript | Integrate with video conferencing transcription |
| **Conflict Resolution** | Double-booking | Suggest which meeting to reschedule based on priority signals | Use attendee seniority, meeting recurrence, subject keywords |

---

## Package: Contacts

**Namespace**: `administrative.contacts`

### Purpose

Manage people and organization records with addresses, communication preferences, and relationship tracking.

### Discovery Questions (R2/R3)

**Entity Discovery (R2)**
- "What contact types exist?" (person, organization, both?)
- "What information do you track for contacts?" (phones, emails, addresses, custom fields)
- "Do contacts have categories or tags?"
- "Are contacts shared across the organization or per-user?"
- "Do you need to track relationships between contacts?" (works at, reports to, spouse)

**Workflow Discovery (R3)**
- "How are contacts typically added?" (manual, import, scan business card)
- "What happens when duplicate contacts are detected?"
- "Do contacts sync with external systems?" (Google, Outlook, CRM)
- "How do you segment or filter contacts?"
- "Are there different permission levels for contact visibility?"

### Entity Templates

#### Contact

```json
{
  "id": "data.contacts.contact",
  "name": "Contact",
  "type": "data",
  "namespace": "contacts",
  "tags": ["core-entity", "administrative"],
  "status": "discovered",

  "spec": {
    "purpose": "Represents a person or organization with contact information and metadata.",
    "acceptance_criteria": [
      { "id": "AC-1", "description": "CRUD operations for contacts", "verification_method": "automated" },
      { "id": "AC-2", "description": "Support multiple emails, phones, addresses per contact", "verification_method": "automated" },
      { "id": "AC-3", "description": "Full-text search across all fields", "verification_method": "automated" },
      { "id": "AC-4", "description": "Duplicate detection on email and phone", "verification_method": "automated" }
    ],
    "fields": {
      "required": [
        { "name": "id", "type": "uuid" },
        { "name": "contact_type", "type": "enum", "values": ["person", "organization"] },
        { "name": "display_name", "type": "string", "max_length": 255, "description": "Computed or manual" },
        { "name": "owner_id", "type": "uuid", "foreign_key": "User" }
      ],
      "optional": [
        { "name": "prefix", "type": "string", "description": "Mr., Ms., Dr., etc." },
        { "name": "first_name", "type": "string" },
        { "name": "middle_name", "type": "string" },
        { "name": "last_name", "type": "string" },
        { "name": "suffix", "type": "string", "description": "Jr., III, PhD, etc." },
        { "name": "nickname", "type": "string" },
        { "name": "organization_name", "type": "string" },
        { "name": "job_title", "type": "string" },
        { "name": "department", "type": "string" },
        { "name": "birthday", "type": "date" },
        { "name": "anniversary", "type": "date" },
        { "name": "notes", "type": "text" },
        { "name": "photo_url", "type": "url" },
        { "name": "source", "type": "string", "description": "How contact was added" },
        { "name": "external_id", "type": "string", "description": "ID from external system" },
        { "name": "is_favorite", "type": "boolean", "default": false }
      ]
    },
    "relationships": [
      { "entity": "ContactEmail", "type": "has_many", "foreign_key": "contact_id" },
      { "entity": "ContactPhone", "type": "has_many", "foreign_key": "contact_id" },
      { "entity": "ContactAddress", "type": "has_many", "foreign_key": "contact_id" },
      { "entity": "ContactGroup", "type": "many_to_many", "through": "ContactGroupMembership" },
      { "entity": "Contact", "type": "has_many", "foreign_key": "organization_id", "description": "People at this org" }
    ],
    "indexes": [
      { "fields": ["display_name"], "type": "btree" },
      { "fields": ["owner_id"], "type": "btree" },
      { "fields": ["first_name", "last_name"], "type": "btree" },
      { "fields": ["display_name", "organization_name"], "type": "fulltext" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "administrative.contacts",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### ContactEmail

```json
{
  "id": "data.contacts.contact_email",
  "name": "Contact Email",
  "type": "data",
  "namespace": "contacts",
  "tags": ["supporting-entity", "administrative"],
  "status": "discovered",

  "requires": ["data.contacts.contact"],

  "spec": {
    "purpose": "Email address for a contact with label and primary flag.",
    "fields": {
      "required": [
        { "name": "id", "type": "uuid" },
        { "name": "contact_id", "type": "uuid", "foreign_key": "Contact" },
        { "name": "email", "type": "email" }
      ],
      "optional": [
        { "name": "label", "type": "string", "description": "e.g., Work, Personal, Other" },
        { "name": "is_primary", "type": "boolean", "default": false }
      ]
    },
    "indexes": [
      { "fields": ["email"], "type": "btree", "unique": false, "purpose": "duplicate detection" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "administrative.contacts",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### ContactPhone

```json
{
  "id": "data.contacts.contact_phone",
  "name": "Contact Phone",
  "type": "data",
  "namespace": "contacts",
  "tags": ["supporting-entity", "administrative"],
  "status": "discovered",

  "requires": ["data.contacts.contact"],

  "spec": {
    "purpose": "Phone number for a contact with label and formatting.",
    "fields": {
      "required": [
        { "name": "id", "type": "uuid" },
        { "name": "contact_id", "type": "uuid", "foreign_key": "Contact" },
        { "name": "phone_number", "type": "string", "description": "E.164 format preferred" }
      ],
      "optional": [
        { "name": "label", "type": "string", "description": "e.g., Mobile, Work, Home, Fax" },
        { "name": "is_primary", "type": "boolean", "default": false },
        { "name": "country_code", "type": "string", "description": "ISO 3166-1 alpha-2" }
      ]
    },
    "indexes": [
      { "fields": ["phone_number"], "type": "btree", "purpose": "duplicate detection" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "administrative.contacts",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### ContactAddress

```json
{
  "id": "data.contacts.contact_address",
  "name": "Contact Address",
  "type": "data",
  "namespace": "contacts",
  "tags": ["supporting-entity", "administrative"],
  "status": "discovered",

  "requires": ["data.contacts.contact"],

  "spec": {
    "purpose": "Physical or mailing address for a contact.",
    "fields": {
      "required": [
        { "name": "id", "type": "uuid" },
        { "name": "contact_id", "type": "uuid", "foreign_key": "Contact" }
      ],
      "optional": [
        { "name": "label", "type": "string", "description": "e.g., Home, Work, Shipping, Billing" },
        { "name": "street_line_1", "type": "string" },
        { "name": "street_line_2", "type": "string" },
        { "name": "city", "type": "string" },
        { "name": "state_province", "type": "string" },
        { "name": "postal_code", "type": "string" },
        { "name": "country", "type": "string", "description": "ISO 3166-1 alpha-2" },
        { "name": "is_primary", "type": "boolean", "default": false },
        { "name": "latitude", "type": "decimal", "description": "For geocoded addresses" },
        { "name": "longitude", "type": "decimal" }
      ]
    }
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "administrative.contacts",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### ContactGroup

```json
{
  "id": "data.contacts.contact_group",
  "name": "Contact Group",
  "type": "data",
  "namespace": "contacts",
  "tags": ["supporting-entity", "administrative"],
  "status": "discovered",

  "spec": {
    "purpose": "Logical grouping of contacts for organization and bulk actions.",
    "fields": {
      "required": [
        { "name": "id", "type": "uuid" },
        { "name": "name", "type": "string", "max_length": 100 },
        { "name": "owner_id", "type": "uuid", "foreign_key": "User" }
      ],
      "optional": [
        { "name": "description", "type": "text" },
        { "name": "color", "type": "string", "description": "Hex color for UI" },
        { "name": "is_system", "type": "boolean", "default": false, "description": "Auto-managed groups" }
      ]
    },
    "relationships": [
      { "entity": "Contact", "type": "many_to_many", "through": "ContactGroupMembership" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "administrative.contacts",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### Import Contacts

```yaml
workflow:
  id: "workflow.contacts.import"
  name: "Import Contacts"
  trigger: "User uploads contact file or connects external service"

  steps:
    - step: 1
      action: "Accept import source"
      screen: "ImportWizard"
      sources: ["CSV", "vCard", "Google", "Outlook", "LinkedIn"]

    - step: 2
      action: "Parse and preview"
      service: "ImportService.parse"
      outputs: ["parsed_contacts", "field_mapping", "errors"]

    - step: 3
      action: "Map fields"
      screen: "FieldMappingDialog"
      user_action: "Confirm or adjust field mapping"

    - step: 4
      action: "Detect duplicates"
      service: "DeduplicationService.findDuplicates"
      match_fields: ["email", "phone", "name_similarity"]
      outputs: ["new_contacts", "potential_duplicates"]

    - step: 5
      action: "Handle duplicates"
      condition: "potential_duplicates.length > 0"
      screen: "DuplicateResolutionDialog"
      user_choices: ["skip", "merge", "create_anyway"]

    - step: 6
      action: "Import contacts"
      service: "ContactService.bulkCreate"

    - step: 7
      action: "Report results"
      screen: "ImportResultsDialog"
      shows: ["created_count", "skipped_count", "errors"]

  ai_touchpoints:
    - location: "step 3"
      capability: "Auto-detect field mapping from column headers and data patterns"
    - location: "step 4"
      capability: "Fuzzy name matching with confidence scores"
```

#### Merge Contacts

```yaml
workflow:
  id: "workflow.contacts.merge"
  name: "Merge Duplicate Contacts"
  trigger: "User selects contacts to merge or system suggests duplicates"

  steps:
    - step: 1
      action: "Display merge preview"
      screen: "MergePreviewDialog"
      shows: ["contact_a_fields", "contact_b_fields", "suggested_merge"]

    - step: 2
      action: "User selects values"
      user_action: "For each field, choose from A, B, or combine"

    - step: 3
      action: "Create merged contact"
      service: "ContactService.merge"

    - step: 4
      action: "Update references"
      service: "ReferenceService.updateAll"
      updates: ["events", "communications", "linked_records"]

    - step: 5
      action: "Archive or delete originals"
      user_choice: ["archive_originals", "delete_originals"]

  ai_touchpoints:
    - location: "step 1"
      capability: "Suggest best value for each field based on recency, completeness, and source reliability"
```

### Edge Case Library

| Edge Case | Description | Handling Strategy |
|-----------|-------------|-------------------|
| **Duplicate detection** | Same person added multiple times | Match on email (exact), phone (normalized), name (fuzzy with threshold) |
| **Shared vs private** | Contact visibility across org | Permission model: private (owner only), shared (specific users/groups), org-wide |
| **External sync conflicts** | Contact modified in two systems | Last-write-wins with conflict log; optional manual resolution |
| **Name ordering** | Different cultures have different name order | Support "display name override" and configurable name format |
| **Organization hierarchy** | Person works at subsidiary | Link contacts to organization contact; support org hierarchies |
| **Deceased/inactive** | Person no longer reachable | Soft delete with "inactive" status; hide from normal search |
| **GDPR/privacy** | Contact requests data deletion | True delete option with cascade; audit log preserved |
| **Import field mismatch** | CSV has unexpected format | Flexible parser with user-assisted mapping; skip unparseable rows |

### AI Touchpoints

| Touchpoint | Location | Capability | Implementation Notes |
|------------|----------|------------|---------------------|
| **Smart Deduplication** | Import, ongoing | Identify likely duplicates across name variations, email domains | Use embedding similarity for name matching; flag for human review |
| **Contact Enrichment** | After creation | Auto-populate company, title, social profiles from email domain | Integrate with Clearbit, Hunter, or similar APIs |
| **Relationship Detection** | Ongoing | Infer relationships from communication patterns | "You email these 3 contacts together often - create a group?" |
| **Business Card Scanning** | Mobile import | OCR + field extraction from business card photo | Use Vision API with structured extraction |

---

## Package: Tasks

**Namespace**: `administrative.tasks`

### Purpose

Track action items, to-dos, and reminders with assignment, prioritization, and due date management.

### Discovery Questions (R2/R3)

**Entity Discovery (R2)**
- "How do users organize tasks?" (lists, projects, tags, priorities)
- "What task statuses do you need?" (to-do, in progress, done, blocked)
- "Do tasks have due dates, time estimates, or both?"
- "Can tasks be assigned to others?"
- "Do tasks have subtasks or checklists?"

**Workflow Discovery (R3)**
- "How are tasks created?" (manual, from email, from meeting, from ticket)
- "What happens when a task is overdue?"
- "How do users view their tasks?" (list, board, calendar)
- "Do tasks need approval workflows?"
- "How are recurring tasks handled?"

### Entity Templates

#### Task

```json
{
  "id": "data.tasks.task",
  "name": "Task",
  "type": "data",
  "namespace": "tasks",
  "tags": ["core-entity", "administrative"],
  "status": "discovered",

  "spec": {
    "purpose": "Represents an actionable item with assignee, due date, and completion tracking.",
    "acceptance_criteria": [
      { "id": "AC-1", "description": "CRUD operations for tasks", "verification_method": "automated" },
      { "id": "AC-2", "description": "Support task assignment and reassignment", "verification_method": "automated" },
      { "id": "AC-3", "description": "Track completion status and timestamp", "verification_method": "automated" },
      { "id": "AC-4", "description": "Support subtasks/checklist items", "verification_method": "automated" }
    ],
    "fields": {
      "required": [
        { "name": "id", "type": "uuid" },
        { "name": "title", "type": "string", "max_length": 500 },
        { "name": "status", "type": "enum", "values": ["todo", "in_progress", "blocked", "done", "cancelled"] },
        { "name": "created_by", "type": "uuid", "foreign_key": "User" }
      ],
      "optional": [
        { "name": "description", "type": "text" },
        { "name": "task_list_id", "type": "uuid", "foreign_key": "TaskList" },
        { "name": "assignee_id", "type": "uuid", "foreign_key": "User" },
        { "name": "due_date", "type": "date" },
        { "name": "due_time", "type": "time" },
        { "name": "priority", "type": "enum", "values": ["urgent", "high", "medium", "low", "none"] },
        { "name": "estimated_minutes", "type": "integer" },
        { "name": "actual_minutes", "type": "integer" },
        { "name": "parent_task_id", "type": "uuid", "foreign_key": "Task", "description": "For subtasks" },
        { "name": "completed_at", "type": "datetime" },
        { "name": "completed_by", "type": "uuid", "foreign_key": "User" },
        { "name": "recurrence_rule_id", "type": "uuid", "foreign_key": "RecurrenceRule" },
        { "name": "source", "type": "string", "description": "Where task originated" },
        { "name": "external_id", "type": "string" },
        { "name": "sort_order", "type": "integer", "description": "Manual ordering within list" }
      ]
    },
    "relationships": [
      { "entity": "TaskList", "type": "belongs_to", "optional": true },
      { "entity": "Task", "type": "has_many", "foreign_key": "parent_task_id", "description": "Subtasks" },
      { "entity": "TaskTag", "type": "many_to_many", "through": "TaskTagging" },
      { "entity": "Reminder", "type": "has_many", "foreign_key": "task_id" }
    ],
    "indexes": [
      { "fields": ["assignee_id", "status"], "type": "btree" },
      { "fields": ["due_date"], "type": "btree" },
      { "fields": ["task_list_id", "sort_order"], "type": "btree" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "administrative.tasks",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### TaskList

```json
{
  "id": "data.tasks.task_list",
  "name": "Task List",
  "type": "data",
  "namespace": "tasks",
  "tags": ["supporting-entity", "administrative"],
  "status": "discovered",

  "spec": {
    "purpose": "Container for organizing tasks (like a project or category).",
    "fields": {
      "required": [
        { "name": "id", "type": "uuid" },
        { "name": "name", "type": "string", "max_length": 100 },
        { "name": "owner_id", "type": "uuid", "foreign_key": "User" }
      ],
      "optional": [
        { "name": "description", "type": "text" },
        { "name": "color", "type": "string" },
        { "name": "icon", "type": "string" },
        { "name": "is_default", "type": "boolean", "default": false },
        { "name": "view_type", "type": "enum", "values": ["list", "board", "calendar"] },
        { "name": "is_shared", "type": "boolean", "default": false }
      ]
    },
    "relationships": [
      { "entity": "Task", "type": "has_many", "foreign_key": "task_list_id" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "administrative.tasks",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Reminder

```json
{
  "id": "data.tasks.reminder",
  "name": "Reminder",
  "type": "data",
  "namespace": "tasks",
  "tags": ["supporting-entity", "administrative"],
  "status": "discovered",

  "spec": {
    "purpose": "Scheduled notification for a task or standalone reminder.",
    "fields": {
      "required": [
        { "name": "id", "type": "uuid" },
        { "name": "remind_at", "type": "datetime" },
        { "name": "user_id", "type": "uuid", "foreign_key": "User" }
      ],
      "optional": [
        { "name": "task_id", "type": "uuid", "foreign_key": "Task" },
        { "name": "title", "type": "string", "description": "For standalone reminders" },
        { "name": "channel", "type": "enum", "values": ["push", "email", "sms", "in_app"], "default": "push" },
        { "name": "is_sent", "type": "boolean", "default": false },
        { "name": "sent_at", "type": "datetime" },
        { "name": "is_recurring", "type": "boolean", "default": false },
        { "name": "recurrence_rule_id", "type": "uuid", "foreign_key": "RecurrenceRule" }
      ]
    },
    "indexes": [
      { "fields": ["remind_at", "is_sent"], "type": "btree", "purpose": "reminder queue processing" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "administrative.tasks",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### Complete Task

```yaml
workflow:
  id: "workflow.tasks.complete"
  name: "Complete Task"
  trigger: "User marks task as done"

  steps:
    - step: 1
      action: "Update task status"
      service: "TaskService.complete"
      sets: ["status=done", "completed_at=now", "completed_by=current_user"]

    - step: 2
      action: "Check for subtasks"
      condition: "has_incomplete_subtasks"
      options:
        - prompt_user: "This task has incomplete subtasks. Complete them too?"
        - auto_complete: "Complete all subtasks automatically"
        - block: "Cannot complete - subtasks required"

    - step: 3
      action: "Handle recurring"
      condition: "task.is_recurring"
      service: "TaskService.createNextOccurrence"

    - step: 4
      action: "Cancel reminders"
      service: "ReminderService.cancelForTask"

    - step: 5
      action: "Notify stakeholders"
      condition: "task.has_watchers OR task.created_by != current_user"
      service: "NotificationService.taskCompleted"

  ai_touchpoints:
    - location: "step 3"
      capability: "Suggest adjusting recurrence if task was consistently late or early"
```

#### Delegate Task

```yaml
workflow:
  id: "workflow.tasks.delegate"
  name: "Delegate Task"
  trigger: "User assigns task to another user"

  steps:
    - step: 1
      action: "Select assignee"
      screen: "UserPicker"
      filters: ["same_team", "has_permission"]

    - step: 2
      action: "Set delegation type"
      user_choices:
        - "full": "Transfer ownership"
        - "partial": "Keep as watcher"

    - step: 3
      action: "Add optional message"
      screen: "DelegationNote"

    - step: 4
      action: "Update task"
      service: "TaskService.delegate"

    - step: 5
      action: "Notify assignee"
      service: "NotificationService.taskAssigned"

  ai_touchpoints:
    - location: "step 1"
      capability: "Suggest assignee based on workload, expertise, and past task assignments"
```

### Edge Case Library

| Edge Case | Description | Handling Strategy |
|-----------|-------------|-------------------|
| **Overdue tasks** | Task past due date | Visual indicator; optional auto-escalation; snooze option |
| **Recurring completion** | User completes recurring task early | Create next occurrence from original schedule or from completion date (configurable) |
| **Circular subtasks** | Task A subtask of B subtask of A | Validate hierarchy on save; reject circular references |
| **Assignee deleted** | Assigned user leaves org | Reassign to creator or manager; flag unassigned tasks |
| **Time zone due dates** | Due date in which timezone? | Date-only = end of day in user's timezone; datetime = explicit timezone |
| **Bulk operations** | Complete/delete many tasks | Batch processing with progress indicator; undo support |
| **Task dependencies** | Task blocked by another | Blocked status; auto-unblock when blocker completes |
| **Migration from other tools** | Import from Asana, Trello, etc. | Mapping templates for common sources; preserve IDs for linking |

### AI Touchpoints

| Touchpoint | Location | Capability | Implementation Notes |
|------------|----------|------------|---------------------|
| **Smart Prioritization** | Dashboard | Suggest task order based on due date, priority, estimated effort, and dependencies | Learn from user's actual completion patterns |
| **Due Date Suggestions** | Task creation | Predict appropriate due date based on task type and user's velocity | "Similar tasks took 3 days - suggest due date?" |
| **Workload Balancing** | Delegation | Show team workload heatmap; warn about over-assignment | Integrate with time tracking if available |
| **Natural Language Input** | Quick add | Parse "Call John tomorrow at 2pm" into task + reminder | Use NLP to extract entities and temporal expressions |

---

## Package: Settings

**Namespace**: `administrative.settings`

### Purpose

Manage user preferences, system configuration, and feature flags at user, team, and organization levels.

### Discovery Questions (R2/R3)

**Entity Discovery (R2)**
- "What can users personalize?" (theme, language, timezone, notifications)
- "What system settings exist?" (business hours, default currency, tax rates)
- "Are there different settings per organization/tenant?"
- "Do you need feature flags for gradual rollout?"

**Workflow Discovery (R3)**
- "Who can change system settings vs user settings?"
- "How do settings inherit?" (org defaults -> team -> user)
- "What happens when settings change?" (real-time or next session)
- "Are there settings that require confirmation or have side effects?"

### Entity Templates

#### UserPreference

```json
{
  "id": "data.settings.user_preference",
  "name": "User Preference",
  "type": "data",
  "namespace": "settings",
  "tags": ["core-entity", "administrative"],
  "status": "discovered",

  "spec": {
    "purpose": "Stores per-user preferences that override org/system defaults.",
    "acceptance_criteria": [
      { "id": "AC-1", "description": "CRUD operations for preferences", "verification_method": "automated" },
      { "id": "AC-2", "description": "Preferences inherit from org defaults", "verification_method": "automated" },
      { "id": "AC-3", "description": "Support typed values (string, number, boolean, json)", "verification_method": "automated" }
    ],
    "fields": {
      "required": [
        { "name": "id", "type": "uuid" },
        { "name": "user_id", "type": "uuid", "foreign_key": "User" },
        { "name": "key", "type": "string", "max_length": 100 },
        { "name": "value", "type": "jsonb", "description": "Typed preference value" }
      ],
      "optional": [
        { "name": "value_type", "type": "enum", "values": ["string", "integer", "boolean", "json"], "default": "string" }
      ]
    },
    "indexes": [
      { "fields": ["user_id", "key"], "type": "btree", "unique": true }
    ],
    "common_keys": [
      { "key": "theme", "type": "string", "values": ["light", "dark", "system"], "default": "system" },
      { "key": "language", "type": "string", "default": "en" },
      { "key": "timezone", "type": "string", "default": "UTC" },
      { "key": "date_format", "type": "string", "default": "YYYY-MM-DD" },
      { "key": "time_format", "type": "string", "values": ["12h", "24h"], "default": "12h" },
      { "key": "week_start", "type": "string", "values": ["sunday", "monday"], "default": "sunday" },
      { "key": "notifications_enabled", "type": "boolean", "default": true },
      { "key": "email_digest", "type": "string", "values": ["none", "daily", "weekly"], "default": "daily" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "administrative.settings",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### SystemConfig

```json
{
  "id": "data.settings.system_config",
  "name": "System Configuration",
  "type": "data",
  "namespace": "settings",
  "tags": ["core-entity", "administrative"],
  "status": "discovered",

  "spec": {
    "purpose": "Organization-wide or system-level configuration (not per-user).",
    "acceptance_criteria": [
      { "id": "AC-1", "description": "Support organization-scoped and global configs", "verification_method": "automated" },
      { "id": "AC-2", "description": "Track who changed what and when", "verification_method": "automated" },
      { "id": "AC-3", "description": "Support environment-specific overrides", "verification_method": "automated" }
    ],
    "fields": {
      "required": [
        { "name": "id", "type": "uuid" },
        { "name": "key", "type": "string", "max_length": 100 },
        { "name": "value", "type": "jsonb" }
      ],
      "optional": [
        { "name": "organization_id", "type": "uuid", "foreign_key": "Organization", "description": "Null for global" },
        { "name": "value_type", "type": "enum", "values": ["string", "integer", "boolean", "json"] },
        { "name": "description", "type": "text" },
        { "name": "is_sensitive", "type": "boolean", "default": false, "description": "Mask in logs/UI" },
        { "name": "requires_restart", "type": "boolean", "default": false },
        { "name": "updated_by", "type": "uuid", "foreign_key": "User" }
      ]
    },
    "indexes": [
      { "fields": ["organization_id", "key"], "type": "btree", "unique": true }
    ],
    "common_keys": [
      { "key": "company_name", "type": "string" },
      { "key": "company_logo_url", "type": "string" },
      { "key": "default_currency", "type": "string", "default": "USD" },
      { "key": "default_timezone", "type": "string", "default": "UTC" },
      { "key": "business_hours", "type": "json", "description": "{ mon: { start: '09:00', end: '17:00' }, ... }" },
      { "key": "fiscal_year_start", "type": "string", "default": "01-01" },
      { "key": "password_policy", "type": "json" },
      { "key": "session_timeout_minutes", "type": "integer", "default": 60 }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "administrative.settings",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### FeatureFlag

```json
{
  "id": "data.settings.feature_flag",
  "name": "Feature Flag",
  "type": "data",
  "namespace": "settings",
  "tags": ["core-entity", "administrative"],
  "status": "discovered",

  "spec": {
    "purpose": "Controls feature availability for gradual rollout and A/B testing.",
    "acceptance_criteria": [
      { "id": "AC-1", "description": "Support global, org, and user-level flags", "verification_method": "automated" },
      { "id": "AC-2", "description": "Support percentage-based rollout", "verification_method": "automated" },
      { "id": "AC-3", "description": "Cache flags for performance", "verification_method": "automated" }
    ],
    "fields": {
      "required": [
        { "name": "id", "type": "uuid" },
        { "name": "key", "type": "string", "max_length": 100, "description": "e.g., 'new_dashboard'" },
        { "name": "is_enabled", "type": "boolean", "default": false }
      ],
      "optional": [
        { "name": "description", "type": "text" },
        { "name": "rollout_percentage", "type": "integer", "min": 0, "max": 100, "description": "% of users who see feature" },
        { "name": "allowed_organizations", "type": "uuid[]", "description": "Org IDs with access" },
        { "name": "allowed_users", "type": "uuid[]", "description": "User IDs with access (beta testers)" },
        { "name": "blocked_organizations", "type": "uuid[]" },
        { "name": "blocked_users", "type": "uuid[]" },
        { "name": "start_at", "type": "datetime", "description": "Auto-enable at this time" },
        { "name": "end_at", "type": "datetime", "description": "Auto-disable at this time" },
        { "name": "variant", "type": "json", "description": "For A/B testing with variants" }
      ]
    },
    "indexes": [
      { "fields": ["key"], "type": "btree", "unique": true }
    ],
    "evaluation_order": [
      "1. Check blocked_users (highest precedence)",
      "2. Check blocked_organizations",
      "3. Check allowed_users (beta list)",
      "4. Check allowed_organizations",
      "5. Check start_at/end_at",
      "6. Check rollout_percentage (hash user_id for consistency)",
      "7. Fall back to is_enabled"
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "administrative.settings",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### Change System Setting

```yaml
workflow:
  id: "workflow.settings.change_system"
  name: "Change System Setting"
  trigger: "Admin updates system configuration"

  steps:
    - step: 1
      action: "Validate permission"
      service: "PermissionService.check"
      required: "system_admin OR org_admin (if org-scoped)"

    - step: 2
      action: "Validate value"
      service: "SettingsService.validate"
      checks: ["type_match", "range_check", "format_check"]

    - step: 3
      action: "Check for side effects"
      condition: "setting.has_side_effects"
      screen: "ConfirmationDialog"
      shows: ["current_value", "new_value", "affected_users", "side_effects"]

    - step: 4
      action: "Save setting"
      service: "SystemConfigService.update"

    - step: 5
      action: "Audit log"
      service: "AuditService.log"
      data: ["old_value", "new_value", "changed_by", "timestamp"]

    - step: 6
      action: "Broadcast change"
      condition: "setting.requires_restart == false"
      service: "SettingsService.broadcast"
      channel: "websocket"

  ai_touchpoints:
    - location: "step 3"
      capability: "Predict impact of setting change based on historical data"
```

#### Feature Flag Rollout

```yaml
workflow:
  id: "workflow.settings.feature_rollout"
  name: "Gradual Feature Rollout"
  trigger: "Admin enables feature flag with percentage"

  steps:
    - step: 1
      action: "Set initial percentage"
      screen: "FeatureFlagEditor"
      input: "rollout_percentage = 5"

    - step: 2
      action: "Monitor metrics"
      service: "MetricsService.trackFeature"
      metrics: ["error_rate", "latency", "user_feedback"]
      duration: "24 hours"

    - step: 3
      action: "Evaluate metrics"
      condition: "metrics within thresholds"
      then: "Increase percentage"
      else: "Alert and hold"

    - step: 4
      action: "Iterate rollout"
      progression: [5, 10, 25, 50, 100]
      between_stages: "manual approval OR auto after duration"

    - step: 5
      action: "Full rollout"
      service: "FeatureFlagService.enable"
      sets: ["is_enabled=true", "rollout_percentage=100"]

  ai_touchpoints:
    - location: "step 3"
      capability: "Anomaly detection in metrics during rollout"
```

### Edge Case Library

| Edge Case | Description | Handling Strategy |
|-----------|-------------|-------------------|
| **Inheritance conflicts** | User pref vs org default | User > Team > Org > System (most specific wins) |
| **Invalid saved values** | Schema changed, old value invalid | Migrate on read; fall back to default if migration fails |
| **Sensitive settings** | API keys, passwords | Encrypt at rest; mask in UI; audit all access |
| **Circular feature deps** | Feature A requires B requires A | Dependency graph validation on save |
| **Percentage drift** | User sees different feature state on different devices | Hash user_id deterministically for consistent evaluation |
| **Settings migration** | Rename or restructure settings | Migration system with version tracking; backward compatibility |
| **Cache invalidation** | Setting changed but cached | Event-driven invalidation; short TTL for critical settings |
| **Timezone change** | User changes timezone preference | Re-render time-based data; option to convert existing events |

### AI Touchpoints

| Touchpoint | Location | Capability | Implementation Notes |
|------------|----------|------------|---------------------|
| **Settings Discovery** | Onboarding | Guide new users through relevant settings based on role | "As an admin, you might want to configure these 5 settings" |
| **Anomaly Detection** | Feature rollout | Alert if metrics degrade during rollout | Compare against baseline from before rollout |
| **Personalization** | User preferences | Suggest settings based on usage patterns | "You use dark mode at night - enable auto theme switching?" |

---

## Cross-Module Integration Patterns

### Calendar Integration Points

| Integrating Module | Integration Pattern | Example |
|-------------------|---------------------|---------|
| **CRM** | Link events to customers | "Meeting with Acme Corp" linked to customer record |
| **Sales** | Sync opportunities with meetings | Deal stage meetings on sales calendar |
| **HR** | Leave on team calendar | PTO requests show as all-day events |
| **Project** | Milestone deadlines | Project deadlines on shared calendar |
| **Field Service** | Appointment scheduling | Service appointments with travel time |

**Calendar as Data Source**:
```yaml
event_created:
  - sync_to: google_calendar (if connected)
  - notify: attendees via email
  - block: availability for conflict detection

event_from_external:
  - import: via Google/Outlook sync
  - detect: duplicates by external_id
  - link: to internal contacts/customers if email matches
```

### Contact Sharing Patterns

| Sharing Level | Access | Use Case |
|---------------|--------|----------|
| **Private** | Owner only | Personal contacts |
| **Team** | Team members | Shared client contacts |
| **Organization** | All org users | Company directory |
| **Public** | External visibility | Published contact info |

**Cross-Module Contact Usage**:
```yaml
crm:
  - Contact becomes CRM Contact when "is_customer" flag set
  - Sync bidirectionally with CRM customer records

invoicing:
  - Use Contact as billing contact
  - Pull address for invoice generation

communication:
  - Use Contact emails/phones for outreach
  - Track communication history against contact
```

### Task Assignment Workflows

| Scenario | Source Module | Task Creation | Assignment |
|----------|---------------|---------------|------------|
| Follow-up | CRM | Auto after meeting | Assigned to meeting owner |
| Approval | Financial | Triggered by threshold | Assigned to approver role |
| Work Order | Field Service | Created from dispatch | Assigned to technician |
| Action Item | Project | From meeting notes | Assigned in meeting |

**Task Status Sync**:
```yaml
task_completed:
  triggers:
    - crm: Update activity timeline
    - project: Mark deliverable progress
    - field_service: Update work order status
```

### Settings Inheritance Model

```
┌─────────────────────────────────────────────────────────────┐
│                     SYSTEM DEFAULTS                          │
│  (Hardcoded in application, fallback for everything)        │
└─────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  ORGANIZATION SETTINGS                       │
│  (SystemConfig where organization_id = org)                 │
│  Overrides: system defaults                                  │
└─────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     TEAM SETTINGS                            │
│  (SystemConfig where team_id = team)                        │
│  Overrides: organization settings                            │
└─────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    USER PREFERENCES                          │
│  (UserPreference where user_id = user)                      │
│  Overrides: team settings (highest precedence)              │
└─────────────────────────────────────────────────────────────┘
```

**Resolution Algorithm**:
```python
def get_setting(user, key):
    # Check user preference first
    if pref := UserPreference.get(user_id=user.id, key=key):
        return pref.value

    # Check team settings
    if user.team_id:
        if config := SystemConfig.get(team_id=user.team_id, key=key):
            return config.value

    # Check org settings
    if config := SystemConfig.get(organization_id=user.org_id, key=key):
        return config.value

    # Check global settings
    if config := SystemConfig.get(organization_id=None, key=key):
        return config.value

    # Return system default
    return SYSTEM_DEFAULTS.get(key)
```

---

## Multi-Tenancy Considerations

### User vs Organization Settings

| Setting Type | Scope | Examples | Who Can Modify |
|--------------|-------|----------|----------------|
| Personal | User | Theme, language, timezone | User |
| Team | Team/Dept | Shared calendars, task lists | Team admin |
| Organization | Org | Logo, business hours, defaults | Org admin |
| System | Global | Feature flags, system limits | System admin |

### Permission Inheritance

```yaml
permissions:
  calendar:
    org_admin:
      - view_all_calendars
      - manage_shared_calendars
      - set_org_calendar_defaults
    team_admin:
      - view_team_calendars
      - manage_team_calendar
    user:
      - manage_own_calendars
      - view_shared_calendars (if granted)

  contacts:
    org_admin:
      - view_all_contacts
      - manage_shared_contacts
      - import_export_bulk
    user:
      - manage_own_contacts
      - view_shared_contacts (if granted)

  settings:
    system_admin:
      - modify_all_settings
      - manage_feature_flags
    org_admin:
      - modify_org_settings
      - view_feature_flags
    user:
      - modify_own_preferences
```

### Feature Flags per Tenant

```yaml
feature_flag_evaluation:
  order:
    1. Check if user explicitly blocked
    2. Check if org explicitly blocked
    3. Check if user explicitly allowed (beta)
    4. Check if org explicitly allowed
    5. Check rollout percentage (deterministic by user_id)
    6. Check global enabled state

  tenant_override:
    - Enterprise orgs can request early access
    - Beta orgs can have all features
    - Some features org-specific (white-label, SSO)
```

---

## External Integration Points

### Google Calendar Integration

```yaml
integration:
  name: "Google Calendar Sync"
  provider: "google"
  scopes:
    - "https://www.googleapis.com/auth/calendar"
    - "https://www.googleapis.com/auth/calendar.events"

  sync_config:
    direction: bidirectional
    conflict_resolution: last_write_wins
    sync_interval: 5_minutes

  field_mapping:
    Event.title: summary
    Event.description: description
    Event.start_at: start.dateTime
    Event.end_at: end.dateTime
    Event.location: location
    Event.is_all_day: (start.date != null)
    Event.attendees: attendees[].email
    Event.recurrence: recurrence

  webhooks:
    incoming:
      endpoint: "/webhooks/google/calendar"
      events: ["created", "updated", "deleted"]
    outgoing:
      on_change: push_to_google

  edge_cases:
    - Handle Google's recurrence format (RRULE) conversion
    - Map Google's responseStatus to our status enum
    - Handle "out of office" and "focus time" event types
    - Rate limiting: exponential backoff on 429
```

### Microsoft Outlook Integration

```yaml
integration:
  name: "Outlook Calendar Sync"
  provider: "microsoft"
  scopes:
    - "Calendars.ReadWrite"
    - "Contacts.ReadWrite"

  sync_config:
    direction: bidirectional
    conflict_resolution: last_write_wins
    delta_sync: true  # Use Graph delta queries

  field_mapping:
    Event.title: subject
    Event.description: body.content
    Event.start_at: start.dateTime
    Event.end_at: end.dateTime
    Event.location: location.displayName
    Event.is_all_day: isAllDay
    Event.attendees: attendees[].emailAddress.address

  contacts_mapping:
    Contact.first_name: givenName
    Contact.last_name: surname
    Contact.emails: emailAddresses[].address
    Contact.phones: phones[].number

  edge_cases:
    - Handle recurring event master vs instances
    - Map Outlook sensitivity levels to visibility
    - Handle shared mailbox calendars
    - Pagination for large contact lists
```

### Contact Import/Export Formats

```yaml
import_formats:
  csv:
    parser: "flexible_csv"
    encoding: ["utf-8", "utf-16", "latin-1"]
    delimiter: [",", ";", "\t"]
    header_detection: auto

  vcard:
    versions: ["2.1", "3.0", "4.0"]
    encoding: "utf-8"
    multi_contact: true

  google_csv:
    preset_mapping: true
    columns: ["Name", "Given Name", "Family Name", "Email 1 - Value", ...]

  outlook_csv:
    preset_mapping: true
    columns: ["First Name", "Last Name", "E-mail Address", ...]

export_formats:
  csv:
    columns: configurable
    encoding: "utf-8"
    include_headers: true

  vcard:
    version: "3.0"
    photo_handling: embed_base64 | link | omit

  json:
    schema: "contact_export_v1"
    pretty_print: optional
```

---

## Screen Templates

### CalendarView

```yaml
screen:
  id: "screen.calendar.calendar_view"
  name: "Calendar View"
  type: "screen"
  namespace: "calendar"

  layout:
    views: ["month", "week", "day", "agenda"]
    default_view: "week"
    sidebar:
      - calendar_list
      - mini_month
      - upcoming_events

  interactions:
    - click_date: "Open event creation for that date/time"
    - drag_event: "Reschedule event"
    - resize_event: "Change event duration"
    - click_event: "Open event detail popover"
    - double_click_event: "Open event edit form"

  filters:
    - calendar_visibility: "Show/hide calendars"
    - date_range: "Navigate to specific date"
    - search: "Filter events by text"

  requires:
    entities: ["Calendar", "Event", "Attendee"]
    permissions: ["calendar:read"]
```

### ContactList

```yaml
screen:
  id: "screen.contacts.contact_list"
  name: "Contact List"
  type: "screen"
  namespace: "contacts"

  layout:
    list_view:
      columns: ["avatar", "name", "organization", "email", "phone", "tags"]
      row_actions: ["edit", "delete", "merge"]
    detail_panel:
      shows_on: "row_click"
      content: ["full_contact_details", "recent_activity"]

  interactions:
    - search: "Full-text search across all fields"
    - filter_by_group: "Show contacts in selected group"
    - sort: "By name, organization, recently added"
    - bulk_select: "For bulk actions"

  bulk_actions:
    - add_to_group
    - remove_from_group
    - export_selected
    - delete_selected
    - merge_selected

  requires:
    entities: ["Contact", "ContactGroup", "ContactEmail", "ContactPhone"]
    permissions: ["contacts:read"]
```

### TaskBoard

```yaml
screen:
  id: "screen.tasks.task_board"
  name: "Task Board (Kanban)"
  type: "screen"
  namespace: "tasks"

  layout:
    columns:
      - id: "todo"
        title: "To Do"
        status_filter: "todo"
      - id: "in_progress"
        title: "In Progress"
        status_filter: "in_progress"
      - id: "blocked"
        title: "Blocked"
        status_filter: "blocked"
      - id: "done"
        title: "Done"
        status_filter: "done"
        collapsed_by_default: true

  card_display:
    - title
    - assignee_avatar
    - due_date (with overdue indicator)
    - priority_indicator
    - subtask_progress

  interactions:
    - drag_between_columns: "Change status"
    - drag_within_column: "Reorder"
    - click_card: "Open detail panel"
    - quick_add: "Add task to column"

  filters:
    - assignee
    - due_date_range
    - priority
    - tags

  requires:
    entities: ["Task", "TaskList"]
    permissions: ["tasks:read"]
```

### SettingsPanel

```yaml
screen:
  id: "screen.settings.settings_panel"
  name: "Settings Panel"
  type: "screen"
  namespace: "settings"

  layout:
    navigation:
      - section: "Personal"
        items: ["profile", "appearance", "notifications", "security"]
      - section: "Organization"
        items: ["company", "team", "billing", "integrations"]
        requires_permission: "org_admin"
      - section: "System"
        items: ["features", "advanced"]
        requires_permission: "system_admin"

  setting_display:
    - label
    - current_value
    - input_control (toggle, dropdown, text, etc.)
    - description
    - inheritance_indicator (if overriding org default)

  interactions:
    - change_setting: "Update preference/config"
    - reset_to_default: "Remove user override"
    - export_settings: "Download settings backup"

  requires:
    entities: ["UserPreference", "SystemConfig", "FeatureFlag"]
    permissions: ["settings:read_own"]
```

---

## Summary

The Administrative module provides foundational capabilities that nearly every application needs:

| Package | Core Entities | Key Workflows | Primary Edge Cases |
|---------|---------------|---------------|-------------------|
| **Calendar** | Event, Attendee, RecurrenceRule, Calendar | Schedule Event, Handle Recurring | Timezone, DST, Conflicts |
| **Contacts** | Contact, ContactEmail, ContactPhone, ContactGroup | Import, Merge, Sync | Duplicates, Privacy, Name formats |
| **Tasks** | Task, TaskList, Reminder | Complete, Delegate, Recurring | Overdue, Subtasks, Dependencies |
| **Settings** | UserPreference, SystemConfig, FeatureFlag | Change System, Rollout Feature | Inheritance, Migration, Cache |

**Cross-Module Integration**: Calendar, contacts, and tasks serve as shared infrastructure for CRM, Sales, HR, Project, and Field Service modules. Settings provide the configuration backbone for all modules.

**Multi-Tenancy**: All packages support user, team, organization, and system-level scoping with proper permission inheritance.

**External Integrations**: Calendar syncs with Google/Outlook; contacts import from CSV, vCard, and external services.

This module should be selected in R1.5 for any application requiring user scheduling, contact management, task tracking, or configuration management - which covers the vast majority of business applications.
