import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

class HumoraCacheService {
  static const String videoCacheKey = 'humora_video_cache';

  // Dedicated cache manager for videos with 14-day retention and up to 100 files
  static final CacheManager videoCacheManager = CacheManager(
    Config(
      videoCacheKey,
      stalePeriod: const Duration(days: 14),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: videoCacheKey),
      fileService: HttpFileService(),
    ),
  );

  /// Checks if a video file for [url] is already saved locally in cache.
  static Future<File?> getCachedVideoFile(String url) async {
    try {
      final fileInfo = await videoCacheManager.getFileFromCache(url);
      if (fileInfo != null && await fileInfo.file.exists()) {
        return fileInfo.file;
      }
    } catch (e) {
      debugPrint('HumoraCacheService: Error getting cached video file: $e');
    }
    return null;
  }

  /// Downloads and caches a video or media file in background or returns the existing cached file
  static Future<File?> downloadAndCacheFile(String url) async {
    try {
      final file = await videoCacheManager.getSingleFile(url);
      return file;
    } catch (e) {
      debugPrint('HumoraCacheService: Error caching file $url: $e');
      return null;
    }
  }

  /// Calculates total real cache size in Megabytes (MB)
  static Future<double> calculateTotalCacheSizeMb() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int totalBytes = 0;

      if (await tempDir.exists()) {
        await for (final entity in tempDir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            try {
              totalBytes += await entity.length();
            } catch (_) {}
          }
        }
      }

      final mb = totalBytes / (1024 * 1024);
      return mb < 0.1 ? 0.0 : double.parse(mb.toStringAsFixed(1));
    } catch (e) {
      debugPrint('HumoraCacheService: Error calculating cache size: $e');
      return 0.0;
    }
  }

  /// Empties both DefaultCacheManager (images/posters) and videoCacheManager (videos)
  static Future<void> clearAllCache() async {
    try {
      await DefaultCacheManager().emptyCache();
    } catch (e) {
      debugPrint('HumoraCacheService: Error clearing DefaultCacheManager: $e');
    }

    try {
      await videoCacheManager.emptyCache();
    } catch (e) {
      debugPrint('HumoraCacheService: Error clearing videoCacheManager: $e');
    }

    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final list = tempDir.listSync(followLinks: false);
        for (final entity in list) {
          final name = entity.uri.pathSegments.isNotEmpty
              ? entity.uri.pathSegments.where((s) => s.isNotEmpty).last
              : '';
          if (name.contains('humora') || name.contains('libCachedImageData') || name.contains('cache')) {
            try {
              await entity.delete(recursive: true);
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('HumoraCacheService: Error clearing tempDir: $e');
    }
  }
}
