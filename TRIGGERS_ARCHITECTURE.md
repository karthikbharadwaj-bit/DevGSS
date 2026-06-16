# `Triggers.cls` Architectural Overview

## Purpose
`force-app/main/default/classes/Triggers.cls` is the project's trigger execution framework. It provides a consistent way to:
1. Register handler classes for specific trigger events (before/after insert/update/delete/undelete).
2. Route execution at runtime to the correct handlers based on the current trigger context.
3. Apply bypass/exclusion controls so handlers can be skipped globally or per handler/event.
4. Provide a shared base class (`TriggerHandlerBase` / `TriggerHelper`) that encapsulates common trigger utilities.
5. Offer a transaction-scoped caching hook (`SObjectCache`) usable from within triggers.

## 1) Handler model
Handlers plugged into the framework must conform to:

```apex
public interface Handler {
    void handle();
    Boolean bypass();
}
```

In practice, handlers usually extend `Triggers.TriggerHandlerBase`, which already implements `bypass()` as `false` by default and requires an implementation of `handle()`.

## 2) Event enumeration (supported trigger phases)
`Triggers.Evt` enumerates the events the framework can route:

- `beforeinsert`
- `beforeupdate`
- `beforedelete`
- `afterinsert`
- `afterupdate`
- `afterdelete`
- `afterundelete`

The framework determines which `Evt` applies using the current `Trigger` context inside `manage()`.

## 3) Registration: `bind(Evt, Handler)`
Each trigger calls `new Triggers().bind(event, handler).bind(...).manage();`

`bind()` records handlers in an internal map:
- key: `event.name()`
- value: `List<Handler>` (ordered by bind call order)

So multiple handlers can be registered for the same trigger event.

## 4) Runtime routing: `manage()`
`manage()` selects a single `Evt` (`ev`) based on Salesforce runtime flags:
- `Trigger.isInsert` + `Trigger.isBefore`  -> `Evt.beforeinsert`
- `Trigger.isInsert` + `Trigger.isAfter`   -> `Evt.afterinsert`
- `Trigger.isUpdate` + `Trigger.isBefore`  -> `Evt.beforeupdate`
- `Trigger.isUpdate` + `Trigger.isAfter`   -> `Evt.afterupdate`
- `Trigger.isDelete` + `Trigger.isBefore`  -> `Evt.beforedelete`
- `Trigger.isDelete` + `Trigger.isAfter`   -> `Evt.afterdelete`
- `Trigger.isUndelete`                     -> `Evt.afterundelete`

Then it fetches the registered handler list for that event and iterates them in order.

For each handler, `manage()` applies three gating steps:
1. Determine handler type via `ObjectHelper.getObjectType(h)` (used only for bypass bookkeeping).
2. Apply global/per-handler exclusion using `excludedHandlers` and the `isExecute` global flag (see next section).
3. Call `h.bypass()`; if it returns `true`, skip `h.handle()` for this handler invocation.

## 5) Bypass/exclusion controls
### A) Global enable/disable
`switchOff()`:
- clears `excludedHandlers`
- sets `isExecute = false`

`switchOn()`:
- clears `excludedHandlers`
- sets `isExecute = true`

In the default mode, `isExecute` is `true`.

### B) Per-handler event exclusion: `except(...)`
`except(Map<String, Set<Evt>> excludedEventsByHandlers)` takes handler type names and events to exclude, then populates:
- `excludedHandlers : Map<Type, Set<Evt>>`

At runtime, the meaning of `excludedHandlers` depends on `isExecute`:
- If `isExecute == true` (normal mode):
  - if the handler's excluded event set contains `ev` -> **skip handler**
- If `isExecute == false` (global off mode):
  - if the handler's excluded event set contains `ev` -> **allow handler**
  - otherwise -> **skip handler**

This dual behavior is what enables “selective enable” behavior when execution is globally switched off.

### C) Handler-level bypass
Each handler can override `bypass()` to conditionally skip itself at runtime.

## 6) Trigger utility helpers
`Triggers.TriggerHandlerBase` extends `Triggers.TriggerHelper`, which encapsulates common patterns:

### Context checks
- `isInsert()`, `isUpdate()`, `isDelete()`, `isUndelete()`
- `isBefore()`, `isAfter()`

### Field-change detection
The framework provides utilities like:
- `isChangedField(SObject record, SObjectField field)`
- `isChangedAnyField(SObject record, Set<SObjectField> fields)`
- `isChangedFieldTo(...)`, `isChangedFieldFrom(...)`, etc.

These are computed based on `Trigger.operationType` and `Trigger.oldMap` where applicable.

### Old/new record access
`Triggers` wraps old/new retrieval in test-visible helper methods:
- `getOldMap()`
- `getOldRecords()`
- `getNewMap()`

`TriggerHelper` stores `newMap`, `oldMap`, and old record lists, and exposes:
- `oldMap()`, `oldRecords()`, `oldRecord(record)`
- `newMap()` (only valid for certain operation types)

This keeps handler code consistent and reduces repeated Trigger boilerplate.

## 7) Cache hook: `getCacheStorage(SObjectType)`
`Triggers` owns a static `SObjectCache CACHE` and pre-registers `SObjectCache.UserCacheStorage` in a static initializer.

Handlers can call:
```apex
Triggers.getCacheStorage(sObjectType)
```

Important constraint: it throws if called when `Trigger.isExecuting == false`. The cache mechanism is therefore intended for use only inside trigger execution.

## 8) Architectural mental model
Think of this framework as:
- A **router** that converts Salesforce trigger context into a single internal enum value (`Evt`)
- A **registry** of handler instances per event
- A **gating layer** (global off/on, per-handler event exclusions, handler-level `bypass()`)
- A shared **base class** that standardizes trigger context introspection and old/new access
- An optional **shared cache** for trigger-scoped performance

## 9) Example wiring pattern
A trigger typically looks like:

```apex
trigger ProServProject on ProServ_Project__c (after insert, after update) {
    new Triggers()
        .bind(Triggers.Evt.afterinsert, new ProServProjectTriggerHandler.ProServProjectAfter())
        .bind(Triggers.Evt.afterupdate, new ProServProjectTriggerHandler.ProServProjectAfter())
        .manage();
}
```

Then the handler’s `handle()` method can safely branch on `Trigger.isInsert` / `Trigger.isUpdate` as needed.

