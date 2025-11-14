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
  String download(DownloadModel model, [DownloadCallback? callback]);
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
    // 初始化下载模型
    _downloadModel = DownloadModel(
      url: widget.imageUrl,
      path: widget.path,
      progress: 0.0,
      status: DownloadStatus.wait,
    );
    _initializeImage();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 应用生命周期变化时的处理
  }

  void _initializeImage() async {
    debugPrint('IMImage: 初始化图片，路径: ${widget.path}');
    if (widget.type == ImageType.asset) return;
    // 检查本地文件是否存在
    final file = File(widget.path);
    if (file.existsSync()) return;
    debugPrint('IMImage: 本地文件不存在，需要下载');
    // 文件不存在，需要下载
    if (widget.imageUrl != null && widget.downloader != null) {
      _downloadImage();
    }
  }

  Future<DownloadStatus> _initializeImageUI() async {
    debugPrint('IMImageUI: 初始化图片，路径: ${widget.path}');
    if (widget.type == ImageType.asset) {
      debugPrint('IMImage: 资源图片，设置状态为完成');
      _downloadModel.status = DownloadStatus.finish;
      return DownloadStatus.finish;
    }
    // 检查本地文件是否存在
    final file = File(widget.path);
    if (file.existsSync()) {
      debugPrint('IMImage: 本地文件存在，设置状态为完成');
      // 文件存在，设置为完成状态
      _downloadModel.status = DownloadStatus.finish;
      return DownloadStatus.finish;
    } else {
      debugPrint('IMImage: 本地文件不存在，需要下载');
      // 文件不存在，需要下载
      if (widget.imageUrl != null && widget.downloader != null) {
        debugPrint('IMImage: 开始下载图片');
        return DownloadStatus.downing;
      } else {
        debugPrint('IMImage: 没有提供下载器或URL，标记为失败');
        // 没有提供下载器或URL，标记为失败
        _downloadModel.status = DownloadStatus.failed;
        return DownloadStatus.failed;
      }
    }
  }

  Future<void> _downloadImage() async {
    debugPrint('IMImage: 开始下载图片流程');
    _downloadModel.status = DownloadStatus.downing;
    debugPrint('IMImage: 设置状态为下载中');

    // 开始下载并获取任务ID
    _taskId = widget.downloader!.download(
      _downloadModel,
      _GlobalDownloadCallback(),
    );
    debugPrint('IMImage: 下载任务已启动，任务ID: $_taskId');

    // 注册状态到管理器（使用弱引用）
    if (_taskId != null) {
      _ImageDownloadManager().registerState(_taskId!, this);
      debugPrint('IMImage: 状态已注册到管理器');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: FutureBuilder<DownloadStatus>(
        initialData: DownloadStatus.wait,
        future: _initializeImageUI(),
        builder: (context, snapshot) {
          if (snapshot.data == DownloadStatus.wait) {
            // 显示加载占位符
            return widget.placeholder ?? CircularProgressIndicator();
          } else if (snapshot.data == DownloadStatus.failed) {
            return widget.errorWidget ?? Icon(Icons.error);
          } else {
            // 成功加载后显示内容
            return _buildContent();
          }
        },
      ),
    );
  }

  Widget _buildContent() {
    switch (_downloadModel.status) {
      case DownloadStatus.wait:
      case DownloadStatus.downing:
      case DownloadStatus.paused:
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
          final file = File(_downloadModel.path ?? widget.path);
          // 检查文件是否存在
          if (file.existsSync()) {
            return Image.file(
              file,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              errorBuilder: (context, error, stackTrace) {
                return widget.errorWidget!;
              },
            );
          } else {
            // 文件不存在，回退到占位符
            return _buildPlaceholder();
          }
        }
      case DownloadStatus.failed:
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
    if (_taskId != null) {
      _ImageDownloadManager().unregisterState(_taskId!);
    }
    super.dispose();
  }
}

/// 全局下载回调实现
class _GlobalDownloadCallback implements DownloadCallback {

  _GlobalDownloadCallback();

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

  // 储存任务ID与下载模型映射
  final Map<String, WeakReference<DownloadCallback>> _callbackRefs = {};

  /// 注册组件状态更新回调
  void registerState(String taskId, _IMImageState state) {
    _stateRefs[taskId] = WeakReference(state);
  }

  /// 注册下载回调
  void registerCallback(String taskId, DownloadCallback callback) {
    _callbackRefs[taskId] = WeakReference(callback);
  }

  /// 取消注册
  void unregisterState(String taskId) {
    _stateRefs.remove(taskId);
  }

  /// 更新下载进度
  void updateProgress(String taskId, DownloadModel model) {
    final stateRef = _stateRefs[taskId];
    if (stateRef != null) {
      final state = stateRef.target;
      // 添加mounted检查确保组件仍然挂载
      if (state != null && state.mounted) {
        state._downloadModel = model;
      }
    }
    // 调用回调方法
    final callbackRef = _callbackRefs[taskId];
    if (callbackRef != null) {
      final callback = callbackRef.target;
      callback?.onProgress(taskId, model);
    }
  }

  void completeDownload(String taskId, DownloadModel model) {
    debugPrint('图片下载管理器: 收到完成回调，任务ID: $taskId');
    final stateRef = _stateRefs[taskId];
    if (stateRef != null) {
      final state = stateRef.target;
      debugPrint('图片下载管理器: 找到状态引用，状态是否为空: ${state == null}');
      // 添加mounted检查确保组件仍然挂载
      if (state != null && state.mounted) {
        debugPrint('图片下载管理器: 调用setState更新UI');
        state.setState(() {
          state._downloadModel = model;
        });
        debugPrint('图片下载管理器: setState调用完成，新状态: ${model.status}');
      } else {
        debugPrint('图片下载管理器: 状态为空或未挂载，移除引用');
        // 如果state为null，从映射中移除无效引用
        _stateRefs.remove(taskId);
      }

      // 调用回调方法
      final callbackRef = _callbackRefs[taskId];
      if (callbackRef != null) {
        final callback = callbackRef.target;
        if (callback != null) {
          debugPrint('图片下载管理器: 调用回调onComplete');
          callback.onComplete(taskId, model);
        } else {
          debugPrint('图片下载管理器: 回调为空，移除引用');
          // 如果callback为null，从映射中移除无效引用
          _callbackRefs.remove(taskId);
        }
      }
    } else {
      debugPrint('图片下载管理器: 未找到任务ID $taskId 的状态引用');
    }
    // 不管怎样都从映射中移除已完成的任务
    _stateRefs.remove(taskId);
    _callbackRefs.remove(taskId);
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

    // 调用回调方法
    final callbackRef = _callbackRefs[taskId];
    if (callbackRef != null) {
      final callback = callbackRef.target;
      callback?.onError(taskId, model);
    }
    // 错误后移除回调引用
    _callbackRefs.remove(taskId);
  }
}
