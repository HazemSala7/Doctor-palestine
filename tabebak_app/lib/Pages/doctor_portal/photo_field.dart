import 'dart:io';

import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/Pages/booking/booking_widgets.dart' show kCancelledColor;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Picks from the gallery, shrunk well below the server's 5 MB limit.
/// Null when the doctor backs out or the gallery can't be opened.
Future<String?> pickPhotoPath() async {
  try {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
      maxHeight: 1400,
      imageQuality: 85,
    );
    return file?.path;
  } on PlatformException {
    return null;
  }
}

/// Null when the doctor backs out or the gallery can't be opened.
Future<String?> pickVideoPath() async {
  try {
    return (await ImagePicker().pickVideo(source: ImageSource.gallery))?.path;
  } on PlatformException {
    return null;
  }
}

/// A round photo with buttons to change or remove it.
class PhotoField extends StatelessWidget {
  final String? url;
  final String? pickedPath;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final double size;
  final IconData placeholderIcon;

  const PhotoField({
    super.key,
    this.url,
    this.pickedPath,
    required this.onPick,
    required this.onRemove,
    this.size = 104,
    this.placeholderIcon = Icons.person_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Icon(placeholderIcon,
        size: size * 0.55, color: kBrandPrimary.withValues(alpha: 0.5));
    final hasPhoto = pickedPath != null || url != null;

    return Column(
      children: [
        InkWell(
          customBorder: const CircleBorder(),
          onTap: onPick,
          child: Container(
            width: size,
            height: size,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
                color: kBrandSky, shape: BoxShape.circle),
            child: pickedPath != null
                ? Image.file(File(pickedPath!), fit: BoxFit.cover)
                : url != null
                    ? Image.network(url!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => placeholder)
                    : placeholder,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: Text(hasPhoto ? 'تغيير الصورة' : 'إضافة صورة'),
            ),
            if (hasPhoto)
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: kCancelledColor),
                label: const Text('إزالة',
                    style: TextStyle(color: kCancelledColor)),
              ),
          ],
        ),
      ],
    );
  }
}
