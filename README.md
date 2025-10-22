# Breakfast Buddy

A Flutter app for team breakfast ordering with payment tracking. Order together, track payments, and make breakfast easier!

## Features

- **User Authentication**: Sign up and login with email/password
- **Daily Order Sessions**: Automatic daily order sessions for your team
- **Order Management**: Add, view, and delete orders with photos
- **Real-time Updates**: See everyone's orders in real-time
- **Payment Tracking**: Track who paid and who owes money
- **Orders Summary**: View all orders grouped by person
- **Image Upload**: Add photos of your breakfast items
- **Multi-platform**: Works on iOS, Android, and Web

## Tech Stack

- **Flutter 3.x**: Cross-platform framework
- **Firebase Authentication**: User authentication
- **Cloud Firestore**: Real-time database
- **Firebase Storage**: Image storage
- **Provider**: State management
- **Image Picker**: Camera and gallery integration

## Getting Started

### Prerequisites

1. Install [Flutter](https://docs.flutter.dev/get-started/install) (version 3.0 or higher)
2. Install [Firebase CLI](https://firebase.google.com/docs/cli#install_the_firebase_cli)
3. Install [Node.js](https://nodejs.org/) (for Firebase CLI)

### Firebase Setup

1. **Create a Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Click "Add project" and follow the setup wizard
   - Enable Google Analytics (optional)

2. **Enable Firebase Services**

   **Authentication:**
   - In Firebase Console, go to Authentication
   - Click "Get Started"
   - Enable "Email/Password" sign-in method

   **Firestore Database:**
   - Go to Firestore Database
   - Click "Create database"
   - Start in **test mode** (or production mode with security rules)
   - Choose your location

   **Storage:**
   - Go to Storage
   - Click "Get started"
   - Start in **test mode** (or production mode with security rules)

3. **Configure Firebase for Flutter**

   Install FlutterFire CLI:
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   ```

   Login to Firebase:
   ```bash
   firebase login
   ```

   Configure your Flutter app:
   ```bash
   cd breakfast_buddy
   flutterfire configure
   ```

   This will:
   - Create a Firebase project (or select existing one)
   - Register your app for iOS, Android, and Web
   - Generate `lib/utils/firebase_options.dart` with your configuration

### Firestore Security Rules

Add these security rules in Firebase Console > Firestore Database > Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Order sessions
    match /orderSessions/{sessionId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if false;
    }

    // Orders
    match /orders/{orderId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && resource.data.userId == request.auth.uid;
      allow delete: if request.auth != null && resource.data.userId == request.auth.uid;
    }

    // Payments
    match /payments/{paymentId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### Storage Security Rules

Add these security rules in Firebase Console > Storage > Rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /orders/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    match /profiles/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Install Dependencies

```bash
flutter pub get
```

### Run the App

**iOS Simulator:**
```bash
flutter run -d ios
```

**Android Emulator:**
```bash
flutter run -d android
```

**Chrome (Web):**
```bash
flutter run -d chrome
```

## Project Structure

```
breakfast_buddy/
├── lib/
│   ├── models/              # Data models
│   │   ├── app_user.dart
│   │   ├── order.dart
│   │   ├── order_session.dart
│   │   └── payment.dart
│   ├── providers/           # State management
│   │   ├── auth_provider.dart
│   │   └── order_provider.dart
│   ├── screens/             # UI screens
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── signup_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── orders/
│   │   │   ├── add_order_screen.dart
│   │   │   └── orders_summary_screen.dart
│   │   └── payments/
│   │       └── payment_tracking_screen.dart
│   ├── services/            # Business logic
│   │   ├── auth_service.dart
│   │   ├── database_service.dart
│   │   └── storage_service.dart
│   ├── utils/               # Utilities
│   │   └── firebase_options.dart
│   └── main.dart            # App entry point
└── pubspec.yaml             # Dependencies
```

## How to Use

1. **Sign Up**: Create an account with your email and name
2. **Login**: Sign in with your credentials
3. **Add Order**:
   - Tap the "+" button
   - Enter item name and price
   - Optionally add a photo
   - Submit your order
4. **View Summary**: See everyone's orders grouped by person
5. **Track Payments**: Mark payments as paid
6. **Close Session**: Close the order session when done

## Database Schema

### Collections

**users/**
- `name`: string
- `email`: string
- `photoUrl`: string (optional)
- `createdAt`: timestamp

**orderSessions/**
- `date`: timestamp
- `createdBy`: userId
- `createdByName`: string
- `status`: "open" | "closed"
- `totalAmount`: number
- `participants`: array of userIds
- `createdAt`: timestamp

**orders/**
- `sessionId`: string
- `userId`: string
- `userName`: string
- `itemName`: string
- `price`: number
- `imageUrl`: string (optional)
- `createdAt`: timestamp

**payments/**
- `sessionId`: string
- `userId`: string
- `userName`: string
- `amount`: number
- `paid`: boolean
- `paidAt`: timestamp (optional)
- `createdAt`: timestamp

## Troubleshooting

**Firebase configuration errors:**
- Make sure you ran `flutterfire configure`
- Check that `lib/utils/firebase_options.dart` exists
- Verify your Firebase project is set up correctly

**Image picker not working:**
- On iOS: Add camera/photo permissions to `ios/Runner/Info.plist`
- On Android: Add permissions to `android/app/src/main/AndroidManifest.xml`

**Build errors:**
- Run `flutter clean`
- Run `flutter pub get`
- Try running again

## Future Enhancements

- Push notifications when orders are added
- Menu templates for favorite restaurants
- Order history and analytics
- Split payment calculations
- Integration with restaurant APIs
- Dark mode support
- Export order summaries to PDF

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is open source and available under the MIT License.

---

Made with Flutter and Firebase
# breakfast_buddy
