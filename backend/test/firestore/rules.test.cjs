const {readFileSync} = require('node:fs');
const {test, before, after} = require('node:test');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, collection, getDocs} = require('firebase/firestore');
let environment;
before(async () => {
  environment = await initializeTestEnvironment({projectId: 'demo-bike-rules',
    firestore: {rules: readFileSync('../../firestore.rules', 'utf8')}});
});
after(async () => environment?.cleanup());
for (const path of [
  'UserBikeSetup/alice/Bikes/bike/SetupList/setup/Tests/test',
  'UserBikeSetup/alice/RideLog/ride',
  'UserBikeSetup/alice/Bikes/bike/setup/Fork',
  'UserBikeSetup/alice/ServiceComponents/fork/ServiceEntries/service'
]) {
  test(`owner access and isolation: ${path}`, async () => {
    const owner = environment.authenticatedContext('alice').firestore();
    const other = environment.authenticatedContext('bob').firestore();
    const guest = environment.unauthenticatedContext().firestore();
    await assertSucceeds(setDoc(doc(owner, path), {name: 'Verification'}));
    await assertSucceeds(getDoc(doc(owner, path)));
    await assertSucceeds(getDocs(collection(owner, path.split('/').slice(0,-1).join('/'))));
    for (const db of [other, guest]) {
      await assertFails(getDoc(doc(db, path)));
      await assertFails(setDoc(doc(db, path), {name: 'Not allowed'}));
    }
  });
}
test('unrecognized paths remain denied', async () => {
  const db = environment.authenticatedContext('alice').firestore();
  await assertFails(setDoc(doc(db, 'UserBikeSetup/alice/Unknown/doc'), {}));
  await assertFails(setDoc(doc(db, 'Public/doc'), {}));
});

test('deletion tombstone prevents old sessions from recreating data', async () => {
  const owner = environment.authenticatedContext('deleted-user').firestore();
  await environment.withSecurityRulesDisabled(async context => {
    await setDoc(doc(context.firestore(), 'AccountDeletions/deleted-user'), {requestedAt: new Date()});
  });
  for (const suffix of ['', '/Bikes/bike', '/Bikes/bike/SetupList/setup', '/Bikes/bike/setup/Fork', '/RideLog/ride', '/ServiceComponents/component/ServiceEntries/entry', '/StravaBikes/gear']) {
    await assertFails(setDoc(doc(owner, `UserBikeSetup/deleted-user${suffix}`), {value: 'stale offline write'}));
  }
  await assertFails(setDoc(doc(owner, 'AccountDeletions/deleted-user'), {}));
  await assertFails(getDoc(doc(owner, 'AccountDeletions/deleted-user')));
});
