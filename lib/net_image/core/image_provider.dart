import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../core/image_manager.dart';
import '../model/download_model.dart';

// 添加自定义 ImageProvider
class DownloadImageProvider extends ImageProvider<DownloadImageProvider> {
  final String filePath;
  final String? imageUrl;
  final ImageDownloader? downloader;
  final DownloadModel downloadModel;
  final ValueChanged<DownloadModel>? onDownloadUpdate;

  const DownloadImageProvider({
    required this.filePath,
    this.imageUrl,
    this.downloader,
    required this.downloadModel,
    this.onDownloadUpdate,
  });

  @override
  Future<DownloadImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<DownloadImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadBuffer(DownloadImageProvider key, DecoderBufferCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      informationCollector: () sync* {
        yield ErrorDescription('Image provider: $this');
        yield ErrorDescription('File path: $filePath');
      },
    );
  }

  Future<ui.Codec> _loadAsync(DownloadImageProvider key, DecoderBufferCallback decode) async {
    assert(key == this);

    final file = File(filePath);

    // 检查文件是否已经存在
    if (await file.exists()) {
      // TODO 处理文件过大问题
      final bytes = await file.readAsBytes();
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      return decode(buffer);
    } else {
      // 文件不存在，需要下载
      if (imageUrl != null && downloader != null) {
        // 启动下载任务
        final completer = Completer<ui.Codec>();

        final callback = _DownloadImageCallback((model) {
          // 更新下载状态
          onDownloadUpdate?.call(model);

          // 如果下载完成，重新尝试加载
          if (model.status == DownloadStatus.finish) {
            _loadAsync(key, decode).then((codec) {
              if (!completer.isCompleted) {
                completer.complete(codec);
              }
            }).catchError((error) {
              if (!completer.isCompleted) {
                completer.completeError(error);
              }
            });
          }
        });

        // 启动下载
        downloader!.download(downloadModel, callback);

        // 等待下载完成或出错
        return completer.future;
      }

      // 抛出异常，让 Image 组件显示 errorBuilder
      throw Exception('File not found: $filePath');
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is DownloadImageProvider
        && filePath == other.filePath
        && imageUrl == other.imageUrl;
  }

  @override
  int get hashCode => Object.hash(filePath, imageUrl);
}

class _DownloadImageCallback implements DownloadCallback {
  final ValueChanged<DownloadModel> _onUpdate;

  _DownloadImageCallback(this._onUpdate);

  @override
  void onComplete(String taskId, DownloadModel model) {
    _onUpdate(model);
  }

  @override
  void onError(String taskId, DownloadModel model) {
    _onUpdate(model);
  }

  @override
  void onProgress(String taskId, DownloadModel model) {
    _onUpdate(model);
  }
}
