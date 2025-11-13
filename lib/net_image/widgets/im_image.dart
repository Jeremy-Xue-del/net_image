import 'dart:io';

import 'package:flutter/material.dart';

import '../model/download_model.dart';
import 'image_placeholder.dart';

enum ImageType {
  /// 普通
  normal,

  /// 资源图片
  asset,
}

/// 下载回调接口
abstract class DownloadCallback {
  void onProgress(String taskId, DownloadModel model);

  void onComplete(String taskId, DownloadModel model);

  void onError(String taskId, DownloadModel model);
}

/// 下载接口
abstract class ImageDownloader {
  /// 下载图片
  /// [model] 下载模型
  /// [callback] 下载回调
  /// 返回任务ID
  String download(DownloadModel model, DownloadCallback callback);
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
       thumbnailPath = null;

  final String? imageUrl;
  final String path;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder; // 修改为可空
  final Widget? errorWidget;
  final ImageType type;
  final ImageDownloader? downloader;
  final String? thumbnailHash; // 缩略图hash
  final String? thumbnailPath; // 缩略图本地地址

  @override
  createState() => _IMImageState();
}

class _IMImageState extends State<IMImage> with WidgetsBindingObserver {
  DownloadModel _downloadModel = DownloadModel();
  String? _taskId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeImage();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 应用生命周期变化时的处理
  }

  Future<void> _initializeImage() async {
    // 初始化下载模型
    _downloadModel = DownloadModel(
      url: widget.imageUrl,
      path: widget.path,
      progress: 0.0,
      status: DownloadStatus.wait,
    );

    // 如果是资源类型，直接设置为完成状态
    if (widget.type == ImageType.asset) {
      setState(() {
        _downloadModel.status = DownloadStatus.finish;
      });
      return;
    }

    // 检查本地文件是否存在
    final file = File(widget.path);
    if (file.existsSync()) {
      // 文件存在，设置为完成状态
      setState(() {
        _downloadModel.status = DownloadStatus.finish;
      });
    } else {
      // 文件不存在，需要下载
      if (widget.imageUrl != null && widget.downloader != null) {
        _downloadImage();
      } else {
        // 没有提供下载器或URL，标记为失败
        setState(() {
          _downloadModel.status = DownloadStatus.failed;
        });
      }
    }
  }

  Future<void> _downloadImage() async {
    setState(() {
      _downloadModel.status = DownloadStatus.downing;
    });

    // 开始下载并获取任务ID
    _taskId = widget.downloader!.download(
      _downloadModel,
      _GlobalDownloadCallback(),
    );

    // 注册状态到管理器（使用弱引用）
    if (_taskId != null) {
      _ImageDownloadManager().registerState(_taskId!, this);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (_downloadModel.status) {
      case DownloadStatus.wait:
      case DownloadStatus.downing:
        // 显示加载页面
        return _buildPlaceholder();
      case DownloadStatus.finish:
        // 显示图片
        if (widget.type == ImageType.asset) {
          return Image.asset(
            widget.path,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) {
              return widget.errorWidget!;
            },
          );
        } else {
          return Image.file(
            File(_downloadModel.path ?? widget.path),
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) {
              return widget.errorWidget!;
            },
          );
        }
      case DownloadStatus.failed:
      case DownloadStatus.paused:
        // 显示失败页面
        return widget.errorWidget!;
      default:
        // 默认显示加载页面
        return Stack(
          alignment: Alignment.center,
          children: [
            _buildPlaceholder(), // 使用自定义占位符
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ],
        );
    }
  }

  /// 构建占位符组件
  Widget _buildPlaceholder() {
    // 如果用户提供了自定义占位符，则使用它
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    // 否则创建一个带有缩略图支持的默认占位符
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
    // 不主动取消下载，让下载器自己管理
    // 弱引用会自动处理对象回收，无需手动移除
    super.dispose();
  }
}

/// 全局下载回调实现
class _GlobalDownloadCallback implements DownloadCallback {
  @override
  void onProgress(String taskId, DownloadModel model) {
    _ImageDownloadManager().updateProgress(taskId, model);
  }

  @override
  void onComplete(String taskId, DownloadModel model) {
    _ImageDownloadManager().completeDownload(taskId, model);
  }

  @override
  void onError(String taskId, DownloadModel model) {
    _ImageDownloadManager().errorDownload(taskId, model);
  }
}

/// 图片下载管理器（全局单例）
class _ImageDownloadManager {
  static final _ImageDownloadManager _instance =
      _ImageDownloadManager._internal();

  factory _ImageDownloadManager() => _instance;

  _ImageDownloadManager._internal();

  // 存储任务ID与组件状态更新回调的映射（使用弱引用）
  final Map<String, WeakReference<_IMImageState>> _stateRefs = {};

  /// 注册组件状态更新回调
  void registerState(String taskId, _IMImageState state) {
    _stateRefs[taskId] = WeakReference(state);
  }

  /// 更新下载进度
  void updateProgress(String taskId, DownloadModel model) {
    final stateRef = _stateRefs[taskId];
    if (stateRef != null) {
      final state = stateRef.target;
      // 添加mounted检查确保组件仍然挂载
      if (state != null && state.mounted) {
        state.setState(() {
          state._downloadModel = model;
        });
      }
    }
  }

  /// 完成下载
  void completeDownload(String taskId, DownloadModel model) {
    final stateRef = _stateRefs[taskId];
    if (stateRef != null) {
      final state = stateRef.target;
      // 添加mounted检查确保组件仍然挂载
      if (state != null && state.mounted) {
        state.setState(() {
          state._downloadModel = model;
        });
      }
      // 下载完成后移除引用
      _stateRefs.remove(taskId);
    }
  }

  /// 下载错误
  void errorDownload(String taskId, DownloadModel model) {
    final stateRef = _stateRefs[taskId];
    if (stateRef != null) {
      final state = stateRef.target;
      // 添加mounted检查确保组件仍然挂载
      if (state != null && state.mounted) {
        state.setState(() {
          state._downloadModel = model;
        });
      }
      // 错误后移除引用
      _stateRefs.remove(taskId);
    }
  }
}
