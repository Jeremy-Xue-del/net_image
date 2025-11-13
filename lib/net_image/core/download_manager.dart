import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../model/download_model.dart';
import '../utils/image_utils.dart';
import '../widgets/im_image.dart';


/// 图片下载管理器实现
class DefaultImageDownloader implements ImageDownloader {
  static final DefaultImageDownloader _instance = DefaultImageDownloader._internal();
  factory DefaultImageDownloader() => _instance;
  DefaultImageDownloader._internal();

  // 存储任务ID与下载信息的映射
  final Map<String, _DownloadTaskInfo> _tasks = {};

  @override
  String download(DownloadModel model, DownloadCallback callback) {
    final taskId = 'task_${DateTime.now().millisecond}_${model.url.hashCode}';

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
  Future<void> _performDownload(_DownloadTaskInfo taskInfo) async {
    try {
      final url = taskInfo.model.url;
      if (url == null) {
        final errorModel = DownloadModel(
          url: taskInfo.model.url,
          path: taskInfo.model.path,
          progress: 0.0,
          status: DownloadStatus.failed,
        );
        taskInfo.callback.onError(taskInfo.taskId, errorModel);
        _tasks.remove(taskInfo.taskId);
        return;
      }

      // 发送HTTP请求
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        client.close();
        final errorModel = DownloadModel(
          url: taskInfo.model.url,
          path: taskInfo.model.path,
          progress: 0.0,
          status: DownloadStatus.failed,
        );
        taskInfo.callback.onError(taskInfo.taskId, errorModel);
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
        taskInfo.callback.onProgress(taskInfo.taskId, progressModel);
      }

      client.close();

      // 转换为Uint8List
      final imageData = Uint8List.fromList(data);

      // 保存到文件
      final filePath = taskInfo.model.path ?? await _getDefaultFilePath(url);
      final file = File(filePath);
      await file.create(recursive: true);
      await file.writeAsBytes(imageData);

      // 通知完成
      final completeModel = DownloadModel(
        url: taskInfo.model.url,
        path: filePath,
        progress: 1.0,
        status: DownloadStatus.finish,
      );
      taskInfo.callback.onComplete(taskInfo.taskId, completeModel);

      // 从任务列表中移除
      _tasks.remove(taskInfo.taskId);
    } catch (e) {
      // 通知错误
      final errorModel = DownloadModel(
        url: taskInfo.model.url,
        path: taskInfo.model.path,
        progress: 0.0,
        status: DownloadStatus.failed,
      );
      taskInfo.callback.onError(taskInfo.taskId, errorModel);

      // 从任务列表中移除
      _tasks.remove(taskInfo.taskId);
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

