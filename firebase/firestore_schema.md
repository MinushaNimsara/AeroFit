# Cloud Firestore schema (AeroFit)

All user data lives under `users/{uid}/…` subcollections.

## `users/{uid}` (document)

| Field | Type | Notes |
|-------|------|-------|
| `displayName` | string | e.g. `"Minusha"` |
| `dailyCalorieGoal` | int | default `2000` |
| `lastWorkoutTimestamp` | timestamp? | Updated when an exercise is logged |
| `createdAt` | timestamp | |

## `users/{uid}/workout_splits/{splitId}`

| Field | Type | Notes |
|-------|------|-------|
| `id` | string | Same as document ID |
| `name` | string | e.g. Chest & Back, Leg Day |
| `createdAt` | timestamp | |

## `users/{uid}/tasks/{taskId}`

| Field | Type | Notes |
|-------|------|-------|
| `id` | string | Same as document ID |
| `title` | string | Task label |
| `isCompleted` | bool | Checkbox state |
| `createdAt` | timestamp | Sort order |

**Dashboard routine pill:** `Done` when `tasks.length > 0` and every task has `isCompleted: true`.

## `users/{uid}/daily_tasks/{taskId}` (legacy)

| Field | Type | Notes |
|-------|------|-------|
| `title` | string | |
| `category` | string | `habit`, `work_block`, `walk_break`, `other` |
| `scheduledDate` | string | `YYYY-MM-DD` |
| `isCompleted` | bool | |
| `sortOrder` | int | |
| `notes` | string? | |

## `users/{uid}/workout_splits/{splitId}`

| Field | Type | Notes |
|-------|------|-------|
| `name` | string | e.g. Push/Pull/Legs |
| `description` | string? | |
| `days` | array | split day labels |

## `users/{uid}/workout_sessions/{sessionId}`

| Field | Type | Notes |
|-------|------|-------|
| `sessionDate` | string | `YYYY-MM-DD` |
| `label` | string | e.g. `"Push Day"` |
| `splitId` | string? | |
| `isCompleted` | bool | **Dashboard gym pill** when any session today is `true` |

## `users/{uid}/exercises/{exerciseId}`

| Field | Type | Notes |
|-------|------|-------|
| `id` | string | Same as document ID |
| `splitId` | string | Links to `workout_splits` document |
| `name` | string | e.g. Incline Treadmill Walk, Chest Press |
| `weightOrSetting` | string | e.g. Speed 5.0 / Incline 12 |
| `notes` | string | Form cues, rest time |
| `imageUrl` | string? | Cloudinary secure URL |
| `timestamp` | timestamp | When the exercise was added |
| `completedDate` | string? | `YYYY-MM-DD` when checked off; auto-resets each new day |

**Dashboard gym pill:** subtitle `X / Y Done` for the active workout split; green when every exercise in that split is checked off today.

## `users/{uid}/exercise_images/{imageId}`

| Field | Type | Notes |
|-------|------|-------|
| `exerciseId` | string | |
| `storagePath` | string | Firebase Storage path |
| `caption` | string? | |

## `users/{uid}/meals/{mealId}`

| Field | Type | Notes |
|-------|------|-------|
| `id` | string | Same as document ID |
| `name` | string | Meal name |
| `calories` | int | kcal |
| `mealType` | string | `Breakfast`, `Lunch`, `Dinner`, `Snack` |
| `imageUrl` | string? | Optional photo URL |
| `timestamp` | timestamp | Log time (used for today's filter) |

**Dashboard diet pill:** shows `X / 2000 kcal`; green when 85–100% of goal without exceeding.

## `users/{uid}/meal_logs/{logId}` (legacy)

| Field | Type | Notes |
|-------|------|-------|
| `logDate` | string | `YYYY-MM-DD` (for queries) |
| `mealSlot` | string | `breakfast`, `lunch`, `dinner`, `snack` |
| `name` | string | |
| `calories` | int | |
| `proteinG` | number | |
| `carbsG` | number | |
| `fatsG` | number | |
| `source` | string | `manual` or `ml_vision` |
| `imageStoragePath` | string? | |

## `users/{uid}/weight_entries/{entryId}`

| Field | Type | Notes |
|-------|------|-------|
| `recordedAt` | string | `YYYY-MM-DD` |
| `weightKg` | number | |

## Storage paths

- Exercise photos: `users/{uid}/exercise_images/{exerciseId}/{filename}`
- Meal photos: `users/{uid}/meal_images/{logId}/{filename}`

## Composite indexes (create in Firebase Console if prompted)

- `daily_tasks`: `scheduledDate` ASC
- `meal_logs`: `logDate` ASC
- `workout_sessions`: `sessionDate` ASC
