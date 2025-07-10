import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:coka/core/utils/helpers.dart';

enum AvatarShape { circle, rectangle }

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final String? fallbackText;
  final AvatarShape shape;
  final double borderRadius;
  final Color? fallbackBackgroundColor;
  final Color fallbackTextColor;
  final BoxBorder? outline;
  final BoxFit fit;
  final Widget? errorWidget;
  final Widget? placeholder;
  final String? cacheKey; // Thêm cache key để force refresh khi cần

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.size = 40.0,
    this.fallbackText,
    this.shape = AvatarShape.circle,
    this.borderRadius = 0.0,
    this.fallbackBackgroundColor,
    this.fallbackTextColor = Colors.white,
    this.outline,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.placeholder,
    this.cacheKey,
  });

  String _getDisplayText() {
    if (fallbackText == null || fallbackText!.trim().isEmpty) return '';

    final words = fallbackText!.trim().split(' ');
    if (words.length == 1) {
      final word = words[0];
       if (word.isEmpty) return '';
      return word[0].toUpperCase();
    }

    final firstInitial = words.first.isNotEmpty ? words.first[0] : '';
    final lastInitial = words.last.isNotEmpty ? words.last[0] : '';

    return '$firstInitial$lastInitial'.toUpperCase();
  }

  static Widget _buildShimmerPlaceholder(double size, AvatarShape shape, double borderRadius) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: shape == AvatarShape.circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: shape == AvatarShape.rectangle
              ? BorderRadius.circular(borderRadius)
              : null,
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(BuildContext context) {
    final displayShape = shape == AvatarShape.circle ? BoxShape.circle : BoxShape.rectangle;
    final displayBorderRadius = shape == AvatarShape.rectangle ? BorderRadius.circular(borderRadius) : null;
    final text = _getDisplayText();
    final hasText = text.isNotEmpty;
    final bgColor = fallbackBackgroundColor ??
        (hasText ? Helpers.getColorFromText(fallbackText!) : Colors.grey[300]);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: displayShape,
        borderRadius: displayBorderRadius,
        border: outline,
      ),
      child: Center(
        child: hasText
            ? Text(
                text,
                style: TextStyle(
                  color: fallbackTextColor,
                  fontSize: size * 0.4, // Adjust font size relative to avatar size
                  fontWeight: FontWeight.bold,
                ),
              )
            : Icon(
                Icons.person, // Default icon if no text
                color: fallbackTextColor.withValues(alpha: 0.6),
                size: size * 0.6,
              ),
      ),
    );
  }

  Widget _buildImageAvatar(BuildContext context) {
    final effectivePlaceholder = placeholder ?? _buildShimmerPlaceholder(size, shape, borderRadius);
    final effectiveErrorWidget = errorWidget ?? _buildFallbackAvatar(context); // Use fallback as error widget by default

    // Thêm cache buster nếu có cacheKey
    final avatarUrl = Helpers.getAvatarUrl(imageUrl!);
    final finalUrl = cacheKey != null ? '$avatarUrl?v=$cacheKey' : avatarUrl;

    final imageWidget = CachedNetworkImage(
      imageUrl: finalUrl,
      width: size,
      height: size,
      fit: fit,
      placeholder: (context, url) => effectivePlaceholder,
      errorWidget: (context, url, error) => effectiveErrorWidget,
      // Force refresh cache nếu có cache key mới
      cacheKey: cacheKey != null ? '${imageUrl}_$cacheKey' : null,
    );

    if (shape == AvatarShape.circle) {
      return Container(
         decoration: BoxDecoration(
           shape: BoxShape.circle,
           border: outline,
         ),
         child: ClipOval(
           child: imageWidget,
         ),
      );
    } else {
       return Container(
         decoration: BoxDecoration(
           shape: BoxShape.rectangle,
           borderRadius: BorderRadius.circular(borderRadius),
           border: outline,
         ),
         child: ClipRRect(
           borderRadius: BorderRadius.circular(borderRadius),
           child: imageWidget,
         ),
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallbackAvatar(context);
    } else {
      return _buildImageAvatar(context);
    }
  }
}
