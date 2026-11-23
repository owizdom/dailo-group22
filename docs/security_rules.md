# Security rules: how they protect user data

The rules are in `firestore.rules`. They decide, on Google's servers, whether each read or write is allowed. The app cannot switch them off, so they hold even if someone edits the app.

## The three ideas

1. Only the owner. Every document a user owns is under `users/{uid}`. A request is allowed only when the signed-in user's id equals that `uid`.
2. Verified email before writing. Recipients, transactions and feedback can only be written by an account whose email is verified.
3. Only well-formed data. Every write is checked field by field. A document with a missing field, an extra field or a wrong type is refused.

Anything the rules do not mention is denied. Firestore refuses whatever is not explicitly allowed.

## Rule by rule

| Function | What it checks | What it protects against |
|---|---|---|
| `isOwner(uid)` | The request is signed in and its id equals the `uid` in the path | One user reading or changing another user's recipients or payments |
| `isVerified()` | The sign-in token says the email is verified | Accounts made with someone else's email address writing data |
| `hasExactFields(data, names)` | The document has exactly the listed fields | Extra hidden fields, and half-written documents |
| `validNetwork(value)` | The value is `mtn` or `airtel` | Free text where a fixed choice belongs |
| `validPhone(value)` | The value matches a Rwandan mobile number, `07` then 2, 3, 8 or 9, then seven digits | Saving a number the app could never dial |
| `isTimestamp(value)`, `isNonNegativeInt(value)` | The type of a date or a number | Text stored where a date or amount belongs |
| `validProfile(data)` | Profile fields, and that `email` equals the sign-in email | A profile claiming another person's email |
| `validRecipient(data)` | Name of 1 to 60 characters, a valid phone, a boolean favourite, dates | Empty or oversized names, bad numbers |
| `validTransaction(data)` | Type and status from fixed lists, amount from 1 to 10,000,000, fee of 0 or more | Negative or absurd amounts, made-up statuses |
| `validFeedback(data)` | Message of 10 to 2,000 characters, rating from 1 to 5 | Spam-sized messages, ratings outside the scale |
| `createdAtUnchanged()` | An update keeps the original `createdAt` | Rewriting when a payment happened |

## What each collection allows

| Path | Read | Create | Update | Delete |
|---|---|---|---|---|
| `users/{uid}` | owner | owner, valid profile | owner, valid, same `createdAt` | nobody |
| `users/{uid}/recipients/{id}` | owner | owner, verified, valid | owner, verified, valid, same `createdAt` | owner, verified |
| `users/{uid}/transactions/{id}` | owner | owner, verified, valid | owner, verified, valid, same `createdAt` | owner, verified |
| `users/{uid}/feedback/{id}` | owner | owner, verified, valid | nobody | nobody |

A profile can be created before the email is verified, because sign-up writes it. It can never be deleted, so an account cannot lose its profile by mistake. Feedback cannot be edited or deleted after it is sent.

## The app and the rules agree

The same limits live in the app, so a user sees a polite message before the server has to refuse anything:

- `lib/core/validators.dart` checks names, phone numbers, amounts and the feedback length.
- `Recipient.maxNameLength` cuts a scanned name to 60 characters.
- After the user verifies their email, the app refreshes its sign-in token, because the server reads "verified" from that token.

If the server still refuses a write, the app does not hide it. The repositories report it on a `writeFailures` stream and the screen shows a message.

## How the rules are tested

`rules_test/rules.test.mjs` holds 182 tests that run against the Firestore emulator. Each test signs in as an owner, a different user, an unverified user or nobody, then tries a read or a write and expects it to succeed or fail.

```
JAVA_HOME=/opt/homebrew/opt/openjdk firebase emulators:exec --only firestore --project demo-dailo "npm --prefix rules_test test"
```

Run `npm install` inside `rules_test/` once before the first run.
