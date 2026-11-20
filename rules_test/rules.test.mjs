// AT19: tests for ../firestore.rules, run against the Firestore emulator.
//
// Who may do what (spec 0001, section 4.1):
//   - Only the signed-in owner (auth uid == {uid}) reads or writes under users/{uid}.
//   - Writes to recipients, transactions and feedback also need a verified email.
//   - The profile document users/{uid} can be written before the email is
//     verified (sign-up does that), can never be deleted, and its `email`
//     must equal the email in the sign-in token.
//   - Every write has exactly the documented fields, with the documented types.
//   - createdAt never changes on update.
//   - Feedback can be created but not updated or deleted.
//   - Everything outside users/** is denied.
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  setLogLevel,
  Timestamp,
  updateDoc,
} from 'firebase/firestore';

// ---------------------------------------------------------------------------
// Setup
// ---------------------------------------------------------------------------

const rules = readFileSync(
  new URL('../firestore.rules', import.meta.url),
  'utf8',
);

// `firebase emulators:exec` sets FIRESTORE_EMULATOR_HOST. Without it, use the
// port from firebase.json.
const emulatorAddress = process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080';
const split = emulatorAddress.lastIndexOf(':');
const emulatorHost = emulatorAddress.slice(0, split);
const emulatorPort = Number(emulatorAddress.slice(split + 1));

// The SDK logs every denied request as a warning. Denials are what these
// tests look for, so only real errors are shown.
setLogLevel('error');

let testEnv;

// The signed-in users in these tests. Alice owns the data. Bob is someone else.
const aliceToken = { email: 'alice@example.com', email_verified: true };
const aliceUnverifiedToken = { email: 'alice@example.com', email_verified: false };
const bobToken = { email: 'bob@example.com', email_verified: true };

/** Firestore as seen by Alice, whose email is verified. */
const alice = () => testEnv.authenticatedContext('alice', aliceToken).firestore();
/** Firestore as seen by Alice before she opens the verification link. */
const aliceUnverified = () =>
  testEnv.authenticatedContext('alice', aliceUnverifiedToken).firestore();
/** Firestore as seen by Bob, a different verified user. */
const bob = () => testEnv.authenticatedContext('bob', bobToken).firestore();
/** Firestore as seen by someone who is not signed in. */
const signedOut = () => testEnv.unauthenticatedContext().firestore();

/** Writes a document with the rules switched off, to set up a test. */
async function seed(path, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), path), data);
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-dailo',
    firestore: { rules, host: emulatorHost, port: emulatorPort },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

after(async () => {
  await testEnv.cleanup();
});

// ---------------------------------------------------------------------------
// Valid documents. Each test starts from one of these and breaks one thing,
// so a test that expects a failure fails for that one reason only.
// ---------------------------------------------------------------------------

const created = Timestamp.fromDate(new Date('2026-11-10T09:00:00Z'));
const later = Timestamp.fromDate(new Date('2026-11-12T09:00:00Z'));

const profile = (changes = {}) => ({
  firstName: 'Alice',
  lastName: 'Mukamana',
  email: 'alice@example.com',
  phone: '0788000001',
  network: 'mtn',
  createdAt: created,
  updatedAt: created,
  ...changes,
});

const recipient = (changes = {}) => ({
  name: 'Uwase Diane',
  phone: '0788452310',
  network: 'mtn',
  isFavorite: false,
  lastPaidAt: null,
  createdAt: created,
  updatedAt: created,
  ...changes,
});

const transaction = (changes = {}) => ({
  type: 'send',
  recipientId: 'r1',
  counterpartyName: 'Uwase Diane',
  counterpartyPhone: '0788452310',
  network: 'mtn',
  amount: 10000,
  fee: 100,
  comment: 'Tomatoes, Tuesday',
  status: 'pending',
  createdAt: created,
  updatedAt: created,
  ...changes,
});

const feedback = (changes = {}) => ({
  message: 'The fee hint saved me money.',
  rating: 5,
  createdAt: created,
  ...changes,
});

