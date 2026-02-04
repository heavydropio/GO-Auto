# Conversational Discovery

Replaces Round 1 (Context & Intent) and Round 1.5 (Module Selection) with a single natural conversation that produces a populated `USE_CASE_TEMPLATE`.

**Target duration**: 5 minutes of chatting.
**Output**: A complete `USE_CASE_TEMPLATE` ready for R2-R7.

---

## A. Conversation Flow

### Pre-Check: Research Artifacts

Before starting the conversation, check for prior research:

- `research/RESEARCH_FINDINGS.md`
- `research/RESEARCH_RECOMMENDATIONS.md`
- `discovery/templates/MODULE_*_GENERATED.md` (research-generated modules)

If found:
1. Read findings and recommendations
2. Pre-fill USE_CASE fields that have clear answers from research
3. In conversation, confirm pre-filled fields instead of asking from scratch
4. Only gap-fill fields not covered by research
5. Log pre-filled fields with source: "research" in discovery-state.json

If research provided a clear problem statement, open with:
> "I've reviewed the research findings. It looks like the core problem is [X]. Does that match your thinking, or has anything changed?"

Instead of the default open-ended "Tell me about what you're building."

### Opening

Start with one open-ended prompt:

> "Tell me about what you're building and the problem it solves."

Do NOT ask about platform, actors, constraints, or modules yet. Let the user talk.

### Listen-First Phase (1-2 minutes)

As the user describes their idea, silently extract:

| Signal | Maps To |
|--------|---------|
| Who has the problem | `problem.who_affected.primary` |
| What the problem is | `problem.one_liner` |
| How they cope today | `problem.current_workaround` |
| Who uses the system | `actors[].name` + `actors[].type` |
| What users want to do | `actors[].goal` |
| "Web app" / "mobile" / etc. | `environment.platform` |
| Mentions of specific systems | `integrations[]` |
| "Must" / "cannot" / "required" | `constraints[]` |
| Trigger phrases (see Section B) | `modules.selected[]` |

After the user's initial description, take stock of what you learned and what gaps remain.

### Gap-Filling Phase (2-3 minutes)

Only ask about things the user did NOT cover. Use natural follow-ups, not a checklist.

**Problem gaps** (if one_liner or workaround unclear):
- "What happens if this problem doesn't get solved?"
- "How do people deal with this today?"

**Actor gaps** (if fewer than expected users mentioned):
- "Besides [mentioned user], who else would use this?"
- "Is there an admin or back-office role?"
- "What's the most important thing [actor] needs to get done?"

**Environment gaps** (if platform unclear):
- "Is this a web app, mobile, or something else?"
- "Does it need to work offline at all?"
- "What existing systems does it need to talk to?"

**Constraint gaps** (if no constraints mentioned):
- "Any hard requirements around compliance, security, or tech stack?"
- "What's your timeline looking like?"
- "Solo project or team?"

### Question Style Rules

1. **One question at a time.** Never ask 3 questions in a paragraph.
2. **Build on what they said.** Reference their words: "You mentioned [X] -- does that also mean [Y]?"
3. **No jargon.** Don't say "actors" or "modules" to the user. Say "users" and "features."
4. **Confirm, don't interrogate.** "It sounds like the main user is [X] -- is that right?" beats "Who is the primary actor?"
5. **Stop when you have enough.** If the required fields checklist (see schema) is met, move to the checkpoint. Don't ask questions you already know the answer to.

### When To Stop Asking

Stop the conversation and move to the checkpoint when ALL of these are true:

- [ ] You can write a one-liner problem statement
- [ ] You know who is primarily affected
- [ ] You have at least 2 success criteria
- [ ] At least 1 primary actor is identified with clear goal
- [ ] Platform is known
- [ ] Timeline is known (even if "TBD")
- [ ] At least 1 module has been triggered (see Section C)

---

## B. Scope Assessment & Path Routing

After the conversation meets the "stop asking" criteria above, assess project complexity to determine whether this project needs full discovery (R2-R7) or can proceed with light discovery.

### Complexity Scoring

Calculate a score from signals gathered during the conversation:

