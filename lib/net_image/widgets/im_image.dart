import 'package:flutter/material.dart';
import '../core/image_manager.dart';
import '../core/image_provider.dart';
import '../model/download_model.dart';
import 'image_placeholder.dart';

enum ImageType {
  /// 普通
  normal,

  /// 资源图片
  asset,
}

/// 优化的网络图片组件
class IMImage extends StatefulWidget {
  const IMImage({
    super.key,
    required this.path,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget = const Icon(Icons.error),
    this.downloader,
    this.thumbnailHash, // 缩略图hash
    this.thumbnailPath, // 缩略图本地地址
    this.animationDuration = const Duration(milliseconds: 500),
    this.radius,
  }) : type = ImageType.normal;

  const IMImage.asset({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget = const Icon(Icons.error),
    this.thumbnailHash,
    this.thumbnailPath,
    this.animationDuration = const Duration(milliseconds: 500),
    this.radius,
  }) : type = ImageType.asset,
       downloader = null,
       imageUrl = null;

  /// 图片地址
  final String? imageUrl;

  /// 图片路径
  final String path;

  /// 图片宽度
  final double? width;

  /// 图片高度
  final double? height;

  /// 缩放模式
  final BoxFit? fit;

  /// 占位符
  final Widget? placeholder;

  /// 错误占位符
  final Widget? errorWidget;

  /// 图片类型
  final ImageType type;

  /// 下载器
  final ImageDownloader? downloader;

  /// 缩略图hash
  final String? thumbnailHash;

  /// 缩略图本地地址
  final String? thumbnailPath;

  /// 动画时长
  final Duration animationDuration;

  /// 圆角
  final BorderRadiusGeometry? radius;

  @override
  createState() => _IMImageState();
}

class _IMImageState extends State<IMImage> with WidgetsBindingObserver {
  late DownloadModel _downloadModel;
  late DownloadImageProvider _imageProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 初始化下载模型
    _downloadModel = DownloadModel(
      url: widget.imageUrl,
      path: widget.path,
      progress: 0.0,
      status: DownloadStatus.wait,
    );

    if (widget.type == ImageType.normal) {
      _imageProvider = DownloadImageProvider(
        filePath: widget.path,
        imageUrl: widget.imageUrl,
        downloader: widget.downloader,
        downloadModel: _downloadModel,
        onDownloadUpdate: _handleDownloadUpdate,
      );
    }
  }

  void _handleDownloadUpdate(DownloadModel model) {
    _downloadModel = model;
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (widget.type == ImageType.asset) {
      child = Image.asset(
        widget.path,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        frameBuilder: _frameBuilder,
        errorBuilder: _errorBuilder,
      );
    } else {
      child = Image(
        image: _imageProvider,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        frameBuilder: _frameBuilder,
        errorBuilder: _errorBuilder,
      );
    }

    if (widget.radius != null) {
      child = ClipRRect(borderRadius: widget.radius!, child: child);
    }
    return SizedBox(width: widget.width, height: widget.height, child: child);
  }

  Widget _frameBuilder(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    final showImage = frame != null;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        // 永远显示占位符作为底
        Positioned.fill(child: _buildPlaceholder()),

        // 上层是图片，初次加载时淡入
        AnimatedOpacity(
          opacity: showImage ? 1.0 : 0.0,
          duration: widget.animationDuration,
          curve: Curves.easeOut,
          child: child,
        ),
      ],
    );
  }

  Widget _errorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return widget.errorWidget ?? const Icon(Icons.error);
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) return widget.placeholder!;
    return ImagePlaceholder(
      blurHash: widget.thumbnailHash,
      thumbnailPath: widget.thumbnailPath,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
