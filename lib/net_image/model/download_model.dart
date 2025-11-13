enum DownloadStatus {
  /// 正在下载
  downing,

  /// 下载完成
  finish,

  /// 下载失败
  failed,

  /// 等待下载
  wait,

  /// 暂停下载
  paused,
}

class DownloadModel {
  /// 图片链接
  String? url;

  /// 图片本地地址
  String? path;

  /// 下载进度
  double? progress;

  /// 下载状态
  DownloadStatus? status;

  DownloadModel({this.url, this.path, this.progress, this.status});
}
