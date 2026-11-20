# Firestore rules tests

Tests for `../firestore.rules` (spec 0001, AT19), run against the Firestore emulator.

1. Install once: `npm --prefix rules_test install` (Node 20 or newer).
2. Java must be installed. On a Mac with Homebrew, set `JAVA_HOME=/opt/homebrew/opt/openjdk`.
3. From the repo root, start the emulator, run the tests and stop it:
   `JAVA_HOME=/opt/homebrew/opt/openjdk firebase emulators:exec --only firestore --project demo-dailo "npm --prefix rules_test test"`

The emulator port is set in `firebase.json` (8080). `demo-dailo` is an offline project id, so nothing touches real Firebase.
