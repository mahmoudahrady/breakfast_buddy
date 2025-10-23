import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Quick Firebase connection test
/// Run this to verify Firebase is properly configured
Future<void> testFirebaseConnection() async {
  print('=== Testing Firebase Connection ===');

  try {
    // Test Firebase Auth
    print('1. Testing Firebase Auth...');
    final auth = FirebaseAuth.instance;
    print('   ✓ Firebase Auth initialized');
    print('   Current user: ${auth.currentUser?.email ?? "None"}');

    // Test Firestore
    print('2. Testing Firestore...');
    final firestore = FirebaseFirestore.instance;
    print('   ✓ Firestore initialized');

    // Try to read from Firestore (this will fail if rules are too restrictive, but that's ok)
    try {
      await firestore.collection('test').limit(1).get();
      print('   ✓ Firestore connection successful');
    } catch (e) {
      print('   ⚠ Firestore read failed (this is normal if not authenticated): $e');
    }

    print('\n=== Firebase Configuration Test Complete ===');
    print('If you see errors above, check:');
    print('1. Firebase Console -> Authentication -> Sign-in method');
    print('2. Enable Email/Password provider');
    print('3. Firebase Console -> Firestore -> Rules');

  } catch (e) {
    print('❌ Firebase Error: $e');
  }
}
