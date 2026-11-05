const {firebaseSession} = require("./firebase-session.cjs");
async function main() {
  const {Client} = await firebaseSession();
  const api = new Client({
    urlPrefix: "https://firebasedatabase.googleapis.com", apiVersion: "v1beta",
  });
  const existing = await api.get("projects/lab7-uib/locations/-/instances");
  if (existing.body.instances?.length) {
    console.log("Database already exists:", existing.body.instances[0].databaseUrl);
    return;
  }
  const result = await api.post(
    "projects/lab7-uib/locations/us-central1/instances",
    {type: "default_database"},
    {queryParams: {databaseId: "lab7-uib-default-rtdb"}},
  );
  console.log("Database created:", result.body.databaseUrl);
}
main().catch(error => {console.error(error.message); process.exitCode = 1;});
