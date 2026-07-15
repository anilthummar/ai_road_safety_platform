import 'package:ai_road_safety_platform/core/services/app_logger.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/entities/dataset_storage_entities.dart';
import 'package:ai_road_safety_platform/features/dataset_collection/domain/services/dataset_file_manager.dart';

/// Default [StorageManager] — folder-size based soft budget.
class StorageManagerImpl implements StorageManager {
  final DatasetFileManager _files;
  final AppLogger _logger;

  @override
  final int softLimitBytes;

  /// Free-bytes unknown floor used when OS does not report capacity.
  final int criticalUsedBytes;

  /// Creates [StorageManagerImpl].
  StorageManagerImpl({
    required DatasetFileManager fileManager,
    required AppLogger logger,
    this.softLimitBytes = 2 * 1024 * 1024 * 1024, // 2 GiB soft budget
    this.criticalUsedBytes = 1800 * 1024 * 1024,
  })  : _files = fileManager,
        _logger = logger;

  @override
  Future<StorageUsage> calculateUsage() async {
    await _files.ensureRootLayout();
    final root = _files.paths.root;
    final used = await _files.directoryByteSize(root);
    final isLow = used >= softLimitBytes * 0.9 || used >= criticalUsedBytes;
    String? warning;
    if (isLow) {
      warning =
          'Low storage: dataset folder is using ${_formatBytes(used)} '
          '(soft limit ${_formatBytes(softLimitBytes)}).';
      _logger.warning('Low Storage Warning: $warning', tag: 'StorageManager');
    }
    return StorageUsage(
      datasetRoot: root,
      usedBytes: used,
      freeBytes: 0,
      totalBytes: 0,
      softLimitBytes: softLimitBytes,
      isLowStorage: isLow,
      warningMessage: warning,
    );
  }

  @override
  Future<bool> isStorageCriticallyLow() async {
    final usage = await calculateUsage();
    return usage.isLowStorage && usage.usedBytes >= criticalUsedBytes;
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(1)} ${units[unit]}';
  }
}

/// Async compute placeholder for encode / IO chains.
class StorageBackgroundProcessorImpl implements StorageBackgroundProcessor {
  bool _disposed = false;

  @override
  Future<T> runAsync<T>(Future<T> Function() work) async {
    if (_disposed) {
      throw StateError('StorageBackgroundProcessor disposed');
    }
    // Future isolate hook — keep non-blocking await chain for Phase 12.5.
    return work();
  }

  @override
  void dispose() => _disposed = true;
}
