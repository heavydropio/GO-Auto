# Inventory Module Catalog

**Module**: Inventory
**Version**: 1.0
**Last Updated**: {{ ISO_DATE }}

---

## Overview

The Inventory module covers all stock management within an application: tracking what's on hand, where it's located, how it moves, and maintaining accurate quantity records. This module is foundational for any business that handles physical goods, manages warehouses, or needs to track stock levels across locations.

### Core Principle

**The transaction ledger is the source of truth.** StockLevel is a cached sum derived from StockTransaction records. Never calculate stock on-the-fly in production queries, and never allow mutable transactions.

### When to Use This Module

Select this module when R1 context includes any of:

| Trigger Phrases | Typical Actors | Business Need |
|-----------------|----------------|---------------|
| "inventory", "stock", "on-hand", "quantity" | Warehouse staff, Inventory manager | Track physical goods quantities |
| "warehouse", "location", "bin", "zone" | Warehouse staff, Operations | Organize and locate products |
| "receiving", "goods receipt", "inbound" | Receiving clerk, Warehouse | Process incoming shipments |
| "cycle count", "physical count", "stocktake" | Inventory staff, Auditor | Verify and correct stock records |
| "transfer", "move", "relocate" | Warehouse staff | Move stock between locations |
| "lot number", "batch", "serial number" | Quality, Compliance | Track product traceability |
| "reorder", "replenishment", "min/max" | Purchasing, Planning | Automate stock replenishment |

### Module Dependencies

```
Inventory Module
├── REQUIRES: Administrative (for settings, units of measure)
├── REQUIRES: Documents (for receiving docs, count sheets)
├── INTEGRATES_WITH: Purchasing (purchase orders, receipts)
├── INTEGRATES_WITH: Sales (available-to-promise, reservations)
├── INTEGRATES_WITH: Manufacturing (BOM consumption, work orders)
├── INTEGRATES_WITH: Financial (inventory valuation, COGS)
```

---

## Packages

This module contains 5 packages:

1. **stock_management** - Core stock tracking and transactions
2. **locations** - Warehouse structure and bin management
3. **receiving** - Inbound goods processing
4. **counting** - Cycle counts and physical inventory
5. **transfers** - Inter-location stock movement

---

## Package 1: Stock Management

### Purpose

Track item quantities through an immutable transaction ledger. Maintain accurate stock levels as cached sums. Support lot tracking, serial tracking, and multiple valuation methods.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What items do you track inventory for? (finished goods, raw materials, supplies)
- Do you track by lot/batch number? (for expiry, traceability)
- Do you track by serial number? (for individual unit tracking)
- What unit of measure variations exist? (each, case, pallet)
- Do you need multiple valuation methods? (FIFO, LIFO, weighted average)

**Workflow Discovery**:
- What triggers a stock transaction? (receipt, sale, adjustment, transfer)
- Who can make inventory adjustments?
- How do you handle negative inventory situations?
- What approval is needed for adjustments above a threshold?

**Edge Case Probing**:
- Can stock go negative? Under what circumstances?
- How do you handle items with multiple units of measure?
- What happens when a lot expires?
- How do you handle inventory valuation during price changes?

### Entity Templates

#### Item

