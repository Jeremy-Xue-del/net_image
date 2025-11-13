import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';

/// 图片相关工具类
class ImageUtils {
  /// 获取安全的文件名
  /// 
  /// 根据图片URL生成唯一的文件名，使用MD5哈希确保唯一性
  /// 同时保留原始文件的扩展名
  static String getSafeFileName(String imageUrl) {
    // 使用URL的MD5哈希值和文件扩展名生成安全的文件名
    final uri = Uri.parse(imageUrl);
    final fileName = basename(uri.path);
    final fileExtension = extension(fileName);
    final bytes = utf8.encode(imageUrl);
    final hash = sha256.convert(bytes);
    return '${hash.toString()}$fileExtension';
  }
}