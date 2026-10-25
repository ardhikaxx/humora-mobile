import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Map<String, double> _downloadProgress = {};
  final ValueNotifier<Map<String, double>> progressNotifier = ValueNotifier({});

  void initialize() {
    FileDownloader().updates.listen((update) {
      if (update is TaskProgressUpdate) {
        _downloadProgress[update.task.taskId] = update.progress;
        progressNotifier.value = Map.from(_downloadProgress);
      } else if (update is TaskStatusUpdate) {
        if (update.status == TaskStatus.complete ||
            update.status == TaskStatus.failed ||
            update.status == TaskStatus.canceled) {
          _downloadProgress.remove(update.task.taskId);
          progressNotifier.value = Map.from(_downloadProgress);
        }
      }
    });
  }

  /// Task ID based on episode ID
  static String getTaskId(String episodeId) => 'episode_download_$episodeId';

  /// Filename for saved video
  static String getFileName(String episodeId) => 'humora_ep_$episodeId.mp4';

  /// Check if video is currently downloading
  bool isDownloading(String episodeId) {
    return _downloadProgress.containsKey(getTaskId(episodeId));
  }

  /// Get current progress ratio (0.0 - 1.0)
  double getProgress(String episodeId) {
    return _downloadProgress[getTaskId(episodeId)] ?? 0.0;
  }

  /// Enqueue or start background download for a comedy episode
  Future<bool> startDownload({
    required String episodeId,
    required String url,
    required String episodeTitle,
    Map<String, String>? headers,
  }) async {
    try {
      final taskId = getTaskId(episodeId);
      final fileName = getFileName(episodeId);

      final task = DownloadTask(
        taskId: taskId,
        url: url,
        filename: fileName,
        headers: headers ?? {},
        displayName: episodeTitle,
        baseDirectory: BaseDirectory.applicationDocuments,
        directory: 'humora_offline_videos',
        updates: Updates.statusAndProgress,
        retries: 3,
        allowPause: true,
      );

      final enqueued = await FileDownloader().enqueue(task);
      if (enqueued) {
        _downloadProgress[taskId] = 0.0;
        progressNotifier.value = Map.from(_downloadProgress);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('DownloadService error starting download: $e');
      return false;
    }
  }

  /// Cancel an ongoing download
  Future<void> cancelDownload(String episodeId) async {
    final taskId = getTaskId(episodeId);
    await FileDownloader().cancelTaskWithId(taskId);
    _downloadProgress.remove(taskId);
    progressNotifier.value = Map.from(_downloadProgress);
  }

  /// Check if the episode video file has already been downloaded and exists locally
  Future<bool> isEpisodeDownloaded(String episodeId) async {
    try {
      final file = await getOfflineVideoFile(episodeId);
      return file != null && await file.exists() && (await file.length()) > 1024;
    } catch (_) {
      return false;
    }
  }

  /// Get the offline File object if downloaded
  Future<File?> getOfflineVideoFile(String episodeId) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final targetPath = '${appDocDir.path}/humora_offline_videos/${getFileName(episodeId)}';
      final file = File(targetPath);
      if (await file.exists()) {
        return file;
      }
    } catch (e) {
      debugPrint('DownloadService: Error finding downloaded video: $e');
    }
    return null;
  }

  /// Delete an offline downloaded episode to free up storage
  Future<bool> deleteDownloadedEpisode(String episodeId) async {
    try {
      final file = await getOfflineVideoFile(episodeId);
      if (file != null && await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      debugPrint('DownloadService: Error deleting file: $e');
    }
    return false;
  }
}
