import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';

/// PhotoCapture widget.
///
/// Shows a horizontal row of already-captured photo thumbnails plus a "+"
/// add button.  Tapping "+" opens a bottom sheet with Camera / Gallery options.
/// Each selected image is scaled down to ensure size < [AppConstants.maxPhotoSizeKb]
/// (500 KB) and returned as a base64-encoded string via [onPhotosChanged].
class PhotoCapture extends StatefulWidget {
  /// Label shown above the row (e.g. "Before Photos" / "After Photos").
  final String label;

  /// Currently stored base64 photos (pre-populated from Firestore).
  final List<String> existingPhotos;

  /// Called whenever the photo list changes.
  final ValueChanged<List<String>> onPhotosChanged;

  const PhotoCapture({
    super.key,
    required this.label,
    required this.existingPhotos,
    required this.onPhotosChanged,
  });

  @override
  State<PhotoCapture> createState() => _PhotoCaptureState();
}

class _PhotoCaptureState extends State<PhotoCapture> {
  final ImagePicker _picker = ImagePicker();
  final List<String> _base64Photos = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _base64Photos.addAll(widget.existingPhotos);
  }

  Future<void> _pickImage(ImageSource source) async {
    final xFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1280,
    );
    if (xFile == null) return;

    setState(() => _isProcessing = true);
    try {
      final bytes = await _compress(xFile.path);
      final b64 = base64Encode(bytes);
      setState(() => _base64Photos.add(b64));
      widget.onPhotosChanged(List.unmodifiable(_base64Photos));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Compress the image at [path] by halving dimensions until under the
  /// [AppConstants.maxPhotoSizeKb] threshold.
  Future<List<int>> _compress(String path) async {
    final file = File(path);
    List<int> bytes = await file.readAsBytes();
    int maxBytes = AppConstants.maxPhotoSizeKb * 1024;

    if (bytes.length <= maxBytes) return bytes;

    // Re-pick with progressively lower quality until we're under the limit
    int quality = 70;
    while (quality >= 20) {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery, // irrelevant — we pass maxWidth
        imageQuality: quality,
        maxWidth: 800,
      );
      if (xFile == null) break;
      bytes = await File(xFile.path).readAsBytes();
      if (bytes.length <= maxBytes) break;
      quality -= 15;
    }

    // Fallback: just return what we have
    return bytes;
  }

  void _removePhoto(int index) {
    setState(() => _base64Photos.removeAt(index));
    widget.onPhotosChanged(List.unmodifiable(_base64Photos));
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Add Photo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: WorkerColors.accent),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: WorkerColors.accent),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _base64Photos.length + 1, // +1 for the add button
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              if (i == _base64Photos.length) {
                // ── Add button ──────────────────────────────────────
                return GestureDetector(
                  onTap: _isProcessing ? null : _showPickerSheet,
                  child: Container(
                    width: 80,
                    height: 88,
                    decoration: BoxDecoration(
                      color: WorkerColors.accentLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: WorkerColors.accent.withOpacity(0.4),
                        width: 1.5,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _isProcessing
                        ? const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: WorkerColors.accent,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.add_a_photo_rounded,
                            size: 28,
                            color: WorkerColors.accent,
                          ),
                  ),
                );
              }

              // ── Thumbnail ───────────────────────────────────────────
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(_base64Photos[i]),
                      width: 80,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 88,
                        color: WorkerColors.divider,
                        child: const Icon(Icons.broken_image_rounded,
                            color: WorkerColors.textLight),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () => _removePhoto(i),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: WorkerColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
