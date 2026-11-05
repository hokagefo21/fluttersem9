async function sendRegistrationPush({uid, profile, messaging, database, timestamp}) {
  if (!profile || typeof profile.fcmToken !== "string" || !profile.fcmToken) return;
  const status = database.ref("registrationPush/" + uid);
  try {
    const messageId = await messaging.send({
      token: profile.fcmToken,
      notification: {
        title: "Регистрация успешна",
        body: profile.name + ", ваши данные сохранены. Добро пожаловать!",
      },
      data: {type: "registration_success", uid},
      android: {
        priority: "high",
        notification: {channelId: "registration", icon: "ic_notification"},
      },
    });
    await status.set({status: "sent", messageId, sentAt: timestamp,
      requestedAt: profile.pushRequestedAt || null});
  } catch (error) {
    const code = error.code || "messaging/unknown-error";
    await status.set({status: "error", code, updatedAt: timestamp});
    // Do not log registration tokens or personal data.
    console.error("Registration push failed:", code);
    throw error;
  }
}
module.exports = {sendRegistrationPush};
