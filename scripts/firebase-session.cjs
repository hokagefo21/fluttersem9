const fs = require("node:fs");
const path = require("node:path");
function findCli() {
  if (process.env.FIREBASE_CLI_PATH) return process.env.FIREBASE_CLI_PATH;
  const cache = path.join(process.env.LOCALAPPDATA || "", "npm-cache", "_npx");
  const candidates = fs.readdirSync(cache).map(id =>
    path.join(cache, id, "node_modules", "firebase-tools"))
    .filter(dir => fs.existsSync(path.join(dir, "package.json")))
    .map(dir => ({dir, version: require(path.join(dir, "package.json")).version}));
  candidates.sort((a, b) => b.version.localeCompare(a.version, undefined, {numeric: true}));
  if (!candidates.length) throw new Error("Run npx firebase-tools@latest login first.");
  return candidates[0].dir;
}
async function firebaseSession() {
  const cli = findCli();
  const auth = require(path.join(cli, "lib/auth"));
  const {requireAuth} = require(path.join(cli, "lib/requireAuth"));
  const {Client} = require(path.join(cli, "lib/apiv2"));
  const account = auth.getGlobalDefaultAccount();
  if (!account) throw new Error("Sign in with Firebase CLI first.");
  await requireAuth({...account, project: "lab7-uib"});
  const credential = {
    async getAccessToken() {
      const token = await auth.getAccessToken(account.tokens.refresh_token, [
        "https://www.googleapis.com/auth/cloud-platform",
        "https://www.googleapis.com/auth/firebase",
        "https://www.googleapis.com/auth/userinfo.email",
      ]);
      return {access_token: token.access_token,
        expires_in: Math.max(60, Math.floor((token.expires_at - Date.now()) / 1000))};
    },
  };
  return {Client, credential};
}
module.exports = {firebaseSession};
