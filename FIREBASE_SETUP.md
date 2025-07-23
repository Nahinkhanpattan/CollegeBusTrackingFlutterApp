# Firebase Setup Guide for College Bus Tracker

## 🔥 Setting Up Firebase

Your app is currently running without Firebase configuration. To enable Firebase features (authentication, database, notifications), follow these steps:

### Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or select an existing project
3. Enter a project name (e.g., "College Bus Tracker")
4. Follow the setup wizard

### Step 2: Add Android App to Firebase

1. In your Firebase project, click the Android icon (🤖)
2. Enter your package name: `com.example.collegebus`
3. Enter app nickname: "College Bus Tracker"
4. Click "Register app"

### Step 3: Download Configuration File

1. Download the `google-services.json` file
2. Place it in: `android/app/google-services.json`

### Step 4: Enable Firebase Services

In your Firebase console, enable these services:

#### Authentication
1. Go to Authentication → Sign-in method
2. Enable "Email/Password"
3. Optionally enable other methods (Google, Phone, etc.)

#### Firestore Database
1. Go to Firestore Database
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location close to your users

#### Cloud Messaging (for notifications)
1. Go to Cloud Messaging
2. The service will be automatically configured

### Step 5: Update Configuration (Optional)

If you want to customize the Firebase configuration, edit:
`android/app/src/main/res/values/values.xml`

Replace the placeholder values with your actual Firebase project details.

### Step 6: Test the Setup

1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `flutter run`

You should see "Firebase initialized successfully" in the console.

## 🚀 Current Status

✅ **App runs without Firebase** - All UI and navigation works
✅ **Error handling added** - Firebase failures won't crash the app
✅ **Configuration ready** - Just need to add your Firebase project

## 📱 Features That Will Work After Firebase Setup

- ✅ User registration and login
- ✅ Email verification
- ✅ Real-time bus tracking
- ✅ Push notifications
- ✅ User role management
- ✅ College management
- ✅ Bus location updates

## 🔧 Troubleshooting

If you still see Firebase errors after setup:

1. **Check google-services.json location**: Must be in `android/app/`
2. **Verify package name**: Must match `com.example.collegebus`
3. **Clean and rebuild**: Run `flutter clean && flutter pub get`
4. **Check Firebase console**: Ensure services are enabled

## 📞 Need Help?

- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Firebase Setup](https://firebase.flutter.dev/docs/overview/)
- [Firebase Console](https://console.firebase.google.com/) 