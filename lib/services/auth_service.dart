import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';
import '../utils/app_logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      AppLogger.info('Starting signup for email: $email');

      // Create user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? firebaseUser = result.user;
      if (firebaseUser == null) {
        AppLogger.error('Firebase user is null after signup');
        return null;
      }

      AppLogger.info('Firebase user created: ${firebaseUser.uid}');

      // Create user document in Firestore
      AppUser newUser = AppUser(
        id: firebaseUser.uid,
        name: name,
        email: email,
        createdAt: DateTime.now(),
      );

      AppLogger.debug('Attempting to save user document to Firestore...');
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(newUser.toFirestore());

      AppLogger.info('User document saved successfully');

      // Update display name
      await firebaseUser.updateDisplayName(name);
      AppLogger.debug('Display name updated');

      return newUser;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('FirebaseAuthException: ${e.code} - ${e.message}', e);
      throw _handleAuthException(e);
    } catch (e) {
      AppLogger.error('Unexpected error during signup', e);
      throw 'An error occurred during sign up: $e';
    }
  }

  // Sign in with email and password
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? firebaseUser = result.user;
      if (firebaseUser == null) return null;

      // Get user data from Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!userDoc.exists) return null;

      return AppUser.fromFirestore(userDoc);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An error occurred during sign in. Please try again.';
    }
  }

  // Sign in with Google
  Future<AppUser?> signInWithGoogle() async {
    try {
      AppLogger.info('Starting Google Sign-In...');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        AppLogger.info('Google Sign-In cancelled by user');
        return null; // User cancelled the sign-in
      }

      AppLogger.info('Google user selected: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      AppLogger.debug('Got Google auth tokens');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      AppLogger.debug('Created Firebase credential');

      // Sign in to Firebase with the Google credential
      UserCredential result = await _auth.signInWithCredential(credential);

      User? firebaseUser = result.user;
      if (firebaseUser == null) {
        AppLogger.error('Firebase user is null after Google Sign-In');
        return null;
      }

      AppLogger.info('Firebase user authenticated: ${firebaseUser.uid}');

      // Check if user document exists in Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      AppUser appUser;

      if (!userDoc.exists) {
        AppLogger.info('Creating new user document in Firestore...');
        // Create new user document if it doesn't exist
        appUser = AppUser(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? googleUser.displayName ?? 'User',
          email: firebaseUser.email ?? googleUser.email,
          photoUrl: firebaseUser.photoURL ?? googleUser.photoUrl,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(appUser.toFirestore());

        AppLogger.info('User document created successfully');
      } else {
        AppLogger.debug('User document already exists, loading...');
        appUser = AppUser.fromFirestore(userDoc);
      }

      return appUser;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('FirebaseAuthException during Google Sign-In: ${e.code} - ${e.message}', e);
      throw _handleAuthException(e);
    } catch (e) {
      AppLogger.error('Unexpected error during Google Sign-In', e);
      throw 'An error occurred during Google Sign-In: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw 'An error occurred during sign out. Please try again.';
    }
  }

  // Get current user data from Firestore
  Future<AppUser?> getCurrentUserData() async {
    try {
      User? firebaseUser = currentUser;
      if (firebaseUser == null) return null;

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!userDoc.exists) return null;

      return AppUser.fromFirestore(userDoc);
    } catch (e) {
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? photoUrl,
  }) async {
    try {
      User? firebaseUser = currentUser;
      if (firebaseUser == null) throw 'No user logged in';

      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .update(updates);

      if (name != null) {
        await firebaseUser.updateDisplayName(name);
      }
      if (photoUrl != null) {
        await firebaseUser.updatePhotoURL(photoUrl);
      }
    } catch (e) {
      throw 'Failed to update profile. Please try again.';
    }
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send password reset email. Please try again.';
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
