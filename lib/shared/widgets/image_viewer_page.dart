import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

class ImageViewerPage extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;

  const ImageViewerPage({
    super.key,
    this.imageUrl,
    this.imageFile,
  }) : assert(imageUrl != null || imageFile != null, 'Either imageUrl or imageFile must be provided');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PhotoView(
        imageProvider: imageFile != null 
            ? FileImage(imageFile!) as ImageProvider
            : CachedNetworkImageProvider(imageUrl!),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
      ),
    );
  }
}
