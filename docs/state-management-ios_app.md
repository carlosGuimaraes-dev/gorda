# State Management Patterns - ios_app

## Primary Pattern
- Centralized `ObservableObject` store: `OfflineStore`.
- UI consumes state via `@EnvironmentObject` and `@StateObject`.

## State Shape
- Published collections for clients, employees, tasks, finance, service types.
- Published control state for session, sync timestamp, preferences, logs.

## Mutation Pattern
- All writes pass through store methods.
- Mutations update memory + Core Data + encrypted snapshot + pending queue.

## Preference Propagation
- `AppPreferences` updates trigger currency normalization and persistence.
- `language` preference is injected as app locale in root app scene.

## Offline-first Behavior
- Domain operations succeed locally.
- `syncPendingChanges()` currently simulates queue consolidation for future backend bridge.
