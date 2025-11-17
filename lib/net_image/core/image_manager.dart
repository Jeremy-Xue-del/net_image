import '../model/download_model.dart';

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

// class GlobalDownloadCallback implements DownloadCallback {
//   @override
//   void onProgress(String taskId, DownloadModel model) =>
//       ImageDownloadManager().updateProgress(taskId, model);
//
//   @override
//   void onComplete(String taskId, DownloadModel model) =>
//       ImageDownloadManager().completeDownload(taskId, model);
//
//   @override
//   void onError(String taskId, DownloadModel model) =>
//       ImageDownloadManager().errorDownload(taskId, model);
// }

// class ImageDownloadManager {
//   static final ImageDownloadManager _instance =
//   ImageDownloadManager._internal();
//
//   factory ImageDownloadManager() => _instance;
//
//   ImageDownloadManager._internal();
//
//   final Map<String, WeakReference<IMImageState>> _stateRefs = {};
//   final Map<String, WeakReference<DownloadCallback>> _callbackRefs = {};
//
//   void registerState(String taskId, IMImageState state) =>
//       _stateRefs[taskId] = WeakReference(state);
//
//   void registerCallback(String taskId, DownloadCallback callback) =>
//       _callbackRefs[taskId] = WeakReference(callback);
//
//   void unregisterState(String taskId) => _stateRefs.remove(taskId);
//
//   void updateProgress(String taskId, DownloadModel model) {
//     final state = _stateRefs[taskId]?.target;
//     if (state != null && state.mounted) state.downloadModel = model;
//     _callbackRefs[taskId]?.target?.onProgress(taskId, model);
//   }
//
//   void completeDownload(String taskId, DownloadModel model) {
//     final state = _stateRefs[taskId]?.target;
//     if (state != null && state.mounted) {
//       state.setState((){
//         state.downloadModel = model;
//       });
//       _callbackRefs[taskId]?.target?.onComplete(taskId, model);
//     }
//     _stateRefs.remove(taskId);
//     _callbackRefs.remove(taskId);
//   }
//
//   void errorDownload(String taskId, DownloadModel model) {
//     final state = _stateRefs[taskId]?.target;
//     if (state != null && state.mounted) {
//       state.setState(() => state.downloadModel = model);
//     }
//     _callbackRefs[taskId]?.target?.onError(taskId, model);
//     _stateRefs.remove(taskId);
//     _callbackRefs.remove(taskId);
//   }
// }