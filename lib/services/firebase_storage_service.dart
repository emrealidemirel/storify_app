import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage? _storage;
  FirebaseStorageService({FirebaseStorage? storage}) : _storage = storage;
  FirebaseStorage get storage => _storage ?? FirebaseStorage.instance;
  static const maxImageBytes = 5 * 1024 * 1024;

  static String imageContentType(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes.take(8).join(',') == '137,80,78,71,13,10,26,10') {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
      return 'image/webp';
    }
    throw const FormatException('Unsupported image format.');
  }

  Future<String> uploadProfileImage(File file, String userId) async {
    if (await file.length() > maxImageBytes) {
      throw const FormatException('Profile image exceeds 5 MB.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > maxImageBytes) {
      throw const FormatException('Image too large.');
    }
    final type = imageContentType(bytes);
    // Preserve the existing path for installed users.
    final ref = storage.ref('users/$userId/profile.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: type));
    return ref.getDownloadURL();
  }

  Future<void> submitStoryReport({
    required String userId,
    required List<String> passages,
    required List<String> choices,
    required String reason,
  }) async {
    if (passages.isEmpty ||
        !{'unsafe', 'offensive', 'other'}.contains(reason)) {
      throw const FormatException('Invalid report.');
    }
    final bytes = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'version': 1,
          'reason': reason,
          'passages': passages,
          'choices': choices,
        }),
      ),
    );
    if (bytes.length > 128 * 1024) {
      throw const FormatException('Report too large.');
    }
    final id = DateTime.now().microsecondsSinceEpoch;
    await storage
        .ref('users/$userId/reports/$id.json')
        .putData(bytes, SettableMetadata(contentType: 'application/json'));
  }

  Future<void> deleteUserData(String userId) async {
    // Restart the first page after deletion: a changing collection must not
    // cause a pagination cursor to skip files. This is safe to retry.
    final reports = storage.ref('users/$userId/reports');
    while (true) {
      final page = await reports.list(const ListOptions(maxResults: 100));
      if (page.items.isEmpty) break;
      for (final ref in page.items) {
        await _deleteIfPresent(ref);
      }
    }
    await _deleteIfPresent(storage.ref('users/$userId/profile.jpg'));
  }

  Future<void> _deleteIfPresent(Reference ref) async {
    try {
      await ref.delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
  }
}
