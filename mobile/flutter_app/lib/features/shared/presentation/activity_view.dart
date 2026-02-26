import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

class ActivityView {
  const ActivityView._();

  static Future<void> share({required List<Object> items}) async {
    if (items.isEmpty) return;

    final textItems = items.whereType<String>().toList();
    final fileItems = items.whereType<XFile>().toList();

    final text = textItems.isEmpty ? null : textItems.join('\n');

    if (fileItems.isNotEmpty) {
      await Share.shareXFiles(fileItems, text: text);
      return;
    }

    if (text != null && text.isNotEmpty) {
      await Share.share(text);
    }
  }
}

class ImagePickerView {
  const ImagePickerView._();

  static final ImagePicker _picker = ImagePicker();

  static Future<XFile?> pickImage({
    ImageSource sourceType = ImageSource.camera,
    bool allowPhotoLibraryFallback = true,
    VoidCallback? onImagePicked,
    VoidCallback? onCancel,
  }) async {
    try {
      final image = await _picker.pickImage(source: sourceType);
      if (image != null) {
        onImagePicked?.call();
        return image;
      }
      onCancel?.call();
      return null;
    } catch (_) {
      if (sourceType == ImageSource.camera && allowPhotoLibraryFallback) {
        try {
          final fallback = await _picker.pickImage(source: ImageSource.gallery);
          if (fallback != null) {
            onImagePicked?.call();
            return fallback;
          }
        } catch (_) {
          // Keep parity with Swift behavior: fail silently and call cancel callback.
        }
      }
      onCancel?.call();
      return null;
    }
  }
}
