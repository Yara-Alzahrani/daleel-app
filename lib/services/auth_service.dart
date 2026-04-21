import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // Sign up with email and password
  Future<String?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Send email verification
      await result.user?.sendEmailVerification();
      
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    } catch (e) {
      print('Sign up error: $e');
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign in with email
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('Sign in successful: ${result.user?.email}');
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth error: ${e.code} - ${e.message}');
      return _getErrorMessage(e.code);
    } catch (e) {
      print('Sign in error: $e');
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign up with phone number
  Future<String?> signUpWithPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _auth.signInWithCredential(credential);
            notifyListeners();
          } catch (e) {
            print('Auto verification error: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Phone verification failed: ${e.code} - ${e.message}');
          throw Exception(_getErrorMessage(e.code));
        },
        codeSent: (String verificationId, int? resendToken) {
          print('Code sent successfully');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Auto retrieval timeout');
        },
      );
      return null;
    } catch (e) {
      print('Phone sign up error: $e');
      return e.toString();
    }
  }

  // Verify phone OTP
  Future<String?> verifyPhoneOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      
      await _auth.signInWithCredential(credential);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      print('OTP verification error: ${e.code} - ${e.message}');
      return _getErrorMessage(e.code);
    } catch (e) {
      print('OTP error: $e');
      return 'Invalid verification code';
    }
  }

  // Sign in with phone
  Future<String?> signInWithPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
  }) async {
    return await signUpWithPhone(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
    );
  }

  // Reset password
  Future<String?> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      print('Password reset error: ${e.code} - ${e.message}');
      return _getErrorMessage(e.code);
    } catch (e) {
      print('Reset password error: $e');
      return 'Failed to send reset email';
    }
  }

  // Save user info to Firestore
  Future<String?> saveUserInfo({
    required String name,
    required String email,
    required String phone,
    required String gender,
    required String nationality,
    String? profileImageUrl,
  }) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        return 'User not authenticated';
      }

      await _firestore.collection('users').doc(userId).set({
        'name': name,
        'email': email,
        'phone': phone,
        'gender': gender,
        'nationality': nationality,
        'profileImageUrl': profileImageUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('User info saved successfully');
      return null;
    } catch (e) {
      print('Save user info error: $e');
      return 'Failed to save user information';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  // Error message helper
  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password should be at least 6 characters';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-verification-code':
        return 'Invalid verification code';
      case 'invalid-phone-number':
        return 'Invalid phone number';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Check your connection';
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'user-disabled':
        return 'This account has been disabled';
      default:
        return 'An error occurred. Please try again';
    }
  }
}