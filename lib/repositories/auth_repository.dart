import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Future<User?> signInWithGoogle();
  Future<User?> signInWithApple();
  Future<void> updateProfile({String? displayName, File? image});
  Future<void> sendEmailVerification();
  Future<User?> signInWithEmail(String email, String password);
  Future<User?> signUpWithEmail(String email, String password);
  Future<User?> signInAnonymously();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  User? getCurrentUser();
  Future<void> verifyAndUpdateEmail(String newEmail, String currentPassword);
  Future<void> updatePassword(String currentPassword, String newPassword);
  Future<void> deleteAccount([String? currentPassword]);
}
