import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../model/download_model.dart';
import '../utils/image_utils.dart';
import '../widgets/im_image.dart';

/// 图片下载管理器实现
class DefaultImageDownloader implements ImageDownloader {
  static final DefaultImageDownloader _instance =
      DefaultImageDownloader._internal();

  factory DefaultImageDownloader() => _instance;

  DefaultImageDownloader._internal();

  // 存储任务ID与下载信息的映射
  final Map<String, _DownloadTaskInfo> _tasks = {};

  @override
  String download(DownloadModel model, [DownloadCallback? callback]) {
    final taskId = 'task_${DateTime.now().millisecond}_${model.url.hashCode}';

    callback ??= _EmptyDownloadCallback();

    // 创建任务信息
    final taskInfo = _DownloadTaskInfo(
      model: model,
      callback: callback,
      taskId: taskId,
    );

    _tasks[taskId] = taskInfo;

    // 启动下载任务
    _performDownload(taskInfo);

    return taskId;
  }

  /// 执行下载任务
  // Future<void> _performDownload(_DownloadTaskInfo taskInfo) async {
  //   try {
  //     final url = taskInfo.model.url;
  //     if (url == null) {
  //       final errorModel = DownloadModel(
  //         url: taskInfo.model.url,
  //         path: taskInfo.model.path,
  //         progress: 0.0,
  //         status: DownloadStatus.failed,
  //       );
  //       final callback = taskInfo.callback.target;
  //       if (callback != null) {
  //         callback.onError(taskInfo.taskId, errorModel);
  //       }
  //       _tasks.remove(taskInfo.taskId);
  //       return;
  //     }
  //
  //     // 发送HTTP请求
  //     final client = http.Client();
  //     final request = http.Request('GET', Uri.parse(url));
  //     final response = await client.send(request);
  //
  //     if (response.statusCode != 200) {
  //       client.close();
  //       final errorModel = DownloadModel(
  //         url: taskInfo.model.url,
  //         path: taskInfo.model.path,
  //         progress: 0.0,
  //         status: DownloadStatus.failed,
  //       );
  //       final callback = taskInfo.callback.target;
  //       if (callback != null) {
  //         callback.onError(taskInfo.taskId, errorModel);
  //       }
  //       _tasks.remove(taskInfo.taskId);
  //       return;
  //     }
  //
  //     // 读取数据并更新进度
  //     final data = <int>[];
  //     final totalBytes = response.contentLength ?? 1;
  //     var receivedBytes = 0;
  //
  //     await for (final chunk in response.stream) {
  //       data.addAll(chunk);
  //       receivedBytes += chunk.length;
  //
  //       // 计算进度并通知
  //       final progress = totalBytes > 0 ? receivedBytes / totalBytes : 0.0;
  //       final progressModel = DownloadModel(
  //         url: taskInfo.model.url,
  //         path: taskInfo.model.path,
  //         progress: progress,
  //         status: DownloadStatus.downing,
  //       );
  //       final callback = taskInfo.callback.target;
  //       if (callback != null) {
  //         callback.onProgress(taskInfo.taskId, progressModel);
  //       }
  //     }
  //
  //     client.close();
  //
  //     // 转换为Uint8List
  //     final imageData = Uint8List.fromList(data);
  //
  //     // 保存到文件
  //     final filePath = taskInfo.model.path ?? await _getDefaultFilePath(url);
  //     final file = File(filePath);
  //     await file.create(recursive: true);
  //     await file.writeAsBytes(imageData);
  //
  //     // 通知完成
  //     final completeModel = DownloadModel(
  //       url: taskInfo.model.url,
  //       path: filePath,
  //       progress: 1.0,
  //       status: DownloadStatus.finish,
  //     );
  //     final callback = taskInfo.callback.target;
  //     if (callback != null) {
  //       callback.onComplete(taskInfo.taskId, completeModel);
  //     }
  //
  //     // 从任务列表中移除
  //     _tasks.remove(taskInfo.taskId);
  //   } catch (e) {
  //     // 通知错误
  //     final errorModel = DownloadModel(
  //       url: taskInfo.model.url,
  //       path: taskInfo.model.path,
  //       progress: 0.0,
  //       status: DownloadStatus.failed,
  //     );
  //     final callback = taskInfo.callback.target;
  //     if (callback != null) {
  //       callback.onError(taskInfo.taskId, errorModel);
  //     }
  //
  //     // 从任务列表中移除
  //     _tasks.remove(taskInfo.taskId);
  //   }
  // }
  /// 执行下载任务
  Future<void> _performDownload(_DownloadTaskInfo taskInfo) async {
    try {
      final url = taskInfo.model.url;
      debugPrint('开始下载图片: $url'); // 添加调试日志

      if (url == null) {
        debugPrint('URL为空，下载失败'); // 添加调试日志
        final errorModel = DownloadModel(
          url: taskInfo.model.url,
          path: taskInfo.model.path,
          progress: 0.0,
          status: DownloadStatus.failed,
        );
        final callback = taskInfo.callback;
        callback.onError(taskInfo.taskId, errorModel);
        _tasks.remove(taskInfo.taskId);
        return;
      }

      // 发送HTTP请求
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      debugPrint('收到响应，状态码: ${response.statusCode}'); // 添加调试日志

      if (response.statusCode != 200) {
        debugPrint('响应状态码不是200，下载失败'); // 添加调试日志
        client.close();
        final errorModel = DownloadModel(
          url: taskInfo.model.url,
          path: taskInfo.model.path,
          progress: 0.0,
          status: DownloadStatus.failed,
        );
        final callback = taskInfo.callback;
        callback.onError(taskInfo.taskId, errorModel);
        _tasks.remove(taskInfo.taskId);
        return;
      }

      // 读取数据并更新进度
      final data = <int>[];
      final totalBytes = response.contentLength ?? 1;
      var receivedBytes = 0;

      await for (final chunk in response.stream) {
        data.addAll(chunk);
        receivedBytes += chunk.length;

        // 计算进度并通知
        final progress = totalBytes > 0 ? receivedBytes / totalBytes : 0.0;
        final progressModel = DownloadModel(
          url: taskInfo.model.url,
          path: taskInfo.model.path,
          progress: progress,
          status: DownloadStatus.downing,
        );
        final callback = taskInfo.callback;
        callback.onProgress(taskInfo.taskId, progressModel);
      }

      client.close();

      debugPrint('下载完成，准备保存文件'); // 添加调试日志

      // 转换为Uint8List
      final imageData = Uint8List.fromList(data);

      // 保存到文件
      final filePath = taskInfo.model.path ?? await _getDefaultFilePath(url);
      final file = File(filePath);
      await file.create(recursive: true);
      await file.writeAsBytes(imageData);

      debugPrint('文件保存成功: $filePath'); // 添加调试日志

      // 通知完成
      final completeModel = DownloadModel(
        url: taskInfo.model.url,
        path: filePath,
        progress: 1.0,
        status: DownloadStatus.finish,
      );
      debugPrint('下载管理器: 准备调用完成回调，文件路径: $filePath');
      final callback = taskInfo.callback;
      debugPrint('下载管理器: 调用onComplete回调');
      callback.onComplete(taskInfo.taskId, completeModel);
      // 从任务列表中移除
      _tasks.remove(taskInfo.taskId);
    } catch (e, stack) {
      debugPrint('下载出现异常: $e\n堆栈信息: $stack'); // 添加调试日志
      // 通知错误
      final errorModel = DownloadModel(
        url: taskInfo.model.url,
        path: taskInfo.model.path,
        progress: 0.0,
        status: DownloadStatus.failed,
      );
      final callback = taskInfo.callback;
      callback.onError(taskInfo.taskId, errorModel);
      // 从任务列表中移除
      _tasks.remove(taskInfo.taskId);
      debugPrint('下载管理器: 任务已完成并移除');
    }
  }

  /// 获取默认文件路径
  Future<String> _getDefaultFilePath(String url) async {
    final safeFileName = ImageUtils.getSafeFileName(url);
    final baseDir = await getApplicationDocumentsDirectory();
    final dirPath = '${baseDir.parent.path}/net_image/image';
    await Directory(dirPath).create(recursive: true);
    return '$dirPath/$safeFileName';
  }
}

class _EmptyDownloadCallback implements DownloadCallback {
  @override
  void onComplete(String taskId, DownloadModel model) {}

  @override
  void onError(String taskId, DownloadModel model) {}

  @override
  void onProgress(String taskId, DownloadModel model) {}
}

/// 下载任务信息
class _DownloadTaskInfo {
  final DownloadModel model;
  final DownloadCallback callback;
  final String taskId;

  _DownloadTaskInfo({
    required this.model,
    required this.callback,
    required this.taskId,
  });
}
