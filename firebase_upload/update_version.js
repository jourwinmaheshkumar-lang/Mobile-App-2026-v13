import admin from 'firebase-admin';
import { readFileSync } from 'fs';

// Initialize Firebase Admin with your service account
const serviceAccount = JSON.parse(readFileSync('./serviceAccountKey.json', 'utf8'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function updateVersion() {
  console.log('Updating app version in Firestore...');
  
  const versionData = {
    buildNumber: 8,
    changelog: "Critical Fix: Resolved OTA update crash by updating FileProvider paths v1.0.7.",
    downloadUrl: "https://github.com/jourwinmaheshkumar-lang/Mobile-App-2026-v13/releases/download/v1.0.7/director_management_arm64_v1.0.7.apk",
    isMandatory: true,
    latestVersion: "1.0.7",
    releasedAt: admin.firestore.FieldValue.serverTimestamp()
  };

  try {
    await db.collection('app_config').doc('version').set(versionData, { merge: true });
    console.log(`✅ Version updated to ${versionData.latestVersion} successfully!`);
    console.log('New Download URL:', versionData.downloadUrl);
  } catch (error) {
    console.error('❌ Error updating version:', error);
  } finally {
    process.exit(0);
  }
}

updateVersion();