/** A copy of [data] without the field [name]. */
function without(data, name) {
  const copy = { ...data };
  delete copy[name];
  return copy;
}

// The field lists from spec section 4.1.
const profileFields = ['firstName', 'lastName', 'email', 'phone', 'network', 'createdAt', 'updatedAt'];
const recipientFields = ['name', 'phone', 'network', 'isFavorite', 'lastPaidAt', 'createdAt', 'updatedAt'];
const transactionFields = [
  'type', 'recipientId', 'counterpartyName', 'counterpartyPhone', 'network',
  'amount', 'fee', 'comment', 'status', 'createdAt', 'updatedAt',
];
const feedbackFields = ['message', 'rating', 'createdAt'];

const profilePath = 'users/alice';
const recipientPath = 'users/alice/recipients/r1';
const transactionPath = 'users/alice/transactions/t1';
const feedbackPath = 'users/alice/feedback/f1';

// Phone numbers: 07 then 2, 3, 8 or 9, then seven digits.
const validPhones = ['0720000000', '0730000000', '0780000000', '0790000000'];
const invalidPhones = {
  '123': 'far too short',
  '0710000000': '071 is not a mobile prefix',
  '0740000000': '074 is not a mobile prefix',
  '078800000': 'nine digits',
  '07880000000': 'eleven digits',
  '+250788000001': 'the international form is stored as 07...',
  '078800000a': 'has a letter',
};

// ---------------------------------------------------------------------------
// Profile: users/{uid}
// ---------------------------------------------------------------------------

