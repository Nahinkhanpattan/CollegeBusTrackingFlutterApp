# College Bus Tracking App

A comprehensive Flutter application for real-time college bus tracking with role-based access control.

## Features

### 🎯 Core Functionality
- **Real-time bus tracking** with Google Maps integration
- **Role-based access control** (Student, Teacher, Driver, Bus Coordinator, Admin)
- **Email domain verification** for automatic approval
- **Push notifications** for real-time updates
- **Location sharing** for drivers
- **Route management** for bus coordinators

### 👥 User Roles

#### Student
- Register with college email (auto-approve with OTP) or await teacher approval
- Track assigned buses via Google Maps
- Send "Wait for me" notifications to drivers
- Receive real-time bus location updates

#### Teacher
- Register with college email (auto-approved) or get approval from Admin/Coordinator
- Track all college buses
- Approve student registrations
- Receive bus notifications

#### Driver
- Register and await approval from Bus Coordinator
- Set up bus information (number, route, stops)
- Share real-time location while driving
- Receive notifications from students and teachers

#### Bus Coordinator
- Register and auto-create college if domain is valid (.ac.in)
- Approve driver registrations
- Manage college information and routes
- Monitor all bus activities

#### Admin
- Full system access and control
- Approve coordinators when needed
- Monitor all colleges and users
- System-wide management capabilities

## Tech Stack

- **Frontend**: Flutter (Android & iOS)
- **Backend**: Firebase
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Cloud Functions
  - Firebase Cloud Messaging (FCM)
- **Maps**: Google Maps API
- **Location**: Flutter geolocator plugin
- **State Management**: Provider
- **Navigation**: GoRouter

## Setup Instructions

### Prerequisites
1. Flutter SDK (>=3.10.0)
2. Firebase project setup
3. Google Maps API key
4. Android Studio / Xcode for mobile development

### Firebase Configuration
1. Create a new Firebase project
2. Enable Authentication, Firestore, and Cloud Messaging
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Place them in the appropriate directories

### Google Maps Setup
1. Enable Google Maps SDK for Android and iOS
2. Get your API key from Google Cloud Console
3. Add the API key to:
   - `android/app/src/main/AndroidManifest.xml`
   - `ios/Runner/AppDelegate.swift`

### Installation
1. Clone the repository
2. Run `flutter pub get`
3. Configure Firebase and Google Maps as described above
4. Run `flutter run`

## Database Structure

### Collections

#### `/users/{userId}`
```json
{
  "fullName": "John Doe",
  "email": "john@rvrjc.ac.in",
  "role": "student",
  "collegeId": "rvrjc",
  "approved": true,
  "emailVerified": true,
  "needsManualApproval": false,
  "approverId": null,
  "createdAt": "2025-01-18T10:00:00Z"
}
```

#### `/colleges/{collegeId}`
```json
{
  "name": "RVR & JC College of Engineering",
  "allowedDomains": ["rvrjc.ac.in"],
  "verified": true,
  "createdBy": "userId_of_coordinator",
  "createdAt": "2025-01-18T10:00:00Z"
}
```

#### `/buses/{busId}`
```json
{
  "busNumber": "ABC-102",
  "driverId": "uid123",
  "startPoint": "City Center",
  "endPoint": "RVR & JC",
  "stopPoints": ["Stop1", "Stop2", "Stop3"],
  "collegeId": "rvrjc",
  "isActive": true
}
```

#### `/bus_locations/{busId}`
```json
{
  "currentLocation": {
    "lat": 16.2362,
    "lng": 80.4324
  },
  "timestamp": "2025-01-18T10:00:00Z",
  "speed": 45.5,
  "heading": 180.0
}
```

## User Registration Flow

1. User selects role and enters details
2. System extracts domain from email
3. If domain exists in `allowedDomains`:
   - Send OTP for verification
   - Auto-approve after verification
4. If domain doesn't exist:
   - Set `needsManualApproval = true`
   - Await approval from appropriate role

## Security Rules

The app implements comprehensive Firestore security rules:
- Users can only read/write their own data
- Role-based access for approvals
- College-specific data isolation
- Location sharing restricted to drivers

## Push Notifications

### Notification Types
- **Student to Driver**: "Wait for me" requests
- **Driver to Users**: Trip start/stop notifications
- **System**: Approval notifications
- **Proximity**: Auto-notify when bus nears stops

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please open an issue in the GitHub repository.