# Breakfast Buddy

A Flutter app designed for teams to order breakfast together every day. Create groups, add restaurants, browse menus, place orders, and track payments - all in one place!

## Features

- **User Authentication**: Sign up with email/password or Google Sign-In
- **Group Management**: Create groups for your team, invite members, and manage permissions
- **Restaurant Integration**: Add restaurants to groups with menu browsing capability
- **Menu Browsing**: View restaurant menus with categories, items, modifiers, and allergens
- **Order Management**: Add, view, and delete orders with quantity and photos
- **Real-time Updates**: See everyone's orders in real-time using Firestore streams
- **Group Status Control**: Activate/deactivate groups to control when ordering is allowed
- **Payment Tracking**: Comprehensive payment tracking with paid/unpaid status
- **Payment Dashboard**: View payment summaries with statistics per member
- **Order Confirmation**: Admins can confirm all orders and automatically create payment records
- **Image Upload**: Add photos of breakfast items via camera or gallery
- **Multi-platform**: Works on iOS, Android, Web, macOS, and Windows

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
    // Helper function to check if user is a group member
    function isGroupMember(groupId) {
      return request.auth.uid in get(/databases/$(database)/documents/groups/$(groupId)).data.memberIds;
    }

    // Helper function to check if user is a group admin
    function isGroupAdmin(groupId) {
      return request.auth.uid == get(/databases/$(database)/documents/groups/$(groupId)).data.adminId;
    }

    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Groups
    match /groups/{groupId} {
      allow read: if request.auth != null && isGroupMember(groupId);
      allow create: if request.auth != null;
      allow update: if request.auth != null && isGroupAdmin(groupId);
      allow delete: if request.auth != null && isGroupAdmin(groupId);
    }

    // Group Members
    match /groupMembers/{memberId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow delete: if request.auth != null &&
                    (isGroupAdmin(resource.data.groupId) ||
                     request.auth.uid == resource.data.userId);
    }

    // Group Restaurants
    match /groupRestaurants/{restaurantId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && isGroupMember(request.resource.data.groupId);
      allow delete: if request.auth != null && isGroupAdmin(resource.data.groupId);
    }

    // Order sessions (legacy)
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
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if false;
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
│   │   ├── allergen.dart
│   │   ├── app_user.dart
│   │   ├── group.dart
│   │   ├── group_member.dart
│   │   ├── group_restaurant.dart
│   │   ├── menu_category.dart
│   │   ├── menu_item.dart
│   │   ├── modifier.dart
│   │   ├── order.dart
│   │   ├── order_session.dart
│   │   ├── payment.dart
│   │   └── restaurant.dart
│   ├── providers/           # State management
│   │   ├── auth_provider.dart
│   │   ├── group_provider.dart
│   │   ├── order_provider.dart
│   │   └── restaurant_provider.dart
│   ├── screens/             # UI screens
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── signup_screen.dart
│   │   ├── groups/
│   │   │   ├── add_restaurant_to_group_screen.dart
│   │   │   ├── create_group_screen.dart
│   │   │   ├── group_details_screen.dart
│   │   │   ├── group_list_screen.dart
│   │   │   ├── group_menu_screen.dart
│   │   │   └── join_group_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── orders/
│   │   │   ├── add_order_screen.dart
│   │   │   └── orders_summary_screen.dart
│   │   ├── payments/
│   │   │   └── payment_tracking_screen.dart
│   │   └── restaurants/
│   │       ├── menu_screen.dart
│   │       └── restaurant_list_screen.dart
│   ├── services/            # Business logic
│   │   ├── auth_service.dart
│   │   ├── database_service.dart
│   │   ├── group_service.dart
│   │   ├── restaurant_service.dart
│   │   └── storage_service.dart
│   ├── utils/               # Utilities
│   │   ├── app_logger.dart
│   │   ├── currency_utils.dart
│   │   └── firebase_options.dart
│   ├── widgets/             # Reusable widgets
│   │   └── currency_display.dart
│   └── main.dart            # App entry point
└── pubspec.yaml             # Dependencies
```

## How to Use

### For Team Members:
1. **Sign Up**: Create an account with your email and name, or use Google Sign-In
2. **Join a Group**: Get the Group ID from your team admin and join the group
3. **Browse Menu**: View restaurants added to your group and browse their menus
4. **Place Orders**:
   - Select items from the menu with modifiers and quantities
   - Add custom items with manual entry
   - View your orders in "My Orders" tab
5. **Track Your Spending**: Check your total amount in the Payments tab
6. **Get Notified**: See when the admin closes orders and payments are confirmed

### For Team Admins:
1. **Create a Group**: Set up a new group for your team
2. **Add Members**: Share the Group ID with team members to join
3. **Add Restaurant**: Link a restaurant with API URL for menu integration
4. **Monitor Orders**: View all team orders in the Orders tab
5. **Activate/Deactivate Group**: Control when team members can order
6. **Confirm Orders**: Click "Confirm All Orders" to:
   - Create payment records for all members
   - Automatically deactivate the group
7. **Track Payments**: Mark payments as paid when members settle up

## Database Schema

### Collections

**users/**
- `name`: string
- `email`: string
- `photoUrl`: string (optional)
- `createdAt`: timestamp

**groups/**
- `name`: string
- `description`: string
- `adminId`: userId
- `adminName`: string
- `memberIds`: array of userIds
- `allowMembersToAddItems`: boolean
- `isActive`: boolean (controls if orders can be placed)
- `createdAt`: timestamp

**groupMembers/**
- `groupId`: string
- `userId`: string
- `userName`: string
- `userEmail`: string
- `userPhotoUrl`: string (optional)
- `isAdmin`: boolean
- `joinedAt`: timestamp

**groupRestaurants/**
- `groupId`: string
- `restaurantId`: string
- `restaurantName`: string
- `restaurantApiUrl`: string (menu API endpoint)
- `restaurantImageUrl`: string (optional)
- `restaurantDescription`: string (optional)
- `addedBy`: userId
- `addedByName`: string
- `addedAt`: timestamp

**orders/**
- `sessionId`: string (optional, for backward compatibility)
- `groupId`: string
- `userId`: string
- `userName`: string
- `itemName`: string
- `price`: number
- `quantity`: number (default: 1)
- `imageUrl`: string (optional)
- `createdAt`: timestamp

**payments/**
- `sessionId`: string (optional)
- `groupId`: string
- `userId`: string
- `userName`: string
- `amount`: number
- `paid`: boolean
- `paidAt`: timestamp (optional)
- `createdAt`: timestamp

**orderSessions/** (legacy, for backward compatibility)
- `date`: timestamp
- `createdBy`: userId
- `createdByName`: string
- `status`: "open" | "closed"
- `totalAmount`: number
- `participants`: array of userIds
- `createdAt`: timestamp

## Database Migration

If you have existing groups created before the `isActive` field was added, run this one-time migration:

```dart
import 'package:breakfast_buddy/utils/migrate_groups_add_isactive.dart';

// Check how many groups need migration
final stats = await checkGroupsMissingIsActive();
print('Groups missing isActive: ${stats['missing']}');

// Run migration (only once!)
await migrateGroupsAddIsActive();
```

You can add a temporary button in your settings/debug screen to run this migration, or call it once from your main.dart during development.

## Troubleshooting

**New groups not allowing orders:**
- Check the logs for `Group created:` messages to verify `isActive: true`
- Check `MenuScreen build` logs to see what isActive value is being used
- Run the migration script if you have existing groups from before this field was added
- Verify Firestore rules allow writing the `isActive` field

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