| Signal | Points | Condition |
|--------|--------|-----------|
| Primary actors | +3 | 3 or more primary actors |
| Primary actors | +1 | Exactly 2 primary actors |
| Modules selected | +3 | 5 or more modules triggered |
| Modules selected | +2 | 3-4 modules triggered |
| Modules selected | +1 | 2 modules triggered |
| Must-have integrations | +2 | 3 or more external systems |
| Must-have integrations | +1 | 2 external systems |
| Compliance/audit keywords | +2 | "compliance", "audit", "HIPAA", "SOC2", "GDPR", "PCI", "regulation" |
| Offline sync | +1 | "offline", "sync later", "no signal" |
| Bulk/multi-tenant | +1 | "bulk", "multi-tenant", "portfolio", "white-label" |

**Threshold**: score >= 5 → recommend full path. Score < 5 → recommend light path.

### Path Recommendation

Present the recommendation naturally after the conversation, before the checkpoint summary.

**Light path (score < 5):**

> "This sounds like a focused build — single workflow, straightforward data model. I have enough to create a plan and move straight to preflight. Want to proceed, or would you prefer a deeper discovery pass?"

**Full path (score >= 5):**

> "This has real complexity — multiple user types, several integration points, [specific signals]. I'd recommend full discovery to map out entities, workflows, and screens before building. We'll work through it together with checkpoints along the way. Sound good, or would you rather keep it light?"

The user can override in either direction. If they say "just use your recommendation," follow the score.

### Light Path: What Happens

1. Present the checkpoint summary (Section D) as normal.
2. After user approval, generate:
   - `discovery/USE_CASE.yaml` — the populated template from conversation
   - `ROADMAP.md` — simple phase breakdown derived from selected modules (one phase per module + a final integration/testing phase)
   - `discovery/discovery-state.json` — minimal state with `"path": "light"`, modules, actors, constraints
3. Announce: "Discovery complete. Run `/go:preflight` to check your environment."

The light path skips R2-R7 entirely. Entity design, workflow mapping, screens, and edge cases are handled during the build phases instead of up front.

### Full Path: What Happens

1. Present the checkpoint summary (Section D) as normal.
2. After user approval, write `discovery/USE_CASE.yaml` and `discovery/discovery-state.json` with `"path": "full"`.
3. Announce: "Discovery foundation set. Moving into entity mapping (R2) and workflow design (R3) — these run in parallel."
4. Proceed to R2 as documented in the round templates.

### Upgrade Path

If a project started on the light path and complexity emerges during building, the user can run `/go:discover` again. The agent detects existing `discovery-state.json` with `"path": "light"` and offers:

> "You have a light discovery on file. Want to upgrade to full discovery? I'll use what we already captured and pick up from R2 (entity mapping)."

---

## C. Trigger Matching System

### Module Catalog

Read trigger phrases from `discovery/templates/MODULE_CATALOG.json`. The table below is the built-in reference; research-generated modules (with `"source": "research"`) extend it at runtime. When matching, check both the table below AND any research-generated entries in the catalog.

While conversing, silently match the user's words against trigger phrases from the 13-module catalog. The user never sees this matching happen. It runs in the background as they talk.

### Trigger Phrase Table

| Module | Trigger Phrases |
|--------|----------------|
| **Administrative** | "schedule", "calendar", "appointment", "meeting", "contact list", "address book", "directory", "to-do", "task list", "reminders", "settings", "preferences", "configuration" |
| **Financial** | "invoice", "bill", "billing", "payment", "pay", "charge", "accounts receivable", "AR", "collections", "accounts payable", "AP", "vendors", "expense", "receipt", "reimbursement", "budget", "forecast", "P&L" |
| **Field Service** | "dispatch", "assign job", "schedule tech", "field", "on-site", "at customer location", "work order", "service ticket", "offline", "no signal", "sync later", "mobile app", "tablet", "phone", "inspection", "checklist", "form" |
| **Inventory** | "inventory", "stock", "warehouse", "transfer", "move stock", "location", "reorder", "low stock", "purchase order", "SKU", "part number", "item", "count", "cycle count", "audit" |
| **Reporting** | "dashboard", "metrics", "KPI", "report", "export", "download", "chart", "graph", "visualization", "scheduled report", "email report" |
| **CRM** | "customer", "client", "account", "contact history", "interaction", "touchpoint", "lead", "prospect", "opportunity", "customer profile", "360 view" |
| **HR/People** | "employee", "staff", "team member", "time tracking", "clock in", "timesheet", "payroll", "pay", "compensation", "PTO", "leave", "vacation", "time off", "org chart", "reporting structure" |
| **Sales** | "pipeline", "deals", "opportunities", "quote", "proposal", "estimate", "order", "purchase", "buy", "commission", "quota", "target", "forecast", "projection" |
| **Procurement** | "vendor", "supplier", "source", "purchase order", "PO", "requisition", "receiving", "goods receipt", "delivery", "RFQ", "bid", "sourcing" |
| **Project/Job** | "project", "job", "engagement", "task", "work item", "assignment", "resource", "allocation", "capacity", "milestone", "deadline", "timeline", "budget", "cost tracking", "burn rate" |
| **Communication** | "email", "message", "send", "chat", "instant message", "Slack", "notification", "alert", "remind", "template", "canned response" |
| **Documents** | "document", "file", "attachment", "template", "generate", "merge", "signature", "e-sign", "DocuSign", "version", "revision", "history" |
| **Compliance** | "audit", "audit trail", "log", "compliance", "regulation", "requirement", "certification", "license", "credential", "policy", "procedure", "acknowledgment", "HIPAA", "SOC2", "GDPR", "PCI" |

