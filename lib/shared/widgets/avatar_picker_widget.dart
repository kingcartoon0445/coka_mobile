import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AvatarPickerWidget extends StatelessWidget {
  final File? avatarFile;
  final Function(File?) onAvatarSelected;

  const AvatarPickerWidget({
    super.key,
    this.avatarFile,
    required this.onAvatarSelected,
  });

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      onAvatarSelected(File(image.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: avatarFile == null ? const Color(0xFFF9FAFB) : null,
        ),
        child: avatarFile != null
            ? ClipOval(
                child: Image.file(
                  avatarFile!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              )
            : const Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.person,
                    size: 32,
                    color: Color(0xFF667085),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Icon(
                      Icons.camera_alt_outlined,
                      size: 18,
                      color: Color(0xFF667085),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
} 