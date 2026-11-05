const {firebaseSession} = require("./firebase-session.cjs");
const fromFunctions = require("node:module").createRequire(require.resolve("../functions/package.json"));
const {initializeApp, deleteApp} = fromFunctions("firebase-admin/app");
const {getDatabase, ServerValue} = fromFunctions("firebase-admin/database");
async function main() {
  const email = process.argv[2];
  if (!email?.startsWith("lab7-test-")) throw new Error("Only laboratory test accounts are accepted.");
  const {credential} = await firebaseSession();
  const app = initializeApp({
    projectId: "lab7-uib", credential,
    databaseURL: "https://lab7-uib-default-rtdb.firebaseio.com",
  });
  const database = getDatabase(app);
  const users = (await database.ref("users").get()).val() || {};
  const match = Object.entries(users).find(([, value]) => value.email === email);
  if (!match) throw new Error("Test registration not found.");
  await database.ref("users/" + match[0]).update({pushRequestedAt: ServerValue.TIMESTAMP});
  console.log("Requested another registration push for the test account");
  await deleteApp(app);
}
main().catch(error => {console.error(error.message); process.exitCode = 1;});
