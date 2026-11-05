const {firebaseSession} = require("./firebase-session.cjs");
async function main() {
  const {Client} = await firebaseSession();
  const services = new Client({urlPrefix: "https://serviceusage.googleapis.com", apiVersion: "v1"});
  for (const service of ["identitytoolkit.googleapis.com", "fcm.googleapis.com"]) {
    await services.post("projects/830203783102/services/" + service + ":enable", {});
    console.log("Enabled:", service);
  }
  const identity = new Client({urlPrefix: "https://identitytoolkit.googleapis.com", apiVersion: "v2"});
  try {
    await identity.get("projects/lab7-uib/config");
  } catch (error) {
    if (error.status !== 404 && !String(error.message).includes("CONFIGURATION_NOT_FOUND")) throw error;
    await identity.post("projects/lab7-uib/identityPlatform:initializeAuth", {});
  }
  await identity.patch("projects/lab7-uib/config",
    {signIn: {email: {enabled: true, passwordRequired: true}}},
    {queryParams: {updateMask: "signIn.email.enabled,signIn.email.passwordRequired"}}
  );
  console.log("Email/password registration enabled");
  const billing = new Client({urlPrefix: "https://cloudbilling.googleapis.com", apiVersion: "v1"});
  const result = await billing.get("projects/lab7-uib/billingInfo");
  console.log("Billing enabled:", Boolean(result.body.billingEnabled));
}
main().catch(error => {console.error(error.message); process.exitCode = 1;});
