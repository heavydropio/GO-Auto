# Communication Module Catalog

**Module**: Communication
**Version**: 1.0
**Last Updated**: 2026-02-05

---

## Overview

The Communication module handles all outbound messaging within an application: sending notifications, marketing campaigns, transactional alerts, and user communications across multiple channels. The core principle is separation of content from delivery from tracking, using a unified message architecture rather than separate tables per channel.

### When to Use This Module

Select this module when R1 context includes any of:

| Trigger Phrases | Typical Actors | Business Need |
|-----------------|----------------|---------------|
| "notification", "alert", "reminder" | System, Admin | Inform users of events or actions needed |
| "email", "send email", "email template" | Marketing, Support | Deliver content via email channel |
| "SMS", "text message", "mobile alerts" | System, Operations | Time-sensitive mobile notifications |
| "push notification", "mobile push" | Product, Engineering | Engage users via app notifications |
| "in-app message", "inbox", "message center" | Product, Support | Deliver messages within the application |
| "campaign", "bulk send", "mass communication" | Marketing | Send to multiple recipients at once |
| "unsubscribe", "preferences", "opt-out" | User, Compliance | Manage communication consent |

### Module Dependencies

```
Communication Module
├── REQUIRES: Administrative (for user settings, preferences)
├── REQUIRES: Documents (for template storage, attachments)
├── INTEGRATES_WITH: CRM (customer contact info, segments)
├── INTEGRATES_WITH: Workflow (trigger-based sending)
├── INTEGRATES_WITH: Compliance (consent tracking, audit trails)
```

---

## Core Design Principles

### Separation of Concerns

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│    CONTENT      │    │    DELIVERY     │    │    TRACKING     │
│                 │    │                 │    │                 │
│  - Templates    │───▶│  - Routing      │───▶│  - DeliveryLog  │
│  - Variables    │    │  - Channels     │    │  - Events       │
│  - Localization │    │  - Retry Logic  │    │  - Analytics    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Unified Message Pattern

**DO**: Use a single Message table with a channel enum to handle all communication types.

```sql
-- Correct: Unified approach
CREATE TABLE message (
    id UUID PRIMARY KEY,
    channel ENUM('email', 'sms', 'push', 'in_app'),
    recipient_id UUID,
    template_id UUID,
    content JSONB,
    status ENUM('pending', 'sent', 'delivered', 'failed'),
    ...
);
```

**AVOID**: Separate tables per channel (EmailMessage, SmsMessage, PushMessage) which leads to:
- Duplicated business logic
- Complex cross-channel queries
- Inconsistent tracking
- Maintenance burden

---

## Packages

This module contains 4 packages:

1. **templates** - Creating and managing message templates
2. **delivery** - Sending messages across channels with retry logic
3. **preferences** - Managing user communication preferences and consent
4. **tracking** - Logging delivery status and engagement metrics

---

## Package 1: Templates

### Purpose

Create, version, and manage reusable message templates with dynamic content injection using Handlebars syntax.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What types of messages do you send? (transactional, marketing, operational)
- Do you need multi-language support?
- What variables need to be dynamic? (user name, order details, links)
- Do you have brand guidelines for different message types?

**Workflow Discovery**:
- Who creates and approves templates?
- How do you test templates before sending?
- Do you A/B test message content?
- What's your template versioning strategy?

**Edge Case Probing**:
- What if a required variable is missing?
- How do you handle templates that work for email but not SMS?
- What if a template references a deleted image?

### Template Engine: Handlebars

The module uses Handlebars for template rendering with support for:

```handlebars
<!-- Basic variable substitution -->
Hello {{user.firstName}},

<!-- Conditionals -->
{{#if order.isRush}}
Your order will arrive by tomorrow!
{{else}}
Your order will arrive in 3-5 business days.
{{/if}}

<!-- Loops -->
{{#each items}}
  - {{this.name}}: ${{this.price}}
{{/each}}

<!-- Formatters -->
Order Total: {{formatCurrency order.total}}
Order Date: {{formatDate order.createdAt "MMM DD, YYYY"}}
```

### Entity Templates

#### Template

