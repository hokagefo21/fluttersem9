// Trusted local backend for the lab on the no-cost Firebase Spark plan.
// Uses the owner's Firebase CLI session in memory; no key is added to Flutter.
const {initializeApp} = require("firebase-admin/app");
const {getDatabase, ServerValue} = require("firebase-admin/database");
const {getMessaging} = require("firebase-admin/messaging");
const {firebaseSession} = require("../scripts/firebase-session.cjs");
const {sendRegistrationPush} = require("./send-registration-push");
async function main() {
  const guard = require("node:net").createServer();
  guard.on("error", error => {
    console.error(error.code === "EADDRINUSE"
      ? "Lab7 push server is already running." : error.message);
    process.exit(1);
  });
  await new Promise(resolve => guard.listen(17877, "127.0.0.1", resolve));
  const {credential} = await firebaseSession();
  const app = initializeApp({
    projectId: "lab7-uib",
    databaseURL: "https://lab7-uib-default-rtdb.firebaseio.com",
    credential,
  });
  const database = getDatabase(app);
  const messaging = getMessaging(app);
  const queues = new Map();
  async function processProfile(uid, profile) {
    if (!profile || !profile.fcmToken) return;
    const existing = (await database.ref("registrationPush/" + uid).get()).val();
    if (existing?.status === "sent" &&
        existing.requestedAt === profile.pushRequestedAt) return;
    await sendRegistrationPush({
      uid, profile, messaging, database, timestamp: ServerValue.TIMESTAMP,
    });
    console.log("Registration push accepted by FCM");
  }
  function enqueue(snapshot) {
    const uid = snapshot.key;
    const task = (queues.get(uid) || Promise.resolve())
      .then(() => processProfile(uid, snapshot.val()))
      .catch(error => console.error("Push worker:", error.code || error.message));
    queues.set(uid, task);
    task.finally(() => { if (queues.get(uid) === task) queues.delete(uid); });
  }
  const users = database.ref("users");
  users.on("child_added", enqueue, error => console.error("Database:", error.code));
  users.on("child_changed", enqueue, error => console.error("Database:", error.code));
  console.log("Lab7 push worker is listening to Firebase Realtime Database");
}
main().catch(error => {console.error(error.message); process.exitCode = 1;});
