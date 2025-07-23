# 🔥 Complete Firebase Setup Guide for College Bus Tracker

## Prerequisites
- Google account
- Flutter project ready
- Android Studio or VS Code

## Step 1: Create Firebase Project

### 1.1 Go to Firebase Console
- Visit: https://console.firebase.google.com/
- Sign in with your Google account

### 1.2 Create New Project
- Click **"Create a project"** or **"Add project"**
- Enter project name: `college-bus-tracker` (or your preferred name)
- **Enable Google Analytics** (recommended)
- Click **"Create project"**

### 1.3 Project Setup
- Wait for project creation to complete
- Click **"Continue"** when ready

## Step 2: Add Android App

### 2.1 Register Android App
- In your Firebase project dashboard, click the **Android icon** (🤖)
- Enter **Android package name**: `com.example.collegebus`
- Enter **App nickname**: `College Bus Tracker`
- Click **"Register app"**

### 2.2 Download Configuration
- **Download** the `google-services.json` file
- **Place it** in your Flutter project at: `android/app/google-services.json`

### 2.3 Verify File Location
Your project structure should look like:
```
collegebus/
├── android/
│   └── app/
│       ├── google-services.json  ← Place here
│       ├── build.gradle.kts
│       └── src/
└── lib/
```

## Step 3: Enable Firebase Services

### 3.1 Authentication
1. Go to **Authentication** in Firebase Console
2. Click **"Get started"**
3. Go to **"Sign-in method"** tab
4. Enable **"Email/Password"**
5. Click **"Save"**

### 3.2 Firestore Database
1. Go to **Firestore Database** in Firebase Console
2. Click **"Create database"**
3. Choose **"Start in test mode"** (for development)
4. Select a **location** close to your users
5. Click **"Done"**

### 3.3 Cloud Messaging (Optional)
1. Go to **Cloud Messaging** in Firebase Console
2. Service is automatically enabled

## Step 4: Configure Firestore Security Rules

### 4.1 Go to Firestore Rules
1. In Firestore Database, click **"Rules"** tab
2. Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null; // Allow reading other users for admin features
    }
    
    // Buses - drivers can manage their own buses
    match /buses/{busId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (resource == null || resource.data.driverId == request.auth.uid);
    }
    
    // Bus locations - drivers can update their bus location
    match /bus_locations/{busId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (resource == null || resource.data.busId == busId);
    }
    
    // Colleges - read only for most users, write for admins
    match /colleges/{collegeId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Notifications - users can read their own notifications
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null && 
        (resource == null || resource.data.receiverId == request.auth.uid);
    }
  }
}
```

3. Click **"Publish"**

## Step 5: Test Firebase Connection

### 5.1 Build the App
```bash
flutter clean
flutter pub get
flutter run
```

### 5.2 Check Logs
Look for these messages in the console:
- ✅ `Firebase initialized successfully`
- ✅ `AuthService: Using real Firebase authentication`

### 5.3 Test Registration
1. Open the app
2. Go to **Register** screen
3. Create a new account
4. Check Firebase Console → Authentication → Users

## Step 6: Create Initial Data (Optional)

### 6.1 Create Test College
In Firestore Console, manually create a test college:

**Collection**: `colleges`
**Document ID**: `test_college`
**Fields**:
```json
{
  "name": "Test University",
  "allowedDomains": ["test.com", "test.edu"],
  "verified": true,
  "createdBy": "admin",
  "createdAt": "2024-01-01T00:00:00.000Z"
}
```

### 6.2 Create Test Users
Create test users in Authentication and Firestore:

**Authentication**: Create users manually
**Firestore Collection**: `users`
**Document ID**: Use the UID from Authentication

Example user document:
```json
{
  "fullName": "Test Student",
  "email": "student@test.com",
  "role": "student",
  "collegeId": "test_college",
  "approved": true,
  "emailVerified": true,
  "needsManualApproval": false,
  "createdAt": "2024-01-01T00:00:00.000Z"
}
```

## Step 7: Production Considerations

### 7.1 Update Security Rules
Before going to production, update Firestore rules to be more restrictive.

### 7.2 Enable Email Verification
In Authentication → Settings → User actions, enable email verification.

### 7.3 Set Up Cloud Functions (Optional)
For advanced features like automatic notifications.

### 7.4 Configure Analytics
Set up Firebase Analytics for user behavior tracking.

## Troubleshooting

### Common Issues:

1. **"google-services.json not found"**
   - Ensure file is in `android/app/google-services.json`
   - Check file permissions

2. **"Permission denied" errors**
   - Check Firestore security rules
   - Verify user authentication

3. **"Firebase not initialized"**
   - Check `google-services.json` format
   - Verify package name matches

4. **Authentication errors**
   - Check if Email/Password auth is enabled
   - Verify user exists in Authentication

### Debug Commands:
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Check Firebase connection
flutter logs | grep Firebase
```

## Next Steps

1. **Test all features** with real Firebase
2. **Create production rules** for security
3. **Set up monitoring** and analytics
4. **Deploy to app stores**

## Support

If you encounter issues:
1. Check Firebase Console for errors
2. Review Flutter logs
3. Verify configuration files
4. Test with Firebase CLI

---

**Note**: This setup enables real Firebase functionality. The app will automatically switch between Firebase and mock data based on availability. 