```json
{
  "id": "data.stock_management.item",
  "name": "Item",
  "type": "data",
  "namespace": "stock_management",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Master record for a stockable product or material.",
    "fields": [
      { "name": "sku", "type": "string", "required": true, "description": "Unique stock keeping unit identifier" },
      { "name": "name", "type": "string", "required": true, "description": "Item name/description" },
      { "name": "item_type", "type": "enum", "required": true, "values": ["finished_good", "raw_material", "component", "consumable", "service"], "description": "Classification of item" },
      { "name": "base_uom", "type": "string", "required": true, "description": "Base unit of measure (each, kg, liter)" },
      { "name": "tracking_type", "type": "enum", "required": true, "values": ["none", "lot", "serial"], "description": "How individual units are tracked" },
      { "name": "category_id", "type": "uuid", "required": false, "description": "Product category for grouping" },
      { "name": "barcode", "type": "string", "required": false, "description": "Primary barcode (UPC, EAN)" },
      { "name": "weight", "type": "decimal", "required": false, "description": "Unit weight for shipping calculations" },
      { "name": "weight_uom", "type": "string", "required": false, "description": "Weight unit (kg, lb)" },
      { "name": "dimensions", "type": "json", "required": false, "description": "Length, width, height for storage planning" },
      { "name": "shelf_life_days", "type": "integer", "required": false, "description": "Days until expiry from manufacture date" },
      { "name": "reorder_point", "type": "decimal", "required": false, "description": "Quantity triggering reorder alert" },
      { "name": "reorder_quantity", "type": "decimal", "required": false, "description": "Standard reorder amount" },
      { "name": "min_stock", "type": "decimal", "required": false, "description": "Minimum stock level to maintain" },
      { "name": "max_stock", "type": "decimal", "required": false, "description": "Maximum stock level" },
      { "name": "standard_cost", "type": "decimal", "required": false, "description": "Standard unit cost for valuation" },
      { "name": "valuation_method", "type": "enum", "required": false, "values": ["fifo", "lifo", "weighted_avg", "standard"], "description": "Cost flow assumption" },
      { "name": "active", "type": "boolean", "required": true, "description": "Whether item can be transacted" }
    ],
    "relationships": [
      { "entity": "ItemCategory", "type": "many_to_one", "required": false },
      { "entity": "StockLevel", "type": "one_to_many", "required": false },
      { "entity": "StockTransaction", "type": "one_to_many", "required": false },
      { "entity": "UnitConversion", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "inventory.stock_management",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### StockLevel

```json
{
  "id": "data.stock_management.stock_level",
  "name": "Stock Level",
  "type": "data",
  "namespace": "stock_management",
  "tags": ["core-entity", "mvp", "derived"],
  "status": "discovered",

  "spec": {
    "purpose": "Cached quantity of an item at a location. Derived from sum of StockTransaction records.",
    "fields": [
      { "name": "item_id", "type": "uuid", "required": true, "description": "Item being tracked" },
      { "name": "location_id", "type": "uuid", "required": true, "description": "Storage location" },
      { "name": "lot_id", "type": "uuid", "required": false, "description": "Lot/batch if lot-tracked" },
      { "name": "quantity_on_hand", "type": "decimal", "required": true, "description": "Physical quantity available" },
      { "name": "quantity_reserved", "type": "decimal", "required": true, "description": "Quantity allocated to orders" },
      { "name": "quantity_available", "type": "decimal", "required": true, "description": "On hand minus reserved (ATP)" },
      { "name": "quantity_incoming", "type": "decimal", "required": false, "description": "Expected from open POs" },
      { "name": "last_movement_at", "type": "datetime", "required": false, "description": "Timestamp of last transaction" },
      { "name": "last_count_at", "type": "datetime", "required": false, "description": "Timestamp of last cycle count" },
      { "name": "unit_cost", "type": "decimal", "required": false, "description": "Current unit cost for valuation" },
      { "name": "total_value", "type": "decimal", "required": false, "description": "quantity_on_hand * unit_cost" }
    ],
    "relationships": [
      { "entity": "Item", "type": "many_to_one", "required": true },
      { "entity": "Location", "type": "many_to_one", "required": true },
      { "entity": "Lot", "type": "many_to_one", "required": false }
    ],
    "notes": "This is a derived/cached entity. The true source of inventory is the StockTransaction ledger. StockLevel should be recalculable from transactions at any time."
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "inventory.stock_management",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### StockTransaction

```json
{
  "id": "data.stock_management.stock_transaction",
  "name": "Stock Transaction",
  "type": "data",
  "namespace": "stock_management",
  "tags": ["core-entity", "mvp", "immutable", "auditable"],
  "status": "discovered",

  "spec": {
    "purpose": "Immutable record of inventory movement. Source of truth for all stock calculations.",
    "fields": [
      { "name": "transaction_number", "type": "string", "required": true, "description": "Unique transaction identifier" },
      { "name": "transaction_type", "type": "enum", "required": true, "values": ["receipt", "issue", "adjustment_in", "adjustment_out", "transfer_out", "transfer_in", "count_adjustment", "return", "scrap"], "description": "Type of movement" },
      { "name": "item_id", "type": "uuid", "required": true, "description": "Item being transacted" },
      { "name": "location_id", "type": "uuid", "required": true, "description": "Location affected" },
      { "name": "lot_id", "type": "uuid", "required": false, "description": "Lot/batch if tracked" },
      { "name": "serial_number", "type": "string", "required": false, "description": "Serial number if tracked" },
      { "name": "quantity", "type": "decimal", "required": true, "description": "Quantity moved (positive=in, negative=out)" },
      { "name": "uom", "type": "string", "required": true, "description": "Unit of measure" },
      { "name": "unit_cost", "type": "decimal", "required": false, "description": "Cost per unit at transaction time" },
      { "name": "total_cost", "type": "decimal", "required": false, "description": "quantity * unit_cost" },
      { "name": "reference_type", "type": "string", "required": false, "description": "Source document type (PO, SO, WO, etc.)" },
      { "name": "reference_id", "type": "uuid", "required": false, "description": "Source document ID" },
      { "name": "reason_code", "type": "string", "required": false, "description": "Reason for adjustment transactions" },
      { "name": "notes", "type": "text", "required": false, "description": "Transaction notes" },
      { "name": "created_by", "type": "uuid", "required": true, "description": "User who created transaction" },
      { "name": "created_at", "type": "datetime", "required": true, "description": "Transaction timestamp" }
    ],
    "relationships": [
      { "entity": "Item", "type": "many_to_one", "required": true },
      { "entity": "Location", "type": "many_to_one", "required": true },
      { "entity": "Lot", "type": "many_to_one", "required": false },
      { "entity": "User", "type": "many_to_one", "required": true }
    ],
    "notes": "NEVER update or delete transaction records. All corrections must be made via new offsetting transactions. This ensures complete audit trail and recalculability."
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "inventory.stock_management",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Lot

```json
{
  "id": "data.stock_management.lot",
  "name": "Lot",
  "type": "data",
  "namespace": "stock_management",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Batch/lot information for traceability and expiry tracking.",
    "fields": [
      { "name": "lot_number", "type": "string", "required": true, "description": "Unique lot/batch identifier" },
      { "name": "item_id", "type": "uuid", "required": true, "description": "Item this lot belongs to" },
      { "name": "manufacture_date", "type": "date", "required": false, "description": "Date of manufacture" },
      { "name": "expiry_date", "type": "date", "required": false, "description": "Expiration date" },
      { "name": "supplier_lot", "type": "string", "required": false, "description": "Supplier's lot number" },
      { "name": "supplier_id", "type": "uuid", "required": false, "description": "Supplier who provided this lot" },
      { "name": "received_date", "type": "date", "required": false, "description": "Date lot was received" },
      { "name": "certificate_number", "type": "string", "required": false, "description": "Quality certificate reference" },
      { "name": "status", "type": "enum", "required": true, "values": ["available", "quarantine", "hold", "expired", "recalled"], "description": "Lot availability status" },
      { "name": "notes", "type": "text", "required": false, "description": "Lot-specific notes" }
    ],
    "relationships": [
      { "entity": "Item", "type": "many_to_one", "required": true },
      { "entity": "Supplier", "type": "many_to_one", "required": false },
      { "entity": "StockLevel", "type": "one_to_many", "required": false },
      { "entity": "StockTransaction", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "inventory.stock_management",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### UnitConversion

```json
{
  "id": "data.stock_management.unit_conversion",
  "name": "Unit Conversion",
  "type": "data",
  "namespace": "stock_management",
  "tags": ["configuration"],
  "status": "discovered",

  "spec": {
    "purpose": "Defines conversion factors between units of measure for an item.",
    "fields": [
      { "name": "item_id", "type": "uuid", "required": true, "description": "Item this conversion applies to" },
      { "name": "from_uom", "type": "string", "required": true, "description": "Source unit of measure" },
      { "name": "to_uom", "type": "string", "required": true, "description": "Target unit of measure" },
      { "name": "conversion_factor", "type": "decimal", "required": true, "description": "Multiply by this to convert (e.g., 12 for case->each)" },
      { "name": "is_default_purchase", "type": "boolean", "required": false, "description": "Default UOM for purchasing" },
      { "name": "is_default_sales", "type": "boolean", "required": false, "description": "Default UOM for sales" }
    ],
    "relationships": [
      { "entity": "Item", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "inventory.stock_management",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### WF-STK-001: Inventory Adjustment

```yaml
workflow:
  id: "wf.stock_management.adjustment"
  name: "Inventory Adjustment"
  trigger: "Discrepancy discovered or damage reported"
  actors: ["Warehouse Staff", "Inventory Manager", "System"]

  steps:
    - step: 1
      name: "Initiate Adjustment"
      actor: "Warehouse Staff"
      action: "Create adjustment request with reason"
      inputs: ["Item", "Location", "Current quantity", "New quantity", "Reason"]
      outputs: ["Adjustment request"]

    - step: 2
      name: "Calculate Variance"
      actor: "System"
      action: "Compute quantity difference and value impact"
      inputs: ["Adjustment request", "Current stock level", "Unit cost"]
      outputs: ["Variance calculation"]
      automatable: true

    - step: 3
      name: "Approval Check"
      actor: "System"
      action: "Determine if approval required based on value threshold"
      inputs: ["Variance calculation", "Approval thresholds"]
      outputs: ["Approval requirement"]
      decision_point: "Within auto-approve threshold?"
      automatable: true

    - step: 4a
      name: "Auto-Approve"
      actor: "System"
      action: "Approve adjustment within threshold"
      inputs: ["Adjustment request"]
      outputs: ["Approved adjustment"]
      condition: "Within auto-approve threshold"
      automatable: true

    - step: 4b
      name: "Manager Approval"
      actor: "Inventory Manager"
      action: "Review and approve/reject adjustment"
      inputs: ["Adjustment request", "Variance calculation"]
      outputs: ["Approval decision"]
      condition: "Exceeds auto-approve threshold"
      decision_point: "Approve? Reject? Request investigation?"

    - step: 5
      name: "Create Transaction"
      actor: "System"
      action: "Create immutable adjustment transaction"
      inputs: ["Approved adjustment"]
      outputs: ["StockTransaction record"]
      automatable: true

    - step: 6
      name: "Update Stock Level"
      actor: "System"
      action: "Recalculate cached stock level"
      inputs: ["StockTransaction"]
      outputs: ["Updated StockLevel"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Detection | Resolution |
|----|----------|------------|-----------|------------|
| EC-STK-001 | **Negative inventory attempted** | High | Validate before transaction | Block or require override with reason; consider backorder |
| EC-STK-002 | **Item tracked by lot but lot not specified** | Medium | Validation rule | Require lot selection; auto-select FIFO if configured |
| EC-STK-003 | **Serial number already exists** | High | Unique constraint | Reject duplicate; investigate source |
| EC-STK-004 | **Unit of measure mismatch** | Medium | Compare to item base UOM | Auto-convert using conversion factor; warn if no conversion |
| EC-STK-005 | **Transaction backdated** | Medium | Date validation | Require approval for backdated entries; recalculate affected periods |
| EC-STK-006 | **Expired lot consumed** | High | Expiry check on issue | Warn/block based on config; require override approval |
| EC-STK-007 | **Valuation mismatch during period close** | High | Reconciliation report | Investigate transactions; may need adjustment entries |
| EC-STK-008 | **Concurrent transactions on same stock** | Medium | Optimistic locking | Retry with current values; serialize if needed |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-STK-001 | **Demand forecasting** | Historical transactions, seasonality | Predicted demand by item/location | Better reorder planning |
| AI-STK-002 | **Anomaly detection** | Transaction patterns | Unusual movement alerts | Catches theft, errors early |
| AI-STK-003 | **Optimal reorder point** | Lead times, demand variability, service level | Recommended min/max | Reduces stockouts and overstock |
| AI-STK-004 | **Lot selection** | FIFO/FEFO rules, customer requirements | Recommended lot for picking | Reduces expiry waste |

---

## Package 2: Locations

### Purpose

Define warehouse structure including zones, aisles, racks, and bins. Support multiple warehouses with different configurations.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- How many warehouses/locations do you have?
- What's your warehouse layout? (zones, aisles, racks, bins)
- Do you have special storage areas? (refrigerated, hazmat, secure)
- Do you use bin locations or just warehouse-level tracking?

**Workflow Discovery**:
- How do you assign items to locations?
- Can items be stored in multiple locations?
- How do you handle location capacity?
- Do you use directed putaway rules?

**Edge Case Probing**:
- What if a location is full?
- How do you handle location merges/splits?
- What about temporary staging areas?

### Entity Templates

#### Location

```json
{
  "id": "data.locations.location",
  "name": "Location",
  "type": "data",
  "namespace": "locations",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Physical storage location within a warehouse.",
    "fields": [
      { "name": "location_code", "type": "string", "required": true, "description": "Unique location identifier (e.g., WH01-A-01-01)" },
      { "name": "name", "type": "string", "required": false, "description": "Human-readable name" },
      { "name": "warehouse_id", "type": "uuid", "required": true, "description": "Parent warehouse" },
      { "name": "zone_id", "type": "uuid", "required": false, "description": "Parent zone within warehouse" },
      { "name": "location_type", "type": "enum", "required": true, "values": ["storage", "receiving", "shipping", "staging", "production", "quality", "returns"], "description": "Purpose of location" },
      { "name": "aisle", "type": "string", "required": false, "description": "Aisle identifier" },
      { "name": "rack", "type": "string", "required": false, "description": "Rack identifier" },
      { "name": "level", "type": "string", "required": false, "description": "Shelf level" },
      { "name": "bin", "type": "string", "required": false, "description": "Bin position" },
      { "name": "capacity", "type": "decimal", "required": false, "description": "Maximum storage capacity" },
      { "name": "capacity_uom", "type": "string", "required": false, "description": "Capacity unit (cubic ft, pallets)" },
      { "name": "weight_capacity", "type": "decimal", "required": false, "description": "Maximum weight capacity" },
      { "name": "storage_class", "type": "enum", "required": false, "values": ["ambient", "refrigerated", "frozen", "hazmat", "secure", "bulk"], "description": "Storage requirements" },
      { "name": "pickable", "type": "boolean", "required": true, "description": "Can pick from this location" },
      { "name": "receivable", "type": "boolean", "required": true, "description": "Can receive into this location" },
      { "name": "active", "type": "boolean", "required": true, "description": "Location is in use" },
      { "name": "sequence", "type": "integer", "required": false, "description": "Pick sequence for routing" }
    ],
    "relationships": [
      { "entity": "Warehouse", "type": "many_to_one", "required": true },
      { "entity": "Zone", "type": "many_to_one", "required": false },
      { "entity": "StockLevel", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "inventory.locations",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Warehouse

```json
{
  "id": "data.locations.warehouse",
  "name": "Warehouse",
  "type": "data",
  "namespace": "locations",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Physical facility for storing inventory.",
    "fields": [
      { "name": "code", "type": "string", "required": true, "description": "Unique warehouse code (e.g., WH01)" },
      { "name": "name", "type": "string", "required": true, "description": "Warehouse name" },
      { "name": "address", "type": "address", "required": true, "description": "Physical address" },
      { "name": "warehouse_type", "type": "enum", "required": false, "values": ["distribution", "manufacturing", "retail", "third_party"], "description": "Type of facility" },
      { "name": "timezone", "type": "string", "required": true, "description": "Timezone for operations" },
      { "name": "manager_id", "type": "uuid", "required": false, "description": "Warehouse manager" },
      { "name": "phone", "type": "phone", "required": false, "description": "Contact phone" },
      { "name": "email", "type": "email", "required": false, "description": "Contact email" },
      { "name": "operating_hours", "type": "json", "required": false, "description": "Operating schedule" },
      { "name": "active", "type": "boolean", "required": true, "description": "Warehouse is operational" }
    ],
    "relationships": [
      { "entity": "Location", "type": "one_to_many", "required": false },
      { "entity": "Zone", "type": "one_to_many", "required": false },
      { "entity": "User", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "inventory.locations",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Zone

```json
{
  "id": "data.locations.zone",
  "name": "Zone",
  "type": "data",
  "namespace": "locations",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Logical grouping of locations within a warehouse.",
    "fields": [
      { "name": "code", "type": "string", "required": true, "description": "Zone code (e.g., PICK, BULK, RECV)" },
      { "name": "name", "type": "string", "required": true, "description": "Zone name" },
      { "name": "warehouse_id", "type": "uuid", "required": true, "description": "Parent warehouse" },
      { "name": "zone_type", "type": "enum", "required": false, "values": ["pick", "bulk", "reserve", "receiving", "shipping", "returns", "hazmat"], "description": "Zone purpose" },
      { "name": "storage_class", "type": "enum", "required": false, "values": ["ambient", "refrigerated", "frozen", "hazmat", "secure"], "description": "Storage conditions" },
      { "name": "replenish_from_zone_id", "type": "uuid", "required": false, "description": "Zone to replenish from" },
      { "name": "pick_sequence", "type": "integer", "required": false, "description": "Order for pick routing" }
    ],
    "relationships": [
      { "entity": "Warehouse", "type": "many_to_one", "required": true },
      { "entity": "Location", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "inventory.locations",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### WF-LOC-001: Directed Putaway

```yaml
workflow:
  id: "wf.locations.directed_putaway"
  name: "Directed Putaway"
  trigger: "Items received need storage location"
  actors: ["System", "Warehouse Staff"]

  steps:
    - step: 1
      name: "Analyze Item Requirements"
      actor: "System"
      action: "Check item storage class, size, weight"
      inputs: ["Item", "Received quantity"]
      outputs: ["Storage requirements"]
      automatable: true

    - step: 2
      name: "Find Available Locations"
      actor: "System"
      action: "Query locations matching requirements with capacity"
      inputs: ["Storage requirements", "Warehouse zones"]
      outputs: ["Candidate locations"]
      automatable: true

    - step: 3
      name: "Apply Putaway Rules"
      actor: "System"
      action: "Score locations by rules (consolidate, velocity, FIFO)"
      inputs: ["Candidate locations", "Putaway rules", "Existing stock"]
      outputs: ["Ranked locations"]
      automatable: true

    - step: 4
      name: "Assign Location"
      actor: "System"
      action: "Select optimal location or split across multiple"
      inputs: ["Ranked locations"]
      outputs: ["Putaway task"]
      automatable: true

    - step: 5
      name: "Execute Putaway"
      actor: "Warehouse Staff"
      action: "Move goods to assigned location, confirm"
      inputs: ["Putaway task"]
      outputs: ["Putaway confirmation"]

    - step: 6
      name: "Update Stock"
      actor: "System"
      action: "Create transaction and update stock level"
      inputs: ["Putaway confirmation"]
      outputs: ["StockTransaction", "Updated StockLevel"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Detection | Resolution |
|----|----------|------------|-----------|------------|
| EC-LOC-001 | **No available location for item** | High | Putaway rule returns empty | Suggest overflow zone; alert supervisor |
| EC-LOC-002 | **Location capacity exceeded** | Medium | Capacity check | Warn and allow override or suggest alternative |
| EC-LOC-003 | **Mixed lots in same location** | Medium | Lot check during putaway | Allow based on config; flag for FIFO tracking |
| EC-LOC-004 | **Location deactivated with stock** | High | Pre-deactivation check | Require stock transfer before deactivation |
| EC-LOC-005 | **Storage class mismatch** | High | Item vs location class | Block putaway; require appropriate location |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-LOC-001 | **Slotting optimization** | Pick patterns, item velocity | Recommended location assignments | Reduces pick travel time |
| AI-LOC-002 | **Space utilization** | Current stock, dimensions | Space efficiency score | Identifies consolidation opportunities |

---

## Package 3: Receiving

### Purpose

Process inbound shipments from suppliers, verify quantities against purchase orders, and manage quality inspection.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- How do you receive against purchase orders?
- Do you have a receiving dock vs direct to stock?
- What information do you capture on receipt? (lot, expiry, COA)
- Do you use advance ship notices (ASN)?

**Workflow Discovery**:
- What's your receiving process? (blind, PO-based, ASN-based)
- Do you have quality inspection? When?
- How do you handle over/under shipments?
- Who can authorize receiving variances?

**Edge Case Probing**:
- Shipment arrives without PO?
- Damaged goods on receipt?
- Supplier sends wrong item?

### Entity Templates

#### Receipt

```json
{
  "id": "data.receiving.receipt",
  "name": "Receipt",
  "type": "data",
  "namespace": "receiving",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Record of goods received into inventory.",
    "fields": [
      { "name": "receipt_number", "type": "string", "required": true, "description": "Unique receipt identifier" },
      { "name": "receipt_type", "type": "enum", "required": true, "values": ["purchase_order", "transfer", "return", "production", "adjustment"], "description": "Source of receipt" },
      { "name": "status", "type": "enum", "required": true, "values": ["pending", "in_progress", "received", "inspecting", "completed", "canceled"], "description": "Receipt status" },
      { "name": "warehouse_id", "type": "uuid", "required": true, "description": "Receiving warehouse" },
      { "name": "receiving_location_id", "type": "uuid", "required": false, "description": "Dock or staging location" },
      { "name": "supplier_id", "type": "uuid", "required": false, "description": "Supplier if purchase receipt" },
      { "name": "purchase_order_id", "type": "uuid", "required": false, "description": "Related PO" },
      { "name": "carrier", "type": "string", "required": false, "description": "Delivery carrier" },
      { "name": "tracking_number", "type": "string", "required": false, "description": "Shipment tracking" },
      { "name": "bill_of_lading", "type": "string", "required": false, "description": "BOL number" },
      { "name": "expected_date", "type": "date", "required": false, "description": "Expected delivery date" },
      { "name": "received_date", "type": "date", "required": false, "description": "Actual receipt date" },
      { "name": "received_by", "type": "uuid", "required": false, "description": "User who received" },
      { "name": "notes", "type": "text", "required": false, "description": "Receipt notes" }
    ],
    "relationships": [
      { "entity": "Warehouse", "type": "many_to_one", "required": true },
      { "entity": "Location", "type": "many_to_one", "required": false },
      { "entity": "Supplier", "type": "many_to_one", "required": false },
      { "entity": "PurchaseOrder", "type": "many_to_one", "required": false },
      { "entity": "ReceiptLine", "type": "one_to_many", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "inventory.receiving",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### ReceiptLine

```json
{
  "id": "data.receiving.receipt_line",
  "name": "Receipt Line",
  "type": "data",
  "namespace": "receiving",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Individual line item on a receipt.",
    "fields": [
      { "name": "receipt_id", "type": "uuid", "required": true, "description": "Parent receipt" },
      { "name": "line_number", "type": "integer", "required": true, "description": "Line sequence" },
      { "name": "item_id", "type": "uuid", "required": true, "description": "Item received" },
      { "name": "po_line_id", "type": "uuid", "required": false, "description": "Related PO line" },
      { "name": "quantity_expected", "type": "decimal", "required": false, "description": "Quantity expected from PO" },
      { "name": "quantity_received", "type": "decimal", "required": true, "description": "Quantity actually received" },
      { "name": "quantity_accepted", "type": "decimal", "required": false, "description": "Quantity passing inspection" },
      { "name": "quantity_rejected", "type": "decimal", "required": false, "description": "Quantity failing inspection" },
      { "name": "uom", "type": "string", "required": true, "description": "Unit of measure" },
      { "name": "lot_number", "type": "string", "required": false, "description": "Lot/batch number" },
      { "name": "expiry_date", "type": "date", "required": false, "description": "Expiration date" },
      { "name": "serial_numbers", "type": "array", "required": false, "description": "List of serial numbers" },
      { "name": "unit_cost", "type": "decimal", "required": false, "description": "Cost per unit" },
      { "name": "location_id", "type": "uuid", "required": false, "description": "Putaway location" },
      { "name": "inspection_status", "type": "enum", "required": false, "values": ["pending", "passed", "failed", "waived"], "description": "QC status" },
      { "name": "damage_notes", "type": "text", "required": false, "description": "Notes on any damage" }
    ],
    "relationships": [
      { "entity": "Receipt", "type": "many_to_one", "required": true },
      { "entity": "Item", "type": "many_to_one", "required": true },
      { "entity": "PurchaseOrderLine", "type": "many_to_one", "required": false },
      { "entity": "Location", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "inventory.receiving",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### WF-RCV-001: Stock Receiving

```yaml
workflow:
  id: "wf.receiving.stock_receiving"
  name: "Stock Receiving"
  trigger: "Shipment arrives at warehouse"
  actors: ["Receiving Clerk", "Quality Inspector", "System"]

  steps:
    - step: 1
      name: "Log Arrival"
      actor: "Receiving Clerk"
      action: "Record carrier, tracking, BOL; identify PO"
      inputs: ["Delivery documents", "PO lookup"]
      outputs: ["Receipt header"]

    - step: 2
      name: "Unload and Count"
      actor: "Receiving Clerk"
      action: "Unload shipment, verify item counts"
      inputs: ["Receipt header", "Expected items"]
      outputs: ["Receipt lines with quantities"]
      decision_point: "Quantities match PO?"

    - step: 3a
      name: "Record Variance"
      actor: "Receiving Clerk"
      action: "Document over/short/damage"
      inputs: ["Receipt lines", "Expected quantities"]
      outputs: ["Variance record"]
      condition: "Quantities do not match"

    - step: 3b
      name: "Approve Variance"
      actor: "System"
      action: "Route variance for approval based on threshold"
      inputs: ["Variance record", "Approval rules"]
      outputs: ["Approval request or auto-approve"]
      condition: "Variance exceeds tolerance"
      automatable: true

    - step: 4
      name: "Capture Lot/Serial"
      actor: "Receiving Clerk"
      action: "Record lot numbers, expiry dates, serial numbers"
      inputs: ["Receipt lines", "Item tracking requirements"]
      outputs: ["Updated receipt lines"]
      condition: "Items require tracking"

    - step: 5
      name: "Quality Inspection"
      actor: "Quality Inspector"
      action: "Inspect samples, record results"
      inputs: ["Receipt lines", "Inspection requirements"]
      outputs: ["Inspection results"]
      condition: "Items require inspection"
      decision_point: "Pass or fail?"

    - step: 6
      name: "Create Transactions"
      actor: "System"
      action: "Create stock transactions for accepted quantities"
      inputs: ["Receipt lines", "Inspection results"]
      outputs: ["StockTransaction records"]
      automatable: true

    - step: 7
      name: "Trigger Putaway"
      actor: "System"
      action: "Generate putaway tasks for received goods"
      inputs: ["Receipt lines", "Putaway rules"]
      outputs: ["Putaway tasks"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Detection | Resolution |
|----|----------|------------|-----------|------------|
| EC-RCV-001 | **Receipt without PO** | Medium | No PO match | Create ad-hoc receipt; flag for review |
| EC-RCV-002 | **Over-shipment beyond tolerance** | Medium | Qty check vs PO | Accept to tolerance; reject or hold excess |
| EC-RCV-003 | **Wrong item received** | High | Item scan mismatch | Reject line; notify supplier; arrange return |
| EC-RCV-004 | **Damaged goods** | Medium | Visual inspection | Document damage; receive to quarantine; file claim |
| EC-RCV-005 | **Expired or near-expiry lot** | High | Expiry check vs policy | Reject if expired; flag if within threshold |
| EC-RCV-006 | **Missing lot/serial for tracked item** | High | Tracking validation | Block receipt until info provided |
| EC-RCV-007 | **Partial shipment** | Low | Qty < expected | Receive partial; leave PO open |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-RCV-001 | **ASN parsing** | ASN document | Structured receipt data | Automates receipt creation |
| AI-RCV-002 | **Document OCR** | Packing slip image | Extracted line items | Speeds data entry |
| AI-RCV-003 | **Supplier performance** | Receipt history, variances | Supplier scorecards | Identifies reliability issues |

---

## Package 4: Counting

### Purpose

Manage cycle counting and physical inventory to verify and correct stock accuracy.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- How often do you count inventory? (daily cycle, annual physical)
- What's your counting method? (ABC velocity, random, full)
- Do you use RF scanners or paper count sheets?
- What variance thresholds trigger investigation?

**Workflow Discovery**:
- Who performs counts? (dedicated counters, warehouse staff)
- How do you handle count discrepancies?
- Can counting happen while operations continue?
- What approval is needed for adjustments?

**Edge Case Probing**:
- Count during active picks?
- Counter counts wrong location?
- Recount required after large variance?

### Entity Templates

#### CycleCount

```json
{
  "id": "data.counting.cycle_count",
  "name": "Cycle Count",
  "type": "data",
  "namespace": "counting",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Header record for a counting session.",
    "fields": [
      { "name": "count_number", "type": "string", "required": true, "description": "Unique count identifier" },
      { "name": "count_type", "type": "enum", "required": true, "values": ["cycle", "physical", "audit", "spot"], "description": "Type of count" },
      { "name": "status", "type": "enum", "required": true, "values": ["planned", "in_progress", "pending_review", "approved", "completed", "canceled"], "description": "Count status" },
      { "name": "warehouse_id", "type": "uuid", "required": true, "description": "Warehouse being counted" },
      { "name": "zone_id", "type": "uuid", "required": false, "description": "Specific zone if not full warehouse" },
      { "name": "scheduled_date", "type": "date", "required": true, "description": "Planned count date" },
      { "name": "started_at", "type": "datetime", "required": false, "description": "When count began" },
      { "name": "completed_at", "type": "datetime", "required": false, "description": "When count finished" },
      { "name": "assigned_to", "type": "uuid", "required": false, "description": "User assigned to count" },
      { "name": "selection_method", "type": "enum", "required": false, "values": ["abc_velocity", "random", "location_based", "item_based", "discrepancy"], "description": "How items were selected" },
      { "name": "blind_count", "type": "boolean", "required": false, "description": "Hide expected quantities from counter" },
      { "name": "approved_by", "type": "uuid", "required": false, "description": "User who approved variances" },
      { "name": "notes", "type": "text", "required": false, "description": "Count notes" }
    ],
    "relationships": [
      { "entity": "Warehouse", "type": "many_to_one", "required": true },
      { "entity": "Zone", "type": "many_to_one", "required": false },
      { "entity": "User", "type": "many_to_one", "required": false },
      { "entity": "CountLine", "type": "one_to_many", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "inventory.counting",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### CountLine

```json
{
  "id": "data.counting.count_line",
  "name": "Count Line",
  "type": "data",
  "namespace": "counting",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Individual item/location to count with results.",
    "fields": [
      { "name": "cycle_count_id", "type": "uuid", "required": true, "description": "Parent count" },
      { "name": "line_number", "type": "integer", "required": true, "description": "Line sequence" },
      { "name": "item_id", "type": "uuid", "required": true, "description": "Item to count" },
      { "name": "location_id", "type": "uuid", "required": true, "description": "Location to count" },
      { "name": "lot_id", "type": "uuid", "required": false, "description": "Specific lot if tracked" },
      { "name": "expected_quantity", "type": "decimal", "required": true, "description": "System quantity" },
      { "name": "counted_quantity", "type": "decimal", "required": false, "description": "Physical count" },
      { "name": "recount_quantity", "type": "decimal", "required": false, "description": "Second count if required" },
      { "name": "final_quantity", "type": "decimal", "required": false, "description": "Accepted quantity" },
      { "name": "variance", "type": "decimal", "required": false, "description": "Difference from expected" },
      { "name": "variance_percent", "type": "decimal", "required": false, "description": "Percentage variance" },
      { "name": "variance_value", "type": "decimal", "required": false, "description": "Dollar value of variance" },
      { "name": "status", "type": "enum", "required": true, "values": ["pending", "counted", "recount_required", "reviewed", "approved", "adjusted"], "description": "Line status" },
      { "name": "counted_by", "type": "uuid", "required": false, "description": "User who counted" },
      { "name": "counted_at", "type": "datetime", "required": false, "description": "When counted" },
      { "name": "reason_code", "type": "string", "required": false, "description": "Reason for variance" },
      { "name": "notes", "type": "text", "required": false, "description": "Counter notes" }
    ],
    "relationships": [
      { "entity": "CycleCount", "type": "many_to_one", "required": true },
      { "entity": "Item", "type": "many_to_one", "required": true },
      { "entity": "Location", "type": "many_to_one", "required": true },
      { "entity": "Lot", "type": "many_to_one", "required": false },
      { "entity": "User", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "inventory.counting",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### WF-CNT-001: Cycle Counting

```yaml
workflow:
  id: "wf.counting.cycle_count"
  name: "Cycle Counting"
  trigger: "Scheduled count date or manual initiation"
  actors: ["System", "Counter", "Inventory Manager"]

  steps:
    - step: 1
      name: "Generate Count List"
      actor: "System"
      action: "Select items/locations based on counting strategy"
      inputs: ["Selection method", "Warehouse", "Last count dates"]
      outputs: ["Count lines"]
      automatable: true

    - step: 2
      name: "Assign Counter"
      actor: "System"
      action: "Assign count to available counter"
      inputs: ["Count lines", "Counter availability"]
      outputs: ["Assigned count"]
      automatable: true

    - step: 3
      name: "Freeze Locations"
      actor: "System"
      action: "Optionally freeze locations from transactions"
      inputs: ["Count lines", "Freeze policy"]
      outputs: ["Frozen locations"]
      condition: "Freeze during count enabled"
      automatable: true

    - step: 4
      name: "Perform Count"
      actor: "Counter"
      action: "Go to location, count items, record quantity"
      inputs: ["Count assignment", "RF scanner or count sheet"]
      outputs: ["Counted quantities"]

    - step: 5
      name: "Calculate Variances"
      actor: "System"
      action: "Compare counted to expected, flag discrepancies"
      inputs: ["Counted quantities", "Expected quantities"]
      outputs: ["Variance report"]
      automatable: true

    - step: 6
      name: "Recount if Required"
      actor: "Counter"
      action: "Perform second count on high-variance items"
      inputs: ["Items exceeding variance threshold"]
      outputs: ["Recount quantities"]
      condition: "Variance exceeds recount threshold"

    - step: 7
      name: "Review Variances"
      actor: "Inventory Manager"
      action: "Review and approve or investigate variances"
      inputs: ["Variance report", "Count history"]
      outputs: ["Approved variances"]
      decision_point: "Approve? Investigate? Recount?"

    - step: 8
      name: "Create Adjustments"
      actor: "System"
      action: "Create adjustment transactions for approved variances"
      inputs: ["Approved variances"]
      outputs: ["StockTransaction records"]
      automatable: true

    - step: 9
      name: "Release Locations"
      actor: "System"
      action: "Unfreeze locations"
      inputs: ["Count complete"]
      outputs: ["Released locations"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Detection | Resolution |
|----|----------|------------|-----------|------------|
| EC-CNT-001 | **Transaction during count** | Medium | Freeze check | Queue transaction until count complete or exclude location |
| EC-CNT-002 | **Multiple counters same location** | Low | Assignment check | Prevent duplicate assignments |
| EC-CNT-003 | **Counter enters zero by mistake** | High | Large variance flag | Require recount; verify location correct |
| EC-CNT-004 | **Item found in wrong location** | Medium | Location mismatch | Create transfer to correct; investigate root cause |
| EC-CNT-005 | **Variance exceeds investigation threshold** | High | Value-based trigger | Lock adjustment pending investigation |
| EC-CNT-006 | **Partial count abandoned** | Low | Status check | Allow resume or restart |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-CNT-001 | **Count prioritization** | Transaction velocity, value, accuracy history | Optimized count schedule | Focuses effort on high-impact items |
| AI-CNT-002 | **Root cause analysis** | Variance patterns, transaction history | Likely cause of discrepancy | Identifies systemic issues |
| AI-CNT-003 | **Accuracy prediction** | Historical count results | Expected accuracy by item/location | Proactive counting |

---

## Package 5: Transfers

### Purpose

Move stock between warehouses or locations within a warehouse with full tracking.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- Do you transfer between warehouses or just within one?
- How do you track in-transit inventory?
- What documentation is required for transfers?
- Do transfers require approval?

**Workflow Discovery**:
- What triggers a transfer? (replenishment, rebalancing, customer request)
- Who initiates transfers?
- How long do transfers take? (same day, multi-day)
- How do you handle partial receipts?

**Edge Case Probing**:
- Goods lost in transit?
- Transfer rejected at destination?
- Urgent transfer bypasses normal process?

### Entity Templates

#### Transfer

```json
{
  "id": "data.transfers.transfer",
  "name": "Transfer",
  "type": "data",
  "namespace": "transfers",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Record of stock movement between locations or warehouses.",
    "fields": [
      { "name": "transfer_number", "type": "string", "required": true, "description": "Unique transfer identifier" },
      { "name": "transfer_type", "type": "enum", "required": true, "values": ["inter_warehouse", "intra_warehouse", "replenishment", "rebalance"], "description": "Type of transfer" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "pending_approval", "approved", "picking", "in_transit", "receiving", "completed", "canceled"], "description": "Transfer status" },
      { "name": "source_warehouse_id", "type": "uuid", "required": true, "description": "Warehouse shipping from" },
      { "name": "source_location_id", "type": "uuid", "required": false, "description": "Specific source location" },
      { "name": "destination_warehouse_id", "type": "uuid", "required": true, "description": "Warehouse receiving to" },
      { "name": "destination_location_id", "type": "uuid", "required": false, "description": "Specific destination location" },
      { "name": "requested_date", "type": "date", "required": false, "description": "When transfer is needed" },
      { "name": "shipped_date", "type": "date", "required": false, "description": "When shipped" },
      { "name": "received_date", "type": "date", "required": false, "description": "When received" },
      { "name": "carrier", "type": "string", "required": false, "description": "Carrier for inter-warehouse" },
      { "name": "tracking_number", "type": "string", "required": false, "description": "Shipment tracking" },
      { "name": "requested_by", "type": "uuid", "required": false, "description": "User who requested" },
      { "name": "approved_by", "type": "uuid", "required": false, "description": "User who approved" },
      { "name": "notes", "type": "text", "required": false, "description": "Transfer notes" }
    ],
    "relationships": [
      { "entity": "Warehouse", "type": "many_to_one", "required": true, "alias": "source_warehouse" },
      { "entity": "Warehouse", "type": "many_to_one", "required": true, "alias": "destination_warehouse" },
      { "entity": "Location", "type": "many_to_one", "required": false, "alias": "source_location" },
      { "entity": "Location", "type": "many_to_one", "required": false, "alias": "destination_location" },
      { "entity": "TransferLine", "type": "one_to_many", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "inventory.transfers",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### TransferLine

```json
{
  "id": "data.transfers.transfer_line",
  "name": "Transfer Line",
  "type": "data",
  "namespace": "transfers",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Individual item being transferred.",
    "fields": [
      { "name": "transfer_id", "type": "uuid", "required": true, "description": "Parent transfer" },
      { "name": "line_number", "type": "integer", "required": true, "description": "Line sequence" },
      { "name": "item_id", "type": "uuid", "required": true, "description": "Item to transfer" },
      { "name": "lot_id", "type": "uuid", "required": false, "description": "Specific lot" },
      { "name": "serial_number", "type": "string", "required": false, "description": "Specific serial" },
      { "name": "quantity_requested", "type": "decimal", "required": true, "description": "Quantity to transfer" },
      { "name": "quantity_shipped", "type": "decimal", "required": false, "description": "Quantity actually shipped" },
      { "name": "quantity_received", "type": "decimal", "required": false, "description": "Quantity received at destination" },
      { "name": "uom", "type": "string", "required": true, "description": "Unit of measure" },
      { "name": "source_location_id", "type": "uuid", "required": false, "description": "Pick from location" },
      { "name": "destination_location_id", "type": "uuid", "required": false, "description": "Put to location" },
      { "name": "status", "type": "enum", "required": true, "values": ["pending", "picked", "shipped", "received", "shorted"], "description": "Line status" }
    ],
    "relationships": [
      { "entity": "Transfer", "type": "many_to_one", "required": true },
      { "entity": "Item", "type": "many_to_one", "required": true },
      { "entity": "Lot", "type": "many_to_one", "required": false },
      { "entity": "Location", "type": "many_to_one", "required": false, "alias": "source_location" },
      { "entity": "Location", "type": "many_to_one", "required": false, "alias": "destination_location" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "inventory.transfers",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### WF-TRF-001: Stock Transfer

```yaml
workflow:
  id: "wf.transfers.stock_transfer"
  name: "Stock Transfer"
  trigger: "Transfer request submitted"
  actors: ["Requester", "Source Warehouse", "Destination Warehouse", "System"]

  steps:
    - step: 1
      name: "Create Transfer Request"
      actor: "Requester"
      action: "Specify items, quantities, source, destination"
      inputs: ["Item requirements", "Source/destination"]
      outputs: ["Transfer request"]

    - step: 2
      name: "Validate Availability"
      actor: "System"
      action: "Check source stock levels"
      inputs: ["Transfer request", "Stock levels"]
      outputs: ["Availability status"]
      automatable: true
      decision_point: "Sufficient stock?"

    - step: 3
      name: "Approve Transfer"
      actor: "System"
      action: "Route for approval based on value/type"
      inputs: ["Transfer request", "Approval rules"]
      outputs: ["Approved transfer"]
      condition: "Transfer exceeds auto-approve threshold"
      automatable: true

    - step: 4
      name: "Pick Items"
      actor: "Source Warehouse"
      action: "Pick items from source locations"
      inputs: ["Approved transfer", "Pick list"]
      outputs: ["Picked items"]

    - step: 5
      name: "Ship Transfer"
      actor: "Source Warehouse"
      action: "Create transfer_out transactions; ship goods"
      inputs: ["Picked items"]
      outputs: ["Shipment", "transfer_out transactions"]

    - step: 6
      name: "Track In-Transit"
      actor: "System"
      action: "Update status to in_transit; track"
      inputs: ["Shipment", "Tracking info"]
      outputs: ["In-transit status"]
      condition: "Inter-warehouse transfer"
      automatable: true

    - step: 7
      name: "Receive Transfer"
      actor: "Destination Warehouse"
      action: "Receive goods, verify quantities"
      inputs: ["Shipment", "Transfer document"]
      outputs: ["Received quantities"]
      decision_point: "Quantities match?"

    - step: 8
      name: "Create Receive Transactions"
      actor: "System"
      action: "Create transfer_in transactions"
      inputs: ["Received quantities"]
      outputs: ["transfer_in transactions", "Updated stock levels"]
      automatable: true

    - step: 9
      name: "Handle Variances"
      actor: "System"
      action: "Flag shipped vs received variances"
      inputs: ["Shipped quantities", "Received quantities"]
      outputs: ["Variance record"]
      condition: "Quantities don't match"
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Detection | Resolution |
|----|----------|------------|-----------|------------|
| EC-TRF-001 | **Goods lost in transit** | High | Shipped != received after expected time | Create loss transaction; investigate; file claim |
| EC-TRF-002 | **Partial shipment** | Medium | Can't pick full quantity | Ship partial; leave transfer open or adjust |
| EC-TRF-003 | **Destination rejects goods** | Medium | Receive with rejection | Return to sender; adjust transactions |
| EC-TRF-004 | **In-transit stock sold** | High | ATP doesn't account for in-transit | Properly exclude in-transit from ATP |
| EC-TRF-005 | **Transfer to full location** | Medium | Capacity check fails | Suggest alternative location |
| EC-TRF-006 | **Urgent transfer bypasses approval** | Low | Emergency flag | Allow with post-hoc review |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-TRF-001 | **Rebalancing recommendation** | Stock levels, demand patterns | Suggested transfers | Prevents stockouts; reduces overstock |
| AI-TRF-002 | **Transit time prediction** | Historical transfers, carrier | Expected arrival | Better planning |
| AI-TRF-003 | **Consolidation suggestion** | Pending transfers | Consolidation opportunities | Reduces shipping costs |

---

## Cross-Package Relationships

The Inventory module packages interconnect to form a complete stock management system:

```
                    ┌─────────────────────────────────────────────┐
                    │               RECEIVING                      │
                    │  (Creates transactions when goods arrive)    │
                    └─────────────────┬───────────────────────────┘
                                      │
                                      ▼
┌───────────────────────────────────────────────────────────────────┐
│                      STOCK MANAGEMENT                              │
│  (Transaction ledger is source of truth)                           │
│  (StockLevel is derived cached sum)                                │
└──────────────┬────────────────────────────────┬───────────────────┘
               │                                │
               ▼                                ▼
┌───────────────────────────┐    ┌───────────────────────────────────┐
│        LOCATIONS          │    │           COUNTING                 │
│  (Where stock is stored)  │    │  (Verifies and corrects levels)   │
└───────────────────────────┘    └───────────────────────────────────┘

┌───────────────────────────────────────────────────────────────────┐
│                         TRANSFERS                                  │
│  (Moves stock between locations/warehouses)                        │
│  (Creates paired transfer_out/transfer_in transactions)            │
└───────────────────────────────────────────────────────────────────┘
```

### Key Integration Points Within Inventory

| From | To | Integration |
|------|-----|-------------|
| Receiving | Stock Management | Receipt creates stock transactions |
| Stock Management | Locations | Stock level exists per item-location |
| Counting | Stock Management | Count adjustments create transactions |
| Transfers | Stock Management | Transfer creates out/in transaction pair |
| Transfers | Locations | Transfer moves between locations |

---

## Cross-Module Integration Patterns

### Integration with Purchasing

| Integration Point | Direction | Description |
|-------------------|-----------|-------------|
| Purchase Order | Purchasing → Inventory | Expected receipts populate incoming quantity |
| Receipt | Inventory → Purchasing | Receipt closes PO lines |
| Reorder Alert | Inventory → Purchasing | Stock below reorder point triggers PO request |

### Integration with Sales

| Integration Point | Direction | Description |
|-------------------|-----------|-------------|
| Available-to-Promise | Inventory → Sales | ATP = on_hand - reserved + incoming |
| Reservation | Sales → Inventory | Sales order reserves stock |
| Shipment | Sales → Inventory | Ship confirmation creates issue transaction |
| Backorder | Inventory → Sales | Insufficient stock creates backorder |

### Integration with Manufacturing

| Integration Point | Direction | Description |
|-------------------|-----------|-------------|
| BOM Consumption | Manufacturing → Inventory | Work order issues component materials |
| Production Receipt | Manufacturing → Inventory | Completed goods received to inventory |
| Material Availability | Inventory → Manufacturing | ATP check for work order release |

### Integration with Financial

| Integration Point | Direction | Description |
|-------------------|-----------|-------------|
| Inventory Valuation | Inventory → Financial | Stock value for balance sheet |
| COGS | Inventory → Financial | Cost of goods sold on shipment |
| Variance Posting | Inventory → Financial | Count adjustments post to variance account |
| Period Close | Financial → Inventory | Inventory cutoff for period end |

---

## Quick Reference

### Entity Summary

| Package | Core Entities | Supporting Entities |
|---------|---------------|---------------------|
| Stock Management | Item, StockLevel, StockTransaction | Lot, UnitConversion |
| Locations | Location, Warehouse | Zone |
| Receiving | Receipt, ReceiptLine | - |
| Counting | CycleCount, CountLine | - |
| Transfers | Transfer, TransferLine | - |

### Workflow Summary

| ID | Workflow | Trigger |
|----|----------|---------|
| WF-STK-001 | Inventory Adjustment | Discrepancy discovered |
| WF-LOC-001 | Directed Putaway | Items received need location |
| WF-RCV-001 | Stock Receiving | Shipment arrives |
| WF-CNT-001 | Cycle Counting | Scheduled count date |
| WF-TRF-001 | Stock Transfer | Transfer request submitted |

### Edge Case Summary by Risk Level

| Risk | Count | Key Themes |
|------|-------|------------|
| High | 12 | Negative inventory, lost goods, data integrity, expired lots |
| Medium | 18 | Variances, capacity, tracking requirements, partial quantities |
| Low | 5 | Process efficiency, partial completion |

### Common Anti-Patterns to Avoid

| Anti-Pattern | Problem | Correct Approach |
|--------------|---------|------------------|
| Single "Inventory" table | No history, audit trail impossible | Transaction ledger + cached level |
| Mutable transactions | Audit trail destroyed | Immutable transactions; offsetting entries |
| Calculate stock on-the-fly | Performance disaster at scale | Cached StockLevel updated by triggers |
| No lot/serial tracking | Cannot trace quality issues | Design for tracking from start |
| In-transit ignored in ATP | Overselling risk | Properly model in-transit state |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | {{ ISO_DATE }} | Initial release |