describe('profile document', () => {
  it('lets the owner create her own profile', async () => {
    await assertSucceeds(setDoc(doc(alice(), profilePath), profile()));
  });

  it('lets the owner create her profile before her email is verified', async () => {
    await assertSucceeds(setDoc(doc(aliceUnverified(), profilePath), profile()));
  });

  it('lets the owner read her own profile', async () => {
    await seed(profilePath, profile());
    await assertSucceeds(getDoc(doc(alice(), profilePath)));
  });

  it('lets the owner update her own profile', async () => {
    await seed(profilePath, profile());
    await assertSucceeds(
      updateDoc(doc(alice(), profilePath), {
        firstName: 'Alicia',
        phone: '0791234567',
        updatedAt: later,
      }),
    );
  });

  it('lets the owner update her profile before her email is verified', async () => {
    await seed(profilePath, profile());
    await assertSucceeds(
      updateDoc(doc(aliceUnverified(), profilePath), {
        firstName: 'Alicia',
        updatedAt: later,
      }),
    );
  });

  it('accepts a server timestamp for createdAt and updatedAt', async () => {
    await assertSucceeds(
      setDoc(
        doc(alice(), profilePath),
        profile({ createdAt: serverTimestamp(), updatedAt: serverTimestamp() }),
      ),
    );
  });

  it('accepts a server timestamp for updatedAt on update', async () => {
    await seed(profilePath, profile());
    await assertSucceeds(
      updateDoc(doc(alice(), profilePath), { updatedAt: serverTimestamp() }),
    );
  });

  it('accepts an empty phone number on a profile', async () => {
    await assertSucceeds(setDoc(doc(alice(), profilePath), profile({ phone: '' })));
  });

  it('accepts both networks on a profile', async () => {
    await assertSucceeds(setDoc(doc(alice(), profilePath), profile({ network: 'airtel' })));
  });

  it("rejects creating a profile with someone else's email", async () => {
    await assertFails(
      setDoc(doc(alice(), profilePath), profile({ email: 'bob@example.com' })),
    );
  });

  it('rejects changing the email on a profile to a different address', async () => {
    await seed(profilePath, profile());
    await assertFails(
      updateDoc(doc(alice(), profilePath), {
        email: 'mallory@example.com',
        updatedAt: later,
      }),
    );
  });

  it('stops another user reading the profile', async () => {
    await seed(profilePath, profile());
    await assertFails(getDoc(doc(bob(), profilePath)));
  });

  it('stops another user creating the profile', async () => {
    await assertFails(setDoc(doc(bob(), profilePath), profile()));
  });

  it('stops another user updating the profile', async () => {
    await seed(profilePath, profile());
    await assertFails(updateDoc(doc(bob(), profilePath), { firstName: 'Mallory' }));
  });

  it('stops a signed-in user listing every profile', async () => {
    await seed(profilePath, profile());
    await assertFails(getDocs(collection(alice(), 'users')));
  });

  it('stops a signed-out visitor reading the profile', async () => {
    await seed(profilePath, profile());
    await assertFails(getDoc(doc(signedOut(), profilePath)));
  });

  it('stops a signed-out visitor creating or updating the profile', async () => {
    await assertFails(setDoc(doc(signedOut(), 'users/new'), profile()));
    await seed(profilePath, profile());
    await assertFails(updateDoc(doc(signedOut(), profilePath), { firstName: 'Mallory' }));
  });

  it('lets nobody delete a profile, not even the owner', async () => {
    await seed(profilePath, profile());
    await assertFails(deleteDoc(doc(alice(), profilePath)));
    await assertFails(deleteDoc(doc(aliceUnverified(), profilePath)));
    await assertFails(deleteDoc(doc(bob(), profilePath)));
    await assertFails(deleteDoc(doc(signedOut(), profilePath)));
  });

  it('rejects a profile with an extra field', async () => {
    await assertFails(setDoc(doc(alice(), profilePath), profile({ isAdmin: true })));
  });

  it('rejects a profile update that adds an extra field', async () => {
    await seed(profilePath, profile());
    await assertFails(updateDoc(doc(alice(), profilePath), { isAdmin: true }));
  });

  for (const name of profileFields) {
    it(`rejects a profile with no ${name}`, async () => {
      await assertFails(setDoc(doc(alice(), profilePath), without(profile(), name)));
    });
  }

  it('rejects a network other than mtn or airtel', async () => {
    await assertFails(setDoc(doc(alice(), profilePath), profile({ network: 'orange' })));
  });

  for (const [phone, why] of Object.entries(invalidPhones)) {
    it(`rejects the profile phone "${phone}" (${why})`, async () => {
      await assertFails(setDoc(doc(alice(), profilePath), profile({ phone })));
    });
  }

  it('rejects a first name that is not text', async () => {
    await assertFails(setDoc(doc(alice(), profilePath), profile({ firstName: 42 })));
  });

  it('rejects a last name that is not text', async () => {
    await assertFails(setDoc(doc(alice(), profilePath), profile({ lastName: null })));
  });

  it('rejects a createdAt that is not a timestamp', async () => {
    await assertFails(
      setDoc(doc(alice(), profilePath), profile({ createdAt: '2026-11-10' })),
    );
  });

  it('rejects changing createdAt when the profile is updated', async () => {
    await seed(profilePath, profile());
    await assertFails(
      updateDoc(doc(alice(), profilePath), { createdAt: later, updatedAt: later }),
    );
  });
});

// ---------------------------------------------------------------------------
// Recipients: users/{uid}/recipients/{recipientId}
// ---------------------------------------------------------------------------

