# Sales Module Catalog

**Module**: Sales
**Version**: 1.0
**Last Updated**: 2026-02-05

---

## Overview

The Sales module covers the complete customer acquisition lifecycle: from initial lead capture through opportunity management, quoting, and order fulfillment. This module is foundational for any B2B or B2C application that manages sales pipelines, tracks deals, and converts prospects into customers.

### When to Use This Module

Select this module when R1 context includes any of:

| Trigger Phrases | Typical Actors | Business Need |
|-----------------|----------------|---------------|
| "lead", "prospect", "inquiry" | Sales Rep, Marketing | Capture and qualify potential customers |
| "opportunity", "deal", "pipeline" | Sales Rep, Sales Manager | Track sales in progress |
| "quote", "proposal", "estimate" | Sales Rep, Sales Engineer | Provide pricing to prospects |
| "order", "purchase order", "close deal" | Sales Rep, Customer | Convert won opportunities to orders |
| "account", "contact", "customer" | Account Manager, Sales Rep | Manage customer relationships |

### Module Dependencies

```
Sales Module
├── REQUIRES: Administrative (for settings, user preferences)
├── REQUIRES: Documents (for proposals, contracts, quotes)
├── INTEGRATES_WITH: Financial (invoicing from orders)
├── INTEGRATES_WITH: Inventory (product availability)
├── INTEGRATES_WITH: CRM (customer 360 view)
```

---

## Packages

This module contains 4 packages:

1. **leads** - Capturing and qualifying potential customers
2. **opportunities** - Managing deals through the sales pipeline
3. **quoting** - Creating and delivering price proposals
4. **orders** - Converting won deals to fulfillable orders

---

## Package 1: Leads

### Purpose

Capture inbound inquiries, qualify prospects, and convert promising leads into sales opportunities. Supports multiple lead sources and qualification frameworks.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What information do you capture for leads? (name, company, budget, timeline)
- What lead sources do you track? (web forms, trade shows, referrals, cold outreach)
- Do you use lead scoring or grading?
- How do you segment or route leads?
- Do you distinguish MQL (Marketing Qualified) from SQL (Sales Qualified)?

**Workflow Discovery**:
- What triggers lead creation? (form submit, import, manual entry)
- Who owns lead qualification? (SDR, AE, marketing automation)
- What's your lead-to-opportunity conversion process?
- How long before unresponsive leads are marked stale?
- Do you use round-robin or territory-based assignment?

**Edge Case Probing**:
- What if a lead already exists as a contact?
- How do you handle duplicate leads?
- What about leads that convert, then return later?

### Entity Templates

#### Lead

