const {test} = require("node:test");
const assert = require("node:assert/strict");
const {sendRegistrationPush} = require("./send-registration-push");
function dependencies(fail = false) {
  const writes = [];
  const messages = [];
  return {
    writes, messages, uid: "test-uid",
    profile: {name: "Student", fcmToken: "test-token"}, timestamp: 123,
    database: {ref: path => ({set: async value => writes.push({path, value})})},
    messaging: {send: async message => {
      messages.push(message);
      if (fail) throw Object.assign(new Error("Failed"), {code: "messaging/internal-error"});
      return "projects/test/messages/123";
    }},
  };
}
test("Push targets the registering device and records acceptance", async () => {
  const deps = dependencies();
  await sendRegistrationPush(deps);
  assert.equal(deps.messages[0].token, "test-token");
  assert.equal(deps.messages[0].android.notification.channelId, "registration");
  assert.equal(deps.writes[0].path, "registrationPush/test-uid");
  assert.equal(deps.writes[0].value.status, "sent");
});
test("Missing token does not claim successful delivery", async () => {
  const deps = dependencies();
  deps.profile.fcmToken = null;
  await sendRegistrationPush(deps);
  assert.equal(deps.messages.length, 0);
  assert.equal(deps.writes.length, 0);
});
test("FCM failure is recorded and propagated", async () => {
  const deps = dependencies(true);
  await assert.rejects(sendRegistrationPush(deps));
  assert.equal(deps.writes[0].value.status, "error");
  assert.equal(deps.writes[0].value.code, "messaging/internal-error");
});