describe('recipients', () => {
  it('lets a verified owner create a recipient', async () => {
    await assertSucceeds(setDoc(doc(alice(), recipientPath), recipient()));
  });

  it('lets a verified owner read a recipient', async () => {
    await seed(recipientPath, recipient());
    await assertSucceeds(getDoc(doc(alice(), recipientPath)));
  });

  it('lets a verified owner list her recipients', async () => {
    await seed(recipientPath, recipient());
    await assertSucceeds(getDocs(collection(alice(), 'users/alice/recipients')));
  });

  it('lets a verified owner update a recipient', async () => {
    await seed(recipientPath, recipient());
    await assertSucceeds(
      updateDoc(doc(alice(), recipientPath), {
        name: 'Diane U.',
        isFavorite: true,
        lastPaidAt: later,
        updatedAt: later,
      }),
    );
  });

  it('lets a verified owner delete a recipient', async () => {
    await seed(recipientPath, recipient());
    await assertSucceeds(deleteDoc(doc(alice(), recipientPath)));
  });

  it('lets an unverified owner read her recipients', async () => {
    await seed(recipientPath, recipient());
    await assertSucceeds(getDoc(doc(aliceUnverified(), recipientPath)));
    await assertSucceeds(getDocs(collection(aliceUnverified(), 'users/alice/recipients')));
  });

  it('stops an unverified owner creating a recipient', async () => {
    await assertFails(setDoc(doc(aliceUnverified(), recipientPath), recipient()));
  });

  it('stops an unverified owner updating a recipient', async () => {
    await seed(recipientPath, recipient());
    await assertFails(updateDoc(doc(aliceUnverified(), recipientPath), { isFavorite: true }));
  });

  it('stops an unverified owner deleting a recipient', async () => {
    await seed(recipientPath, recipient());
    await assertFails(deleteDoc(doc(aliceUnverified(), recipientPath)));
  });

  it('stops another verified user reading recipients', async () => {
    await seed(recipientPath, recipient());
    await assertFails(getDoc(doc(bob(), recipientPath)));
    await assertFails(getDocs(collection(bob(), 'users/alice/recipients')));
  });

  it('stops another verified user writing recipients', async () => {
    await assertFails(setDoc(doc(bob(), recipientPath), recipient()));
    await seed(recipientPath, recipient());
    await assertFails(updateDoc(doc(bob(), recipientPath), { isFavorite: true }));
    await assertFails(deleteDoc(doc(bob(), recipientPath)));
  });

  it('stops a signed-out visitor reading recipients', async () => {
    await seed(recipientPath, recipient());
    await assertFails(getDoc(doc(signedOut(), recipientPath)));
    await assertFails(getDocs(collection(signedOut(), 'users/alice/recipients')));
  });

  it('stops a signed-out visitor writing recipients', async () => {
    await assertFails(setDoc(doc(signedOut(), recipientPath), recipient()));
    await seed(recipientPath, recipient());
    await assertFails(updateDoc(doc(signedOut(), recipientPath), { isFavorite: true }));
    await assertFails(deleteDoc(doc(signedOut(), recipientPath)));
  });

  it('accepts a lastPaidAt of null', async () => {
    await assertSucceeds(setDoc(doc(alice(), recipientPath), recipient({ lastPaidAt: null })));
  });

  it('accepts a lastPaidAt that is a timestamp', async () => {
    await assertSucceeds(setDoc(doc(alice(), recipientPath), recipient({ lastPaidAt: later })));
  });

  it('accepts a server timestamp for createdAt and updatedAt', async () => {
    await assertSucceeds(
      setDoc(
        doc(alice(), recipientPath),
        recipient({ createdAt: serverTimestamp(), updatedAt: serverTimestamp() }),
      ),
    );
  });

  it('rejects a lastPaidAt that is neither null nor a timestamp', async () => {
    await assertFails(setDoc(doc(alice(), recipientPath), recipient({ lastPaidAt: 'yesterday' })));
  });

  for (const phone of validPhones) {
    it(`accepts the phone number ${phone}`, async () => {
      await assertSucceeds(setDoc(doc(alice(), recipientPath), recipient({ phone })));
    });
  }

  for (const [phone, why] of Object.entries(invalidPhones)) {
    it(`rejects the phone number "${phone}" (${why})`, async () => {
      await assertFails(setDoc(doc(alice(), recipientPath), recipient({ phone })));
    });
  }

  it('rejects an empty phone number, because a recipient always has one', async () => {
    await assertFails(setDoc(doc(alice(), recipientPath), recipient({ phone: '' })));
  });

  it('rejects an empty name', async () => {
    await assertFails(setDoc(doc(alice(), recipientPath), recipient({ name: '' })));
  });

  it('accepts a name of 60 characters', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), recipientPath), recipient({ name: 'a'.repeat(60) })),
    );
  });

  it('rejects a name of 61 characters', async () => {
    await assertFails(
      setDoc(doc(alice(), recipientPath), recipient({ name: 'a'.repeat(61) })),
    );
  });

  it('rejects a name that is not text', async () => {
    await assertFails(setDoc(doc(alice(), recipientPath), recipient({ name: 42 })));
  });

  it('rejects an isFavorite that is a string', async () => {
    await assertFails(setDoc(doc(alice(), recipientPath), recipient({ isFavorite: 'yes' })));
  });

  it('rejects an isFavorite that is a number', async () => {
    await assertFails(setDoc(doc(alice(), recipientPath), recipient({ isFavorite: 1 })));
  });

  it('rejects a network other than mtn or airtel', async () => {
    await assertFails(setDoc(doc(alice(), recipientPath), recipient({ network: 'orange' })));
  });

  it('accepts both networks', async () => {
    await assertSucceeds(setDoc(doc(alice(), recipientPath), recipient({ network: 'airtel' })));
  });

  it('rejects a recipient with an extra field', async () => {
    await assertFails(setDoc(doc(alice(), recipientPath), recipient({ nickname: 'Di' })));
  });

  it('rejects an update that adds an extra field', async () => {
    await seed(recipientPath, recipient());
    await assertFails(updateDoc(doc(alice(), recipientPath), { nickname: 'Di' }));
  });

  for (const name of recipientFields) {
    it(`rejects a recipient with no ${name}`, async () => {
      await assertFails(setDoc(doc(alice(), recipientPath), without(recipient(), name)));
    });
  }

  it('rejects changing createdAt when a recipient is updated', async () => {
    await seed(recipientPath, recipient());
    await assertFails(
      updateDoc(doc(alice(), recipientPath), { createdAt: later, updatedAt: later }),
    );
  });
});

