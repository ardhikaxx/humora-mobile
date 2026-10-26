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

  /// Storage cap in Megabytes (MB) to prevent unlimited disk growth
  static const double maxStorageCapMb = 500.0;

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
  static Future<File?> downloadAndCacheFile(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      // Auto-prune if cache is nearing or exceeding maxStorageCapMb
      autoPruneIfExceedsLimit();

      final file = await videoCacheManager.getSingleFile(url, headers: headers);
      return file;
    } catch (e) {
      debugPrint('HumoraCacheService: Error caching file $url: $e');
      return null;
    }
  }

  /// Automatically prune oldest cached video files if cache exceeds storage cap (defaults to 500 MB)
  static Future<void> autoPruneIfExceedsLimit({double maxLimitMb = maxStorageCapMb}) async {
    try {
      final currentMb = await calculateTotalCacheSizeMb();
      if (currentMb > maxLimitMb) {
        debugPrint('HumoraCacheService: Cache size (${currentMb.toStringAsFixed(1)} MB) exceeds cap ($maxLimitMb MB). Pruning oldest files...');
        final tempDir = await getTemporaryDirectory();
        if (await tempDir.exists()) {
          final files = <File>[];
          await for (final entity in tempDir.list(recursive: true, followLinks: false)) {
            if (entity is File) {
              files.add(entity);
            }
          }
          // Sort oldest modified first
          files.sort((a, b) {
            try {
              return a.lastModifiedSync().compareTo(b.lastModifiedSync());
            } catch (_) {
              return 0;
            }
          });
          // Remove oldest 30% of files
          final countToRemove = (files.length * 0.3).ceil();
          for (int i = 0; i < countToRemove && i < files.length; i++) {
            try {
              await files[i].delete();
            } catch (_) {}
          }
          debugPrint('HumoraCacheService: Pruned $countToRemove files successfully.');
        }
      }
    } catch (e) {
      debugPrint('HumoraCacheService: Auto prune error: $e');
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
