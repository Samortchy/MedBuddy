import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_db.dart';

/// Holds the on-device profile image (from SQFLite) for a given user id.
class ProfileImageNotifier extends StateNotifier<Uint8List?> {
  final String userId;

  ProfileImageNotifier(this.userId) : super(null) {
    _load();
  }

  Future<void> _load() async {
    state = await LocalDb.instance.getProfileImage(userId);
  }

  Future<void> setImage(Uint8List bytes) async {
    await LocalDb.instance.saveProfileImage(userId, bytes);
    state = bytes;
  }

  Future<void> clear() async {
    await LocalDb.instance.deleteProfileImage(userId);
    state = null;
  }
}

final profileImageProvider =
    StateNotifierProvider.family<ProfileImageNotifier, Uint8List?, String>(
  (ref, userId) => ProfileImageNotifier(userId),
);
