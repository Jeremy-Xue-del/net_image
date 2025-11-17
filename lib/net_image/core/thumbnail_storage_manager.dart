import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/image_utils.dart';
import '../../blur_hash/blur_hash.dart';

/// 缩略图存储管理器单例
class ThumbnailStorageManager {
  static final ThumbnailStorageManager _instance = ThumbnailStorageManager._internal();
  factory ThumbnailStorageManager() => _instance;
  ThumbnailStorageManager._internal();

  String? _thumbnailDirectory;

  /// 初始化缩略图存储目录
  /// 应在应用启动时调用
  Future<void> initialize({String? customDirectory}) async {
    if (customDirectory != null) {
      _thumbnailDirectory = customDirectory;
    } else {
      // 默认存储目录
      final baseDir = await getApplicationDocumentsDirectory();
      _thumbnailDirectory = '${baseDir.parent.path}/net_image/thumbnails';
    }

    // 确保目录存在
    final dir = Directory(_thumbnailDirectory!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// 获取缩略图存储目录
  Future<String> _getThumbnailDirectory() async {
    if (_thumbnailDirectory == null) {
      // 如果未初始化，使用默认目录
      final baseDir = await getApplicationDocumentsDirectory();
      _thumbnailDirectory = '${baseDir.parent.path}/net_image/thumbnails';

      // 确保目录存在
      final dir = Directory(_thumbnailDirectory!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
    return _thumbnailDirectory!;
  }

  /// 通过路径获取缩略图文件
  /// [localPath] 本地缩略图文件路径
  /// 如果文件存在直接返回，否则返回null
  Future<File?> getThumbnailByPath(String localPath) async {
    try {
      final file = File(localPath);
      if (await file.exists()) {
        return file;
      }
    } catch (e) {
      debugPrint('通过路径获取缩略图失败: $e');
    }
    return null;
  }

  /// 生成并保存缩略图
  /// [blurHash] blurHash字符串
  /// [width] 生成宽度
  /// [height] 生成高度
  /// 返回保存的文件路径
  Future<String> generateAndSaveThumbnail({
    required String blurHash,
    int width = 32,
    int height = 32,
  }) async {
    try {
      // 生成blurHash图像数据
      final pixels = await blurHashDecodeImage(
        blurHash: blurHash,
        width: width,
        height: height,
      );

      // 将图像数据编码为PNG格式
      final byteData = await pixels.toByteData(format: ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('无法将图像转换为PNG格式');
      }

      // 获取文件路径
      final thumbDir = await _getThumbnailDirectory();
      final fileName = ImageUtils.getSafeFileName(blurHash);
      final filePath = '$thumbDir/$fileName';

      // 保存到文件
      final file = File(filePath);
      await file.create(recursive: true);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return filePath;
    } catch (e) {
      // 如果生成失败，返回空字符串
      debugPrint('生成缩略图失败: $e');
      rethrow;
    }
  }

  /// 保存本地缩略图文件到管理目录
  /// [localPath] 本地缩略图文件路径
  /// [blurHash] 对应的blurHash（用于生成文件名）
  /// 返回保存后的文件路径
  Future<String> saveLocalThumbnail({
    required String localPath,
    required String blurHash,
  }) async {
    try {
      final sourceFile = File(localPath);
      if (!await sourceFile.exists()) {
        throw Exception('本地缩略图文件不存在: $localPath');
      }

      // 获取目标文件路径
      final thumbDir = await _getThumbnailDirectory();
      final fileName = ImageUtils.getSafeFileName(blurHash);
      final targetPath = '$thumbDir/$fileName';

      // 复制文件
      final targetFile = File(targetPath);
      await targetFile.create(recursive: true);
      await sourceFile.copy(targetPath);

      return targetPath;
    } catch (e) {
      debugPrint('保存本地缩略图失败: $e');
      rethrow;
    }
  }

  /// 获取缩略图文件（通过blurHash）
  /// [blurHash] blurHash字符串
  /// 如果文件存在返回文件，否则返回null
  Future<File?> getThumbnail(String blurHash) async {
    try {
      final thumbDir = await _getThumbnailDirectory();
      final fileName = ImageUtils.getSafeFileName(blurHash);
      final filePath = '$thumbDir/$fileName';
      final file = File(filePath);
      debugPrint("缩略图位置:${file.path}");
      if (await file.exists()) {
        return file;
      }
    } catch (e) {
      debugPrint('获取缩略图失败: $e');
    }
    return null;
  }

  /// 检查缩略图是否存在（通过blurHash）
  /// [blurHash] blurHash字符串
  /// 返回是否存在
  Future<bool> hasThumbnail(String blurHash) async {
    try {
      final thumbDir = await _getThumbnailDirectory();
      final fileName = ImageUtils.getSafeFileName(blurHash);
      final filePath = '$thumbDir/$fileName';
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      debugPrint('检查缩略图失败: $e');
      return false;
    }
  }
}