// ---------------------------------------------------------------------------
// Transactions: users/{uid}/transactions/{txId}
// ---------------------------------------------------------------------------

describe('transactions', () => {
  it('lets a verified owner create a transaction', async () => {
    await assertSucceeds(setDoc(doc(alice(), transactionPath), transaction()));
  });

  it('lets a verified owner read a transaction', async () => {
    await seed(transactionPath, transaction());
    await assertSucceeds(getDoc(doc(alice(), transactionPath)));
  });

  it('lets a verified owner list her transactions', async () => {
    await seed(transactionPath, transaction());
    await assertSucceeds(getDocs(collection(alice(), 'users/alice/transactions')));
  });

  it('lets a verified owner mark a transaction successful', async () => {
    await seed(transactionPath, transaction());
    await assertSucceeds(
      updateDoc(doc(alice(), transactionPath), { status: 'success', updatedAt: later }),
    );
  });

  it('lets a verified owner mark a transaction failed', async () => {
    await seed(transactionPath, transaction());
    await assertSucceeds(
      updateDoc(doc(alice(), transactionPath), { status: 'failed', updatedAt: later }),
    );
  });

  it('lets a verified owner delete a transaction', async () => {
    await seed(transactionPath, transaction());
    await assertSucceeds(deleteDoc(doc(alice(), transactionPath)));
  });

  it('accepts a server timestamp for createdAt and updatedAt', async () => {
    await assertSucceeds(
      setDoc(
        doc(alice(), transactionPath),
        transaction({ createdAt: serverTimestamp(), updatedAt: serverTimestamp() }),
      ),
    );
  });

  it('accepts an airtime purchase with no recipient, name or other number', async () => {
    const purchase = transaction({
      type: 'airtime',
      recipientId: null,
      counterpartyName: '',
      counterpartyPhone: '',
      amount: 500,
      fee: 0,
    });
    await assertSucceeds(setDoc(doc(alice(), transactionPath), purchase));
  });

  for (const type of ['send', 'airtime', 'data']) {
    it(`accepts the type ${type}`, async () => {
      await assertSucceeds(setDoc(doc(alice(), transactionPath), transaction({ type })));
    });
  }

  for (const status of ['pending', 'success', 'failed']) {
    it(`accepts the status ${status}`, async () => {
      await assertSucceeds(setDoc(doc(alice(), transactionPath), transaction({ status })));
    });
  }

  it('accepts both networks', async () => {
    await assertSucceeds(setDoc(doc(alice(), transactionPath), transaction({ network: 'airtel' })));
  });

  it('accepts an amount of 1', async () => {
    await assertSucceeds(setDoc(doc(alice(), transactionPath), transaction({ amount: 1 })));
  });

  it('accepts an amount of 10,000,000', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), transactionPath), transaction({ amount: 10000000 })),
    );
  });

  it('accepts a fee of 0', async () => {
    await assertSucceeds(setDoc(doc(alice(), transactionPath), transaction({ fee: 0 })));
  });

  it('rejects an amount of 0', async () => {
    await assertFails(setDoc(doc(alice(), transactionPath), transaction({ amount: 0 })));
  });

  it('rejects an amount of 10,000,001', async () => {
    await assertFails(
      setDoc(doc(alice(), transactionPath), transaction({ amount: 10000001 })),
    );
  });

  it('rejects a negative amount', async () => {
    await assertFails(setDoc(doc(alice(), transactionPath), transaction({ amount: -500 })));
  });

  it('rejects an amount that is a string', async () => {
    await assertFails(setDoc(doc(alice(), transactionPath), transaction({ amount: '500' })));
  });

  it('rejects an amount that is not a whole number', async () => {
    await assertFails(setDoc(doc(alice(), transactionPath), transaction({ amount: 500.5 })));
  });

  it('rejects a negative fee', async () => {
    await assertFails(setDoc(doc(alice(), transactionPath), transaction({ fee: -1 })));
  });

  it('rejects a fee that is a string', async () => {
    await assertFails(setDoc(doc(alice(), transactionPath), transaction({ fee: '100' })));
  });

  it('rejects a fee that is not a whole number', async () => {
    await assertFails(setDoc(doc(alice(), transactionPath), transaction({ fee: 99.5 })));
  });

  it('rejects the type withdraw', async () => {
    await assertFails(setDoc(doc(alice(), transactionPath), transaction({ type: 'withdraw' })));
  });

  it('rejects the status done', async () => {
    await assertFails(setDoc(doc(alice(), transactionPath), transaction({ status: 'done' })));
  });

  it('rejects an update that sets the status to done', async () => {
    await seed(transactionPath, transaction());
    await assertFails(updateDoc(doc(alice(), transactionPath), { status: 'done' }));
  });

  it('rejects a network other than mtn or airtel', async () => {
    await assertFails(setDoc(doc(alice(), transactionPath), transaction({ network: 'orange' })));
  });

  it('rejects a transaction with an extra field such as total', async () => {
    await assertFails(setDoc(doc(alice(), transactionPath), transaction({ total: 10100 })));
  });

  it('rejects an update that adds an extra field', async () => {
    await seed(transactionPath, transaction());
    await assertFails(updateDoc(doc(alice(), transactionPath), { total: 10100 }));
  });

  for (const name of transactionFields) {
    it(`rejects a transaction with no ${name}`, async () => {
      await assertFails(setDoc(doc(alice(), transactionPath), without(transaction(), name)));
    });
  }

  for (const [phone, why] of Object.entries(invalidPhones)) {
    it(`rejects the counterparty phone "${phone}" (${why})`, async () => {
      await assertFails(
        setDoc(doc(alice(), transactionPath), transaction({ counterpartyPhone: phone })),
      );
    });
  }

  it('rejects a recipientId that is neither text nor null', async () => {
    await assertFails(setDoc(doc(alice(), transactionPath), transaction({ recipientId: 7 })));
  });

  it('rejects a comment that is not text', async () => {
    await assertFails(setDoc(doc(alice(), transactionPath), transaction({ comment: 5 })));
  });

  it('rejects a counterparty name that is not text', async () => {
    await assertFails(
      setDoc(doc(alice(), transactionPath), transaction({ counterpartyName: null })),
    );
  });

  it('rejects changing createdAt when a transaction is updated', async () => {
    await seed(transactionPath, transaction());
    await assertFails(
      updateDoc(doc(alice(), transactionPath), { createdAt: later, updatedAt: later }),
    );
  });

  it('stops another verified user reading transactions', async () => {
    await seed(transactionPath, transaction());
    await assertFails(getDoc(doc(bob(), transactionPath)));
    await assertFails(getDocs(collection(bob(), 'users/alice/transactions')));
  });

  it('stops another verified user writing transactions', async () => {
    await assertFails(setDoc(doc(bob(), transactionPath), transaction()));
    await seed(transactionPath, transaction());
    await assertFails(updateDoc(doc(bob(), transactionPath), { status: 'failed' }));
    await assertFails(deleteDoc(doc(bob(), transactionPath)));
  });

  it('stops a signed-out visitor reading transactions', async () => {
    await seed(transactionPath, transaction());
    await assertFails(getDoc(doc(signedOut(), transactionPath)));
    await assertFails(getDocs(collection(signedOut(), 'users/alice/transactions')));
  });

  it('stops a signed-out visitor writing transactions', async () => {
    await assertFails(setDoc(doc(signedOut(), transactionPath), transaction()));
    await seed(transactionPath, transaction());
    await assertFails(updateDoc(doc(signedOut(), transactionPath), { status: 'failed' }));
    await assertFails(deleteDoc(doc(signedOut(), transactionPath)));
  });

  it('lets an unverified owner read her transactions', async () => {
    await seed(transactionPath, transaction());
    await assertSucceeds(getDoc(doc(aliceUnverified(), transactionPath)));
    await assertSucceeds(getDocs(collection(aliceUnverified(), 'users/alice/transactions')));
  });

  it('stops an unverified owner creating a transaction', async () => {
    await assertFails(setDoc(doc(aliceUnverified(), transactionPath), transaction()));
  });

  it('stops an unverified owner updating a transaction', async () => {
    await seed(transactionPath, transaction());
    await assertFails(updateDoc(doc(aliceUnverified(), transactionPath), { status: 'failed' }));
  });

  it('stops an unverified owner deleting a transaction', async () => {
    await seed(transactionPath, transaction());
    await assertFails(deleteDoc(doc(aliceUnverified(), transactionPath)));
  });
});

