import 'dart:io';
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
    this.animationDuration = const Duration(milliseconds: 5000),
  }) : type = ImageType.normal;

  const IMImage.asset({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : type = ImageType.asset,
       downloader = null,
       imageUrl = null,
       placeholder = null,
       errorWidget = null,
       thumbnailHash = null,
       thumbnailPath = null,
       animationDuration = const Duration(milliseconds: 500);

  final String? imageUrl;
  final String path;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final ImageType type;
  final ImageDownloader? downloader;
  final String? thumbnailHash;
  final String? thumbnailPath;

  /// 动画时长
  final Duration animationDuration;

  @override
  createState() => _IMImageState();
}

class _IMImageState extends State<IMImage> with WidgetsBindingObserver {
  late DownloadModel _downloadModel;
  late DownloadImageProvider _imageProvider;
  bool _hasTransitioned = false;

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

    _imageProvider = DownloadImageProvider(
      filePath: widget.path,
      imageUrl: widget.imageUrl,
      downloader: widget.downloader,
      downloadModel: _downloadModel,
      onDownloadUpdate: _handleDownloadUpdate,
    );
  }

  void _handleDownloadUpdate(DownloadModel model) {
    _downloadModel = model;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == ImageType.asset) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Image.asset(
          widget.path,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Image(
        image: _imageProvider,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        frameBuilder: _frameBuilder,
        // loadingBuilder: _loadingBuilder,
        errorBuilder: _errorBuilder,
      ),
    );
  }

  Widget _loadingBuilder(
    BuildContext context,
    Widget child,
    ImageChunkEvent? loadingProgress,
  ) {
    // 检查文件是否存在
    final file = File(widget.path);
    if (file.existsSync()) {
      // 文件存在，直接显示图像
      return child;
    }

    // 文件不存在，根据下载状态显示不同内容
    switch (_downloadModel.status) {
      case DownloadStatus.wait:
      case DownloadStatus.downing:
      case DownloadStatus.paused:
        return _buildPlaceholder();
      case DownloadStatus.failed:
        return widget.errorWidget ?? const Icon(Icons.error);
      default:
        return _buildPlaceholder();
    }
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
        Positioned.fill(
          child: _buildPlaceholder(),
        ),

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
