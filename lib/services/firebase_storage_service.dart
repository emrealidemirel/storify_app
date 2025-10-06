import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirebaseStorageService {
  static Future<String?> uploadUserProfileImage(File file, String userId) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('users/$userId/profile.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        print('Upload failed: $e');
      }
      return null;
    }
  }
}