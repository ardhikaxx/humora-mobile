import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class HumoraImage extends StatelessWidget {
  final String imagePathOrUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const HumoraImage({
    super.key,
    required this.imagePathOrUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    final trimmed = imagePathOrUrl.trim();

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      imageWidget = CachedNetworkImage(
        imageUrl: trimmed,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: AppColors.primaryPurple.withValues(alpha: 0.15),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryPurple,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallback(),
      );
    } else {
      imageWidget = Image.asset(
        trimmed.isNotEmpty ? trimmed : 'assets/images/thumbnails/thumb_caradeketin.png',
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: AppColors.primaryPurple,
      child: const Center(
        child: Icon(
          Icons.movie_outlined,
          color: Colors.white54,
          size: 28,
        ),
      ),
    );
  }
}
