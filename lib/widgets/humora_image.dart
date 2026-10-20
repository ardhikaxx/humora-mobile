import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/network/api_config.dart';
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
    String trimmed = imagePathOrUrl.trim();

    // If relative path from API (e.g. /storage/... or storage/...)
    if (trimmed.startsWith('/storage/') || trimmed.startsWith('storage/')) {
      final baseHost = ApiConfig.baseUrl.replaceFirst('/api/v1', '');
      final leadingSlash = trimmed.startsWith('/') ? '' : '/';
      trimmed = '$baseHost$leadingSlash$trimmed';
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      // Normalize host against ApiConfig.baseUrl to adapt localhost / 10.0.2.2 / LAN IP
      final baseUri = Uri.tryParse(ApiConfig.baseUrl);
      final imgUri = Uri.tryParse(trimmed);
      if (baseUri != null && imgUri != null && imgUri.hasScheme && imgUri.hasAuthority) {
        if (imgUri.authority != baseUri.authority) {
          trimmed = imgUri.replace(
            scheme: baseUri.scheme,
            host: baseUri.host,
            port: baseUri.hasPort ? baseUri.port : null,
          ).toString();
        }
      }

      imageWidget = CachedNetworkImage(
        imageUrl: trimmed,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A1647), Color(0xFF140D26)],
            ),
          ),
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
    } else if (trimmed.startsWith('assets/')) {
      imageWidget = Image.asset(
        trimmed,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    } else {
      imageWidget = _buildFallback();
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E1752), Color(0xFF190F30)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.movie_filter_rounded,
          color: Colors.white38,
          size: 28,
        ),
      ),
    );
  }
}
