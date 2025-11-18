import 'dart:async';

import 'package:flutter/material.dart';
import '../../blur_hash/blurhash_image.dart';
import '../core/thumbnail_storage_manager.dart';

/// 图片加载占位组件
class ImagePlaceholder extends StatefulWidget {
  final Color backgroundColor;
  final String? blurHash; // blurHash参数
  final String? thumbnailPath; // 本地缩略图路径参数
  final double? width; // 宽度参数
  final double? height; // 高度参数
  final BoxFit? fit; // 裁剪方式参数

  const ImagePlaceholder({
    super.key,
    this.backgroundColor = Colors.grey,
    this.blurHash,
    this.thumbnailPath,
    this.width,
    this.height,
    this.fit,
  });

  @override
  State<ImagePlaceholder> createState() => _ImagePlaceholderState();
}

class _ImagePlaceholderState extends State<ImagePlaceholder> {
  @override
  Widget build(BuildContext context) {
    // 如果提供了本地缩略图路径，优先使用
    if (widget.thumbnailPath != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: FutureBuilder<Widget>(
          future: _buildLocalThumbnailWidget(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return snapshot.data!;
            } else if (snapshot.hasError) {
              // 出错时显示默认占位符
              return _buildDefaultPlaceholder();
            }
            // 加载中显示默认占位符
            return _buildDefaultPlaceholder();
          },
        ),
      );
    }

    // 如果提供了blurHash，显示blurHash图像
    if (widget.blurHash != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: FutureBuilder<Widget>(
          future: _buildBlurHashWidget(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return snapshot.data!;
            } else if (snapshot.hasError) {
              // 出错时显示默认占位符
              return _buildDefaultPlaceholder();
            }
            // 加载中显示默认占位符
            return _buildDefaultPlaceholder();
          },
        ),
      );
    }

    // 否则显示默认占位符
    return _buildDefaultPlaceholder();
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: widget.backgroundColor,
    );
  }

  Future<Widget> _buildLocalThumbnailWidget() async {
    try {
      final storageManager = ThumbnailStorageManager();
      final thumbnailFile = await storageManager.getThumbnailByPath(
        localPath: widget.thumbnailPath,
      );

      if (thumbnailFile != null) {
        // 如果本地缩略图文件存在，直接显示
        return Image.file(
          thumbnailFile,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) {
            // 处理图像加载错误，回退到其他选项
            if (widget.blurHash != null) {
              return _buildBlurHashFromFuture();
            } else {
              return _buildDefaultPlaceholder();
            }
          },
        );
      } else {
        // 如果本地缩略图文件不存在，回退到blurHash
        if (widget.blurHash != null) {
          return _buildBlurHashFromFuture();
        } else {
          return _buildDefaultPlaceholder();
        }
      }
    } catch (e) {
      // 出错时回退到blurHash或默认占位符
      if (widget.blurHash != null) {
        return _buildBlurHashFromFuture();
      } else {
        return _buildDefaultPlaceholder();
      }
    }
  }

  Future<Widget> _buildBlurHashWidget() async {
    try {
      // 首先直接显示blurHash图像（不等待生成缩略图）
      final blurHashWidget = _buildBlurHashFromFuture();

      // 在后台检查并生成缩略图（不阻塞UI）
      unawaited(_checkAndGenerateThumbnail());

      return blurHashWidget;
    } catch (e) {
      // 出错时返回默认占位符
      return _buildDefaultPlaceholder();
    }
  }

  // 用于直接创建BlurHash图像的辅助方法
  Widget _buildBlurHashFromFuture() {
    return Image(
      image: BlurHashImage(
        widget.blurHash!,
        decodingWidth: 32,
        decodingHeight: 32,
      ),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }

  /// 检查并生成缩略图
  Future<void> _checkAndGenerateThumbnail() async {
    try {
      final storageManager = ThumbnailStorageManager();
      final hasThumbnail = await storageManager.hasThumbnail(widget.blurHash!);

      // 如果本地没有缩略图，生成并保存
      if (!hasThumbnail) {
        await storageManager.generateAndSaveThumbnail(
          blurHash: widget.blurHash!,
          width: 32,
          height: 32,
        );
      }
    } catch (e) {
      // 后台任务出错不影响主流程
      debugPrint('后台生成缩略图失败: $e');
    }
  }
}