// ---------------------------------------------------------------------------
// Feedback: users/{uid}/feedback/{feedbackId}
// ---------------------------------------------------------------------------

describe('feedback', () => {
  for (const rating of [1, 2, 3, 4, 5]) {
    it(`lets a verified owner send feedback with a rating of ${rating}`, async () => {
      await assertSucceeds(setDoc(doc(alice(), feedbackPath), feedback({ rating })));
    });
  }

  it('accepts a message of 10 characters', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), feedbackPath), feedback({ message: 'a'.repeat(10) })),
    );
  });

  it('accepts a message of 2000 characters', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), feedbackPath), feedback({ message: 'a'.repeat(2000) })),
    );
  });

  it('accepts a server timestamp for createdAt', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), feedbackPath), feedback({ createdAt: serverTimestamp() })),
    );
  });

  it('lets the owner read her own feedback back', async () => {
    await seed(feedbackPath, feedback());
    await assertSucceeds(getDoc(doc(alice(), feedbackPath)));
  });

  it('rejects a rating of 0', async () => {
    await assertFails(setDoc(doc(alice(), feedbackPath), feedback({ rating: 0 })));
  });

  it('rejects a rating of 6', async () => {
    await assertFails(setDoc(doc(alice(), feedbackPath), feedback({ rating: 6 })));
  });

  it('rejects a rating that is not a whole number', async () => {
    await assertFails(setDoc(doc(alice(), feedbackPath), feedback({ rating: 4.5 })));
  });

  it('rejects a rating that is a string', async () => {
    await assertFails(setDoc(doc(alice(), feedbackPath), feedback({ rating: '5' })));
  });

  it('rejects a message of 5 characters', async () => {
    await assertFails(setDoc(doc(alice(), feedbackPath), feedback({ message: 'Hello' })));
  });

  it('rejects a message of 2001 characters', async () => {
    await assertFails(
      setDoc(doc(alice(), feedbackPath), feedback({ message: 'a'.repeat(2001) })),
    );
  });

  it('rejects a message that is not text', async () => {
    await assertFails(setDoc(doc(alice(), feedbackPath), feedback({ message: 1234567890 })));
  });

  it('rejects feedback with an extra field', async () => {
    await assertFails(
      setDoc(doc(alice(), feedbackPath), feedback({ email: 'alice@example.com' })),
    );
  });

  for (const name of feedbackFields) {
    it(`rejects feedback with no ${name}`, async () => {
      await assertFails(setDoc(doc(alice(), feedbackPath), without(feedback(), name)));
    });
  }

  it('rejects a createdAt that is not a timestamp', async () => {
    await assertFails(
      setDoc(doc(alice(), feedbackPath), feedback({ createdAt: '2026-11-10' })),
    );
  });

  it('stops the owner updating feedback once it is sent', async () => {
    await seed(feedbackPath, feedback());
    await assertFails(updateDoc(doc(alice(), feedbackPath), { rating: 1 }));
  });

  it('stops the owner deleting feedback once it is sent', async () => {
    await seed(feedbackPath, feedback());
    await assertFails(deleteDoc(doc(alice(), feedbackPath)));
  });

  it('stops another user reading the feedback', async () => {
    await seed(feedbackPath, feedback());
    await assertFails(getDoc(doc(bob(), feedbackPath)));
    await assertFails(getDocs(collection(bob(), 'users/alice/feedback')));
  });

  it('stops another user sending feedback into the account', async () => {
    await assertFails(setDoc(doc(bob(), feedbackPath), feedback()));
  });

  it('stops another user updating or deleting the feedback', async () => {
    await seed(feedbackPath, feedback());
    await assertFails(updateDoc(doc(bob(), feedbackPath), { rating: 1 }));
    await assertFails(deleteDoc(doc(bob(), feedbackPath)));
  });

  it('stops a signed-out visitor reading feedback', async () => {
    await seed(feedbackPath, feedback());
    await assertFails(getDoc(doc(signedOut(), feedbackPath)));
  });

  it('stops a signed-out visitor sending feedback', async () => {
    await assertFails(setDoc(doc(signedOut(), feedbackPath), feedback()));
  });

  it('stops an unverified owner sending feedback', async () => {
    await assertFails(setDoc(doc(aliceUnverified(), feedbackPath), feedback()));
  });
});