### Matching Rules

1. **Exact match**: If the user says a trigger phrase verbatim, the module is a candidate.
2. **Semantic match**: If the user describes the concept without the exact phrase (e.g., "track what we owe suppliers" = Procurement + Financial), the module is a candidate.
3. **Context match**: Domain context can trigger modules even without explicit phrases. A legal app mentioning "filings" and "deadlines" triggers Compliance and Project/Job.
4. **Threshold**: A module needs at least 2 trigger signals (phrase matches or semantic matches) to be selected. A single mention is noted but not auto-selected.
5. **Package selection**: Once a module is selected, determine which packages apply based on what the user actually described. Don't select all packages -- only the ones with evidence.

### Tracking Format (Internal)

Keep a running mental tally as the conversation progresses:

```
Module Matches:
  financial: ["invoice" (explicit), "payment" (explicit), "billing" (explicit)] -> SELECT
    packages: invoicing, payments
  compliance: ["audit trail" (explicit), "regulation" (semantic from "USPTO requirements")] -> SELECT
    packages: regulatory, audit_trail
  documents: ["template" (explicit), "generate" (semantic from "draft applications")] -> SELECT
    packages: storage, templates
  crm: ["client" (explicit)] -> WATCH (only 1 signal)
  inventory: [] -> SKIP
```

---

## D. Progressive Template Population

The USE_CASE_TEMPLATE fills in as the conversation progresses. Here is the mapping from conversation signals to template fields:

### Phase 1: Opening Statement

The user's first description typically populates:

| Conversation Signal | Template Field |
|---------------------|---------------|
| "We need to..." / "The problem is..." | `problem.one_liner` |
| "[Person/role] spends too much time on..." | `problem.who_affected.primary`, `problem.current_workaround` |
| "It should let [someone] do [something]" | `actors[0].name`, `actors[0].goal` |
| Domain-specific nouns (invoice, patient, order) | Module trigger signals |
| "Web app" / "mobile" / "API" | `environment.platform` |

### Phase 2: Follow-Up Questions

Each follow-up answer fills remaining gaps:

| Question Theme | Template Fields Populated |
|----------------|--------------------------|
| "Who else uses it?" | Additional `actors[]` entries |
| "What does success look like?" | `problem.success_criteria` |
| "What systems does it talk to?" | `integrations[]` |
| "Any hard requirements?" | `constraints[]` |
| "Timeline?" | `constraints[]` with `category: timeline` |
| "How do they cope today?" | `problem.current_workaround` |

### Phase 3: Inference

After the conversation, fill remaining fields by inference:

| Inference | Confidence | Example |
|-----------|------------|---------|
| User said it explicitly | high | "We need to track billable hours" |
| Strongly implied by context | medium | User mentions "invoices" -> invoice generation needed |
| Reasonable assumption from domain | low | Web app -> desktop-first responsive |

For medium/low confidence items, add them to `validation.items_needing_confirmation`.

---

## E. Checkpoint Protocol

### Presenting the Template

After the conversation, present the populated template to the user in a readable summary (not raw YAML). Use this format:

---

