const {firebaseSession} = require("./firebase-session.cjs");
const fromFunctions = require("node:module").createRequire(require.resolve("../functions/package.json"));
const {initializeApp, deleteApp} = fromFunctions("firebase-admin/app");
const {getDatabase} = fromFunctions("firebase-admin/database");
async function main() {
  const {credential} = await firebaseSession();
  const app = initializeApp({
    projectId: "lab7-uib", credential,
    databaseURL: "https://lab7-uib-default-rtdb.firebaseio.com",
  });
  const db = getDatabase(app);
  const users = (await db.ref("users").get()).val() || {};
  const rows = [];
  for (const [uid, profile] of Object.entries(users)) {
    if (!profile.email.startsWith("lab7-test-")) continue;
    const push = (await db.ref("registrationPush/" + uid).get()).val();
    rows.push({
      email: profile.email, fields: Object.keys(profile),
      fcmTokenPresent: Boolean(profile.fcmToken),
      pushStatus: push?.status || "pending",
      pushError: push?.code || null,
    });
  }
  console.log(JSON.stringify(rows, null, 2));
  const response = await fetch("https://lab7-uib-default-rtdb.firebaseio.com/users.json");
  console.log("Unauthenticated database access:", response.status);
  await deleteApp(app);
}
main().catch(error => {console.error(error.message); process.exitCode = 1;});
