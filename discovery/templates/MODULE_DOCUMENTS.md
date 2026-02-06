# Documents Module Catalog

**Module**: Documents
**Version**: 1.0
**Last Updated**: 2026-02-05

---

## Overview

The Documents module manages file storage, versioning, organization, and sharing within an application. This module handles document upload, retrieval, templating, folder structures, tagging, and electronic signatures. The philosophy is "Simple Core, Rich Extensions"—a lean core for storage and retrieval with integrations for advanced features like e-signatures and collaboration.

### When to Use This Module

Select this module when R1 context includes any of:

| Trigger Phrases | Typical Actors | Business Need |
|-----------------|----------------|---------------|
| "upload", "file storage", "documents" | All users | Store and retrieve files |
| "version", "revision", "history" | Authors, Reviewers | Track document changes over time |
| "folder", "organize", "file structure" | All users | Organize documents hierarchically |
| "share", "permissions", "access" | Admins, Document owners | Control who can view/edit documents |
| "template", "generate", "merge" | Business users, Admins | Create documents from templates |
| "signature", "sign", "e-sign", "DocuSign" | Signers, Legal, Business | Collect legally binding signatures |
| "tag", "label", "categorize" | All users | Classify and find documents |

### Module Dependencies

```
Documents Module
├── REQUIRES: Administrative (for settings, user management)
├── INTEGRATES_WITH: CRM (client documents, attachments)
├── INTEGRATES_WITH: Financial (invoices, receipts, contracts)
├── INTEGRATES_WITH: Project/Job (project files, deliverables)
├── INTEGRATES_WITH: Compliance (audit trails, retention)
```

### Design Philosophy: Simple Core, Rich Extensions

**Core Principles**:
- Store file content in blob storage (S3, GCS, Azure Blob) with CDN delivery
- Store metadata in database—NEVER store BLOBs in the database
- Use existing template engines (Handlebars, Mustache, Jinja2)—don't build your own
- Integrate with e-signature providers (DocuSign, HelloSign)—don't build your own
- Simple append-only versioning—skip check-in/check-out complexity
- Flat tags over hierarchical taxonomies

**What to Avoid**:
- Database BLOBs (performance killer at scale)
- Hierarchical/nested tag structures (complexity without value)
- Building custom collaboration features (use integrations instead)
- Complex check-in/check-out locking (append-only is simpler)

---

## Packages

This module contains 5 packages:

1. **storage** - Core file upload, storage, and retrieval
2. **organization** - Folders, tags, and document structure
3. **versioning** - Document version history and management
4. **templates** - Document generation from templates
5. **signatures** - Electronic signature collection and tracking

---

## Package 1: Storage

### Purpose

Handle file uploads, secure storage in blob storage, and retrieval via CDN. Manage file metadata separate from content.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What file types do you need to store? (PDF, images, Office docs, videos)
- What's your largest expected file size?
- Do you need to preview files in-browser?
- What metadata do you track per document? (custom fields, dates, owners)

**Workflow Discovery**:
- How do users upload files? (drag-drop, form, email, API)
- Who can upload? Who can delete?
- Do you need virus scanning on upload?
- How long must files be retained?

**Edge Case Probing**:
- What happens if upload fails midway?
- Can users upload duplicate files?
- Do you need to handle very large files (multi-GB)?

### Entity Templates

#### Document

