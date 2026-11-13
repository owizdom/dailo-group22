# Tasks: Group 22

Each member owns one area of the app and works on their own branches. Every branch goes into `main` through a pull request that a teammate reviews.

| Member | Area |
|---|---|
| Wisdom Ikechukwu Okechukwu | App start, the send-money flow, fees and the USSD dialer |
| Alieu O Jobe | Authentication and security rules |
| Cyuzuzo Germain | Recipients and QR codes |
| Nkingi Gakindi Chris | History, airtime and data, settings and feedback |
| Erioluwa Gideon Olowoyo | Design system, shared widgets and the home screen |

## Rounds

We build from the inside out, so each round stands on the one before it.

| Round | Dates | What lands |
|---|---|---|
| 1. Domain and core | Sat 14 to Sun 15 Nov | Entities, rules and validators, theme, strings in English and Kinyarwanda |
| 2. Data, cubits, rules and shared widgets | Mon 16 to Tue 17 Nov | Firebase and SharedPreferences classes, cubits, security rules, shared widgets |
| 3. Screens | Wed 18 to Thu 19 Nov | The screens for each area, with their widget tests |
| 4. The app comes together | Fri 20 to Sat 21 Nov | The app shell that joins the screens, layout tests, and the database, security and testing notes |

## Who reviews whom

The reviewer changes every round, so everyone reads code from more than one area.

| Round | Wisdom | Alieu | Germain | Chris | Gideon |
|---|---|---|---|---|---|
| 1 | Alieu | Gideon | Wisdom | Germain | Chris |
| 2 | Chris | Wisdom | Gideon | Alieu | Germain |
| 3 | Alieu | Germain | Chris | Gideon | Wisdom |
| 4 | Germain | Gideon | Chris | Wisdom | Alieu |

Each cell is the person who reviews that member's pull request in that round.

## How we work

- Nobody pushes to `main`. It only accepts pull requests with an approving review.
- A review means running the branch: `flutter analyze`, `flutter test`, and the app on a phone or emulator when there is a screen to see.
- The owner merges their pull request after it is approved.
- Small commits, a few each day, each with a message that says what changed.
- Tests come with the code they test, in the same pull request.
