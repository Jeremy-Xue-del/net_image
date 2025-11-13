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
  final Widget child;

  const ImagePlaceholder({
    super.key,
    this.backgroundColor = Colors.grey,
    this.blurHash,
    this.thumbnailPath,
    this.width,
    this.height,
    this.fit,
    this.child = const Icon(Icons.photo, size: 40, color: Colors.white),
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
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Container(
        color: widget.backgroundColor,
        child: Center(child: widget.child),
      ),
    );
  }

  Future<Widget> _buildLocalThumbnailWidget() async {
    try {
      final storageManager = ThumbnailStorageManager();
      final thumbnailFile = await storageManager.getThumbnailByPath(widget.thumbnailPath!);

      if (thumbnailFile != null) {
        // 如果本地缩略图文件存在，直接显示
        return Image.file(
          thumbnailFile,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        );
      } else {
        // 如果本地缩略图文件不存在，回退到blurHash
        if (widget.blurHash != null) {
          return _buildBlurHashWidget();
        } else {
          return _buildDefaultPlaceholder();
        }
      }
    } catch (e) {
      // 出错时回退到blurHash或默认占位符
      if (widget.blurHash != null) {
        return _buildBlurHashWidget();
      } else {
        return _buildDefaultPlaceholder();
      }
    }
  }

  Future<Widget> _buildBlurHashWidget() async {
    try {
      // 首先检查本地是否已有缩略图
      final storageManager = ThumbnailStorageManager();
      final thumbnailFile = await storageManager.getThumbnail(widget.blurHash!);

      if (thumbnailFile != null) {
        // 如果本地已有缩略图，直接显示
        return Image.file(
          thumbnailFile,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        );
      } else {
        // 如果本地没有缩略图，生成并保存
        return _generateAndSaveThumbnail();
      }
    } catch (e) {
      // 出错时返回默认占位符
      return _buildDefaultPlaceholder();
    }
  }

  Future<Widget> _generateAndSaveThumbnail() async {
    try {
      // 使用ThumbnailStorageManager生成并保存缩略图
      final storageManager = ThumbnailStorageManager();
      await storageManager.generateAndSaveThumbnail(
        blurHash: widget.blurHash!,
        width: 32,
        height: 32,
      );

      // 再次获取缩略图文件
      final thumbnailFile = await storageManager.getThumbnail(widget.blurHash!);
      if (thumbnailFile != null) {
        return Image.file(
          thumbnailFile,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        );
      } else {
        // 如果保存后仍然无法获取，使用BlurHashImage直接显示
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
    } catch (e) {
      // 出错时使用BlurHashImage直接显示
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
  }
}