> **Here's what I captured. Let me know what needs adjusting.**
>
> **Problem**: [one_liner]
>
> **Who's affected**: [primary] (and [secondary] if applicable)
>
> **Success looks like**:
> - [criterion 1]
> - [criterion 2]
> - [criterion 3]
>
> **Users**:
> | Who | What they need | How often |
> |-----|---------------|-----------|
> | [actor 1] | [goal] | [frequency] |
> | [actor 2] | [goal] | [frequency] |
>
> **Platform**: [platform] | **Offline**: [yes/no] | **Timeline**: [timeline]
>
> **Integrations**: [system 1] (must-have), [system 2] (nice-to-have)
>
> **Key constraints**: [constraint 1], [constraint 2]
>
> **Feature areas I'll focus on** (based on what you described):
> - [Module 1]: [packages] -- because [rationale]
> - [Module 2]: [packages] -- because [rationale]
>
> **Assumptions I'm making** (flag anything wrong):
> - [assumption 1]
> - [assumption 2]

---

### User Feedback Loop

After presenting:

1. **Ask once**: "Does this capture it? Anything to add, change, or remove?"
2. **Apply corrections**: Update the template fields based on feedback.
3. **Re-present only if major changes**: If the user corrects a core field (problem statement, actor, module), show the updated summary. For minor tweaks, acknowledge and move on.

### Completion Gate

The template is "complete enough" to proceed to R2 when:

1. All required fields from the schema checklist are populated.
2. The user has seen the summary and said it's correct (or made corrections that were applied).
3. At least 1 module is selected with at least 1 package.

At completion, announce:

> "Great -- discovery foundation is set. I'll move into entity mapping (R2) and workflow design (R3) next. These can run in parallel."

Then write the template to `discovery/USE_CASE_TEMPLATE.yaml` and update `discovery-state.json`.

---

## F. Example Conversation: IP/Trademark Submission Engine

Below is how this conversation would play out for the SCENARIO-001 test case.

---

**Claude**: Tell me about what you're building and the problem it solves.

**User**: I want to build a tool that helps people file trademarks with the USPTO. Right now, IP attorneys spend 40+ hours per application just on research and drafting. Small inventors can't afford $15-30K in attorney fees, so they either skip trademark protection or try to navigate the USPTO system alone and make mistakes. I want to automate the prior art research using AI and generate the application documents, then submit electronically through the USPTO API.

> *[Internal: Captured problem one_liner, who_affected, current_workaround, cost_of_inaction. Trigger matches: "document"+"generate" -> Documents; "compliance"/"regulation" implicit from USPTO; "template" implicit from "generate application documents"; "submit electronically" -> integration. Watching: Financial (filing fees likely), Communication (notifications likely), Project (application lifecycle).]*

**Claude**: That's a clear pain point. Three types of users jump out to me from what you said -- the individual inventor doing it themselves, the IP attorney who'd use this to speed up their workflow, and maybe a corporate IP team filing in bulk. Is that right, or are there others?

**User**: Exactly those three. The individual inventor is the self-service path, the attorney uses it as a power tool for their clients, and corporate teams need bulk filing. Each has pretty different needs.