```json
{
  "id": "data.leads.lead",
  "name": "Lead",
  "type": "data",
  "namespace": "leads",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Represents an unqualified prospect who has shown interest in your product or service.",
    "fields": [
      { "name": "first_name", "type": "string", "required": true, "description": "Lead's first name" },
      { "name": "last_name", "type": "string", "required": true, "description": "Lead's last name" },
      { "name": "email", "type": "email", "required": true, "description": "Primary contact email" },
      { "name": "phone", "type": "phone", "required": false, "description": "Contact phone number" },
      { "name": "company", "type": "string", "required": false, "description": "Company or organization name" },
      { "name": "title", "type": "string", "required": false, "description": "Job title or role" },
      { "name": "source", "type": "enum", "required": true, "values": ["web_form", "trade_show", "referral", "cold_outreach", "partner", "advertisement", "other"], "description": "How lead was acquired" },
      { "name": "status", "type": "enum", "required": true, "values": ["new", "contacted", "qualified", "unqualified", "converted", "dead"], "description": "Current lead status" },
      { "name": "lead_score", "type": "integer", "required": false, "description": "Numeric qualification score (0-100)" },
      { "name": "owner_id", "type": "uuid", "required": false, "description": "Assigned sales rep" },
      { "name": "industry", "type": "string", "required": false, "description": "Industry vertical" },
      { "name": "company_size", "type": "enum", "required": false, "values": ["1-10", "11-50", "51-200", "201-500", "501-1000", "1000+"], "description": "Employee count range" },
      { "name": "budget", "type": "decimal", "required": false, "description": "Stated or estimated budget" },
      { "name": "timeline", "type": "string", "required": false, "description": "Expected purchase timeline" },
      { "name": "pain_points", "type": "text", "required": false, "description": "Identified business challenges" },
      { "name": "notes", "type": "text", "required": false, "description": "General notes about lead" },
      { "name": "converted_at", "type": "datetime", "required": false, "description": "When lead was converted to opportunity" },
      { "name": "converted_to_contact_id", "type": "uuid", "required": false, "description": "Contact created on conversion" },
      { "name": "converted_to_opportunity_id", "type": "uuid", "required": false, "description": "Opportunity created on conversion" }
    ],
    "relationships": [
      { "entity": "User", "type": "many_to_one", "required": false },
      { "entity": "LeadActivity", "type": "one_to_many", "required": false },
      { "entity": "Campaign", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "sales.leads",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### LeadActivity

```json
{
  "id": "data.leads.lead_activity",
  "name": "Lead Activity",
  "type": "data",
  "namespace": "leads",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Log of interactions and touchpoints with a lead.",
    "fields": [
      { "name": "lead_id", "type": "uuid", "required": true, "description": "Associated lead" },
      { "name": "user_id", "type": "uuid", "required": false, "description": "User who performed activity" },
      { "name": "type", "type": "enum", "required": true, "values": ["email", "call", "meeting", "note", "task", "status_change", "score_change"], "description": "Activity type" },
      { "name": "subject", "type": "string", "required": false, "description": "Activity subject or title" },
      { "name": "description", "type": "text", "required": false, "description": "Activity details" },
      { "name": "outcome", "type": "enum", "required": false, "values": ["no_answer", "left_voicemail", "connected", "meeting_scheduled", "not_interested", "qualified"], "description": "Result of activity" },
      { "name": "next_action_date", "type": "date", "required": false, "description": "Scheduled follow-up" },
      { "name": "created_at", "type": "datetime", "required": true, "description": "When activity occurred" }
    ],
    "relationships": [
      { "entity": "Lead", "type": "many_to_one", "required": true },
      { "entity": "User", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "sales.leads",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Campaign

```json
{
  "id": "data.leads.campaign",
  "name": "Campaign",
  "type": "data",
  "namespace": "leads",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Marketing campaign that generates or nurtures leads.",
    "fields": [
      { "name": "name", "type": "string", "required": true, "description": "Campaign name" },
      { "name": "type", "type": "enum", "required": true, "values": ["email", "webinar", "trade_show", "content", "advertising", "referral_program", "other"], "description": "Campaign type" },
      { "name": "status", "type": "enum", "required": true, "values": ["planned", "active", "paused", "completed"], "description": "Campaign status" },
      { "name": "start_date", "type": "date", "required": false, "description": "Campaign start date" },
      { "name": "end_date", "type": "date", "required": false, "description": "Campaign end date" },
      { "name": "budget", "type": "decimal", "required": false, "description": "Allocated budget" },
      { "name": "actual_cost", "type": "decimal", "required": false, "description": "Actual spend" },
      { "name": "expected_revenue", "type": "decimal", "required": false, "description": "Projected revenue" },
      { "name": "leads_generated", "type": "integer", "required": false, "description": "Count of leads from campaign" },
      { "name": "opportunities_generated", "type": "integer", "required": false, "description": "Count of opportunities from campaign" },
      { "name": "revenue_generated", "type": "decimal", "required": false, "description": "Actual closed revenue" }
    ],
    "relationships": [
      { "entity": "Lead", "type": "one_to_many", "required": false },
      { "entity": "Opportunity", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "sales.leads",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.leads.capture_and_qualify

```yaml
workflow:
  id: "wf.leads.capture_and_qualify"
  name: "Capture and Qualify Lead"
  trigger: "Lead submitted via web form, import, or manual entry"
  actors: ["System", "SDR", "Sales Rep"]

  steps:
    - step: 1
      name: "Capture Lead"
      actor: "System"
      action: "Create lead record from source"
      inputs: ["Form data", "Source tracking"]
      outputs: ["New lead record"]
      automatable: true

    - step: 2
      name: "Deduplicate Check"
      actor: "System"
      action: "Check for existing leads or contacts with same email/company"
      inputs: ["Lead email", "Lead company"]
      outputs: ["Duplicate matches or none"]
      automatable: true
      decision_point: "Merge with existing? Create new?"

    - step: 3
      name: "Auto-Score"
      actor: "System"
      action: "Calculate lead score based on fit criteria"
      inputs: ["Lead attributes", "Scoring rules"]
      outputs: ["Lead score"]
      automatable: true

    - step: 4
      name: "Route Lead"
      actor: "System"
      action: "Assign to appropriate rep based on territory, round-robin, or score"
      inputs: ["Lead score", "Lead attributes", "Assignment rules"]
      outputs: ["Assigned owner"]
      automatable: true

    - step: 5
      name: "Initial Outreach"
      actor: "SDR"
      action: "Contact lead within SLA timeframe"
      inputs: ["Lead record", "Contact info"]
      outputs: ["Activity log", "Qualification notes"]

    - step: 6
      name: "Qualify Lead"
      actor: "SDR"
      action: "Assess BANT or other qualification criteria"
      inputs: ["Discovery conversation"]
      outputs: ["Qualification status"]
      decision_point: "Qualified? Unqualified? Needs nurturing?"

    - step: 7a
      name: "Convert to Opportunity"
      actor: "SDR"
      action: "Create account, contact, and opportunity"
      inputs: ["Qualified lead"]
      outputs: ["Account", "Contact", "Opportunity"]
      condition: "Lead is qualified"

    - step: 7b
      name: "Mark Unqualified"
      actor: "SDR"
      action: "Update status with reason"
      inputs: ["Unqualified lead"]
      outputs: ["Updated lead status"]
      condition: "Lead is not qualified"
```

#### wf.leads.lead_nurturing

```yaml
workflow:
  id: "wf.leads.lead_nurturing"
  name: "Nurture Unresponsive Lead"
  trigger: "Lead not responding to outreach"
  actors: ["System", "Marketing", "SDR"]

  steps:
    - step: 1
      name: "Trigger Nurture Sequence"
      actor: "System"
      action: "Add lead to drip email campaign"
      inputs: ["Lead record", "Days since last contact"]
      outputs: ["Nurture enrollment"]
      condition: "No response after 3 attempts"
      automatable: true

    - step: 2
      name: "Send Content"
      actor: "System"
      action: "Deliver educational content over time"
      inputs: ["Nurture sequence", "Lead interests"]
      outputs: ["Email sends", "Engagement tracking"]
      automatable: true

    - step: 3
      name: "Monitor Engagement"
      actor: "System"
      action: "Track opens, clicks, page visits"
      inputs: ["Email events", "Web tracking"]
      outputs: ["Engagement score"]
      automatable: true

    - step: 4
      name: "Re-qualify on Engagement"
      actor: "SDR"
      action: "Follow up when engagement threshold met"
      inputs: ["High engagement alert"]
      outputs: ["Activity log", "New qualification status"]
      condition: "Engagement score exceeds threshold"

    - step: 5
      name: "Archive Stale"
      actor: "System"
      action: "Mark lead as dead after extended inactivity"
      inputs: ["Days inactive", "No engagement"]
      outputs: ["Updated status"]
      condition: "No engagement after nurture sequence complete"
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-SAL-001 | **Lead already exists as contact** | Medium | Offer to link or update existing contact; don't create duplicate |
| EC-SAL-002 | **Duplicate lead from multiple sources** | Medium | Merge leads; track all sources; credit first source for attribution |
| EC-SAL-003 | **Lead from competitor domain** | Low | Flag for review; may be research, may be legitimate |
| EC-SAL-004 | **Lead converts then returns as new lead** | Medium | Recognize returning contact; link to existing account |
| EC-SAL-005 | **Bulk import creates thousands of duplicates** | High | Pre-process for deduplication; use batch match before import |
| EC-SAL-006 | **Lead owner leaves company** | Medium | Auto-reassign to manager or queue; don't leave orphaned |
| EC-SAL-007 | **Lead requests removal (GDPR/CCPA)** | High | Anonymize or delete per policy; log compliance action |
| EC-SAL-008 | **Lead score changes after conversion** | Low | Lock score at conversion time; keep history for reporting |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-SAL-001 | **Lead scoring** | Lead attributes, behavior | Fit and intent score | Prioritize high-value leads |
| AI-SAL-002 | **Lead enrichment** | Email, company name | Firmographic data | Better qualification without manual research |
| AI-SAL-003 | **Best time to contact** | Lead timezone, engagement patterns | Optimal call/email time | Higher connection rates |
| AI-SAL-004 | **Duplicate detection** | Lead data, existing records | Match probability | Prevent duplicate work |

---

## Package 2: Opportunities

### Purpose

Track deals through the sales pipeline, manage forecasts, and coordinate selling activities to maximize win rates and revenue.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What stages does a deal go through? (discovery, demo, proposal, negotiation, close)
- What information do you track on opportunities? (amount, close date, probability)
- Do you use opportunity products/line items?
- How do you track competitors?
- Do you have multiple sales processes for different deal types?

**Workflow Discovery**:
- How do opportunities get created? (from leads, direct entry, partner referral)
- What activities move deals forward? (meetings, demos, trials)
- How do you forecast revenue? (stage-based, commit levels)
- Who can change close dates or amounts?
- What happens when a deal is lost?

**Edge Case Probing**:
- Deal stuck in stage for months?
- Customer ghosts mid-deal?
- Multiple opportunities for same account simultaneously?
- Deal won but customer backs out before contract?

### Entity Templates

#### Account

```json
{
  "id": "data.opportunities.account",
  "name": "Account",
  "type": "data",
  "namespace": "opportunities",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Represents a company or organization that is a customer or prospect.",
    "fields": [
      { "name": "name", "type": "string", "required": true, "description": "Company name" },
      { "name": "type", "type": "enum", "required": true, "values": ["prospect", "customer", "partner", "competitor", "other"], "description": "Account classification" },
      { "name": "industry", "type": "string", "required": false, "description": "Industry vertical" },
      { "name": "website", "type": "url", "required": false, "description": "Company website" },
      { "name": "phone", "type": "phone", "required": false, "description": "Main phone number" },
      { "name": "billing_address", "type": "address", "required": false, "description": "Billing address" },
      { "name": "shipping_address", "type": "address", "required": false, "description": "Shipping address" },
      { "name": "employee_count", "type": "integer", "required": false, "description": "Number of employees" },
      { "name": "annual_revenue", "type": "decimal", "required": false, "description": "Estimated annual revenue" },
      { "name": "owner_id", "type": "uuid", "required": false, "description": "Account owner (sales rep)" },
      { "name": "parent_account_id", "type": "uuid", "required": false, "description": "Parent company for subsidiaries" },
      { "name": "source", "type": "string", "required": false, "description": "How account was acquired" },
      { "name": "description", "type": "text", "required": false, "description": "Account notes" }
    ],
    "relationships": [
      { "entity": "Contact", "type": "one_to_many", "required": false },
      { "entity": "Opportunity", "type": "one_to_many", "required": false },
      { "entity": "User", "type": "many_to_one", "required": false },
      { "entity": "Account", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "sales.opportunities",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Contact

```json
{
  "id": "data.opportunities.contact",
  "name": "Contact",
  "type": "data",
  "namespace": "opportunities",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Represents an individual person at an account.",
    "fields": [
      { "name": "first_name", "type": "string", "required": true, "description": "First name" },
      { "name": "last_name", "type": "string", "required": true, "description": "Last name" },
      { "name": "email", "type": "email", "required": true, "description": "Primary email" },
      { "name": "phone", "type": "phone", "required": false, "description": "Phone number" },
      { "name": "mobile", "type": "phone", "required": false, "description": "Mobile phone" },
      { "name": "title", "type": "string", "required": false, "description": "Job title" },
      { "name": "department", "type": "string", "required": false, "description": "Department" },
      { "name": "account_id", "type": "uuid", "required": false, "description": "Associated account" },
      { "name": "role", "type": "enum", "required": false, "values": ["decision_maker", "influencer", "champion", "blocker", "end_user", "economic_buyer", "technical_buyer"], "description": "Buying role" },
      { "name": "mailing_address", "type": "address", "required": false, "description": "Mailing address" },
      { "name": "lead_source", "type": "string", "required": false, "description": "Original lead source" },
      { "name": "owner_id", "type": "uuid", "required": false, "description": "Contact owner" },
      { "name": "do_not_call", "type": "boolean", "required": false, "description": "Do not call preference" },
      { "name": "do_not_email", "type": "boolean", "required": false, "description": "Do not email preference" },
      { "name": "notes", "type": "text", "required": false, "description": "Contact notes" }
    ],
    "relationships": [
      { "entity": "Account", "type": "many_to_one", "required": false },
      { "entity": "Opportunity", "type": "many_to_many", "required": false },
      { "entity": "User", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "sales.opportunities",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Opportunity

```json
{
  "id": "data.opportunities.opportunity",
  "name": "Opportunity",
  "type": "data",
  "namespace": "opportunities",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Represents a potential sale being tracked through the pipeline.",
    "fields": [
      { "name": "name", "type": "string", "required": true, "description": "Opportunity name" },
      { "name": "account_id", "type": "uuid", "required": true, "description": "Associated account" },
      { "name": "primary_contact_id", "type": "uuid", "required": false, "description": "Primary contact on deal" },
      { "name": "owner_id", "type": "uuid", "required": true, "description": "Opportunity owner (sales rep)" },
      { "name": "stage", "type": "enum", "required": true, "values": ["prospecting", "qualification", "needs_analysis", "proposal", "negotiation", "closed_won", "closed_lost"], "description": "Current pipeline stage" },
      { "name": "amount", "type": "decimal", "required": false, "description": "Deal value" },
      { "name": "currency", "type": "string", "required": false, "description": "Deal currency (ISO 4217)" },
      { "name": "probability", "type": "integer", "required": false, "description": "Win probability percentage (0-100)" },
      { "name": "expected_revenue", "type": "decimal", "required": false, "description": "amount * probability" },
      { "name": "close_date", "type": "date", "required": true, "description": "Expected close date" },
      { "name": "type", "type": "enum", "required": false, "values": ["new_business", "existing_business", "renewal", "upsell", "cross_sell"], "description": "Opportunity type" },
      { "name": "lead_source", "type": "string", "required": false, "description": "Original lead source" },
      { "name": "campaign_id", "type": "uuid", "required": false, "description": "Source campaign" },
      { "name": "next_step", "type": "string", "required": false, "description": "Next action to advance deal" },
      { "name": "competitor", "type": "string", "required": false, "description": "Primary competitor" },
      { "name": "loss_reason", "type": "string", "required": false, "description": "Why deal was lost" },
      { "name": "description", "type": "text", "required": false, "description": "Opportunity notes" },
      { "name": "created_at", "type": "datetime", "required": true, "description": "When opportunity was created" },
      { "name": "closed_at", "type": "datetime", "required": false, "description": "When opportunity was closed" }
    ],
    "relationships": [
      { "entity": "Account", "type": "many_to_one", "required": true },
      { "entity": "Contact", "type": "many_to_many", "required": false },
      { "entity": "User", "type": "many_to_one", "required": true },
      { "entity": "Quote", "type": "one_to_many", "required": false },
      { "entity": "OpportunityProduct", "type": "one_to_many", "required": false },
      { "entity": "Activity", "type": "one_to_many", "required": false },
      { "entity": "Campaign", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "sales.opportunities",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### PipelineStage

```json
{
  "id": "data.opportunities.pipeline_stage",
  "name": "Pipeline Stage",
  "type": "data",
  "namespace": "opportunities",
  "tags": ["configuration"],
  "status": "discovered",

  "spec": {
    "purpose": "Configurable stage in the sales pipeline with default probability.",
    "fields": [
      { "name": "name", "type": "string", "required": true, "description": "Stage name" },
      { "name": "order", "type": "integer", "required": true, "description": "Display order in pipeline" },
      { "name": "probability", "type": "integer", "required": true, "description": "Default win probability (0-100)" },
      { "name": "is_closed", "type": "boolean", "required": true, "description": "Whether this is a closed stage" },
      { "name": "is_won", "type": "boolean", "required": false, "description": "Whether this is a won stage" },
      { "name": "description", "type": "string", "required": false, "description": "Stage description" },
      { "name": "entry_criteria", "type": "text", "required": false, "description": "What must be true to enter this stage" },
      { "name": "exit_criteria", "type": "text", "required": false, "description": "What must be true to exit this stage" },
      { "name": "sales_process_id", "type": "uuid", "required": false, "description": "Which sales process this belongs to" }
    ],
    "relationships": [
      { "entity": "SalesProcess", "type": "many_to_one", "required": false }
    ],
    "notes": "Limit pipeline to 5-7 stages maximum for best results. More stages increase friction without improving forecast accuracy."
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "sales.opportunities",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Activity

```json
{
  "id": "data.opportunities.activity",
  "name": "Activity",
  "type": "data",
  "namespace": "opportunities",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Logged sales activity (call, meeting, email) related to an opportunity.",
    "fields": [
      { "name": "type", "type": "enum", "required": true, "values": ["call", "email", "meeting", "demo", "task", "note"], "description": "Activity type" },
      { "name": "subject", "type": "string", "required": true, "description": "Activity subject" },
      { "name": "description", "type": "text", "required": false, "description": "Activity details" },
      { "name": "opportunity_id", "type": "uuid", "required": false, "description": "Related opportunity" },
      { "name": "account_id", "type": "uuid", "required": false, "description": "Related account" },
      { "name": "contact_id", "type": "uuid", "required": false, "description": "Related contact" },
      { "name": "owner_id", "type": "uuid", "required": true, "description": "Activity owner" },
      { "name": "due_date", "type": "datetime", "required": false, "description": "Due date for tasks" },
      { "name": "completed_at", "type": "datetime", "required": false, "description": "When activity was completed" },
      { "name": "status", "type": "enum", "required": true, "values": ["planned", "completed", "canceled"], "description": "Activity status" },
      { "name": "outcome", "type": "string", "required": false, "description": "Result of activity" },
      { "name": "created_at", "type": "datetime", "required": true, "description": "When activity was created" }
    ],
    "relationships": [
      { "entity": "Opportunity", "type": "many_to_one", "required": false },
      { "entity": "Account", "type": "many_to_one", "required": false },
      { "entity": "Contact", "type": "many_to_one", "required": false },
      { "entity": "User", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "sales.opportunities",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.opportunities.advance_stage

```yaml
workflow:
  id: "wf.opportunities.advance_stage"
  name: "Advance Opportunity Stage"
  trigger: "Sales rep updates opportunity stage"
  actors: ["Sales Rep", "System", "Manager"]

  steps:
    - step: 1
      name: "Request Stage Change"
      actor: "Sales Rep"
      action: "Select new stage for opportunity"
      inputs: ["Current opportunity", "Target stage"]
      outputs: ["Stage change request"]

    - step: 2
      name: "Validate Entry Criteria"
      actor: "System"
      action: "Check that required fields and activities are complete"
      inputs: ["Stage change request", "Stage entry criteria"]
      outputs: ["Validation result"]
      automatable: true
      decision_point: "Criteria met?"

    - step: 3a
      name: "Update Stage"
      actor: "System"
      action: "Change stage and update probability"
      inputs: ["Validated request"]
      outputs: ["Updated opportunity"]
      condition: "Validation passed"
      automatable: true

    - step: 3b
      name: "Block and Notify"
      actor: "System"
      action: "Show missing criteria to rep"
      inputs: ["Failed validation"]
      outputs: ["Criteria checklist"]
      condition: "Validation failed"
      automatable: true

    - step: 4
      name: "Log Stage History"
      actor: "System"
      action: "Record stage change with timestamp and duration"
      inputs: ["Stage change"]
      outputs: ["Stage history record"]
      automatable: true

    - step: 5
      name: "Alert Manager (optional)"
      actor: "System"
      action: "Notify manager of significant stage changes"
      inputs: ["Stage change", "Notification rules"]
      outputs: ["Manager notification"]
      condition: "Stage is final or high-value deal"
      automatable: true
```

#### wf.opportunities.win_close

```yaml
workflow:
  id: "wf.opportunities.win_close"
  name: "Close Won Opportunity"
  trigger: "Opportunity moved to Closed Won stage"
  actors: ["Sales Rep", "Sales Manager", "System"]

  steps:
    - step: 1
      name: "Mark Closed Won"
      actor: "Sales Rep"
      action: "Change stage to Closed Won"
      inputs: ["Opportunity", "Final details"]
      outputs: ["Won opportunity"]

    - step: 2
      name: "Validate Required Fields"
      actor: "System"
      action: "Ensure all required closed fields are populated"
      inputs: ["Won opportunity"]
      outputs: ["Validation result"]
      automatable: true

    - step: 3
      name: "Create Order (if applicable)"
      actor: "System"
      action: "Generate order from opportunity products"
      inputs: ["Won opportunity", "Opportunity products"]
      outputs: ["Order record"]
      automatable: true

    - step: 4
      name: "Update Account Status"
      actor: "System"
      action: "Change account type from prospect to customer"
      inputs: ["Account"]
      outputs: ["Updated account"]
      condition: "First won opportunity for account"
      automatable: true

    - step: 5
      name: "Trigger Handoff"
      actor: "System"
      action: "Notify implementation/success team"
      inputs: ["Won opportunity", "Customer details"]
      outputs: ["Handoff notification"]
      automatable: true

    - step: 6
      name: "Commission Calculation"
      actor: "System"
      action: "Calculate sales commission based on deal terms"
      inputs: ["Won opportunity", "Commission plan"]
      outputs: ["Commission record"]
      automatable: true
```

#### wf.opportunities.loss_close

```yaml
workflow:
  id: "wf.opportunities.loss_close"
  name: "Close Lost Opportunity"
  trigger: "Opportunity moved to Closed Lost stage"
  actors: ["Sales Rep", "Sales Manager", "System"]

  steps:
    - step: 1
      name: "Mark Closed Lost"
      actor: "Sales Rep"
      action: "Change stage to Closed Lost with reason"
      inputs: ["Opportunity", "Loss reason"]
      outputs: ["Lost opportunity"]

    - step: 2
      name: "Require Loss Reason"
      actor: "System"
      action: "Validate loss reason is provided"
      inputs: ["Lost opportunity"]
      outputs: ["Validated closure"]
      automatable: true

    - step: 3
      name: "Log Competitor Win (if applicable)"
      actor: "Sales Rep"
      action: "Record which competitor won and why"
      inputs: ["Competitor details"]
      outputs: ["Competitive intelligence"]
      condition: "Lost to competitor"

    - step: 4
      name: "Manager Review (optional)"
      actor: "Sales Manager"
      action: "Review significant losses for coaching"
      inputs: ["Lost opportunity", "Sales history"]
      outputs: ["Review notes"]
      condition: "High-value deal or strategic account"

    - step: 5
      name: "Add to Win-Back Campaign"
      actor: "System"
      action: "Schedule future re-engagement"
      inputs: ["Lost opportunity", "Win-back rules"]
      outputs: ["Campaign enrollment"]
      condition: "Loss reason indicates future potential"
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-SAL-010 | **Deal stuck in stage for months** | Medium | Flag stale opportunities; require update or close |
| EC-SAL-011 | **Customer ghosts after proposal** | Medium | Implement follow-up sequence; auto-close after threshold |
| EC-SAL-012 | **Multiple opportunities on same account** | Low | Allow but require differentiation (different products, contacts) |
| EC-SAL-013 | **Close date repeatedly pushed** | Medium | Track push count; alert manager after N pushes |
| EC-SAL-014 | **Deal won but customer backs out** | High | Reopen to Closed Lost; reverse commission; update forecasts |
| EC-SAL-015 | **Competitor field empty for lost deals** | Medium | Make competitor required when lost to competitor |
| EC-SAL-016 | **Stage skipped (e.g., Prospecting to Proposal)** | Low | Allow with warning; some fast-track deals are valid |
| EC-SAL-017 | **Amount changed after forecast submission** | High | Track change history; alert finance of material changes |
| EC-SAL-018 | **Rep leaves mid-deal** | Medium | Auto-reassign to manager; maintain activity history |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-SAL-005 | **Win probability prediction** | Opportunity data, activity history | Predicted win rate | More accurate forecasting |
| AI-SAL-006 | **Next best action** | Opportunity stage, buyer signals | Recommended action | Guide reps to effective activities |
| AI-SAL-007 | **Deal risk scoring** | Activity gaps, stage duration | Risk indicators | Identify deals needing intervention |
| AI-SAL-008 | **Competitive intelligence** | Win/loss data | Competitor strengths/weaknesses | Better positioning |
| AI-SAL-009 | **Close date prediction** | Historical patterns | Likely close date | Realistic forecasts |

---

## Package 3: Quoting

### Purpose

Create professional price quotes with products, discounts, and terms. Support approval workflows for non-standard pricing and seamless quote-to-order conversion.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What products or services do you quote? (catalog items, custom, bundles)
- Do you use price books for different markets or customer tiers?
- How do discounts work? (line-level, order-level, volume-based)
- What terms appear on quotes? (validity period, payment terms)
- Do you support multiple currencies?

**Workflow Discovery**:
- Who can create quotes? (sales rep, sales engineer, system)
- What approval thresholds exist? (discount levels, deal size)
- How are quotes delivered? (email, portal, PDF)
- Can customers accept quotes electronically?
- How do you handle quote revisions?

**Edge Case Probing**:
- Quote expired but customer wants to accept?
- Customer requests change after quote accepted?
- Product discontinued after quote sent?

### Entity Templates

#### Product

```json
{
  "id": "data.quoting.product",
  "name": "Product",
  "type": "data",
  "namespace": "quoting",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Represents a product or service that can be sold.",
    "fields": [
      { "name": "name", "type": "string", "required": true, "description": "Product name" },
      { "name": "code", "type": "string", "required": true, "description": "Product SKU or code" },
      { "name": "description", "type": "text", "required": false, "description": "Product description" },
      { "name": "type", "type": "enum", "required": true, "values": ["product", "service", "subscription", "bundle"], "description": "Product type" },
      { "name": "family", "type": "string", "required": false, "description": "Product family or category" },
      { "name": "is_active", "type": "boolean", "required": true, "description": "Available for sale" },
      { "name": "unit_of_measure", "type": "string", "required": false, "description": "Unit (each, hour, license, etc.)" },
      { "name": "standard_price", "type": "decimal", "required": false, "description": "Default price if no price book" },
      { "name": "cost", "type": "decimal", "required": false, "description": "Product cost for margin calculation" },
      { "name": "taxable", "type": "boolean", "required": false, "description": "Subject to sales tax" }
    ],
    "relationships": [
      { "entity": "PriceBookEntry", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "sales.quoting",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### PriceBook

```json
{
  "id": "data.quoting.price_book",
  "name": "Price Book",
  "type": "data",
  "namespace": "quoting",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Named collection of prices for products, supporting different markets or customer tiers.",
    "fields": [
      { "name": "name", "type": "string", "required": true, "description": "Price book name" },
      { "name": "description", "type": "string", "required": false, "description": "Price book description" },
      { "name": "is_standard", "type": "boolean", "required": true, "description": "Whether this is the default price book" },
      { "name": "is_active", "type": "boolean", "required": true, "description": "Price book is available for use" },
      { "name": "currency", "type": "string", "required": false, "description": "Primary currency for this price book" },
      { "name": "effective_date", "type": "date", "required": false, "description": "When prices become effective" },
      { "name": "expiration_date", "type": "date", "required": false, "description": "When prices expire" }
    ],
    "relationships": [
      { "entity": "PriceBookEntry", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "sales.quoting",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### PriceBookEntry

```json
{
  "id": "data.quoting.price_book_entry",
  "name": "Price Book Entry",
  "type": "data",
  "namespace": "quoting",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Junction object linking a product to a price book with a specific price.",
    "fields": [
      { "name": "product_id", "type": "uuid", "required": true, "description": "Product being priced" },
      { "name": "price_book_id", "type": "uuid", "required": true, "description": "Price book containing this price" },
      { "name": "unit_price", "type": "decimal", "required": true, "description": "Price in this price book" },
      { "name": "currency", "type": "string", "required": false, "description": "Price currency (overrides price book)" },
      { "name": "is_active", "type": "boolean", "required": true, "description": "Entry is available for use" },
      { "name": "min_quantity", "type": "decimal", "required": false, "description": "Minimum quantity for this price" },
      { "name": "max_quantity", "type": "decimal", "required": false, "description": "Maximum quantity for this price" }
    ],
    "relationships": [
      { "entity": "Product", "type": "many_to_one", "required": true },
      { "entity": "PriceBook", "type": "many_to_one", "required": true }
    ],
    "notes": "This junction object enables many-to-many between Product and PriceBook with price as the relationship attribute."
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "sales.quoting",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Quote

```json
{
  "id": "data.quoting.quote",
  "name": "Quote",
  "type": "data",
  "namespace": "quoting",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Represents a formal price proposal sent to a prospect or customer.",
    "fields": [
      { "name": "quote_number", "type": "string", "required": true, "description": "Unique quote identifier" },
      { "name": "name", "type": "string", "required": true, "description": "Quote name or title" },
      { "name": "opportunity_id", "type": "uuid", "required": false, "description": "Associated opportunity" },
      { "name": "account_id", "type": "uuid", "required": true, "description": "Customer account" },
      { "name": "contact_id", "type": "uuid", "required": false, "description": "Primary contact" },
      { "name": "owner_id", "type": "uuid", "required": true, "description": "Quote owner" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "pending_approval", "approved", "sent", "viewed", "accepted", "rejected", "expired"], "description": "Quote status" },
      { "name": "price_book_id", "type": "uuid", "required": false, "description": "Price book used" },
      { "name": "subtotal", "type": "decimal", "required": true, "description": "Sum of line items" },
      { "name": "discount_amount", "type": "decimal", "required": false, "description": "Total discount applied" },
      { "name": "discount_percent", "type": "decimal", "required": false, "description": "Overall discount percentage" },
      { "name": "tax_amount", "type": "decimal", "required": false, "description": "Total tax" },
      { "name": "shipping_amount", "type": "decimal", "required": false, "description": "Shipping cost" },
      { "name": "total", "type": "decimal", "required": true, "description": "Final quote total" },
      { "name": "currency", "type": "string", "required": true, "description": "Quote currency" },
      { "name": "valid_from", "type": "date", "required": true, "description": "Quote valid from date" },
      { "name": "valid_until", "type": "date", "required": true, "description": "Quote expiration date" },
      { "name": "payment_terms", "type": "string", "required": false, "description": "Payment terms" },
      { "name": "terms_and_conditions", "type": "text", "required": false, "description": "Legal terms" },
      { "name": "notes", "type": "text", "required": false, "description": "Customer-visible notes" },
      { "name": "internal_notes", "type": "text", "required": false, "description": "Internal notes" },
      { "name": "sent_at", "type": "datetime", "required": false, "description": "When quote was sent" },
      { "name": "accepted_at", "type": "datetime", "required": false, "description": "When customer accepted" },
      { "name": "rejection_reason", "type": "string", "required": false, "description": "Why quote was rejected" }
    ],
    "relationships": [
      { "entity": "Opportunity", "type": "many_to_one", "required": false },
      { "entity": "Account", "type": "many_to_one", "required": true },
      { "entity": "Contact", "type": "many_to_one", "required": false },
      { "entity": "QuoteLineItem", "type": "one_to_many", "required": true },
      { "entity": "PriceBook", "type": "many_to_one", "required": false },
      { "entity": "Order", "type": "one_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "sales.quoting",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### QuoteLineItem

```json
{
  "id": "data.quoting.quote_line_item",
  "name": "Quote Line Item",
  "type": "data",
  "namespace": "quoting",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Individual product or service line on a quote.",
    "fields": [
      { "name": "quote_id", "type": "uuid", "required": true, "description": "Parent quote" },
      { "name": "product_id", "type": "uuid", "required": false, "description": "Product being quoted" },
      { "name": "line_number", "type": "integer", "required": true, "description": "Display order" },
      { "name": "description", "type": "string", "required": true, "description": "Line item description" },
      { "name": "quantity", "type": "decimal", "required": true, "description": "Quantity" },
      { "name": "unit_price", "type": "decimal", "required": true, "description": "Price per unit" },
      { "name": "list_price", "type": "decimal", "required": false, "description": "Original list price for comparison" },
      { "name": "discount_percent", "type": "decimal", "required": false, "description": "Line discount %" },
      { "name": "discount_amount", "type": "decimal", "required": false, "description": "Line discount $" },
      { "name": "subtotal", "type": "decimal", "required": true, "description": "quantity * unit_price" },
      { "name": "total", "type": "decimal", "required": true, "description": "After discount" },
      { "name": "tax_rate", "type": "decimal", "required": false, "description": "Tax rate for this line" },
      { "name": "cost", "type": "decimal", "required": false, "description": "Product cost for margin" },
      { "name": "margin_percent", "type": "decimal", "required": false, "description": "Calculated margin" }
    ],
    "relationships": [
      { "entity": "Quote", "type": "many_to_one", "required": true },
      { "entity": "Product", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "sales.quoting",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### DiscountApproval

```json
{
  "id": "data.quoting.discount_approval",
  "name": "Discount Approval",
  "type": "data",
  "namespace": "quoting",
  "tags": ["core-entity", "auditable"],
  "status": "discovered",

  "spec": {
    "purpose": "Request and record of approval for non-standard discounts.",
    "fields": [
      { "name": "quote_id", "type": "uuid", "required": true, "description": "Quote requiring approval" },
      { "name": "requested_by", "type": "uuid", "required": true, "description": "User who requested approval" },
      { "name": "approver_id", "type": "uuid", "required": false, "description": "User who approved/rejected" },
      { "name": "approval_level", "type": "enum", "required": true, "values": ["manager", "director", "vp", "executive"], "description": "Required approval level" },
      { "name": "discount_percent", "type": "decimal", "required": true, "description": "Discount being requested" },
      { "name": "reason", "type": "text", "required": true, "description": "Justification for discount" },
      { "name": "status", "type": "enum", "required": true, "values": ["pending", "approved", "rejected", "expired"], "description": "Approval status" },
      { "name": "decision_notes", "type": "text", "required": false, "description": "Approver notes" },
      { "name": "requested_at", "type": "datetime", "required": true, "description": "When request was made" },
      { "name": "decided_at", "type": "datetime", "required": false, "description": "When decision was made" }
    ],
    "relationships": [
      { "entity": "Quote", "type": "many_to_one", "required": true },
      { "entity": "User", "type": "many_to_one", "required": true }
    ],
    "notes": "Standard discount tiers: 0-10% auto-approved, 11-20% manager, 21%+ VP approval required."
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "sales.quoting",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.quoting.create_and_approve

```yaml
workflow:
  id: "wf.quoting.create_and_approve"
  name: "Create and Approve Quote"
  trigger: "Sales rep creates quote for opportunity"
  actors: ["Sales Rep", "Manager", "VP", "System"]

  steps:
    - step: 1
      name: "Create Draft Quote"
      actor: "Sales Rep"
      action: "Add products and configure pricing"
      inputs: ["Opportunity", "Products", "Price book"]
      outputs: ["Draft quote"]

    - step: 2
      name: "Apply Discounts"
      actor: "Sales Rep"
      action: "Add line or quote-level discounts"
      inputs: ["Draft quote", "Discount justification"]
      outputs: ["Quote with discounts"]
      decision_point: "Discount level?"

    - step: 3
      name: "Check Approval Requirements"
      actor: "System"
      action: "Determine approval level based on discount"
      inputs: ["Quote discount percentage", "Approval thresholds"]
      outputs: ["Required approval level"]
      automatable: true

    - step: 4a
      name: "Auto-Approve (within threshold)"
      actor: "System"
      action: "Mark quote as approved"
      inputs: ["Quote with discount <= 10%"]
      outputs: ["Approved quote"]
      condition: "Discount <= auto-approval threshold"
      automatable: true

    - step: 4b
      name: "Manager Approval"
      actor: "Manager"
      action: "Review and approve/reject discount"
      inputs: ["Quote with 11-20% discount"]
      outputs: ["Approval decision"]
      condition: "Discount 11-20%"

    - step: 4c
      name: "VP Approval"
      actor: "VP"
      action: "Review and approve/reject large discount"
      inputs: ["Quote with >20% discount"]
      outputs: ["Approval decision"]
      condition: "Discount > 20%"

    - step: 5
      name: "Finalize Quote"
      actor: "System"
      action: "Lock pricing and generate quote document"
      inputs: ["Approved quote"]
      outputs: ["Final quote PDF"]
      automatable: true
```

#### wf.quoting.deliver_and_track

```yaml
workflow:
  id: "wf.quoting.deliver_and_track"
  name: "Deliver Quote and Track Response"
  trigger: "Quote approved and ready to send"
  actors: ["Sales Rep", "Customer", "System"]

  steps:
    - step: 1
      name: "Send Quote"
      actor: "Sales Rep"
      action: "Deliver quote via email or portal"
      inputs: ["Approved quote", "Contact email"]
      outputs: ["Sent quote", "Delivery confirmation"]

    - step: 2
      name: "Track Opens"
      actor: "System"
      action: "Monitor when customer views quote"
      inputs: ["Sent quote"]
      outputs: ["viewed_at timestamp"]
      automatable: true

    - step: 3
      name: "Follow Up"
      actor: "Sales Rep"
      action: "Contact customer after viewing"
      inputs: ["View notification"]
      outputs: ["Activity log"]

    - step: 4a
      name: "Accept Quote"
      actor: "Customer"
      action: "Customer accepts quote"
      inputs: ["Quote"]
      outputs: ["Accepted quote"]
      condition: "Customer accepts"

    - step: 4b
      name: "Request Revision"
      actor: "Customer"
      action: "Customer requests changes"
      inputs: ["Quote", "Change request"]
      outputs: ["Revision request"]
      condition: "Customer requests changes"

    - step: 4c
      name: "Reject Quote"
      actor: "Customer"
      action: "Customer declines"
      inputs: ["Quote", "Rejection reason"]
      outputs: ["Rejected quote"]
      condition: "Customer rejects"

    - step: 5
      name: "Expire Quote"
      actor: "System"
      action: "Mark quote as expired after validity period"
      inputs: ["Quote", "valid_until date"]
      outputs: ["Expired quote"]
      condition: "No response by expiration"
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-SAL-020 | **Quote expired but customer wants to accept** | Medium | Allow reissue with updated dates; may require re-approval if prices changed |
| EC-SAL-021 | **Customer requests change after acceptance** | Medium | Create revision; original remains for audit; link to new version |
| EC-SAL-022 | **Product discontinued after quote sent** | High | Flag quote; offer substitutes; notify rep immediately |
| EC-SAL-023 | **Price book changed after quote created** | Medium | Lock prices at quote creation; don't auto-update |
| EC-SAL-024 | **Multiple quotes for same opportunity** | Low | Allow; track primary vs alternate; only one can convert to order |
| EC-SAL-025 | **Discount exceeds cost (negative margin)** | High | Block or require executive approval; show margin warning |
| EC-SAL-026 | **Quote currency differs from account preference** | Low | Allow with exchange rate; show both currencies |
| EC-SAL-027 | **Approval chain member unavailable** | Medium | Support delegation or escalation; don't block deals |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-SAL-010 | **Discount recommendation** | Deal size, customer history, competition | Optimal discount | Maximize margin while winning |
| AI-SAL-011 | **Quote content generation** | Products, customer industry | Customized descriptions | Professional, relevant quotes |
| AI-SAL-012 | **Cross-sell suggestions** | Products in quote, purchase history | Related products | Increase deal size |
| AI-SAL-013 | **Price optimization** | Win/loss data, competitor pricing | Price point recommendations | Data-driven pricing |

---

## Package 4: Orders

### Purpose

Convert accepted quotes into fulfillable orders, track order status, and coordinate with downstream systems for billing and delivery.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What information is on an order? (shipping, billing, terms)
- Do you support partial shipments?
- How do you handle backorders?
- What order statuses do you track?
- Do you have different order types (standard, subscription, renewal)?

**Workflow Discovery**:
- How are orders created? (from quotes, direct entry, e-commerce)
- Who can create or modify orders?
- What triggers order fulfillment?
- How do you handle order changes after submission?
- When does invoicing occur relative to shipping?

**Edge Case Probing**:
- Order placed but product out of stock?
- Customer cancels after order placed?
- Partial refund on multi-item order?

### Entity Templates

#### Order

```json
{
  "id": "data.orders.order",
  "name": "Order",
  "type": "data",
  "namespace": "orders",
  "tags": ["core-entity", "mvp", "auditable"],
  "status": "discovered",

  "spec": {
    "purpose": "Represents a customer purchase ready for fulfillment and billing.",
    "fields": [
      { "name": "order_number", "type": "string", "required": true, "description": "Unique order identifier" },
      { "name": "account_id", "type": "uuid", "required": true, "description": "Customer account" },
      { "name": "contact_id", "type": "uuid", "required": false, "description": "Order contact" },
      { "name": "opportunity_id", "type": "uuid", "required": false, "description": "Source opportunity" },
      { "name": "quote_id", "type": "uuid", "required": false, "description": "Source quote" },
      { "name": "owner_id", "type": "uuid", "required": true, "description": "Order owner" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "submitted", "approved", "processing", "shipped", "delivered", "completed", "canceled"], "description": "Order status" },
      { "name": "type", "type": "enum", "required": false, "values": ["standard", "subscription", "renewal", "return"], "description": "Order type" },
      { "name": "order_date", "type": "date", "required": true, "description": "Date order was placed" },
      { "name": "requested_delivery_date", "type": "date", "required": false, "description": "Customer requested delivery" },
      { "name": "actual_delivery_date", "type": "date", "required": false, "description": "Actual delivery date" },
      { "name": "billing_address", "type": "address", "required": true, "description": "Billing address" },
      { "name": "shipping_address", "type": "address", "required": false, "description": "Shipping address" },
      { "name": "shipping_method", "type": "string", "required": false, "description": "Shipping carrier/method" },
      { "name": "subtotal", "type": "decimal", "required": true, "description": "Sum of line items" },
      { "name": "discount_amount", "type": "decimal", "required": false, "description": "Total discount" },
      { "name": "shipping_amount", "type": "decimal", "required": false, "description": "Shipping cost" },
      { "name": "tax_amount", "type": "decimal", "required": false, "description": "Total tax" },
      { "name": "total", "type": "decimal", "required": true, "description": "Order total" },
      { "name": "currency", "type": "string", "required": true, "description": "Order currency" },
      { "name": "payment_terms", "type": "string", "required": false, "description": "Payment terms" },
      { "name": "po_number", "type": "string", "required": false, "description": "Customer PO number" },
      { "name": "notes", "type": "text", "required": false, "description": "Order notes" },
      { "name": "canceled_at", "type": "datetime", "required": false, "description": "When order was canceled" },
      { "name": "cancellation_reason", "type": "string", "required": false, "description": "Why order was canceled" }
    ],
    "relationships": [
      { "entity": "Account", "type": "many_to_one", "required": true },
      { "entity": "Contact", "type": "many_to_one", "required": false },
      { "entity": "Opportunity", "type": "many_to_one", "required": false },
      { "entity": "Quote", "type": "one_to_one", "required": false },
      { "entity": "OrderLineItem", "type": "one_to_many", "required": true },
      { "entity": "Shipment", "type": "one_to_many", "required": false },
      { "entity": "Invoice", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "sales.orders",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### OrderLineItem

```json
{
  "id": "data.orders.order_line_item",
  "name": "Order Line Item",
  "type": "data",
  "namespace": "orders",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Individual product line on an order.",
    "fields": [
      { "name": "order_id", "type": "uuid", "required": true, "description": "Parent order" },
      { "name": "product_id", "type": "uuid", "required": true, "description": "Product ordered" },
      { "name": "line_number", "type": "integer", "required": true, "description": "Display order" },
      { "name": "description", "type": "string", "required": true, "description": "Line description" },
      { "name": "quantity", "type": "decimal", "required": true, "description": "Quantity ordered" },
      { "name": "quantity_shipped", "type": "decimal", "required": false, "description": "Quantity shipped so far" },
      { "name": "quantity_backordered", "type": "decimal", "required": false, "description": "Quantity on backorder" },
      { "name": "unit_price", "type": "decimal", "required": true, "description": "Price per unit" },
      { "name": "discount_percent", "type": "decimal", "required": false, "description": "Line discount %" },
      { "name": "subtotal", "type": "decimal", "required": true, "description": "quantity * unit_price" },
      { "name": "total", "type": "decimal", "required": true, "description": "After discount" },
      { "name": "status", "type": "enum", "required": true, "values": ["pending", "allocated", "shipped", "delivered", "canceled", "backordered"], "description": "Line status" }
    ],
    "relationships": [
      { "entity": "Order", "type": "many_to_one", "required": true },
      { "entity": "Product", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "sales.orders",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Shipment

```json
{
  "id": "data.orders.shipment",
  "name": "Shipment",
  "type": "data",
  "namespace": "orders",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Physical shipment of order items.",
    "fields": [
      { "name": "order_id", "type": "uuid", "required": true, "description": "Parent order" },
      { "name": "shipment_number", "type": "string", "required": true, "description": "Shipment identifier" },
      { "name": "status", "type": "enum", "required": true, "values": ["pending", "picked", "packed", "shipped", "in_transit", "delivered", "returned"], "description": "Shipment status" },
      { "name": "carrier", "type": "string", "required": false, "description": "Shipping carrier" },
      { "name": "tracking_number", "type": "string", "required": false, "description": "Carrier tracking number" },
      { "name": "shipped_at", "type": "datetime", "required": false, "description": "When shipment was sent" },
      { "name": "delivered_at", "type": "datetime", "required": false, "description": "When shipment was delivered" },
      { "name": "ship_to_address", "type": "address", "required": true, "description": "Delivery address" },
      { "name": "shipping_cost", "type": "decimal", "required": false, "description": "Actual shipping cost" },
      { "name": "weight", "type": "decimal", "required": false, "description": "Shipment weight" },
      { "name": "notes", "type": "text", "required": false, "description": "Shipping notes" }
    ],
    "relationships": [
      { "entity": "Order", "type": "many_to_one", "required": true },
      { "entity": "ShipmentLine", "type": "one_to_many", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "sales.orders",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.orders.quote_to_order

```yaml
workflow:
  id: "wf.orders.quote_to_order"
  name: "Convert Quote to Order"
  trigger: "Customer accepts quote"
  actors: ["Customer", "Sales Rep", "System"]

  steps:
    - step: 1
      name: "Accept Quote"
      actor: "Customer"
      action: "Sign or accept quote electronically"
      inputs: ["Quote", "Acceptance method"]
      outputs: ["Accepted quote"]

    - step: 2
      name: "Create Order"
      actor: "System"
      action: "Generate order from accepted quote"
      inputs: ["Accepted quote"]
      outputs: ["Draft order"]
      automatable: true

    - step: 3
      name: "Validate Order"
      actor: "System"
      action: "Check product availability and customer credit"
      inputs: ["Draft order", "Inventory", "Credit limits"]
      outputs: ["Validation result"]
      automatable: true
      decision_point: "All products available? Credit approved?"

    - step: 4
      name: "Collect Payment Info (if required)"
      actor: "Sales Rep"
      action: "Capture payment method or PO number"
      inputs: ["Order", "Payment terms"]
      outputs: ["Payment information"]
      condition: "Prepayment required or first order"

    - step: 5
      name: "Submit Order"
      actor: "System"
      action: "Finalize order and trigger fulfillment"
      inputs: ["Validated order", "Payment info"]
      outputs: ["Submitted order"]
      automatable: true

    - step: 6
      name: "Update Opportunity"
      actor: "System"
      action: "Mark opportunity as Closed Won"
      inputs: ["Submitted order", "Opportunity"]
      outputs: ["Updated opportunity"]
      automatable: true

    - step: 7
      name: "Send Confirmation"
      actor: "System"
      action: "Email order confirmation to customer"
      inputs: ["Submitted order", "Contact email"]
      outputs: ["Confirmation email"]
      automatable: true
```

#### wf.orders.fulfillment

```yaml
workflow:
  id: "wf.orders.fulfillment"
  name: "Order Fulfillment"
  trigger: "Order submitted for processing"
  actors: ["Warehouse", "Shipping", "System"]

  steps:
    - step: 1
      name: "Allocate Inventory"
      actor: "System"
      action: "Reserve inventory for order lines"
      inputs: ["Order", "Inventory levels"]
      outputs: ["Allocation result"]
      automatable: true
      decision_point: "Full allocation? Partial? Backorder?"

    - step: 2a
      name: "Pick Items"
      actor: "Warehouse"
      action: "Retrieve items from warehouse locations"
      inputs: ["Pick list"]
      outputs: ["Picked items"]
      condition: "Items available"

    - step: 2b
      name: "Create Backorder"
      actor: "System"
      action: "Place unavailable items on backorder"
      inputs: ["Unavailable items"]
      outputs: ["Backorder record"]
      condition: "Items not available"
      automatable: true

    - step: 3
      name: "Pack Shipment"
      actor: "Warehouse"
      action: "Package items for shipping"
      inputs: ["Picked items", "Packing materials"]
      outputs: ["Packed shipment"]

    - step: 4
      name: "Generate Labels"
      actor: "System"
      action: "Create shipping labels with carrier"
      inputs: ["Shipment", "Carrier integration"]
      outputs: ["Shipping labels", "Tracking number"]
      automatable: true

    - step: 5
      name: "Ship"
      actor: "Shipping"
      action: "Hand off to carrier"
      inputs: ["Packed shipment", "Labels"]
      outputs: ["Shipped confirmation"]

    - step: 6
      name: "Update Status"
      actor: "System"
      action: "Update order and notify customer"
      inputs: ["Shipping confirmation"]
      outputs: ["Updated order status", "Shipment notification"]
      automatable: true

    - step: 7
      name: "Track Delivery"
      actor: "System"
      action: "Monitor carrier tracking until delivered"
      inputs: ["Tracking number"]
      outputs: ["Delivery confirmation"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-SAL-030 | **Product out of stock after order** | Medium | Backorder or substitute; notify customer immediately |
| EC-SAL-031 | **Customer cancels after order placed** | Medium | Allow if not shipped; partial cancel if partially shipped |
| EC-SAL-032 | **Partial shipment needed** | Low | Ship what's available; backorder remainder; track partial status |
| EC-SAL-033 | **Customer changes shipping address** | Medium | Allow before ship; redirect fee if in transit |
| EC-SAL-034 | **Order placed with invalid payment** | High | Hold order; notify customer; auto-cancel after X days |
| EC-SAL-035 | **Duplicate order submitted** | Medium | Detect by customer + products + timing; confirm before processing |
| EC-SAL-036 | **Order from blocked customer** | High | Reject with reason; require credit hold resolution |
| EC-SAL-037 | **Product recalled after order** | High | Stop shipment; notify customer; offer replacement or refund |
| EC-SAL-038 | **Multiple invoices for partial shipments** | Medium | Track invoiced amounts; prevent over-invoicing |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-SAL-014 | **Delivery date prediction** | Order contents, warehouse location, carrier | Estimated delivery | Accurate customer expectations |
| AI-SAL-015 | **Order anomaly detection** | Order patterns, customer history | Fraud/error flags | Prevent losses |
| AI-SAL-016 | **Inventory optimization** | Order trends, lead times | Reorder recommendations | Reduce stockouts |

---

## Cross-Package Relationships

The Sales module packages connect to form a complete customer acquisition and order management system:

```
                    ┌─────────────────────────────────────────────┐
                    │                 LEADS                        │
                    │  (Capture and qualify potential customers)   │
                    └─────────────────┬───────────────────────────┘
                                      │ Convert
                                      ▼
┌───────────────────────────────────────────────────────────────────┐
│                       OPPORTUNITIES                                │
│  (Track deals through pipeline; manage accounts and contacts)      │
└───────────────────────────────┬───────────────────────────────────┘
                                │ Create Quote
                                ▼
┌───────────────────────────────────────────────────────────────────┐
│                         QUOTING                                    │
│  (Build proposals with products, pricing, discounts)               │
│  (Product + PriceBook + PriceBookEntry for pricing)                │
└───────────────────────────────┬───────────────────────────────────┘
                                │ Accept Quote
                                ▼
┌───────────────────────────────────────────────────────────────────┐
│                          ORDERS                                    │
│  (Fulfill and deliver; trigger invoicing)                          │
└───────────────────────────────────────────────────────────────────┘
```

### Key Integration Points Within Sales

| From | To | Integration |
|------|-----|-------------|
| Lead | Opportunity | Conversion creates Account, Contact, Opportunity |
| Lead | Account/Contact | Merge if existing; create if new |
| Opportunity | Quote | Quote links to opportunity for tracking |
| Opportunity | Account | Opportunity belongs to account |
| Quote | Order | Accepted quote converts to order |
| Quote | Product | Line items reference products |
| Order | Invoice | Order triggers invoice creation (via Financial) |
| Order | Shipment | Order fulfillment creates shipments |

---

## Integration Points (External Systems)

### CRM Platforms

| System | Use Case | Notes |
|--------|----------|-------|
| **Salesforce** | Enterprise CRM | Industry standard; extensive API |
| **HubSpot** | Marketing + Sales | Good for SMB; free tier available |
| **Pipedrive** | Sales-focused CRM | Pipeline visualization |
| **Microsoft Dynamics** | Enterprise CRM | Microsoft ecosystem |

### Marketing Automation

| System | Use Case | Notes |
|--------|----------|-------|
| **Marketo** | Enterprise marketing | Lead scoring, nurturing |
| **Pardot** | B2B marketing (Salesforce) | Tight Salesforce integration |
| **HubSpot Marketing** | Inbound marketing | Content, SEO, social |
| **Mailchimp** | Email marketing | SMB-friendly |

### E-Signature

| System | Use Case | Notes |
|--------|----------|-------|
| **DocuSign** | Contract signing | Industry leader |
| **Adobe Sign** | E-signatures | Adobe ecosystem |
| **PandaDoc** | Proposals + signatures | Quote-to-cash focus |

### CPQ (Configure-Price-Quote)

| System | Use Case | Notes |
|--------|----------|-------|
| **Salesforce CPQ** | Complex quoting | Salesforce native |
| **DealHub** | Proposal automation | Room for customization |
| **PandaDoc** | Lightweight CPQ | Good for SMB |

### ERP/Fulfillment

| System | Use Case | Notes |
|--------|----------|-------|
| **NetSuite** | Order management | Full ERP |
| **SAP** | Enterprise ERP | Large organizations |
| **ShipStation** | Shipping automation | E-commerce fulfillment |

---

## Key Metrics

### Lead Metrics

| Metric | Definition | Target |
|--------|------------|--------|
| **Lead Response Time** | Time from lead creation to first contact | < 5 minutes (web), < 1 hour (other) |
| **Lead-to-Opportunity Rate** | % of leads that become opportunities | 15-25% (varies by source) |
| **Lead Score Accuracy** | Correlation between score and conversion | High scores convert 3x more |

### Opportunity Metrics

| Metric | Definition | Target |
|--------|------------|--------|
| **Win Rate** | Opportunities won / Total closed | 20-30% typical |
| **Sales Velocity** | (# Opps x Win Rate x Avg Deal) / Cycle Time | Higher is better |
| **Pipeline Coverage** | Pipeline value / Quota | 3-4x coverage |
| **Average Deal Size** | Total won revenue / Deals won | Track trends |
| **Sales Cycle Length** | Days from opportunity creation to close | Varies by segment |
| **Stage Conversion Rate** | % moving to next stage | Track by stage |

### Quote Metrics

| Metric | Definition | Target |
|--------|------------|--------|
| **Quote-to-Close Rate** | Quotes accepted / Quotes sent | 30-50% |
| **Average Discount** | Mean discount across quotes | Monitor for margin erosion |
| **Time to Quote** | Days from request to quote sent | < 24 hours |
| **Quote Revision Rate** | Quotes requiring revision | Lower is better |

### Order Metrics

| Metric | Definition | Target |
|--------|------------|--------|
| **Order Accuracy** | Orders without errors / Total orders | > 99% |
| **On-Time Delivery** | Orders delivered by requested date | > 95% |
| **Backorder Rate** | Orders with backorders / Total orders | < 5% |
| **Order Cancellation Rate** | Canceled orders / Total orders | < 2% |

---

## Anti-Patterns to Avoid

### Pipeline Design

| Anti-Pattern | Problem | Better Approach |
|--------------|---------|-----------------|
| **15+ pipeline stages** | Friction; poor adoption; meaningless forecasts | 5-7 stages with clear criteria |
| **No entry/exit criteria** | Inconsistent stage definitions | Define and enforce criteria |
| **Probability not tied to stage** | Inaccurate forecasting | Default probability per stage |
| **No closed-lost stage** | Deals disappear without learning | Require loss reason |

### Lead Management

| Anti-Pattern | Problem | Better Approach |
|--------------|---------|-----------------|
| **No lead scoring** | Equal treatment of all leads | Score by fit and behavior |
| **Infinite lead aging** | Database pollution | Archive stale leads |
| **Manual assignment only** | Slow response, uneven distribution | Round-robin or auto-routing |

### Quoting

| Anti-Pattern | Problem | Better Approach |
|--------------|---------|-----------------|
| **Complex approval chains** | Deal velocity suffers | Streamlined tiers (3 max) |
| **No discount visibility** | Margin erosion | Show margin impact |
| **Manual quote documents** | Inconsistent, slow | Template-based generation |

### Data Quality

| Anti-Pattern | Problem | Better Approach |
|--------------|---------|-----------------|
| **Excessive custom fields** | Low adoption, clutter | 10-15 fields per object max |
| **No required fields** | Incomplete data | Require key fields at stage gates |
| **Duplicate records** | Confusion, bad reporting | Dedup rules and merge tools |

---

## Quick Reference

### Entity Summary

| Package | Core Entities | Supporting Entities |
|---------|---------------|---------------------|
| Leads | Lead, Campaign | LeadActivity |
| Opportunities | Opportunity, Account, Contact | PipelineStage, Activity |
| Quoting | Quote, QuoteLineItem, Product | PriceBook, PriceBookEntry, DiscountApproval |
| Orders | Order, OrderLineItem | Shipment |

### Workflow Summary

| ID | Workflow | Trigger |
|----|----------|---------|
| wf.leads.capture_and_qualify | Capture and Qualify Lead | Lead submitted |
| wf.leads.lead_nurturing | Nurture Lead | Lead not responding |
| wf.opportunities.advance_stage | Advance Stage | Rep updates stage |
| wf.opportunities.win_close | Close Won | Deal won |
| wf.opportunities.loss_close | Close Lost | Deal lost |
| wf.quoting.create_and_approve | Create and Approve Quote | Rep creates quote |
| wf.quoting.deliver_and_track | Deliver Quote | Quote approved |
| wf.orders.quote_to_order | Quote to Order | Customer accepts |
| wf.orders.fulfillment | Order Fulfillment | Order submitted |

### Discount Approval Thresholds

| Discount Range | Approval Level | Typical SLA |
|----------------|----------------|-------------|
| 0-10% | Auto-approved | Immediate |
| 11-20% | Manager | 4 hours |
| 21%+ | VP | 24 hours |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-05 | Initial release |
