# Heads Up AI reminder setup

The app currently runs end to end with `MockSmartReminderService`, so no API key is needed for local development. The editor previews a plan before saving. When a task is saved, a `TaskSnapshot` is sent to the smart-reminder service. `NotificationManager` schedules the chosen lead-up time, a separate due-time notification, and optional prep nudge as local notifications.

## Recommended production architecture

Use a small backend endpoint rather than calling an LLM directly from the iOS client. The iOS app should send a minimal structured payload:

```json
{
  "title": "Change the oil",
  "category": "cars",
  "dueDate": "2026-12-01T18:00:00Z",
  "completionMode": "diy",
  "selectedLeadDays": 7,
  "prepReminderEnabled": true,
  "userPrepItems": []
}
```

The backend should call the selected model provider, validate a strict JSON response, and return only the reminder plan the app needs. Keep the user's `selectedLeadDays` authoritative; the model may suggest prep timing and supplies but should not silently change the chosen lead time:

```json
{
  "leadDays": 7,
  "prepLeadDays": 14,
  "prepItems": ["Motor oil", "Oil filter"],
  "message": "Heads up: your oil change is coming up.",
  "prepMessage": "Gather what you need: Motor oil, Oil filter."
}
```

Do not ship a provider API key in the app. Store it as a server-side secret, restrict the backend endpoint with user authentication and rate limits, and log only the minimum data needed for debugging. For sensitive health, finance, or household data, provide an opt-out and disclose retention/training behavior.

## Exact code changes to turn on a live provider

1. Add an `HTTPS` endpoint to `LiveAIStepsServiceStub` in `Services/AIService.swift`.
2. Decode the response into `SmartReminderPlan` after validating lead times and message length.
3. Replace the default service in `ReminderCoordinator` with `LiveSmartReminderService`.
4. Keep `TaskSnapshot` as the request type so SwiftData models never cross an async service boundary.
5. Keep the local-notification path for the first release. Reschedule the plan whenever a task is edited or a recurring task advances, and cancel lead, due, and prep identifiers when a one-time task is completed or deleted.
6. Add remote push notifications only when server-side recurring schedules, multi-device sync, or server-triggered nudges are required. Use APNs through your backend and request only the notification permissions the product needs.

## Cost and reliability

Use a fast, lower-cost model for classification and prep suggestions, cache plans by normalized task text/category, and regenerate only when the title, completion mode, prep items, or due date changes. Add timeouts and fall back to the local mock/rule-based plan if the network or provider is unavailable. Track token usage and per-user rate limits before enabling the feature broadly.