> *[Internal: 3 primary actors confirmed, high confidence. "Bulk filing" reinforces Project module. "Clients" noted for CRM watch -- but in context, attorney's clients, not CRM lifecycle.]*

**Claude**: What does success look like for the individual inventor path? If this tool works perfectly, what changes for them?

**User**: They should be able to do their own prior art research in under 2 hours instead of 20+, fill out the application with guidance, and submit it to the USPTO electronically with a 95%+ form compliance rate. And then track the status and get notified about office actions.

> *[Internal: 4 success criteria captured. "Track status" + "notified" -> Communication.notifications triggered. "Office actions" -> Project.task_management (deadlines). Module signals now: Documents (3), Compliance (2), Project (3), Communication (2), Financial (watching).]*

**Claude**: You mentioned submitting through the USPTO API. Are there other systems this needs to integrate with?

**User**: USPTO API for submission, USPTO TSDR for status tracking, and some AI provider for the research agent. We'll need document storage for all the application files. And probably some notification system for deadline alerts -- office actions have strict response windows.

> *[Internal: Integrations captured: USPTO API (must-have), USPTO TSDR (must-have), AI/LLM provider (must-have), Document storage (must-have), Notification service (nice-to-have). "Strict response windows" reinforces Compliance.]*

**Claude**: Got it. Any hard requirements around compliance, security, or legal?

**User**: Big one: we cannot practice law. The tool is advisory only -- it helps with research and filing but doesn't give legal advice. We also need to handle PII securely since we're dealing with inventor names, addresses, and sometimes SSNs for foreign applicants. And obviously everything has to comply with USPTO electronic filing requirements.

> *[Internal: 3 hard constraints captured. Compliance module now firmly selected (regulatory, audit_trail, policies). Security constraint noted.]*

**Claude**: Is this a web app? And what's the timeline?

**User**: Web app. Timeline is TBD -- we're still in discovery.

> *[Internal: Platform: web. Timeline: TBD. All required fields now populated. Module selection finalized:]*
>
> *Modules selected:*
> - *documents (storage, templates, versioning) -- application documents, draft generation, revision tracking*
> - *compliance (regulatory, audit_trail, policies) -- USPTO requirements, legal defensibility, advisory-only enforcement*
> - *project (project_management, task_management) -- application lifecycle, office action deadlines*
> - *communication (notifications, email) -- status alerts, deadline reminders*
> - *financial (payments) -- USPTO filing fees*

**Claude**: Here's what I captured. Let me know what needs adjusting.

> **Problem**: IP attorneys and individual inventors spend excessive time (40+ hours per application) on trademark research and drafting, making the process cost-prohibitive for small inventors.
>
> **Who's affected**: Individual inventors (primary), IP attorneys and corporate IP teams (also primary, different needs)
>
> **Success looks like**:
> - Reduce prior art research from 20+ hours to under 2 hours via AI
> - Enable individual inventors to complete USPTO submission without attorney help
> - 95%+ form compliance acceptance rate
> - Track status and office actions with automated notifications
>
> **Users**:
> | Who | What they need | How often |
> |-----|---------------|-----------|
> | Individual Inventor | Self-file trademark without attorney | Occasional (1-5 apps) |
> | IP Attorney | Speed up research and drafting for clients | Weekly |
> | Corporate IP Team | Bulk filing management | Daily |
>
> **Platform**: Web | **Offline**: No | **Timeline**: TBD
>
> **Integrations**: USPTO API (must-have), USPTO TSDR (must-have), AI/LLM provider (must-have), Document storage (must-have), Notification service (nice-to-have)
>
> **Key constraints**: Cannot practice law (advisory only), PII security required, USPTO e-filing compliance required
>
> **Feature areas I'll focus on**:
> - **Documents** (storage, templates, versioning) -- application document generation and revision tracking
> - **Compliance** (regulatory, audit trail) -- USPTO filing requirements, legal audit trail
> - **Project** (project management, task management) -- application lifecycle tracking, office action deadlines
> - **Communication** (notifications, email) -- status alerts, deadline reminders
> - **Financial** (payments) -- USPTO filing fee tracking
>
> **Assumptions I'm making**:
> - Desktop-first responsive design (professional/legal use case)
> - Cloud-hosted (web app with external API integrations)
> - US trademarks only (USPTO) for initial scope
> - AI research uses external LLM API, not self-hosted

**User**: That looks right. I'd add that payment processing for the filing fees could be nice-to-have rather than must-have -- we might just inform users of the fees initially.

**Claude**: Noted -- I'll mark payment handling as secondary priority. Everything else is solid.

Discovery foundation is set. I'll move into entity mapping (R2) and workflow design (R3) next. These can run in parallel.

---

### What Happened Behind the Scenes

| Conversation Turn | Template Fields Populated | Modules Triggered |
|-------------------|--------------------------|-------------------|
| User's opening statement | problem (one_liner, who_affected, current_workaround, cost_of_inaction) | Documents (2), Compliance (1), Project (1) |
| Actor confirmation | actors (3 primary) | Project (+1) |
| Success criteria | problem.success_criteria (4 items) | Communication (2), Project (+1) |
| Integrations | integrations (5 systems) | -- |
| Constraints | constraints (3 hard) | Compliance (+2) |
| Platform + timeline | environment.platform, constraints[timeline] | -- |
| Checkpoint | User approved | Financial confirmed secondary |

Total conversation: **6 exchanges**. Total time: **~4 minutes**.

The same information that R1 and R1.5 captured in two separate structured rounds was gathered in a single flowing conversation, with module matching happening silently throughout.
