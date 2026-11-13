# Spec: DailO

Status: written by the team before the code.

## Objective

An Android app that lets a mobile money user send money, buy airtime and buy data through guided screens instead of the `*182#` menu. The app dials the USSD code. It works with no mobile data once the user has signed in.

It follows our Part 1 research: people lose their place in the menu, mistype numbers, and do not know the fee until after paying.

## Non-goals

- No iOS, web or desktop build.
- The app never asks for, stores or sends the MoMo PIN.
- The app does not hold or move money. It only dials the network's own code.
- The app does not read the USSD dialog or the confirmation SMS.
- No Facebook or phone-number sign-in.

## Screens

| Screen | Purpose |
|---|---|
| Sign in | Email and password, or Google |
| Sign up (two steps) | Name, then email, phone, password and terms |
| Verify email | Tells the user to open the emailed link |
| Forgot password | Sends a reset email |
| Home | Four actions and the latest transactions |
| Send money | Type a number, scan a code, or pick a recent or favourite recipient |
| Scan QR | Reads a DailO payment code |
| Amount | Amount, quick amounts, live fee and total, fee band warning, comment |
| Review | Name, amount, fee and total before the phone dials |
| Result | Asks what the network said, then shows a receipt |
| Recipients | Search, add, edit, favourite, delete |
| My QR code | The user's own payment code |
| Transaction history | Search and filter every payment and purchase |
| Transaction detail | One record, with a way to correct its result or delete it |
| Buy airtime, Buy data | Amount, then the dialer |
| Settings | Profile, dark mode, default network, fee warning, language, sign out |
| Edit profile | Name and phone |
| Feedback | A rating and a message |

## Rules

Fees are MTN's published table. On-net means MTN to MTN.

| Amount (Frw) | On-net fee | Off-net fee |
|---|---|---|
| 1 to 1,000 | 20 | 100 |
| 1,001 to 10,000 | 100 | 200 |
| 10,001 to 150,000 | 250 | 350 |
| 150,001 to 2,000,000 | 1,500 | 1,600 |
| 2,000,001 to 5,000,000 | 3,000 | 3,000 |
| 5,000,001 to 10,000,000 | 5,000 | 5,000 |

- When an amount is up to 10% above a band edge, the amount screen suggests the cheaper amount.
- A phone number is valid when it normalises to `07` followed by 2, 3, 8 or 9 and seven more digits. `+250` and `250` prefixes are accepted.
- The send code is `*182*1*1*<phone>*<amount>#` for MTN to MTN and `*182*1*2*<phone>*<amount>#` to another network. When no chained code is known the app dials `*182#` and shows the steps.
- A payment record is saved as pending before the phone dials. The user then says whether it succeeded, failed, or they are not sure.

## Data

Cloud Firestore. Four collections, all under the user's own document. The full diagram is in `docs/erd.md`.

- Writes go to the local cache first, so the app works offline and lists update at once.
- A transaction keeps the recipient's name and number as they were when it was paid.
- Preferences are stored on the phone with SharedPreferences.

## State and navigation

- Cubit from `flutter_bloc`. No `setState`.
- Three layers: `presentation`, `domain`, `data`. Screens use cubits, cubits use the interfaces in `domain`, and only `data` imports Firebase.
- Named routes. No screen imports another screen.
- The first screen follows the sign-in state: splash, sign in, verify email, or home. A change of state rebuilds the navigator, so the back button can never return to a signed-out screen's predecessor.

## Validation

- Email: required and shaped like an address.
- Password: at least 8 characters with a letter and a number.
- Names: 2 to 30 characters.
- Amount: 1 to 10,000,000 Frw.
- Feedback: 10 to 2,000 characters.

Errors show after the first press on a submit button, then clear while the user types.

## Acceptance tests

| Test | File |
|---|---|
| Fee at both edges of every band | `test/unit/fee_table_test.dart` |
| Phone numbers in every accepted form | `test/unit/phone_number_test.dart` |
| USSD codes, and that no code holds a PIN | `test/unit/ussd_codes_test.dart` |
| Stored fields equal the ERD | `test/unit/entities_test.dart` |
| Sign-in states and every error message | `test/cubits/auth_cubit_test.dart` |
| Recipient create, read, update, delete | `test/cubits/recipients_cubit_test.dart` |
| The record is saved before the phone dials | `test/cubits/send_money_cubit_test.dart` |
| Preferences restored by a new instance | `test/data/prefs_settings_repository_test.dart` |
| Fee and total update as the amount changes | `test/widgets/send/amount_screen_test.dart` |
| No overflow on small, large and landscape screens | `test/widgets/layout/all_screens_layout_test.dart` |
| Sign in, sign out and the verification gate in the whole app | `test/flows/app_flow_test.dart` |
| Owner-only access and well-formed data | `rules_test/rules.test.mjs` |

## Pre-mortem

It is demo day and we lost marks. Most likely reasons:

1. The chained USSD code does not work on a real SIM. So: test it early on a phone, and keep the `*182#` fallback with steps.
2. Someone cannot explain their code. So: small files, one idea per file, comments on the tricky lines.
3. A screen overflows when the phone is rotated. So: every screen scrolls, and a test pumps every screen in landscape.
4. A grader asks how a "no data" app uses Firebase. So: payments are saved to the offline cache and synced later, and only the first sign-in needs a connection.
5. The ERD and the database differ by a field. So: a test compares the stored fields with the list.