```json
{
  "id": "data.templates.template",
  "name": "Template",
  "type": "data",
  "namespace": "templates",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Reusable message template with dynamic content placeholders.",
    "fields": [
      { "name": "template_key", "type": "string", "required": true, "description": "Unique identifier for programmatic reference (e.g., 'order_confirmation')" },
      { "name": "name", "type": "string", "required": true, "description": "Human-readable template name" },
      { "name": "description", "type": "text", "required": false, "description": "Purpose and usage notes" },
      { "name": "category", "type": "enum", "required": true, "values": ["transactional", "marketing", "operational", "system"], "description": "Template classification" },
      { "name": "channels", "type": "array", "required": true, "description": "Supported channels ['email', 'sms', 'push', 'in_app']" },
      { "name": "subject", "type": "string", "required": false, "description": "Email subject line (supports Handlebars)" },
      { "name": "body_html", "type": "text", "required": false, "description": "HTML body for email" },
      { "name": "body_text", "type": "text", "required": false, "description": "Plain text body for email/SMS" },
      { "name": "push_title", "type": "string", "required": false, "description": "Push notification title" },
      { "name": "push_body", "type": "string", "required": false, "description": "Push notification body (max 256 chars)" },
      { "name": "in_app_content", "type": "json", "required": false, "description": "Structured in-app message content" },
      { "name": "variables", "type": "json", "required": false, "description": "Schema of expected variables with types" },
      { "name": "locale", "type": "string", "required": true, "description": "ISO locale code (en-US, es-MX)" },
      { "name": "version", "type": "integer", "required": true, "description": "Template version number" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "active", "archived"], "description": "Template lifecycle status" },
      { "name": "created_by", "type": "uuid", "required": true, "description": "User who created template" },
      { "name": "approved_by", "type": "uuid", "required": false, "description": "User who approved for use" },
      { "name": "approved_at", "type": "datetime", "required": false, "description": "Approval timestamp" }
    ],
    "relationships": [
      { "entity": "TemplateVersion", "type": "one_to_many", "required": false },
      { "entity": "Message", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "communication.templates",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### TemplateVersion

```json
{
  "id": "data.templates.template_version",
  "name": "Template Version",
  "type": "data",
  "namespace": "templates",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Historical version of a template for auditing and rollback.",
    "fields": [
      { "name": "template_id", "type": "uuid", "required": true, "description": "Parent template" },
      { "name": "version", "type": "integer", "required": true, "description": "Version number" },
      { "name": "subject", "type": "string", "required": false, "description": "Subject at this version" },
      { "name": "body_html", "type": "text", "required": false, "description": "HTML body at this version" },
      { "name": "body_text", "type": "text", "required": false, "description": "Plain text body at this version" },
      { "name": "push_title", "type": "string", "required": false, "description": "Push title at this version" },
      { "name": "push_body", "type": "string", "required": false, "description": "Push body at this version" },
      { "name": "change_notes", "type": "text", "required": false, "description": "What changed in this version" },
      { "name": "created_at", "type": "datetime", "required": true, "description": "When version was created" },
      { "name": "created_by", "type": "uuid", "required": true, "description": "Who created this version" }
    ],
    "relationships": [
      { "entity": "Template", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "communication.templates",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.templates.create_and_approve

```yaml
workflow:
  id: "wf.templates.create_and_approve"
  name: "Create and Approve Template"
  trigger: "Staff creates new message template"
  actors: ["Content Creator", "Reviewer", "System"]

  steps:
    - step: 1
      name: "Draft Template"
      actor: "Content Creator"
      action: "Create template with content and variable placeholders"
      inputs: ["Template type", "Channel requirements", "Variable schema"]
      outputs: ["Draft template"]

    - step: 2
      name: "Preview and Test"
      actor: "Content Creator"
      action: "Render template with sample data across channels"
      inputs: ["Draft template", "Sample variable data"]
      outputs: ["Rendered previews per channel"]
      decision_point: "Does rendering look correct on all channels?"

    - step: 3
      name: "Submit for Review"
      actor: "Content Creator"
      action: "Request approval from reviewer"
      inputs: ["Draft template", "Rendered previews"]
      outputs: ["Pending review template"]

    - step: 4
      name: "Review Content"
      actor: "Reviewer"
      action: "Verify content, branding, and compliance"
      inputs: ["Pending template"]
      outputs: ["Approval decision"]
      decision_point: "Approve, request changes, or reject?"

    - step: 5a
      name: "Activate Template"
      actor: "System"
      action: "Set template status to active"
      inputs: ["Approved template"]
      outputs: ["Active template"]
      condition: "Approved"
      automatable: true

    - step: 5b
      name: "Return for Revisions"
      actor: "Reviewer"
      action: "Send back with change requests"
      inputs: ["Template", "Feedback"]
      outputs: ["Draft template with notes"]
      condition: "Changes requested"
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-COM-001 | **Required variable missing** | High | Fail gracefully with default value or block send; log error |
| EC-COM-002 | **Template works for email but exceeds SMS limit** | Medium | Channel-specific validation; truncate or block with warning |
| EC-COM-003 | **Template references deleted image** | Medium | Check asset existence before activation; use placeholder |
| EC-COM-004 | **HTML renders differently across email clients** | Low | Use tested email frameworks (MJML); preview in multiple clients |
| EC-COM-005 | **Variable contains HTML/script injection** | High | Escape all variables by default; explicit raw helper for trusted content |
| EC-COM-006 | **Template locale not available for user** | Medium | Fall back to default locale; log for translation queue |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-COM-001 | **Subject line generation** | Email body, campaign goal | Suggested subject lines | Improves open rates |
| AI-COM-002 | **SMS content compression** | Full message | 160-char optimized version | Maintains meaning within limits |
| AI-COM-003 | **Variable validation** | Template, sample data | Missing/mistyped variable warnings | Catches errors before send |
| AI-COM-004 | **Localization assistance** | Template in base language | Suggested translations | Speeds multi-language rollout |

---

## Package 2: Delivery

### Purpose

Route messages to appropriate channels, manage sending queues, and handle retry logic with exponential backoff.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What channels do you currently use? (email, SMS, push, in-app)
- What service providers handle each channel? (SendGrid, Twilio, Firebase)
- Do you need priority levels for different message types?
- What's your expected message volume? (per hour, per day)

**Workflow Discovery**:
- Should messages send immediately or queue for batch processing?
- What triggers automated messages? (events, schedules, user actions)
- How do you handle channel failover? (email fails, try SMS)
- Who monitors delivery health?

**Edge Case Probing**:
- What if the delivery service is temporarily unavailable?
- How do you handle rate limiting from providers?
- What if user has no valid contact for preferred channel?

### Retry Strategy: Exponential Backoff

```
Attempt 1: Immediate
Attempt 2: Wait 1 minute
Attempt 3: Wait 5 minutes
Attempt 4: Wait 30 minutes
Attempt 5: Wait 2 hours
Failed: Move to Dead Letter Queue (DLQ)
```

### Entity Templates

#### Message

```json
{
  "id": "data.delivery.message",
  "name": "Message",
  "type": "data",
  "namespace": "delivery",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Unified record of a message to be sent via any channel.",
    "fields": [
      { "name": "message_id", "type": "uuid", "required": true, "description": "Unique message identifier" },
      { "name": "channel", "type": "enum", "required": true, "values": ["email", "sms", "push", "in_app"], "description": "Delivery channel" },
      { "name": "recipient_id", "type": "uuid", "required": true, "description": "Target user ID" },
      { "name": "recipient_address", "type": "string", "required": true, "description": "Email, phone, device token, or user ID depending on channel" },
      { "name": "template_id", "type": "uuid", "required": false, "description": "Template used (null if ad-hoc)" },
      { "name": "subject", "type": "string", "required": false, "description": "Rendered subject (email)" },
      { "name": "body", "type": "text", "required": true, "description": "Rendered message body" },
      { "name": "body_html", "type": "text", "required": false, "description": "HTML version (email)" },
      { "name": "variables", "type": "json", "required": false, "description": "Variable values used in rendering" },
      { "name": "priority", "type": "enum", "required": true, "values": ["critical", "high", "normal", "low"], "description": "Delivery priority" },
      { "name": "status", "type": "enum", "required": true, "values": ["pending", "queued", "sending", "sent", "delivered", "failed", "bounced", "complained"], "description": "Current delivery status" },
      { "name": "attempt_count", "type": "integer", "required": true, "description": "Number of delivery attempts" },
      { "name": "next_attempt_at", "type": "datetime", "required": false, "description": "Scheduled retry time" },
      { "name": "sent_at", "type": "datetime", "required": false, "description": "When successfully sent to provider" },
      { "name": "delivered_at", "type": "datetime", "required": false, "description": "When confirmed delivered" },
      { "name": "failed_at", "type": "datetime", "required": false, "description": "When permanently failed" },
      { "name": "failure_reason", "type": "string", "required": false, "description": "Error message if failed" },
      { "name": "provider_id", "type": "string", "required": false, "description": "External provider message ID" },
      { "name": "idempotency_key", "type": "string", "required": false, "description": "Key to prevent duplicate sends" },
      { "name": "metadata", "type": "json", "required": false, "description": "Additional context (campaign_id, trigger_event)" },
      { "name": "created_at", "type": "datetime", "required": true, "description": "When message was created" }
    ],
    "relationships": [
      { "entity": "User", "type": "many_to_one", "required": true },
      { "entity": "Template", "type": "many_to_one", "required": false },
      { "entity": "DeliveryLog", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "communication.delivery",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### DeliveryLog

```json
{
  "id": "data.delivery.delivery_log",
  "name": "Delivery Log",
  "type": "data",
  "namespace": "delivery",
  "tags": ["core-entity", "auditable"],
  "status": "discovered",

  "spec": {
    "purpose": "Detailed log of each delivery attempt and status change.",
    "fields": [
      { "name": "message_id", "type": "uuid", "required": true, "description": "Parent message" },
      { "name": "event_type", "type": "enum", "required": true, "values": ["queued", "sending", "sent", "delivered", "opened", "clicked", "bounced", "complained", "unsubscribed", "failed", "retrying"], "description": "Event type" },
      { "name": "timestamp", "type": "datetime", "required": true, "description": "When event occurred" },
      { "name": "provider", "type": "string", "required": false, "description": "Delivery provider (sendgrid, twilio)" },
      { "name": "provider_event_id", "type": "string", "required": false, "description": "Provider's event reference" },
      { "name": "status_code", "type": "string", "required": false, "description": "Provider status/error code" },
      { "name": "details", "type": "json", "required": false, "description": "Full event payload from provider" },
      { "name": "ip_address", "type": "string", "required": false, "description": "IP for opens/clicks" },
      { "name": "user_agent", "type": "string", "required": false, "description": "User agent for opens/clicks" },
      { "name": "link_url", "type": "string", "required": false, "description": "Clicked link URL" }
    ],
    "relationships": [
      { "entity": "Message", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "communication.delivery",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### ChannelProvider

```json
{
  "id": "data.delivery.channel_provider",
  "name": "Channel Provider",
  "type": "data",
  "namespace": "delivery",
  "tags": ["configuration"],
  "status": "discovered",

  "spec": {
    "purpose": "Configuration for external delivery service provider.",
    "fields": [
      { "name": "channel", "type": "enum", "required": true, "values": ["email", "sms", "push", "in_app"], "description": "Channel this provider handles" },
      { "name": "provider_name", "type": "string", "required": true, "description": "Provider identifier (sendgrid, twilio, firebase)" },
      { "name": "is_primary", "type": "boolean", "required": true, "description": "Primary provider for this channel" },
      { "name": "api_endpoint", "type": "string", "required": true, "description": "Provider API base URL" },
      { "name": "credentials", "type": "encrypted_json", "required": true, "description": "API keys/tokens (encrypted)" },
      { "name": "rate_limit", "type": "integer", "required": false, "description": "Max messages per second" },
      { "name": "daily_limit", "type": "integer", "required": false, "description": "Max messages per day" },
      { "name": "status", "type": "enum", "required": true, "values": ["active", "degraded", "disabled"], "description": "Provider operational status" },
      { "name": "failover_provider_id", "type": "uuid", "required": false, "description": "Backup provider if this one fails" },
      { "name": "webhook_secret", "type": "encrypted_string", "required": false, "description": "Secret for validating inbound webhooks" }
    ],
    "relationships": [
      { "entity": "ChannelProvider", "type": "many_to_one", "required": false, "description": "Failover provider" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "communication.delivery",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.delivery.send_message

```yaml
workflow:
  id: "wf.delivery.send_message"
  name: "Send Message via Channel"
  trigger: "Message created or scheduled send time reached"
  actors: ["System", "Provider"]

  steps:
    - step: 1
      name: "Check Preferences"
      actor: "System"
      action: "Verify recipient has not opted out of this channel/category"
      inputs: ["Message", "UserPreference", "SuppressionList"]
      outputs: ["Send allowed: yes/no"]
      automatable: true

    - step: 2a
      name: "Block Send"
      actor: "System"
      action: "Mark message as blocked due to preferences"
      inputs: ["Message"]
      outputs: ["Blocked message status"]
      condition: "Recipient opted out"
      automatable: true

    - step: 2b
      name: "Render Content"
      actor: "System"
      action: "Apply template with variables if using template"
      inputs: ["Message", "Template", "Variables"]
      outputs: ["Rendered message content"]
      condition: "Send allowed"
      automatable: true

    - step: 3
      name: "Select Provider"
      actor: "System"
      action: "Route to appropriate provider for channel"
      inputs: ["Message channel", "ChannelProvider config"]
      outputs: ["Selected provider"]
      automatable: true

    - step: 4
      name: "Submit to Provider"
      actor: "System"
      action: "Send message via provider API"
      inputs: ["Rendered message", "Provider credentials"]
      outputs: ["Provider response"]
      automatable: true

    - step: 5a
      name: "Log Success"
      actor: "System"
      action: "Record successful send in DeliveryLog"
      inputs: ["Provider success response"]
      outputs: ["DeliveryLog entry", "Updated message status"]
      condition: "Provider accepted message"
      automatable: true

    - step: 5b
      name: "Handle Failure"
      actor: "System"
      action: "Log failure, calculate next retry time"
      inputs: ["Provider error response", "Current attempt count"]
      outputs: ["DeliveryLog entry", "Retry schedule or DLQ"]
      condition: "Provider rejected message"
      automatable: true
```

#### wf.delivery.retry_failed

```yaml
workflow:
  id: "wf.delivery.retry_failed"
  name: "Retry Failed Message"
  trigger: "Scheduled retry time reached for failed message"
  actors: ["System", "Provider"]

  steps:
    - step: 1
      name: "Check Attempt Count"
      actor: "System"
      action: "Determine if more retries allowed"
      inputs: ["Message attempt_count"]
      outputs: ["Retry allowed: yes/no"]
      automatable: true

    - step: 2a
      name: "Move to DLQ"
      actor: "System"
      action: "Mark message as permanently failed, move to dead letter queue"
      inputs: ["Message exceeding max attempts"]
      outputs: ["DLQ entry", "Alert notification"]
      condition: "Max retries exceeded"
      automatable: true

    - step: 2b
      name: "Attempt Resend"
      actor: "System"
      action: "Retry send with exponential backoff"
      inputs: ["Message to retry"]
      outputs: ["Send result"]
      condition: "Retries remaining"
      automatable: true

    - step: 3
      name: "Calculate Next Retry"
      actor: "System"
      action: "Apply exponential backoff: 1m, 5m, 30m, 2h"
      inputs: ["Current attempt count"]
      outputs: ["next_attempt_at timestamp"]
      condition: "Send failed again"
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-COM-007 | **Provider API timeout** | High | Implement idempotency keys; check status before retry to prevent duplicates |
| EC-COM-008 | **Rate limit exceeded** | Medium | Queue with backpressure; respect provider rate limits |
| EC-COM-009 | **Invalid recipient address** | Medium | Validate format before send; mark as permanent failure (no retry) |
| EC-COM-010 | **User has no valid contact for channel** | Medium | Try fallback channel if configured; notify sender |
| EC-COM-011 | **Provider returns soft bounce** | Medium | Retry with exponential backoff; track bounce count |
| EC-COM-012 | **Provider returns hard bounce** | High | Add to suppression list; mark as permanent failure; no retry |
| EC-COM-013 | **Duplicate send request** | Medium | Use idempotency key to detect and block duplicate |
| EC-COM-014 | **Message stuck in sending state** | Medium | Timeout detection job; reset to pending or fail after threshold |
| EC-COM-015 | **Primary provider down** | High | Automatic failover to backup provider; alert ops team |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-COM-005 | **Optimal send time** | User engagement history | Best time to send | Improves open/engagement rates |
| AI-COM-006 | **Channel selection** | User preferences, message type | Recommended channel | Increases delivery success |
| AI-COM-007 | **Failure pattern detection** | DeliveryLog history | Systemic issue alerts | Early warning on provider problems |
| AI-COM-008 | **Content spam scoring** | Message content | Spam probability score | Prevents deliverability issues |

---

## Package 3: Preferences

### Purpose

Manage user communication preferences, consent records, channel subscriptions, and suppression lists for compliance with regulations (GDPR, CAN-SPAM, TCPA).

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What preference categories do users control? (marketing, transactional, all)
- Do you need per-channel preferences? (email yes, SMS no)
- How do you track consent acquisition?
- Do you maintain suppression lists?

**Workflow Discovery**:
- How do users update preferences? (settings page, email link)
- What's the default state for new users? (opt-in vs opt-out)
- How do you handle unsubscribe requests?
- How long do you retain consent records?

**Edge Case Probing**:
- User unsubscribes from marketing but you need to send transactional?
- User with multiple accounts has different preferences?
- External system (CRM) updates preferences - how to sync?

### Entity Templates

#### UserPreference

```json
{
  "id": "data.preferences.user_preference",
  "name": "User Preference",
  "type": "data",
  "namespace": "preferences",
  "tags": ["core-entity", "mvp", "gdpr"],
  "status": "discovered",

  "spec": {
    "purpose": "User's communication preferences across channels and categories.",
    "fields": [
      { "name": "user_id", "type": "uuid", "required": true, "description": "User these preferences belong to" },
      { "name": "channel", "type": "enum", "required": true, "values": ["email", "sms", "push", "in_app"], "description": "Communication channel" },
      { "name": "category", "type": "enum", "required": true, "values": ["transactional", "marketing", "operational", "all"], "description": "Message category" },
      { "name": "enabled", "type": "boolean", "required": true, "description": "Whether user wants to receive this type" },
      { "name": "frequency", "type": "enum", "required": false, "values": ["realtime", "daily_digest", "weekly_digest", "never"], "description": "Delivery frequency preference" },
      { "name": "quiet_hours_start", "type": "time", "required": false, "description": "Do not disturb start time" },
      { "name": "quiet_hours_end", "type": "time", "required": false, "description": "Do not disturb end time" },
      { "name": "timezone", "type": "string", "required": false, "description": "User timezone for quiet hours" },
      { "name": "updated_at", "type": "datetime", "required": true, "description": "Last preference change" },
      { "name": "updated_by", "type": "enum", "required": true, "values": ["user", "system", "admin", "import"], "description": "Who made last change" }
    ],
    "relationships": [
      { "entity": "User", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "communication.preferences",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### ChannelSubscription

```json
{
  "id": "data.preferences.channel_subscription",
  "name": "Channel Subscription",
  "type": "data",
  "namespace": "preferences",
  "tags": ["core-entity", "gdpr"],
  "status": "discovered",

  "spec": {
    "purpose": "Granular subscription to specific message topics or lists.",
    "fields": [
      { "name": "user_id", "type": "uuid", "required": true, "description": "Subscribed user" },
      { "name": "list_id", "type": "string", "required": true, "description": "Subscription list identifier" },
      { "name": "list_name", "type": "string", "required": true, "description": "Human-readable list name" },
      { "name": "channel", "type": "enum", "required": true, "values": ["email", "sms", "push", "in_app"], "description": "Channel for this subscription" },
      { "name": "status", "type": "enum", "required": true, "values": ["subscribed", "unsubscribed", "pending"], "description": "Subscription status" },
      { "name": "subscribed_at", "type": "datetime", "required": false, "description": "When subscribed" },
      { "name": "unsubscribed_at", "type": "datetime", "required": false, "description": "When unsubscribed" },
      { "name": "source", "type": "string", "required": false, "description": "How they subscribed (signup form, import, api)" },
      { "name": "double_opt_in_confirmed", "type": "boolean", "required": false, "description": "Double opt-in completed" },
      { "name": "double_opt_in_at", "type": "datetime", "required": false, "description": "When confirmed" }
    ],
    "relationships": [
      { "entity": "User", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "communication.preferences",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### SuppressionList

```json
{
  "id": "data.preferences.suppression_list",
  "name": "Suppression List Entry",
  "type": "data",
  "namespace": "preferences",
  "tags": ["core-entity", "compliance"],
  "status": "discovered",

  "spec": {
    "purpose": "Addresses that should never receive messages (bounces, complaints, manual blocks).",
    "fields": [
      { "name": "address", "type": "string", "required": true, "description": "Email, phone, or device token" },
      { "name": "channel", "type": "enum", "required": true, "values": ["email", "sms", "push"], "description": "Channel this suppression applies to" },
      { "name": "reason", "type": "enum", "required": true, "values": ["hard_bounce", "complaint", "unsubscribe", "manual", "invalid"], "description": "Why address is suppressed" },
      { "name": "source", "type": "string", "required": false, "description": "Source of suppression (provider name, admin action)" },
      { "name": "added_at", "type": "datetime", "required": true, "description": "When added to suppression list" },
      { "name": "expires_at", "type": "datetime", "required": false, "description": "Optional expiration (soft bounces may clear)" },
      { "name": "original_user_id", "type": "uuid", "required": false, "description": "User ID if known" },
      { "name": "notes", "type": "text", "required": false, "description": "Additional context" }
    ],
    "relationships": []
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "communication.preferences",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### ConsentRecord

```json
{
  "id": "data.preferences.consent_record",
  "name": "Consent Record",
  "type": "data",
  "namespace": "preferences",
  "tags": ["core-entity", "gdpr", "audit"],
  "status": "discovered",

  "spec": {
    "purpose": "Immutable audit trail of consent given or withdrawn.",
    "fields": [
      { "name": "user_id", "type": "uuid", "required": true, "description": "User who gave/withdrew consent" },
      { "name": "consent_type", "type": "string", "required": true, "description": "Type of consent (marketing_email, sms_alerts)" },
      { "name": "action", "type": "enum", "required": true, "values": ["granted", "withdrawn"], "description": "Consent action" },
      { "name": "timestamp", "type": "datetime", "required": true, "description": "When action occurred" },
      { "name": "source", "type": "string", "required": true, "description": "Where consent was captured (signup_form, settings_page, email_link)" },
      { "name": "ip_address", "type": "string", "required": false, "description": "IP address at time of consent" },
      { "name": "user_agent", "type": "string", "required": false, "description": "Browser/device info" },
      { "name": "consent_text", "type": "text", "required": false, "description": "Exact text shown to user" },
      { "name": "legal_basis", "type": "enum", "required": false, "values": ["consent", "legitimate_interest", "contract", "legal_obligation"], "description": "GDPR legal basis" }
    ],
    "relationships": [
      { "entity": "User", "type": "many_to_one", "required": true }
    ],
    "notes": "Records are append-only; never update or delete for compliance."
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "communication.preferences",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.preferences.unsubscribe

```yaml
workflow:
  id: "wf.preferences.unsubscribe"
  name: "Process Unsubscribe Request"
  trigger: "User clicks unsubscribe link or requests opt-out"
  actors: ["User", "System"]

  steps:
    - step: 1
      name: "Receive Request"
      actor: "System"
      action: "Parse unsubscribe request (email link, SMS STOP, API call)"
      inputs: ["Unsubscribe token or user identifier", "Channel"]
      outputs: ["Validated unsubscribe request"]
      automatable: true

    - step: 2
      name: "Show Preference Center"
      actor: "User"
      action: "Display preference options (unsubscribe all vs. specific lists)"
      inputs: ["Current preferences"]
      outputs: ["User selection"]
      decision_point: "Unsubscribe from all or just some?"

    - step: 3
      name: "Update Preferences"
      actor: "System"
      action: "Apply preference changes"
      inputs: ["User selection"]
      outputs: ["Updated UserPreference records"]
      automatable: true

    - step: 4
      name: "Record Consent Change"
      actor: "System"
      action: "Create immutable ConsentRecord"
      inputs: ["Preference change", "Request metadata"]
      outputs: ["ConsentRecord entry"]
      automatable: true

    - step: 5
      name: "Confirm to User"
      actor: "System"
      action: "Display/send confirmation of preference update"
      inputs: ["Updated preferences"]
      outputs: ["Confirmation page/message"]
      automatable: true

    - step: 6
      name: "Sync to Providers"
      actor: "System"
      action: "Update suppression lists in email/SMS providers"
      inputs: ["Updated preferences"]
      outputs: ["Provider sync confirmation"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-COM-016 | **User unsubscribes from marketing but needs transactional** | Low | Separate transactional from marketing; transactional ignores marketing prefs |
| EC-COM-017 | **Same email on multiple accounts with different prefs** | Medium | Suppression list applies to address regardless of account |
| EC-COM-018 | **External CRM updates preferences** | Medium | API sync with conflict resolution (most restrictive wins) |
| EC-COM-019 | **User requests data deletion (GDPR)** | High | Anonymize consent records; remove from all lists; suppress address |
| EC-COM-020 | **Preference change during active campaign** | Low | Check preferences at send time, not enqueue time |
| EC-COM-021 | **Double opt-in not completed** | Medium | Don't send marketing until confirmed; send reminder, then delete pending |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-COM-009 | **Re-engagement prediction** | User activity, preference changes | Likelihood to re-subscribe | Target win-back campaigns |
| AI-COM-010 | **Preference inference** | User behavior patterns | Suggested default preferences | Personalized onboarding |

---

## Package 4: Tracking

### Purpose

Monitor delivery status, engagement metrics, and provide analytics on communication performance.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What metrics do you need to track? (delivery, opens, clicks)
- Do you need real-time dashboards or batch reporting?
- How long do you retain tracking data?
- Do you track at aggregate or individual level?

**Workflow Discovery**:
- How do you receive delivery webhooks from providers?
- Who reviews communication performance?
- What actions are triggered by tracking data? (re-engagement, alerts)
- How do you handle tracking for privacy-conscious users?

**Edge Case Probing**:
- User with tracking blocked - how to handle?
- Provider webhook arrives out of order?
- High-volume webhook flood from provider?

### Entity Templates

#### MessageEvent

```json
{
  "id": "data.tracking.message_event",
  "name": "Message Event",
  "type": "data",
  "namespace": "tracking",
  "tags": ["core-entity", "analytics"],
  "status": "discovered",

  "spec": {
    "purpose": "Engagement event for a delivered message (open, click, etc.).",
    "fields": [
      { "name": "message_id", "type": "uuid", "required": true, "description": "Related message" },
      { "name": "event_type", "type": "enum", "required": true, "values": ["delivered", "opened", "clicked", "converted", "replied", "forwarded"], "description": "Engagement event type" },
      { "name": "timestamp", "type": "datetime", "required": true, "description": "When event occurred" },
      { "name": "link_url", "type": "string", "required": false, "description": "Clicked URL" },
      { "name": "link_id", "type": "string", "required": false, "description": "Link identifier for tracking" },
      { "name": "ip_address", "type": "string", "required": false, "description": "IP of interaction" },
      { "name": "user_agent", "type": "string", "required": false, "description": "Browser/email client" },
      { "name": "device_type", "type": "enum", "required": false, "values": ["desktop", "mobile", "tablet", "unknown"], "description": "Device category" },
      { "name": "geo_country", "type": "string", "required": false, "description": "Country from IP geolocation" },
      { "name": "geo_city", "type": "string", "required": false, "description": "City from IP geolocation" }
    ],
    "relationships": [
      { "entity": "Message", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "communication.tracking",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### CampaignMetrics

```json
{
  "id": "data.tracking.campaign_metrics",
  "name": "Campaign Metrics",
  "type": "data",
  "namespace": "tracking",
  "tags": ["core-entity", "analytics"],
  "status": "discovered",

  "spec": {
    "purpose": "Aggregated metrics for a message campaign or batch send.",
    "fields": [
      { "name": "campaign_id", "type": "string", "required": true, "description": "Campaign identifier" },
      { "name": "campaign_name", "type": "string", "required": true, "description": "Human-readable campaign name" },
      { "name": "channel", "type": "enum", "required": true, "values": ["email", "sms", "push", "in_app"], "description": "Primary channel" },
      { "name": "sent_count", "type": "integer", "required": true, "description": "Total messages sent" },
      { "name": "delivered_count", "type": "integer", "required": true, "description": "Successfully delivered" },
      { "name": "bounced_count", "type": "integer", "required": true, "description": "Hard + soft bounces" },
      { "name": "opened_count", "type": "integer", "required": false, "description": "Unique opens (email/push)" },
      { "name": "clicked_count", "type": "integer", "required": false, "description": "Unique clicks" },
      { "name": "unsubscribed_count", "type": "integer", "required": false, "description": "Unsubscribes from this send" },
      { "name": "complained_count", "type": "integer", "required": false, "description": "Spam complaints" },
      { "name": "converted_count", "type": "integer", "required": false, "description": "Tracked conversions" },
      { "name": "delivery_rate", "type": "decimal", "required": false, "description": "delivered / sent * 100" },
      { "name": "open_rate", "type": "decimal", "required": false, "description": "opened / delivered * 100" },
      { "name": "click_rate", "type": "decimal", "required": false, "description": "clicked / delivered * 100" },
      { "name": "started_at", "type": "datetime", "required": true, "description": "Campaign start time" },
      { "name": "completed_at", "type": "datetime", "required": false, "description": "When all sends finished" },
      { "name": "last_updated", "type": "datetime", "required": true, "description": "Last metrics refresh" }
    ],
    "relationships": [
      { "entity": "Message", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "communication.tracking",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### WebhookEvent

```json
{
  "id": "data.tracking.webhook_event",
  "name": "Webhook Event",
  "type": "data",
  "namespace": "tracking",
  "tags": ["core-entity", "audit"],
  "status": "discovered",

  "spec": {
    "purpose": "Raw inbound webhook from delivery provider for auditing and reprocessing.",
    "fields": [
      { "name": "provider", "type": "string", "required": true, "description": "Source provider (sendgrid, twilio)" },
      { "name": "event_type", "type": "string", "required": true, "description": "Provider event type" },
      { "name": "payload", "type": "json", "required": true, "description": "Full webhook payload" },
      { "name": "received_at", "type": "datetime", "required": true, "description": "When received" },
      { "name": "processed", "type": "boolean", "required": true, "description": "Successfully processed" },
      { "name": "processed_at", "type": "datetime", "required": false, "description": "When processed" },
      { "name": "error", "type": "string", "required": false, "description": "Processing error if failed" },
      { "name": "message_id", "type": "uuid", "required": false, "description": "Matched internal message ID" },
      { "name": "signature_valid", "type": "boolean", "required": false, "description": "Webhook signature verified" }
    ],
    "relationships": [
      { "entity": "Message", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "communication.tracking",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.tracking.process_webhook

```yaml
workflow:
  id: "wf.tracking.process_webhook"
  name: "Process Provider Webhook"
  trigger: "Inbound webhook from delivery provider"
  actors: ["Provider", "System"]

  steps:
    - step: 1
      name: "Receive Webhook"
      actor: "System"
      action: "Accept and store raw webhook payload"
      inputs: ["HTTP request from provider"]
      outputs: ["WebhookEvent record"]
      automatable: true

    - step: 2
      name: "Validate Signature"
      actor: "System"
      action: "Verify webhook authenticity using provider secret"
      inputs: ["Webhook payload", "Provider webhook_secret"]
      outputs: ["Validation result"]
      automatable: true

    - step: 3a
      name: "Reject Invalid"
      actor: "System"
      action: "Log and discard invalid webhook"
      inputs: ["Invalid webhook"]
      outputs: ["Error log, 401 response"]
      condition: "Signature invalid"
      automatable: true

    - step: 3b
      name: "Parse Event"
      actor: "System"
      action: "Extract event type, message ID, and details"
      inputs: ["Valid webhook payload"]
      outputs: ["Parsed event data"]
      condition: "Signature valid"
      automatable: true

    - step: 4
      name: "Match to Message"
      actor: "System"
      action: "Find internal message by provider_id"
      inputs: ["Provider message reference"]
      outputs: ["Matched Message record"]
      automatable: true

    - step: 5
      name: "Update Status"
      actor: "System"
      action: "Update Message status and create DeliveryLog/MessageEvent"
      inputs: ["Parsed event", "Matched message"]
      outputs: ["Updated records"]
      automatable: true

    - step: 6
      name: "Trigger Actions"
      actor: "System"
      action: "Execute any event-driven actions (suppress on bounce, etc.)"
      inputs: ["Event type", "Message data"]
      outputs: ["Triggered action results"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-COM-022 | **Webhook arrives before message marked as sent** | Medium | Queue webhook; retry matching; eventually match or orphan |
| EC-COM-023 | **Duplicate webhook received** | Low | Idempotent processing using provider_event_id |
| EC-COM-024 | **High-volume webhook flood** | High | Rate limiting; async queue processing; autoscaling |
| EC-COM-025 | **Provider webhook format changes** | Medium | Version-aware parsing; alert on unknown formats |
| EC-COM-026 | **Open tracking blocked by privacy feature** | Low | Accept lower open rates; focus on click/conversion metrics |
| EC-COM-027 | **Click tracking URL expired** | Low | Redirect to destination anyway; log as tracking miss |
| EC-COM-028 | **Metrics aggregation delay** | Low | Near-real-time for dashboards; exact counts in batch |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-COM-011 | **Anomaly detection** | Campaign metrics, historical patterns | Performance anomaly alerts | Catch problems early |
| AI-COM-012 | **Engagement prediction** | User history, message content | Predicted engagement score | Personalized send optimization |
| AI-COM-013 | **Content performance analysis** | A/B test results, engagement data | Winning variant recommendation | Data-driven content decisions |

---

## Cross-Package Relationships

The Communication module packages interconnect to form a complete messaging system:

```
                    ┌─────────────────────────────────────────────┐
                    │               TEMPLATES                      │
                    │  (Creates reusable message content)          │
                    └─────────────────┬───────────────────────────┘
                                      │
                                      ▼
┌───────────────────────────────────────────────────────────────────┐
│                         DELIVERY                                   │
│  (Renders, routes, sends via channels with retry)                  │
│                          │                     │                   │
│                          ▼                     ▼                   │
│         ┌────────────────────────┐   ┌────────────────────────┐   │
│         │     PREFERENCES        │   │      TRACKING          │   │
│         │  (Checks before send)  │   │  (Records after send)  │   │
│         └────────────────────────┘   └────────────────────────┘   │
└───────────────────────────────────────────────────────────────────┘
```

### Key Integration Points Within Communication

| From | To | Integration |
|------|-----|-------------|
| Templates | Delivery | Delivery renders template with variables |
| Delivery | Preferences | Check opt-out before sending |
| Delivery | Tracking | Log all delivery attempts and outcomes |
| Preferences | Delivery | Suppression list blocks sends |
| Tracking | Preferences | Bounce/complaint updates suppression list |
| Tracking | Templates | Engagement data informs template optimization |

---

## Integration Points (External Systems)

### Email Providers

| System | Use Case | Notes |
|--------|----------|-------|
| **SendGrid** | Transactional and marketing email | Most popular; good webhooks |
| **Mailgun** | Developer-focused email | Strong API; good for transactional |
| **Amazon SES** | High-volume, cost-effective | Requires more setup; cheap at scale |
| **Postmark** | Transactional email focus | Excellent deliverability |
| **Mailchimp/Mandrill** | Marketing email | Good for campaigns |

### SMS Providers

| System | Use Case | Notes |
|--------|----------|-------|
| **Twilio** | SMS, MMS, voice | Most feature-rich; global coverage |
| **MessageBird** | SMS, WhatsApp, voice | Good international rates |
| **Plivo** | SMS, voice | Cost-effective alternative |
| **Amazon SNS** | SMS notifications | Simple; integrated with AWS |
| **Vonage (Nexmo)** | SMS, WhatsApp, voice | Good for enterprise |

### Push Notification Services

| System | Use Case | Notes |
|--------|----------|-------|
| **Firebase Cloud Messaging** | Android, iOS, web push | Google's free service |
| **Apple Push Notification Service** | iOS native | Required for iOS |
| **OneSignal** | Cross-platform push | Free tier; easy setup |
| **Pusher** | Real-time messaging | WebSocket-based |
| **Amazon SNS** | Mobile push | Multi-platform |

### In-App Messaging

| System | Use Case | Notes |
|--------|----------|-------|
| **Intercom** | In-app + support chat | Full-featured; expensive |
| **Drift** | Conversational marketing | Sales-focused |
| **Custom implementation** | Message center | Most flexibility |

---

## Compliance Considerations

### CAN-SPAM (Email - US)

| Requirement | Implementation |
|-------------|----------------|
| Unsubscribe mechanism | One-click unsubscribe link in all marketing emails |
| Honor opt-out within 10 days | Process immediately; never send after unsubscribe |
| Valid physical address | Include in email footer |
| Accurate headers | From address must be truthful |
| Clear subject lines | No deceptive subjects |

### GDPR (Email/SMS - EU)

| Requirement | Implementation |
|-------------|----------------|
| Explicit consent | Double opt-in for marketing |
| Record of consent | ConsentRecord with timestamp, source, consent text |
| Right to withdraw | Easy unsubscribe; immediate effect |
| Right to access | Export user's consent history |
| Right to erasure | Anonymize records; add to suppression list |
| Data minimization | Retain only necessary data |

### TCPA (SMS - US)

| Requirement | Implementation |
|-------------|----------------|
| Prior express consent | Written consent for marketing SMS |
| Opt-out mechanism | Honor STOP keyword immediately |
| Identification | Identify sender in messages |
| Time restrictions | No texts before 8am or after 9pm local time |

### CASL (Email - Canada)

| Requirement | Implementation |
|-------------|----------------|
| Express consent | Clear opt-in with purpose stated |
| Identification | Sender name and contact info |
| Unsubscribe | Working mechanism; honored within 10 days |

---

## Anti-Patterns to Avoid

### 1. Separate Tables Per Channel

**Wrong**:
```sql
CREATE TABLE email_messages (...);
CREATE TABLE sms_messages (...);
CREATE TABLE push_messages (...);
```

**Right**: Single `message` table with `channel` enum.

### 2. Synchronous Sending

**Wrong**:
```python
def create_order(order):
    save_order(order)
    send_email(order.customer, "order_confirmation")  # Blocks request
    return order
```

**Right**: Queue messages asynchronously.

### 3. Custom Template Language

**Wrong**: Inventing a new templating syntax.

**Right**: Use Handlebars or established templating engine.

### 4. Ignoring Delivery Feedback

**Wrong**: Continuing to send to addresses that bounce.

**Right**: Process webhooks; maintain suppression lists.

### 5. Hard-Coded Retry Logic

**Wrong**: Fixed retry intervals scattered through code.

**Right**: Configurable exponential backoff with DLQ.

---

## Quick Reference

### Entity Summary

| Package | Core Entities | Supporting Entities |
|---------|---------------|---------------------|
| Templates | Template | TemplateVersion |
| Delivery | Message, DeliveryLog | ChannelProvider |
| Preferences | UserPreference, SuppressionList | ChannelSubscription, ConsentRecord |
| Tracking | MessageEvent, CampaignMetrics | WebhookEvent |

### Workflow Summary

| ID | Workflow | Trigger |
|----|----------|---------|
| wf.templates.create_and_approve | Create and Approve Template | Staff creates template |
| wf.delivery.send_message | Send Message via Channel | Message ready to send |
| wf.delivery.retry_failed | Retry Failed Message | Retry timer expires |
| wf.preferences.unsubscribe | Process Unsubscribe | User opts out |
| wf.tracking.process_webhook | Process Provider Webhook | Inbound webhook |

### Retry Schedule

| Attempt | Wait Time | Cumulative |
|---------|-----------|------------|
| 1 | Immediate | 0 |
| 2 | 1 minute | 1 min |
| 3 | 5 minutes | 6 min |
| 4 | 30 minutes | 36 min |
| 5 | 2 hours | 2h 36min |
| Failed | Move to DLQ | - |

### Common Edge Case Themes

1. **Delivery failures** - Temporary vs permanent; retry vs suppress
2. **User preferences** - Check at send time; handle conflicts
3. **Compliance** - Consent records; unsubscribe handling
4. **Provider issues** - Failover; idempotency; webhook reliability
5. **Volume management** - Rate limits; queue backpressure
6. **Cross-channel** - Unified tracking; fallback routing
7. **Content issues** - Missing variables; template validation

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-05 | Initial release |
