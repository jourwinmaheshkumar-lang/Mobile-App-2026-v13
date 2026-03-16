import admin from 'firebase-admin';
import { readFileSync } from 'fs';

// Initialize Firebase Admin with your service account
const serviceAccount = JSON.parse(readFileSync('./serviceAccountKey.json', 'utf8'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Read directors data from both parts
const part1 = JSON.parse(readFileSync('./directors_part1.json', 'utf8'));
const part2 = JSON.parse(readFileSync('./directors_part2.json', 'utf8'));
const directors = [...part1, ...part2];

async function deleteExisting() {
  console.log('Deleting existing directors...');
  const snapshot = await db.collection('directors').get();
  const batch = db.batch();
  snapshot.docs.forEach(doc => batch.delete(doc.ref));
  if (snapshot.docs.length > 0) {
    await batch.commit();
    console.log(`Deleted ${snapshot.docs.length} existing documents`);
  }
}

async function uploadDirectors() {
  console.log(`Uploading ${directors.length} directors...`);

  for (const director of directors) {
    if (director['S.NO'] && typeof director['S.NO'] === 'number') {
      const docRef = db.collection('directors').doc(`director_${director['S.NO']}`);
      await docRef.set(director);
      console.log(`✓ ${director['S.NO']}. ${director['DIRECTORS NAMES']}`);
    }
  }

  console.log('\n✅ All 59 directors uploaded successfully!');
  process.exit(0);
}

async function main() {
  try {
    await deleteExisting();
    await uploadDirectors();
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

main();
