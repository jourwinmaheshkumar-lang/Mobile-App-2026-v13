# Firebase Cloud Setup Guide

## Step 1: Create Firebase Project (FREE)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `DirectorHubPro` (or any name you prefer)
4. Disable Google Analytics (optional, keeps it simpler)
5. Click "Create project"

## Step 2: Register Android App

1. In Firebase Console, click the Android icon to add an Android app
2. Enter package name: `com.example.directormanagement`
3. Enter app nickname: `Director Hub Pro`
4. Click "Register app"

## Step 3: Download google-services.json

1. Download the `google-services.json` file
2. Place it in: `app/` folder (same level as `build.gradle`)
   
   ```
   Mobile App 2026/
   ├── app/
   │   ├── google-services.json  <-- PUT FILE HERE
   │   ├── build.gradle
   │   └── src/
   └── build.gradle
   ```

## Step 4: Enable Firestore Database

1. In Firebase Console, go to "Build" > "Firestore Database"
2. Click "Create database"
3. Select "Start in test mode" (for development)
4. Choose a location close to you (e.g., `asia-south1` for India)
5. Click "Enable"

## Step 5: Set Security Rules (for production)

In Firestore > Rules, update to:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow access to all collections for development
    match /directors/{document=**} { allow read, write: if true; }
    match /reports/{document=**} { allow read, write: if true; }
    match /activity_logs/{document=**} { allow read, write: if true; }
  }
}
```

⚠️ **Warning**: For production, you should add authentication and proper security rules.

## Step 6: Build and Run

1. Sync Gradle files
2. Build the project
3. Data will now automatically sync to Firebase Cloud!

## Free Tier Limits

Firebase Firestore Free Tier includes:
- 1 GB storage
- 50,000 reads per day
- 20,000 writes per day
- 20,000 deletes per day

This is more than enough for a Director Management app!

## Troubleshooting

### Error: "Default FirebaseApp is not initialized"
- Make sure `google-services.json` is in the `app/` folder
- Sync Gradle files

### Error: "Permission denied"
- Make sure Firestore rules allow read/write
- Use "test mode" during development

### Data not syncing
- Check internet connection
- Check Firebase Console > Firestore to see if data appears
