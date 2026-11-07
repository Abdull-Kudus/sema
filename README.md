# Sema · Campus Incident Reporting

> *Sema* is Swahili for "speak up". Students at African Leadership University report broken
> facilities, outages, sanitation and safety issues; campus staff triage them and every update
> reaches the reporter in real time.

Flutter · Riverpod · go_router · Firebase Authentication · Cloud Firestore · Firebase Storage

## Repository layout

```
sema/
├── app/                      Flutter mobile app (frontend)
│   ├── lib/
│   │   ├── core/             config, theme tokens, router, shared widgets, providers
│   │   └── features/
│   │       ├── auth/         data · application · domain · presentation
│   │       ├── reports/      create / browse / filter / detail / status workflow
│   │       ├── home/         student home + staff console
│   │       ├── notifications/
│   │       ├── profile/
│   │       └── shell/        bottom navigation
│   └── test/                 unit, data (fake Firestore), widget, brand-asset tests
├── backend/                  Firebase backend
│   ├── firestore.rules       role-based access control
│   ├── storage.rules         photo upload rules
│   └── firestore.indexes.json
└── firebase.json             deploy + emulator config
```

Each feature is split into **domain** (models), **data** (Firebase repositories),
**application** (Riverpod providers / notifiers) and **presentation** (widgets). Widgets never touch
Firebase directly.

## Features

- **ALU-only accounts.** Email/password sign-up restricted to `@alustudent.com` and
  `@alueducation.com`, mandatory email verification (auto-detected), password reset, and
  "Continue with ALU Google" which brings the real profile photo.
- **Roles.** `@alueducation.com` accounts are staff. A student account can also be promoted by
  setting `role: "staff"` on `users/{uid}` in the Firebase Console. Enforced in the security rules,
  not only the UI.
- **Report an incident.** 8 categories, title, description, campus location + room, priority,
  up to 3 compressed photos with upload progress, anonymous option, validation and unsaved-changes guard.
- **Browse.** Campus feed / my reports, live search, status chips with counts, category filters,
  sort by newest / most supported / priority, skeleton loaders, empty states.
- **Track.** Four-step status tracker, full update history with staff notes, "Me too" support
  counter to surface duplicates, photo gallery with zoom.
- **Staff console.** Open incidents, resolution rate, average fix time, load by category,
  a priority-ordered "needs attention" queue, and status updates that notify the reporter
  in one atomic batch.
- **Alerts** inbox with unread badge, swipe to dismiss.
- **Light / dark / system theme**, Clash Grotesk type, Solar icons, motion via `flutter_animate`.

## Demo supervisor account

For the demo there is a seeded staff account, `supervisor.demo@alueducation.com`, created with
`firebase auth:import` and marked as verified (it has no real mailbox). Sign in from
**Welcome → Supervisor portal**. Its password is kept only in `backend/seed/demo-supervisor.local.md`,
which git ignores.

It is ordinary data in Firebase Auth, not a code path: real staff (`@alueducation.com`) and
students (`@alustudent.com`) register, verify their email and sign in exactly as before.

## Firestore data model

```
users/{uid}                     name, email, role, photoUrl, createdAt
  notifications/{id}            reportId, title, body, status, read, createdAt
reports/{id}                    title, description, category, priority, status,
                                location, locationDetail, photoUrls[], photoPaths[],
                                reporterId, reporterName?, reporterPhotoUrl?, isAnonymous,
                                upvoterIds[], handledBy?, createdAt, updatedAt, resolvedAt?
  updates/{id}                  status, note, authorId, authorName, authorRole, createdAt
Storage: reports/{uid}/{reportId}/{file}.jpg · avatars/{uid}/avatar.jpg
```

## Install the APK (Android)

1. On your phone, open the repository's **Releases** page on GitHub and download `sema-vX.Y.Z.apk` from the latest release.
2. Open the downloaded file. If Android asks, allow **Install unknown apps** for your browser or Files app (Settings → Apps → Special access).
3. Tap **Install**, then open Sema and sign in with your ALU email (`@alustudent.com` for students, `@alueducation.com` for staff).

Requires Android 7.0 or newer. iOS builds need a Mac with Xcode (`flutter build ipa`).

### New releases

Sema does not update itself. Each release is published like this:

1. Bump `version:` in `app/pubspec.yaml` (for example `1.0.1+2`; the number after `+` must always go up).
2. Build: `cd app && flutter build apk --release`.
3. Rename `app/build/app/outputs/flutter-apk/app-release.apk` to `sema-v1.0.1.apk`.
4. On GitHub: **Releases → Draft a new release**, tag `v1.0.1`, attach the APK and list the changes.

Users install the new APK over the old one, and their data is kept because it lives in Firebase. Users can check which version they have under Profile → About.

## Diagrams

The PlantUML sources are in `docs/diagrams/`: ERD, use cases, architecture, the status-update sequence and the report activity flow. To render them to PNG, run `java -jar plantuml.jar -tpng docs/diagrams/*.puml` (get the jar from plantuml.com), or use the VS Code PlantUML extension.

## Demo data

`node backend/seed/seed.mjs` seeds 8 realistic reports with openly licensed photos (credits in `backend/seed/PHOTO-CREDITS.md`), their status history and the students' alerts. It reads the demo passwords from gitignored `*.local.md` files.

## Run it

```bash
cd app
flutter pub get
flutter run            # Android emulator or device
flutter test           # 33 tests
```

Deploy rules (from the repo root): `firebase deploy --only firestore,storage`.

Regenerate the logo PNGs, launcher icons and splash after changing `SemaMark`:

```bash
flutter test --update-goldens test/tool
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Branching

`feat/*` → `staging` → `main`, merged with `--no-ff` so every feature stays visible in history.