```json
{
  "id": "data.storage.document",
  "name": "Document",
  "type": "data",
  "namespace": "storage",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Core entity representing a stored document with metadata.",
    "fields": [
      { "name": "name", "type": "string", "required": true, "description": "Display name of the document" },
      { "name": "file_key", "type": "string", "required": true, "description": "Blob storage key/path" },
      { "name": "mime_type", "type": "string", "required": true, "description": "MIME type (application/pdf, image/jpeg, etc.)" },
      { "name": "file_size", "type": "integer", "required": true, "description": "Size in bytes" },
      { "name": "checksum", "type": "string", "required": true, "description": "SHA-256 hash for integrity verification" },
      { "name": "status", "type": "enum", "required": true, "values": ["uploading", "active", "archived", "deleted"], "description": "Document lifecycle status" },
      { "name": "owner_id", "type": "uuid", "required": true, "description": "User who owns/uploaded the document" },
      { "name": "folder_id", "type": "uuid", "required": false, "description": "Parent folder if organized" },
      { "name": "description", "type": "text", "required": false, "description": "Optional description or notes" },
      { "name": "uploaded_at", "type": "datetime", "required": true, "description": "When document was uploaded" },
      { "name": "archived_at", "type": "datetime", "required": false, "description": "When document was archived" },
      { "name": "retention_until", "type": "date", "required": false, "description": "Minimum retention date" },
      { "name": "current_version_id", "type": "uuid", "required": false, "description": "Latest version reference" }
    ],
    "relationships": [
      { "entity": "User", "type": "many_to_one", "required": true },
      { "entity": "Folder", "type": "many_to_one", "required": false },
      { "entity": "DocumentVersion", "type": "one_to_many", "required": false },
      { "entity": "Tag", "type": "many_to_many", "required": false },
      { "entity": "DocumentShare", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "documents.storage",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### DocumentVersion

```json
{
  "id": "data.storage.document_version",
  "name": "Document Version",
  "type": "data",
  "namespace": "storage",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Immutable record of a document at a point in time (append-only versioning).",
    "fields": [
      { "name": "document_id", "type": "uuid", "required": true, "description": "Parent document" },
      { "name": "version_number", "type": "integer", "required": true, "description": "Sequential version (1, 2, 3...)" },
      { "name": "file_key", "type": "string", "required": true, "description": "Blob storage key for this version" },
      { "name": "file_size", "type": "integer", "required": true, "description": "Size in bytes" },
      { "name": "checksum", "type": "string", "required": true, "description": "SHA-256 hash" },
      { "name": "created_by", "type": "uuid", "required": true, "description": "User who uploaded this version" },
      { "name": "created_at", "type": "datetime", "required": true, "description": "Version creation timestamp" },
      { "name": "change_summary", "type": "string", "required": false, "description": "Brief description of changes" }
    ],
    "relationships": [
      { "entity": "Document", "type": "many_to_one", "required": true },
      { "entity": "User", "type": "many_to_one", "required": true }
    ],
    "notes": "Versions are immutable. New content creates a new version. Old versions are retained for history."
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "documents.storage",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.storage.upload_document

```yaml
workflow:
  id: "wf.storage.upload_document"
  name: "Upload Document"
  trigger: "User initiates file upload"
  actors: ["User", "System", "Storage Service"]

  steps:
    - step: 1
      name: "Initiate Upload"
      actor: "User"
      action: "Select file and provide metadata"
      inputs: ["File", "Name", "Folder (optional)", "Tags (optional)"]
      outputs: ["Upload request"]

    - step: 2
      name: "Validate File"
      actor: "System"
      action: "Check file type, size limits, virus scan"
      inputs: ["Upload request"]
      outputs: ["Validation result"]
      automatable: true
      decision_point: "File allowed? Size within limits?"

    - step: 3
      name: "Generate Upload URL"
      actor: "System"
      action: "Create presigned URL for direct blob upload"
      inputs: ["Validated request"]
      outputs: ["Presigned upload URL", "Document record (status=uploading)"]
      automatable: true

    - step: 4
      name: "Upload to Storage"
      actor: "User"
      action: "Browser uploads directly to blob storage"
      inputs: ["Presigned URL", "File content"]
      outputs: ["Upload confirmation"]

    - step: 5
      name: "Finalize Document"
      actor: "System"
      action: "Verify upload, calculate checksum, update status"
      inputs: ["Upload confirmation", "Document record"]
      outputs: ["Active document", "Version 1 created"]
      automatable: true

    - step: 6
      name: "Index for Search"
      actor: "System"
      action: "Extract text, index metadata for search"
      inputs: ["Active document"]
      outputs: ["Search index updated"]
      automatable: true
```

#### wf.storage.delete_document

```yaml
workflow:
  id: "wf.storage.delete_document"
  name: "Delete Document"
  trigger: "User requests document deletion"
  actors: ["User", "System", "Admin"]

  steps:
    - step: 1
      name: "Request Deletion"
      actor: "User"
      action: "Select document(s) to delete"
      inputs: ["Document selection"]
      outputs: ["Deletion request"]

    - step: 2
      name: "Check Permissions"
      actor: "System"
      action: "Verify user can delete (owner or admin)"
      inputs: ["Deletion request", "User permissions"]
      outputs: ["Authorization result"]
      automatable: true

    - step: 3
      name: "Check Dependencies"
      actor: "System"
      action: "Check for active shares, signatures, references"
      inputs: ["Document"]
      outputs: ["Dependency check result"]
      automatable: true
      decision_point: "Dependencies exist?"

    - step: 4a
      name: "Soft Delete"
      actor: "System"
      action: "Mark document as deleted (retain for recovery period)"
      inputs: ["Approved deletion"]
      outputs: ["Soft-deleted document"]
      condition: "Standard deletion"
      automatable: true

    - step: 4b
      name: "Admin Approval for Hard Delete"
      actor: "Admin"
      action: "Approve permanent deletion"
      inputs: ["Hard delete request"]
      outputs: ["Approved hard delete"]
      condition: "Permanent deletion requested"

    - step: 5
      name: "Purge (after retention)"
      actor: "System"
      action: "Remove from blob storage after retention period"
      inputs: ["Soft-deleted document past retention"]
      outputs: ["Permanently deleted"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-DOC-001 | **Upload fails midway** | Medium | Track upload status; allow resume; clean up orphaned uploads after timeout |
| EC-DOC-002 | **Duplicate file uploaded** | Low | Detect by checksum; warn user but allow (same content, different document) |
| EC-DOC-003 | **File exceeds size limit** | Low | Reject before upload starts; provide clear error message |
| EC-DOC-004 | **Unsupported file type** | Low | Configurable allowlist; reject with helpful message |
| EC-DOC-005 | **Virus detected in upload** | High | Quarantine file; notify user and admin; do not activate |
| EC-DOC-006 | **Storage service unavailable** | High | Queue uploads for retry; notify user of delay |
| EC-DOC-007 | **Document deleted while being viewed** | Medium | Allow view to complete; show deleted status on next access |
| EC-DOC-008 | **Retention period prevents deletion** | Medium | Block deletion; show retention end date |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-DOC-001 | **Auto-tagging** | Document content, filename | Suggested tags | Speeds organization; improves findability |
| AI-DOC-002 | **Content extraction** | PDF/image document | Extracted text (OCR) | Enables full-text search |
| AI-DOC-003 | **Document classification** | Document content | Document type/category | Auto-routing and organization |
| AI-DOC-004 | **Duplicate detection** | Document content | Similar documents | Prevents redundancy |

---

## Package 2: Organization

### Purpose

Organize documents using folders and tags. Folders provide hierarchical structure; tags provide flexible cross-cutting classification.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- How deep can folder nesting go?
- Can a document exist in multiple folders?
- What tags/labels do you use to classify documents?
- Are there mandatory tags or folder assignments?

**Workflow Discovery**:
- Who creates folders? Who manages tags?
- Are there folder templates for new projects/clients?
- How do users find documents? (browse vs search)
- Do folders have permissions separate from documents?

**Edge Case Probing**:
- What if someone deletes a folder with documents in it?
- Can users create their own tags or only use predefined ones?
- How do you handle folder/tag name collisions?

### Entity Templates

#### Folder

```json
{
  "id": "data.organization.folder",
  "name": "Folder",
  "type": "data",
  "namespace": "organization",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Hierarchical container for organizing documents.",
    "fields": [
      { "name": "name", "type": "string", "required": true, "description": "Folder name" },
      { "name": "parent_id", "type": "uuid", "required": false, "description": "Parent folder (null for root)" },
      { "name": "path", "type": "string", "required": true, "description": "Full path (e.g., /Clients/Acme/Contracts)" },
      { "name": "owner_id", "type": "uuid", "required": true, "description": "Folder owner" },
      { "name": "description", "type": "text", "required": false, "description": "Folder description" },
      { "name": "color", "type": "string", "required": false, "description": "Display color for UI" },
      { "name": "created_at", "type": "datetime", "required": true, "description": "Creation timestamp" },
      { "name": "updated_at", "type": "datetime", "required": true, "description": "Last modification" }
    ],
    "relationships": [
      { "entity": "Folder", "type": "many_to_one", "required": false, "description": "Parent folder" },
      { "entity": "Folder", "type": "one_to_many", "required": false, "description": "Child folders" },
      { "entity": "Document", "type": "one_to_many", "required": false },
      { "entity": "User", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "documents.organization",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Tag

```json
{
  "id": "data.organization.tag",
  "name": "Tag",
  "type": "data",
  "namespace": "organization",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Flat label for cross-cutting document classification.",
    "fields": [
      { "name": "name", "type": "string", "required": true, "description": "Tag name (unique, lowercase)" },
      { "name": "display_name", "type": "string", "required": true, "description": "Human-readable display name" },
      { "name": "color", "type": "string", "required": false, "description": "Tag color for UI" },
      { "name": "description", "type": "text", "required": false, "description": "Tag purpose/meaning" },
      { "name": "system_tag", "type": "boolean", "required": true, "description": "System-managed vs user-created" },
      { "name": "usage_count", "type": "integer", "required": false, "description": "Number of documents with this tag" }
    ],
    "relationships": [
      { "entity": "Document", "type": "many_to_many", "required": false }
    ],
    "notes": "Tags are FLAT, not hierarchical. Avoid nested tag structures which add complexity without value."
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "documents.organization",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### DocumentTag (Junction)

```json
{
  "id": "data.organization.document_tag",
  "name": "Document Tag Assignment",
  "type": "data",
  "namespace": "organization",
  "tags": ["junction-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Junction table linking documents to tags.",
    "fields": [
      { "name": "document_id", "type": "uuid", "required": true, "description": "Tagged document" },
      { "name": "tag_id", "type": "uuid", "required": true, "description": "Applied tag" },
      { "name": "tagged_by", "type": "uuid", "required": true, "description": "User who applied tag" },
      { "name": "tagged_at", "type": "datetime", "required": true, "description": "When tag was applied" },
      { "name": "auto_tagged", "type": "boolean", "required": false, "description": "Applied by AI vs manually" }
    ],
    "relationships": [
      { "entity": "Document", "type": "many_to_one", "required": true },
      { "entity": "Tag", "type": "many_to_one", "required": true },
      { "entity": "User", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "documents.organization",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.organization.create_folder_structure

```yaml
workflow:
  id: "wf.organization.create_folder_structure"
  name: "Create Folder Structure"
  trigger: "New project/client/matter created"
  actors: ["System", "User"]

  steps:
    - step: 1
      name: "Trigger from Parent Entity"
      actor: "System"
      action: "Detect new entity requiring folder structure"
      inputs: ["New client/project/matter"]
      outputs: ["Folder creation trigger"]
      automatable: true

    - step: 2
      name: "Apply Folder Template"
      actor: "System"
      action: "Create folder hierarchy from template"
      inputs: ["Folder template", "Entity context"]
      outputs: ["Created folder structure"]
      automatable: true

    - step: 3
      name: "Set Permissions"
      actor: "System"
      action: "Apply default permissions based on entity"
      inputs: ["Folder structure", "Permission template"]
      outputs: ["Folders with permissions"]
      automatable: true

    - step: 4
      name: "Notify Users"
      actor: "System"
      action: "Alert relevant users of new folder availability"
      inputs: ["Folder structure", "User assignments"]
      outputs: ["Notifications sent"]
      automatable: true
```

#### wf.organization.bulk_tag_documents

```yaml
workflow:
  id: "wf.organization.bulk_tag_documents"
  name: "Bulk Tag Documents"
  trigger: "User selects multiple documents for tagging"
  actors: ["User", "System"]

  steps:
    - step: 1
      name: "Select Documents"
      actor: "User"
      action: "Choose documents to tag"
      inputs: ["Document selection"]
      outputs: ["Selected documents"]

    - step: 2
      name: "Choose Tags"
      actor: "User"
      action: "Select tags to apply or remove"
      inputs: ["Available tags", "Current tags on selection"]
      outputs: ["Tag operations (add/remove)"]

    - step: 3
      name: "Apply Tags"
      actor: "System"
      action: "Add or remove tags from all selected documents"
      inputs: ["Selected documents", "Tag operations"]
      outputs: ["Updated documents"]
      automatable: true

    - step: 4
      name: "Update Search Index"
      actor: "System"
      action: "Re-index affected documents"
      inputs: ["Updated documents"]
      outputs: ["Index updated"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-DOC-010 | **Delete folder with contents** | Medium | Require confirmation; move contents to parent or delete recursively |
| EC-DOC-011 | **Folder name collision** | Low | Append number suffix; or reject with clear error |
| EC-DOC-012 | **Tag renamed while in use** | Low | Update all references; maintain tag_id consistency |
| EC-DOC-013 | **Circular folder reference** | High | Validate parent chain on move; prevent cycles |
| EC-DOC-014 | **Maximum folder depth exceeded** | Low | Enforce configurable depth limit (e.g., 10 levels) |
| EC-DOC-015 | **Orphaned documents after folder delete** | Medium | Move to "Unfiled" folder; never delete documents silently |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-DOC-005 | **Tag suggestions** | Document content, existing tags | Recommended tags | Improves consistency |
| AI-DOC-006 | **Folder suggestions** | Document metadata, folder structure | Recommended folder | Speeds filing |
| AI-DOC-007 | **Tag cleanup** | Tag usage statistics | Merge/rename suggestions | Maintains tag hygiene |

---

## Package 3: Versioning

### Purpose

Track document changes over time using simple append-only versioning. Each edit creates a new version; old versions are immutable and retained.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- How many versions do you typically keep?
- Do you need to compare versions side-by-side?
- Should version history be visible to all viewers?

**Workflow Discovery**:
- When does a new version get created? (every save, explicit action)
- Can users restore/revert to previous versions?
- Who can see version history?
- Do you need approval before new version becomes "current"?

**Edge Case Probing**:
- What if two users upload new versions simultaneously?
- Can you delete specific versions?
- Should version comments be required?

### Discovery Note: Append-Only Philosophy

**Skip check-in/check-out complexity**. Traditional document management systems use locking (check-out) to prevent conflicts. This adds significant complexity:
- Users forget to check in
- Locks become stale
- Offline editing breaks the model

**Instead, use append-only versioning**:
- Any authorized user can upload a new version at any time
- If two users upload simultaneously, both versions are kept
- The later upload becomes "current" but earlier version is preserved
- Conflicts are rare in practice and easily resolved by keeping both

### Entity Templates

The core versioning entity (DocumentVersion) is defined in Package 1: Storage.

#### VersionComparison (View Model)

```json
{
  "id": "data.versioning.version_comparison",
  "name": "Version Comparison",
  "type": "view",
  "namespace": "versioning",
  "tags": ["view-model"],
  "status": "discovered",

  "spec": {
    "purpose": "Computed comparison between two document versions.",
    "fields": [
      { "name": "document_id", "type": "uuid", "required": true, "description": "Document being compared" },
      { "name": "version_a", "type": "integer", "required": true, "description": "First version number" },
      { "name": "version_b", "type": "integer", "required": true, "description": "Second version number" },
      { "name": "diff_type", "type": "enum", "required": true, "values": ["text", "binary", "image"], "description": "Type of diff available" },
      { "name": "diff_summary", "type": "text", "required": false, "description": "Human-readable change summary" },
      { "name": "additions", "type": "integer", "required": false, "description": "Lines/sections added" },
      { "name": "deletions", "type": "integer", "required": false, "description": "Lines/sections removed" }
    ],
    "relationships": [
      { "entity": "Document", "type": "many_to_one", "required": true },
      { "entity": "DocumentVersion", "type": "many_to_one", "required": true }
    ],
    "notes": "Generated on-demand, not stored. Use diff libraries appropriate to file type."
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "documents.versioning",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.versioning.upload_new_version

```yaml
workflow:
  id: "wf.versioning.upload_new_version"
  name: "Upload New Version"
  trigger: "User uploads updated file for existing document"
  actors: ["User", "System"]

  steps:
    - step: 1
      name: "Select Document"
      actor: "User"
      action: "Choose document to update"
      inputs: ["Document"]
      outputs: ["Selected document"]

    - step: 2
      name: "Upload New File"
      actor: "User"
      action: "Provide new file content and optional change summary"
      inputs: ["New file", "Change summary (optional)"]
      outputs: ["Upload request"]

    - step: 3
      name: "Create Version Record"
      actor: "System"
      action: "Assign next version number, store file, create version record"
      inputs: ["Upload request", "Current version number"]
      outputs: ["New DocumentVersion (version_number = current + 1)"]
      automatable: true

    - step: 4
      name: "Update Current Version Pointer"
      actor: "System"
      action: "Set document.current_version_id to new version"
      inputs: ["Document", "New version"]
      outputs: ["Updated document"]
      automatable: true

    - step: 5
      name: "Notify Subscribers"
      actor: "System"
      action: "Alert users watching this document"
      inputs: ["Document", "New version"]
      outputs: ["Notifications sent"]
      automatable: true
```

#### wf.versioning.restore_version

```yaml
workflow:
  id: "wf.versioning.restore_version"
  name: "Restore Previous Version"
  trigger: "User requests to restore an older version"
  actors: ["User", "System"]

  steps:
    - step: 1
      name: "View Version History"
      actor: "User"
      action: "Browse available versions"
      inputs: ["Document"]
      outputs: ["Version list"]

    - step: 2
      name: "Select Version to Restore"
      actor: "User"
      action: "Choose version to make current"
      inputs: ["Version list"]
      outputs: ["Selected version"]

    - step: 3
      name: "Create Restoration Version"
      actor: "System"
      action: "Copy selected version content as new version (preserves history)"
      inputs: ["Selected version"]
      outputs: ["New version (copy of restored content)"]
      automatable: true
      notes: "Restoration creates a NEW version with the old content. We never modify history."

    - step: 4
      name: "Update Current Pointer"
      actor: "System"
      action: "Point document to restoration version"
      inputs: ["Document", "Restoration version"]
      outputs: ["Updated document"]
      automatable: true

    - step: 5
      name: "Log Restoration"
      actor: "System"
      action: "Record restoration in audit log"
      inputs: ["Document", "Restored from version", "Restored to version"]
      outputs: ["Audit entry"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-DOC-020 | **Simultaneous version uploads** | Medium | Accept both; later timestamp becomes current; both preserved |
| EC-DOC-021 | **Storage limit reached** | Medium | Warn user; allow archival of old versions |
| EC-DOC-022 | **Version restore for signed document** | High | Create new version but preserve signature on original; warn user |
| EC-DOC-023 | **Binary file comparison requested** | Low | Provide size/checksum diff only; no content diff for binaries |
| EC-DOC-024 | **Version deletion requested** | High | Generally disallow; admin override with audit trail only |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-DOC-008 | **Change summarization** | Version A content, Version B content | Natural language summary | Helps users understand changes |
| AI-DOC-009 | **Anomaly detection** | Version history patterns | Unusual activity alerts | Security monitoring |

---

## Package 4: Templates

### Purpose

Generate documents from templates using merge fields. Integrate with standard template engines (Handlebars, Mustache, Jinja2)—do not build custom template parsing.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What types of documents do you generate? (contracts, letters, reports)
- What data sources feed into templates? (client info, project data)
- Do you need conditional sections in templates?
- What output formats? (PDF, DOCX, HTML)

**Workflow Discovery**:
- Who creates/manages templates?
- How do users select which template to use?
- Do generated documents need review before sending?
- Can templates be versioned?

**Edge Case Probing**:
- What if merge data is missing a required field?
- Can users customize generated documents before finalizing?
- Do templates need approval workflows?

### Design Note: Use Existing Template Engines

**Do not build a custom template engine**. Leverage mature solutions:
- **Handlebars/Mustache** - Simple, logic-less templates
- **Jinja2** - More powerful with loops and conditionals
- **Docxtemplater** - Word document (.docx) templating
- **Carbone** - Excel, PowerPoint, and Word templating

Pick one and standardize. Template syntax should be familiar to users of these tools.

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
    "purpose": "Reusable document template with merge fields.",
    "fields": [
      { "name": "name", "type": "string", "required": true, "description": "Template name" },
      { "name": "description", "type": "text", "required": false, "description": "Template purpose/usage" },
      { "name": "template_type", "type": "enum", "required": true, "values": ["docx", "html", "pdf", "email"], "description": "Template format" },
      { "name": "template_key", "type": "string", "required": true, "description": "Blob storage key for template file" },
      { "name": "engine", "type": "enum", "required": true, "values": ["handlebars", "jinja2", "docxtemplater", "carbone"], "description": "Template engine to use" },
      { "name": "schema", "type": "json", "required": true, "description": "Expected merge fields and types" },
      { "name": "category", "type": "string", "required": false, "description": "Template category (contracts, letters, etc.)" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "active", "deprecated"], "description": "Template lifecycle status" },
      { "name": "owner_id", "type": "uuid", "required": true, "description": "Template owner/maintainer" },
      { "name": "version", "type": "integer", "required": true, "description": "Template version number" },
      { "name": "created_at", "type": "datetime", "required": true, "description": "Creation timestamp" },
      { "name": "updated_at", "type": "datetime", "required": true, "description": "Last update timestamp" }
    ],
    "relationships": [
      { "entity": "User", "type": "many_to_one", "required": true },
      { "entity": "GeneratedDocument", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "documents.templates",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### GeneratedDocument

```json
{
  "id": "data.templates.generated_document",
  "name": "Generated Document",
  "type": "data",
  "namespace": "templates",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Record of a document generated from a template.",
    "fields": [
      { "name": "template_id", "type": "uuid", "required": true, "description": "Source template" },
      { "name": "template_version", "type": "integer", "required": true, "description": "Template version used" },
      { "name": "document_id", "type": "uuid", "required": true, "description": "Resulting document" },
      { "name": "merge_data", "type": "json", "required": true, "description": "Data used for generation" },
      { "name": "generated_by", "type": "uuid", "required": true, "description": "User who generated" },
      { "name": "generated_at", "type": "datetime", "required": true, "description": "Generation timestamp" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "finalized", "sent"], "description": "Generated doc status" }
    ],
    "relationships": [
      { "entity": "Template", "type": "many_to_one", "required": true },
      { "entity": "Document", "type": "one_to_one", "required": true },
      { "entity": "User", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "documents.templates",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.templates.generate_document

```yaml
workflow:
  id: "wf.templates.generate_document"
  name: "Generate Document from Template"
  trigger: "User initiates document generation"
  actors: ["User", "System"]

  steps:
    - step: 1
      name: "Select Template"
      actor: "User"
      action: "Choose template from available options"
      inputs: ["Template category", "Search criteria"]
      outputs: ["Selected template"]

    - step: 2
      name: "Preview Required Fields"
      actor: "System"
      action: "Display merge fields and auto-populate from context"
      inputs: ["Template schema", "Context (client, project, etc.)"]
      outputs: ["Pre-filled merge form"]
      automatable: true

    - step: 3
      name: "Complete Merge Data"
      actor: "User"
      action: "Review and complete merge field values"
      inputs: ["Pre-filled merge form"]
      outputs: ["Complete merge data"]

    - step: 4
      name: "Generate Document"
      actor: "System"
      action: "Apply merge data to template using template engine"
      inputs: ["Template", "Merge data"]
      outputs: ["Generated document content"]
      automatable: true

    - step: 5
      name: "Preview Result"
      actor: "User"
      action: "Review generated document"
      inputs: ["Generated document content"]
      outputs: ["Approval or edit request"]
      decision_point: "Accept, edit, or regenerate?"

    - step: 6
      name: "Save as Document"
      actor: "System"
      action: "Create Document record, store in blob storage"
      inputs: ["Approved content", "Metadata"]
      outputs: ["Saved Document", "GeneratedDocument record"]
      automatable: true
```

#### wf.templates.manage_template

```yaml
workflow:
  id: "wf.templates.manage_template"
  name: "Create or Update Template"
  trigger: "Admin creates or updates a template"
  actors: ["Admin", "System"]

  steps:
    - step: 1
      name: "Upload Template File"
      actor: "Admin"
      action: "Upload template file (DOCX, HTML, etc.)"
      inputs: ["Template file"]
      outputs: ["Uploaded template"]

    - step: 2
      name: "Parse Template"
      actor: "System"
      action: "Extract merge fields from template"
      inputs: ["Uploaded template"]
      outputs: ["Detected fields"]
      automatable: true

    - step: 3
      name: "Define Schema"
      actor: "Admin"
      action: "Confirm fields, set required/optional, add descriptions"
      inputs: ["Detected fields"]
      outputs: ["Field schema"]

    - step: 4
      name: "Test Generation"
      actor: "Admin"
      action: "Generate test document with sample data"
      inputs: ["Template", "Sample data"]
      outputs: ["Test document"]

    - step: 5
      name: "Activate Template"
      actor: "Admin"
      action: "Set template status to active"
      inputs: ["Tested template"]
      outputs: ["Active template"]

    - step: 6
      name: "Version Previous"
      actor: "System"
      action: "If updating, archive previous version"
      inputs: ["Previous template version"]
      outputs: ["Archived version"]
      condition: "Updating existing template"
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-DOC-030 | **Required merge field missing** | Medium | Block generation; highlight missing fields |
| EC-DOC-031 | **Template engine error** | Medium | Log error details; show user-friendly message; allow retry |
| EC-DOC-032 | **Template deprecated after generation started** | Low | Complete with current version; log which version used |
| EC-DOC-033 | **Merge data contains HTML/scripts** | High | Sanitize input; escape special characters |
| EC-DOC-034 | **Generated document too large** | Low | Set size limits on merge data; warn before generation |
| EC-DOC-035 | **Template references deleted data source** | Medium | Show warning; allow manual data entry |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-DOC-010 | **Smart field population** | Context entities, field names | Suggested field values | Reduces manual entry |
| AI-DOC-011 | **Template recommendations** | Use case description | Matching templates | Helps find right template |
| AI-DOC-012 | **Content review** | Generated document | Issues, suggestions | Quality assurance |

---

## Package 5: Signatures

### Purpose

Collect legally binding electronic signatures on documents. Integrate with established e-signature providers (DocuSign, HelloSign/Dropbox Sign)—do not build custom signature infrastructure.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What types of documents require signatures? (contracts, agreements, forms)
- Do you need multiple signers on one document?
- What signer information do you collect? (name, email, title)
- Do you need signing order (sequential vs parallel)?

**Workflow Discovery**:
- Who initiates signature requests?
- How are signers notified? (email, SMS, in-app)
- What happens after all signatures collected?
- Do you need in-person signing support?

**Edge Case Probing**:
- What if a signer declines?
- Can the document be modified after some signatures?
- How long do signers have to complete?
- What if a signer's email bounces?

### Design Note: Integrate, Don't Build

**Do not build custom e-signature infrastructure**. Legal validity of e-signatures depends on:
- Audit trails proving signer identity
- Tamper-evident document sealing
- Compliance with e-signature laws (ESIGN, UETA, eIDAS)

Established providers (DocuSign, HelloSign, Adobe Sign) handle all of this. Your job is integration:
- Send documents to provider
- Track status via webhooks
- Store completed documents
- Maintain signature records

### Entity Templates

#### Signature

```json
{
  "id": "data.signatures.signature",
  "name": "Signature",
  "type": "data",
  "namespace": "signatures",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Record of an electronic signature on a document.",
    "fields": [
      { "name": "signature_request_id", "type": "uuid", "required": true, "description": "Parent signature request" },
      { "name": "signer_email", "type": "email", "required": true, "description": "Signer's email address" },
      { "name": "signer_name", "type": "string", "required": true, "description": "Signer's full name" },
      { "name": "signer_role", "type": "string", "required": false, "description": "Role/title (e.g., 'Client', 'Contractor')" },
      { "name": "status", "type": "enum", "required": true, "values": ["pending", "sent", "viewed", "signed", "declined", "expired"], "description": "Signature status" },
      { "name": "signing_order", "type": "integer", "required": false, "description": "Order in signing sequence (1, 2, 3...)" },
      { "name": "provider_signer_id", "type": "string", "required": false, "description": "E-sign provider's signer ID" },
      { "name": "signed_at", "type": "datetime", "required": false, "description": "When signature was applied" },
      { "name": "ip_address", "type": "string", "required": false, "description": "Signer's IP address (from provider)" },
      { "name": "declined_reason", "type": "text", "required": false, "description": "Reason if declined" }
    ],
    "relationships": [
      { "entity": "SignatureRequest", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "documents.signatures",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### SignatureRequest

```json
{
  "id": "data.signatures.signature_request",
  "name": "Signature Request",
  "type": "data",
  "namespace": "signatures",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Request for one or more signatures on a document.",
    "fields": [
      { "name": "document_id", "type": "uuid", "required": true, "description": "Document to be signed" },
      { "name": "title", "type": "string", "required": true, "description": "Request title/subject" },
      { "name": "message", "type": "text", "required": false, "description": "Message to signers" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "sent", "in_progress", "completed", "declined", "expired", "voided"], "description": "Overall request status" },
      { "name": "provider", "type": "enum", "required": true, "values": ["docusign", "hellosign", "adobesign"], "description": "E-signature provider" },
      { "name": "provider_request_id", "type": "string", "required": false, "description": "Provider's envelope/request ID" },
      { "name": "signing_order_type", "type": "enum", "required": true, "values": ["parallel", "sequential"], "description": "Parallel (all at once) or sequential" },
      { "name": "expires_at", "type": "datetime", "required": false, "description": "Request expiration date" },
      { "name": "reminder_frequency", "type": "enum", "required": false, "values": ["none", "daily", "weekly"], "description": "Reminder schedule" },
      { "name": "created_by", "type": "uuid", "required": true, "description": "User who initiated request" },
      { "name": "created_at", "type": "datetime", "required": true, "description": "Creation timestamp" },
      { "name": "completed_at", "type": "datetime", "required": false, "description": "When all signatures collected" }
    ],
    "relationships": [
      { "entity": "Document", "type": "many_to_one", "required": true },
      { "entity": "Signature", "type": "one_to_many", "required": true },
      { "entity": "User", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "documents.signatures",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### DocumentShare

```json
{
  "id": "data.signatures.document_share",
  "name": "Document Share",
  "type": "data",
  "namespace": "signatures",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Record of document shared with external or internal users.",
    "fields": [
      { "name": "document_id", "type": "uuid", "required": true, "description": "Shared document" },
      { "name": "share_type", "type": "enum", "required": true, "values": ["user", "email", "link"], "description": "Type of share" },
      { "name": "recipient_user_id", "type": "uuid", "required": false, "description": "Internal user (if user share)" },
      { "name": "recipient_email", "type": "email", "required": false, "description": "External email (if email share)" },
      { "name": "share_link", "type": "string", "required": false, "description": "Unique link (if link share)" },
      { "name": "permission", "type": "enum", "required": true, "values": ["view", "download", "edit"], "description": "Access level granted" },
      { "name": "expires_at", "type": "datetime", "required": false, "description": "Share expiration" },
      { "name": "password_protected", "type": "boolean", "required": false, "description": "Requires password to access" },
      { "name": "access_count", "type": "integer", "required": false, "description": "Number of times accessed" },
      { "name": "last_accessed_at", "type": "datetime", "required": false, "description": "Most recent access" },
      { "name": "created_by", "type": "uuid", "required": true, "description": "User who created share" },
      { "name": "created_at", "type": "datetime", "required": true, "description": "Share creation timestamp" },
      { "name": "revoked_at", "type": "datetime", "required": false, "description": "When share was revoked" }
    ],
    "relationships": [
      { "entity": "Document", "type": "many_to_one", "required": true },
      { "entity": "User", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "documents.signatures",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.signatures.request_signatures

```yaml
workflow:
  id: "wf.signatures.request_signatures"
  name: "Request Signatures on Document"
  trigger: "User initiates signature request"
  actors: ["User", "System", "E-Sign Provider", "Signer"]

  steps:
    - step: 1
      name: "Select Document"
      actor: "User"
      action: "Choose document requiring signatures"
      inputs: ["Document"]
      outputs: ["Selected document"]

    - step: 2
      name: "Add Signers"
      actor: "User"
      action: "Specify signers with email, name, role, order"
      inputs: ["Signer details"]
      outputs: ["Signer list"]

    - step: 3
      name: "Configure Request"
      actor: "User"
      action: "Set signing order, expiration, reminders, message"
      inputs: ["Configuration options"]
      outputs: ["Request configuration"]

    - step: 4
      name: "Place Signature Fields"
      actor: "User"
      action: "Mark where signatures and fields should appear"
      inputs: ["Document", "Field placements"]
      outputs: ["Annotated document"]
      decision_point: "Use template positions or custom?"

    - step: 5
      name: "Send to Provider"
      actor: "System"
      action: "Create envelope/request in e-sign provider"
      inputs: ["Document", "Signers", "Configuration"]
      outputs: ["Provider request ID"]
      automatable: true

    - step: 6
      name: "Notify Signers"
      actor: "E-Sign Provider"
      action: "Send signing invitations"
      inputs: ["Signer emails"]
      outputs: ["Invitations sent"]
      automatable: true

    - step: 7
      name: "Track Progress"
      actor: "System"
      action: "Receive webhooks for status updates"
      inputs: ["Provider webhooks"]
      outputs: ["Updated signature statuses"]
      automatable: true
```

#### wf.signatures.process_completion

```yaml
workflow:
  id: "wf.signatures.process_completion"
  name: "Process Completed Signatures"
  trigger: "All signers have signed (webhook from provider)"
  actors: ["System", "E-Sign Provider"]

  steps:
    - step: 1
      name: "Receive Completion Webhook"
      actor: "System"
      action: "Receive notification all signatures collected"
      inputs: ["Provider webhook"]
      outputs: ["Completion event"]
      automatable: true

    - step: 2
      name: "Download Signed Document"
      actor: "System"
      action: "Retrieve signed PDF from provider"
      inputs: ["Provider request ID"]
      outputs: ["Signed document"]
      automatable: true

    - step: 3
      name: "Download Audit Trail"
      actor: "System"
      action: "Retrieve certificate of completion"
      inputs: ["Provider request ID"]
      outputs: ["Audit trail PDF"]
      automatable: true

    - step: 4
      name: "Create New Version"
      actor: "System"
      action: "Store signed document as new version"
      inputs: ["Original document", "Signed document"]
      outputs: ["Document version (signed)"]
      automatable: true

    - step: 5
      name: "Update Status"
      actor: "System"
      action: "Mark signature request as completed"
      inputs: ["Signature request"]
      outputs: ["Completed status"]
      automatable: true

    - step: 6
      name: "Notify Parties"
      actor: "System"
      action: "Send completion notification with signed copy"
      inputs: ["Signers", "Requester", "Signed document"]
      outputs: ["Notifications sent"]
      automatable: true

    - step: 7
      name: "Trigger Downstream Workflows"
      actor: "System"
      action: "Fire events for dependent processes"
      inputs: ["Completed signature request"]
      outputs: ["Workflow triggers"]
      automatable: true
      notes: "E.g., activate contract, create project, start billing"
```

#### wf.signatures.handle_decline

```yaml
workflow:
  id: "wf.signatures.handle_decline"
  name: "Handle Signature Decline"
  trigger: "Signer declines to sign"
  actors: ["System", "User"]

  steps:
    - step: 1
      name: "Receive Decline Webhook"
      actor: "System"
      action: "Receive notification of decline"
      inputs: ["Provider webhook", "Decline reason"]
      outputs: ["Decline event"]
      automatable: true

    - step: 2
      name: "Update Status"
      actor: "System"
      action: "Mark signer as declined, request as declined"
      inputs: ["Signature", "Signature request"]
      outputs: ["Updated statuses"]
      automatable: true

    - step: 3
      name: "Notify Requester"
      actor: "System"
      action: "Alert user who initiated request"
      inputs: ["Requester", "Decline details"]
      outputs: ["Notification sent"]
      automatable: true

    - step: 4
      name: "Review and Decide"
      actor: "User"
      action: "Assess reason, decide next steps"
      inputs: ["Decline details"]
      outputs: ["Decision"]
      decision_point: "Modify document? New signer? Cancel request?"

    - step: 5a
      name: "Void and Recreate"
      actor: "User"
      action: "Void current request, create new one"
      inputs: ["Modified document or signers"]
      outputs: ["New signature request"]
      condition: "Retry with changes"

    - step: 5b
      name: "Close Request"
      actor: "User"
      action: "Accept decline, close request"
      inputs: ["Declined request"]
      outputs: ["Closed request"]
      condition: "Accept decline"
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-DOC-040 | **Signer email bounces** | Medium | Notify requester; allow email correction and resend |
| EC-DOC-041 | **Signer requests document change** | Medium | Void current request; modify document; create new request |
| EC-DOC-042 | **Request expires before completion** | Medium | Notify all parties; allow extension or void |
| EC-DOC-043 | **Provider webhook fails** | High | Implement retry with backoff; manual status check fallback |
| EC-DOC-044 | **Sequential signer unavailable** | Medium | Allow skip (if configured) or substitution |
| EC-DOC-045 | **Document modified after request sent** | High | Prevent modification; require void and new request |
| EC-DOC-046 | **Provider service outage** | High | Queue requests; retry when available; notify users of delay |
| EC-DOC-047 | **Partial completion then void** | Medium | All signatures invalid; start fresh; audit trail preserved |
| EC-DOC-048 | **Duplicate signature request** | Low | Warn before sending; allow if intentional (different signers) |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-DOC-013 | **Signer extraction** | Document content | Identified signers and roles | Auto-populate signer list |
| AI-DOC-014 | **Field placement** | Document, signer roles | Suggested signature field positions | Speeds setup |
| AI-DOC-015 | **Completion prediction** | Historical signing patterns | Expected completion time | Sets expectations |

---

## Cross-Package Relationships

The Documents module packages interconnect to provide complete document lifecycle management:

```
                    ┌─────────────────────────────────────────────┐
                    │                STORAGE                       │
                    │  (Core document upload, retrieval, metadata) │
                    └─────────────────┬───────────────────────────┘
                                      │
              ┌───────────────────────┼───────────────────────┐
              │                       │                       │
              ▼                       ▼                       ▼
┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│    ORGANIZATION     │  │     VERSIONING      │  │     TEMPLATES       │
│ (Folders and tags)  │  │ (Version history)   │  │ (Document gen)      │
└─────────────────────┘  └─────────────────────┘  └──────────┬──────────┘
                                      │                       │
                                      │                       │
                                      ▼                       │
                         ┌─────────────────────┐              │
                         │     SIGNATURES      │◄─────────────┘
                         │ (E-sign collection) │
                         └─────────────────────┘
```

### Key Integration Points Within Documents

| From | To | Integration |
|------|-----|-------------|
| Storage | Versioning | Upload creates version; version references storage |
| Storage | Organization | Document placed in folder; tagged |
| Templates | Storage | Generated document stored as new Document |
| Templates | Signatures | Generated contracts sent for signature |
| Signatures | Versioning | Signed document becomes new version |
| Organization | Storage | Folder deletion affects documents |

---

## Integration Points (External Systems)

### Blob Storage Providers

| System | Use Case | Notes |
|--------|----------|-------|
| **AWS S3** | Primary storage | Most common; excellent SDK |
| **Google Cloud Storage** | Primary storage | Good for GCP shops |
| **Azure Blob Storage** | Primary storage | Good for Microsoft shops |
| **MinIO** | Self-hosted S3-compatible | For on-premises requirements |
| **Cloudflare R2** | Edge storage | S3-compatible; no egress fees |

### CDN Providers

| System | Use Case | Notes |
|--------|----------|-------|
| **CloudFront** | Pairs with S3 | Signed URLs for private content |
| **Cloudflare** | Edge delivery | Easy setup; good performance |
| **Fastly** | Enterprise CDN | Real-time purging |

### E-Signature Providers

| System | Use Case | Notes |
|--------|----------|-------|
| **DocuSign** | Enterprise e-signatures | Market leader; full-featured |
| **HelloSign (Dropbox Sign)** | SMB e-signatures | Developer-friendly; simpler |
| **Adobe Sign** | Enterprise, PDF-native | Good for Adobe ecosystem |
| **PandaDoc** | Document + signatures | Combined template + signing |

### Template Engines

| System | Use Case | Notes |
|--------|----------|-------|
| **Handlebars** | Simple merge | Logic-less; safe |
| **Jinja2** | Complex templates | Loops, conditionals; Python |
| **Docxtemplater** | Word documents | .docx manipulation |
| **Carbone** | Office documents | Word, Excel, PowerPoint |

### Search and OCR

| System | Use Case | Notes |
|--------|----------|-------|
| **Elasticsearch** | Full-text search | Powerful; complex |
| **Algolia** | Search-as-a-service | Easy setup; hosted |
| **Typesense** | Simple search | Open source; easy |
| **Google Vision** | OCR | High accuracy |
| **AWS Textract** | Document OCR | Forms and tables |

### Preview Services

| System | Use Case | Notes |
|--------|----------|-------|
| **PDF.js** | PDF preview | Client-side; open source |
| **Google Docs Viewer** | Multiple formats | Hosted; limited |
| **Aspose** | Document conversion | Commercial; comprehensive |
| **LibreOffice** | Server-side conversion | Open source; self-hosted |

---

## Compliance Considerations

### Data Privacy (GDPR, CCPA)

| Requirement | Implementation |
|-------------|----------------|
| Data minimization | Only store necessary metadata |
| Right to deletion | Implement true deletion (not just soft delete) |
| Access logs | Track who accessed what and when |
| Data portability | Export in standard formats |
| Consent tracking | Log consent for document sharing |

### Document Retention

| Area | Retention | Notes |
|------|-----------|-------|
| Contracts | 7+ years after expiration | May vary by jurisdiction |
| Financial documents | 7 years | Tax and audit requirements |
| Employment documents | 7 years after termination | Labor law compliance |
| Legal correspondence | Varies | Follow litigation hold requirements |
| General business | Per policy | Define and document retention schedule |

### E-Signature Compliance

| Regulation | Coverage | Notes |
|------------|----------|-------|
| **ESIGN Act** (US) | Electronic signatures in commerce | Federal law; broad validity |
| **UETA** (US) | State-level e-signature law | Adopted by most states |
| **eIDAS** (EU) | European e-signature regulation | Three levels of signature validity |
| **Industry-specific** | HIPAA, SEC, etc. | Additional requirements may apply |

**Best Practice**: Let e-signature providers handle compliance. DocuSign, HelloSign, and Adobe Sign are designed for legal validity.

### Audit Requirements

| Area | Requirement | Notes |
|------|-------------|-------|
| Access logging | Who viewed/downloaded when | Immutable logs |
| Change tracking | All modifications recorded | Version history |
| Signature audit trail | Complete signing record | Provider supplies |
| Retention compliance | Enforce minimum retention | Block premature deletion |

---

## Quick Reference

### Entity Summary

| Package | Core Entities | Supporting Entities |
|---------|---------------|---------------------|
| Storage | Document, DocumentVersion | - |
| Organization | Folder, Tag | DocumentTag |
| Versioning | (uses DocumentVersion) | VersionComparison (view) |
| Templates | Template, GeneratedDocument | - |
| Signatures | Signature, SignatureRequest | DocumentShare |

### Workflow Summary

| ID | Workflow | Trigger |
|----|----------|---------|
| wf.storage.upload_document | Upload Document | User initiates upload |
| wf.storage.delete_document | Delete Document | User requests deletion |
| wf.organization.create_folder_structure | Create Folder Structure | New project/client created |
| wf.organization.bulk_tag_documents | Bulk Tag Documents | User selects multiple docs |
| wf.versioning.upload_new_version | Upload New Version | User updates document |
| wf.versioning.restore_version | Restore Previous Version | User requests restore |
| wf.templates.generate_document | Generate Document | User initiates generation |
| wf.templates.manage_template | Manage Template | Admin creates/updates template |
| wf.signatures.request_signatures | Request Signatures | User initiates signing |
| wf.signatures.process_completion | Process Completion | All signers complete |
| wf.signatures.handle_decline | Handle Decline | Signer declines |

### Common Edge Case Themes

1. **Upload failures** - Network issues, size limits, virus detection
2. **Concurrent access** - Multiple users editing/versioning
3. **External dependencies** - E-sign provider outages, storage failures
4. **Retention conflicts** - Deletion requests vs compliance requirements
5. **Permission boundaries** - Share expiration, access revocation
6. **Status transitions** - Invalid state changes (signing deleted doc)
7. **Integration failures** - Webhook delivery, API timeouts

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-05 | Initial release |
