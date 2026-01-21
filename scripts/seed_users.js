const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// CONFIGURATION
const SERVICE_ACCOUNT_PATH = './service-account.json'; // Download from Firebase Console
const DATA_FILE_PATH = './users_master.json';

// COLORS
const RED = '\x1b[31m';
const GREEN = '\x1b[32m';
const RESET = '\x1b[0m';

async function seed() {
  console.log("Starting Seeding Process...");

  // 1. Check for Service Account
  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(`${RED}ERROR: service-account.json not found!${RESET}`);
    console.log("1. Go to Firebase Console -> Project Settings -> Service accounts");
    console.log("2. Click 'Generate new private key'");
    console.log(`3. Save the file as '${path.resolve(SERVICE_ACCOUNT_PATH)}'`);
    process.exit(1);
  }

  // 2. Initialize Firebase
  const serviceAccount = require(SERVICE_ACCOUNT_PATH);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  const db = admin.firestore();

  // 3. Read Data
  if (!fs.existsSync(DATA_FILE_PATH)) {
    console.error(`${RED}ERROR: users_master.json not found!${RESET}`);
    process.exit(1);
  }
  const users = JSON.parse(fs.readFileSync(DATA_FILE_PATH, 'utf8'));
  console.log(`Found ${users.length} users to seed.`);

  // 4. Write to Users Collection (not whitelist, since we have no auth triggers)
  const batch = db.batch();
  let count = 0;

  for (const user of users) {
    if (!user.email) {
      console.warn(`Skipping user without email: ${JSON.stringify(user)}`);
      continue;
    }

    // Write to 'users' collection with email as document ID
    // Since we can't use Firebase Auth triggers on free tier
    const ref = db.collection('users').doc(user.email.replace('@psgtech.ac.in', ''));
    batch.set(ref, {
      email: user.email,
      name: user.name,
      regNo: user.regNo,
      teamId: user.teamId,
      batch: user.batch,
      roles: user.roles,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    count++;
  }

  try {
    await batch.commit();
    console.log(`${GREEN}SUCCESS: Seeded ${count} users into 'users' collection.${RESET}`);
    console.log("Users can now login using Email Link authentication.");
  } catch (e) {
    console.error(`${RED}FAILED to commit batch:${RESET}`, e);
  }
}

seed();
