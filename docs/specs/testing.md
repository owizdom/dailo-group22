# Testing: what is tested and how to run it

## Run everything

```
flutter analyze          # must report "No issues found!"
flutter test             # 780 tests
tool/check.sh            # the gate: format, analyze, architecture rules, tests, coverage
```

The gate fails if any of these is true: `dart format` would change a file, the analyzer reports an issue, `setState(` appears in `lib/`, a Firebase package is imported outside the data layer, no test ran, a test was skipped, or line coverage is under 70%.

## What each group of tests covers

| Folder | Tests | What it proves |
|---|---|---|
| `test/unit/` | 278 | The fee table at both edges of every band, phone number rules, USSD codes, QR text, validators, formatters, entity mapping against the ERD fields, error code mapping, strings in both languages |
| `test/cubits/` | 139 | Every cubit over in-memory repositories: sign-in states and errors, recipient create, read, update and delete, the send-money steps, top-ups, history search and filter, settings saved and restored |
| `test/data/` | 7 | The preferences class against SharedPreferences: saved, restored by a new instance, safe on damaged values |
| `test/widgets/auth/` | 35 | Sign in, sign up, verify email, forgot password: validation messages, button actions, navigation |
| `test/widgets/home/` | 42 | Home, settings, edit profile, feedback, splash |
| `test/widgets/send/` | 55 | Send money, scan, amount with live fee, review, result |
| `test/widgets/recipients/` | 32 | Recipients list, add and edit, payment QR code |
| `test/widgets/history/` | 33 | History, detail, buy airtime, buy data |
| `test/widgets/layout/` | 142 | Every screen at 320x568, 430x932 and 568x320 landscape with no overflow, in English and Kinyarwanda, plus tap-target size and text contrast in light and dark themes |
| `test/flows/` | 16 | The whole app with real cubits: sign in, sign out, verification gate, theme and language, preferences after a relaunch |
| `rules_test/` | 182 | The Firestore security rules against the emulator |

## How the widget tests work

`test/fakes/harness.dart` builds the real cubits on top of in-memory repositories and a fake dialer. A widget test taps a real screen, and the same cubit code runs as in the app. Only Firebase and the phone dialer are replaced.

Tests find widgets by the keys in `lib/core/keys.dart`, not by text. They keep passing when the wording or the language changes.

## Coverage

Line coverage of `lib/` is about 94%, measured by `tool/check.sh`. The generated `firebase_options.dart` is left out of that number; with it the figure is 93.6%.

Flutter only counts files that a test loads. `test/coverage_imports_test.dart` imports every file under `lib/`, and the gate fails if one is missing from it, so the percentage cannot be inflated by leaving files out.

The lines not covered are the classes that talk to Firebase and to the phone dialer, and `main.dart`. They need a real backend and a real SIM, so they are checked by hand on a device.

## Checked by hand

| Check | How |
|---|---|
| Register, verify, sign out, sign in | Emulator against the real Firebase project |
| Add, edit, favourite and delete a recipient, and see each change in the Firebase Console | Emulator |
| Send money with the simulated dialer and see the record in the Console | Emulator, `flutter run --dart-define=SIMULATE_USSD=true` |
| Google sign-in | Emulator |
| Dark mode and Kinyarwanda survive closing and reopening the app | Emulator |
| Rotation to landscape | Emulator |