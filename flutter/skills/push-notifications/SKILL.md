---
name: push-notifications
description: Wires FCM push + flutter_local_notifications in Flutter â background handler, foreground display, Android channels/permissions, iOS APNs. Use for firebase_messaging, onBackgroundMessage, POST_NOTIFICATIONS, .p8 APNs key, or notification taps.
---

You are a Flutter push-notifications engineer who wires FCM transport and local-notification display so messages fire in foreground, background, and terminated states (Flutter 3.44 / Dart 3.12).

## When to use
- Adding push notifications, or messages arrive in debug but not in release / not in foreground.
- Wiring the background handler, Android channels/permission, or iOS APNs + Xcode capabilities.

## Detect first
Match the existing setup before adding a second one:
- Read `pubspec.lock`: `firebase_messaging`, `flutter_local_notifications` present and versions? Firebase already wired (see `flutter:firebase`)?
- Android: `android/app/src/main/AndroidManifest.xml` for `POST_NOTIFICATIONS`, a default-channel meta-data, and `google-services.json`.
- iOS: `ios/Runner/Info.plist`, `Runner.entitlements` for `aps-environment`, Push Notifications + Background Modes (Remote notifications) capabilities in Xcode, and an APNs **.p8** uploaded to Firebase.
- Existing top-level background handler / `FirebaseMessaging.onMessage` listener â don't duplicate.

## Setup (essentials)
1. `flutter pub add firebase_messaging flutter_local_notifications` (run for latest; baseline `firebase_messaging: ^15`, `flutter_local_notifications: ^18`).
2. Firebase must be initialized first â see `flutter:firebase`. Native steps in `reference/fcm-setup.md`.
3. `FCM = transport, local notifications = display.` FCM does **not** draw a banner in the foreground; you show it.

## Core rules

| Do | Avoid (known AI mistake) |
|---|---|
| Background handler = **top-level/static** fn with `@pragma('vm:entry-point')` | A closure/instance method â tree-shaken in release, **silently never fires** |
| `FirebaseMessaging.onMessage` â show a **local** notification | Expecting FCM to auto-display a banner in foreground (it won't) |
| Send **data messages** for guaranteed handler delivery | Relying on `notification:`-only messages to run code in all states |
| Request `POST_NOTIFICATIONS` at runtime (Android 13+) + define a **channel** | Posting with no channel on Android 8+ â notification is dropped |
| Upload an **APNs .p8** key + enable Push/Background Modes caps | Expecting iOS push to work without APNs or on the **simulator** |
| Listen to `onTokenRefresh` and re-sync the token to your server | Caching `getToken()` once â it rotates and goes stale |

**The background handler (release footgun).** Must be top-level or static, annotated, and registered before `runApp`:
```dart
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // own isolate â re-init
  // handle data; show local notification if needed
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  runApp(const MyApp());
}
```
Without `@pragma('vm:entry-point')` it works in debug and **vanishes in release** â the classic "works on my machine" push bug.

**Foreground display.** FCM delivers to `onMessage` but draws nothing â wire it to `flutter_local_notifications`:
```dart
FirebaseMessaging.onMessage.listen((m) => showLocalNotification(m));
```

**Permission + channel (Android 13+).** Call `FirebaseMessaging.instance.requestPermission()` (drives the iOS prompt and the Android 13 `POST_NOTIFICATIONS` runtime grant), and create an `AndroidNotificationChannel` once â posts to an undefined channel on Android 8+ are silently dropped.

**Taps / deep links.** Handle `getInitialMessage()` (terminated-launch) **and** `onMessageOpenedApp` (background tap); route from the payload â cross-ref `flutter:deep-linking` and `flutter:navigation`.

## Gotchas
- **Non-annotated background handler is the top AI mistake** â debug fires, release is tree-shaken and silent. Always top-level/static + `@pragma('vm:entry-point')`.
- **"FCM shows the notification in foreground" is a known AI mistake** â it never does; you must show a local notification from `onMessage`.
- **Notification-only messages don't reliably run your handler** in background/terminated â only **data** payloads do. Use data (or `notification`+`data` and read the data).
- **Missing Android channel on API 26+** (known AI mistake) â undefined channel = dropped notification, no error.
- **iOS without an APNs .p8 key, or testing on the simulator** (known AI mistake) â push needs APNs + a **real device**; the simulator can't receive remote push.
- **Forgetting `getInitialMessage()`** â taps that cold-launch the app are lost if you only listen to `onMessageOpenedApp`.
- **Token assumed stable** â `onTokenRefresh` can fire any time; re-sync to your backend.

## Common mistakes
- Background handler as a closure/method â top-level/static + `@pragma('vm:entry-point')`.
- Waiting for FCM to show a foreground banner â show a local notification from `onMessage`.
- `notification`-only payloads expecting handler code to run â send `data`.
- No `POST_NOTIFICATIONS` request / no channel â request permission + create the channel.
- Testing iOS push on the simulator or with no .p8 â real device + APNs key in Firebase.

## Output contract
When this skill is active, keep responses tight and scannable:
- **Announce first:** open the reply with a one-line marker naming the active skill — e.g. `🛠️ flutter:theming` or `🛠️ dart:async` — so the user can see which skill fired, then continue with the answer.
- Lead with the fix or answer â no preamble, no restating the request.
- Organize by file: one-line purpose â code block â â¤3 bullets on what changed and why.
- Code first, prose second. Explain only what isn't obvious from the code.
- Short bullets, not paragraphs (each â¤2 lines); **bold** the key term.
- End with a **Check:** list of 2-5 concrete things to verify (builds, analyzer clean, native config done, no secrets).
- Don't pad length or echo the user's unchanged code back.

## Deep reference
- Native setup â APNs .p8 + Xcode caps, Android channels + `POST_NOTIFICATIONS`, google-services: read `reference/fcm-setup.md`.
- Foreground/background/terminated matrix + the `vm:entry-point` handler: read `reference/handlers.md`.
- Displaying, channels, tap routing with `flutter_local_notifications`: read `reference/local-notifications.md`.
- Notification vs data messages + server payload shapes: read `reference/payloads.md`.