// ---------------------------------------------------------------------------
// Everything else
// ---------------------------------------------------------------------------

describe('documents outside users', () => {
  it('denies reading other/doc, even for a verified user', async () => {
    await seed('other/doc', { hello: 'world' });
    await assertFails(getDoc(doc(alice(), 'other/doc')));
  });

  it('denies writing other/doc, even for a verified user', async () => {
    await assertFails(setDoc(doc(alice(), 'other/doc'), { hello: 'world' }));
  });

  it('denies updating and deleting other/doc, even for a verified user', async () => {
    await seed('other/doc', { hello: 'world' });
    await assertFails(updateDoc(doc(alice(), 'other/doc'), { hello: 'again' }));
    await assertFails(deleteDoc(doc(alice(), 'other/doc')));
  });

  it('denies reading and writing other/doc when signed out', async () => {
    await seed('other/doc', { hello: 'world' });
    await assertFails(getDoc(doc(signedOut(), 'other/doc')));
    await assertFails(setDoc(doc(signedOut(), 'other/doc'), { hello: 'world' }));
  });

  it('denies recipients, transactions and feedback kept at the top level', async () => {
    await assertFails(setDoc(doc(alice(), 'recipients/r1'), recipient()));
    await assertFails(setDoc(doc(alice(), 'transactions/t1'), transaction()));
    await assertFails(setDoc(doc(alice(), 'feedback/f1'), feedback()));
  });
});
