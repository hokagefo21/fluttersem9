const {initializeApp} = require("firebase-admin/app");
const {getDatabase, ServerValue} = require("firebase-admin/database");
const {getMessaging} = require("firebase-admin/messaging");
const {onValueWritten} = require("firebase-functions/v2/database");
const {sendRegistrationPush} = require("./send-registration-push");
initializeApp();

// Keep this region aligned with the Realtime Database location.
exports.registrationPush = onValueWritten(
  {ref: "/users/{uid}", region: "us-central1"},
  async (event) => {
    const after = event.data.after.val();
    const before = event.data.before.val();
    if (!after || !after.fcmToken) return;
    if (before && before.fcmToken === after.fcmToken &&
        before.pushRequestedAt === after.pushRequestedAt) return;
    await sendRegistrationPush({
      uid: event.params.uid, profile: after,
      messaging: getMessaging(), database: getDatabase(), timestamp: ServerValue.TIMESTAMP,
    });
  }
);
