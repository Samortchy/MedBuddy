import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_image_provider.dart';

/// Circular profile avatar that shows the on-device (SQFLite) photo for the
/// currently signed-in user, and lets them set it from camera/gallery.
class ProfileAvatar extends ConsumerWidget {
  final double size;
  final Color background;
  final Color iconColor;

  const ProfileAvatar({
    super.key,
    this.size = 80,
    this.background = MedBuddyColors.pureWhite,
    this.iconColor = MedBuddyColors.primary,
  });

  Future<void> _pick(
      BuildContext context, WidgetRef ref, String userId, ImageSource src) async {
    try {
      final picker = ImagePicker();
      final picked =
          await picker.pickImage(source: src, imageQuality: 70, maxWidth: 800);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      await ref.read(profileImageProvider(userId).notifier).setImage(bytes);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not set photo: $e')),
        );
      }
    }
  }

  void _showOptions(
      BuildContext context, WidgetRef ref, String userId, bool hasImage) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MedBuddyColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: MedBuddyColors.primary),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pick(context, ref, userId, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: MedBuddyColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pick(context, ref, userId, ImageSource.gallery);
              },
            ),
            if (hasImage)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: MedBuddyColors.emergency),
                title: const Text('Remove Photo',
                    style: TextStyle(color: MedBuddyColors.emergency)),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(profileImageProvider(userId).notifier).clear();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider)?.userId;
    final image = userId == null ? null : ref.watch(profileImageProvider(userId));

    return GestureDetector(
      onTap: userId == null
          ? null
          : () => _showOptions(context, ref, userId, image != null),
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: background,
              border: Border.all(color: MedBuddyColors.primaryLight, width: 2),
              image: image != null
                  ? DecorationImage(image: MemoryImage(image), fit: BoxFit.cover)
                  : null,
            ),
            child: image == null
                ? Icon(Icons.person_outline, color: iconColor, size: size * 0.5)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(size * 0.06),
              decoration: BoxDecoration(
                color: MedBuddyColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: MedBuddyColors.pureWhite, width: 2),
              ),
              child: Icon(Icons.camera_alt,
                  color: MedBuddyColors.pureWhite, size: size * 0.18),
            ),
          ),
        ],
      ),
    );
  }
}
