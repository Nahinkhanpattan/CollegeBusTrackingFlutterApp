# Firebase Web Setup Guide

## Step 1: Get Your Web App Configuration

1. **Go to Firebase Console:**
   - Visit [https://console.firebase.google.com](https://console.firebase.google.com)
   - Select your project: `collegebustrackingflutterapp`

2. **Add Web App:**
   - Click on the gear icon (⚙️) next to "Project Overview"
   - Select "Project settings"
   - Scroll down to "Your apps" section
   - Click "Add app" and select the web icon (</>)
   - Give it a nickname like "College Bus Web App"
   - Click "Register app"

3. **Copy Configuration:**
   - After registering, you'll see a configuration object like this:
   ```javascript
   const firebaseConfig = {
     apiKey: "AIzaSyALKYuU_cpEV_rjyZDX6POB30GC-oASDVU",
     authDomain: "collegebustrackingflutterapp.firebaseapp.com",
     projectId: "collegebustrackingflutterapp",
     storageBucket: "collegebustrackingflutterapp.firebasestorage.app",
     messagingSenderId: "670144541497",
     appId: "1:670144541497:web:ACTUAL_WEB_APP_ID_HERE"
   };
   ```

4. **Update web/index.html:**
   - Replace the `appId` in the `firebaseConfig` object with your actual web app ID
   - The current placeholder `"1:670144541497:web:your_web_app_id_here"` needs to be replaced

## Step 2: Enable Authentication for Web

1. **Go to Authentication:**
   - In Firebase Console, go to "Authentication" → "Sign-in method"
   - Make sure "Email/Password" is enabled

## Step 3: Enable Firestore for Web

1. **Go to Firestore Database:**
   - In Firebase Console, go to "Firestore Database"
   - If not created, click "Create database"
   - Choose "Start in test mode" for now (we'll update rules later)

## Step 4: Test the App

1. **Run the web app:**
   ```bash
   flutter run -d chrome
   ```

2. **Try registration** - it should work now!

## Troubleshooting

If you still get errors:
1. Check browser console for specific error messages
2. Make sure you're using the correct web app ID
3. Verify Firestore rules are updated
4. Check if all Firebase services are enabled
