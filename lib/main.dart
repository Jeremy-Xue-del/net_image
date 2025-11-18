import 'package:flutter/material.dart';
import 'net_image/core/download_manager.dart';
import 'net_image/utils/image_utils.dart';
import 'net_image/widgets/im_image.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Persistent Image Cache Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ImageListPage(),
    );
  }
}

class ImageListPage extends StatefulWidget {
  const ImageListPage({super.key});

  @override
  State<ImageListPage> createState() => _ImageListPageState();
}

class _ImageListPageState extends State<ImageListPage> {
  ImageModel assetData = ImageModel(
    path: 'assets/images/wallhaven-yqxzqx.jpg',
    blurHash: 'LcDcj+%gIUs:_4t7Ris:%Naxj@oe',
    thumbnailPath:
        '/data/user/0/com.example.net_image/net_image/thumbnails/'
        '${ImageUtils.getSafeFileName('assets/images/wallhaven-yqxzqx.jpg')}',
  );

  ImageModel networkData = ImageModel(
    url: 'https://pic2.zhimg.com/v2-4edf83ea78bfbc41bf2856306637337b_r.jpg',
    path:
        '/data/user/0/com.example.net_image/net_image/images/'
        '${ImageUtils.getSafeFileName('https://pic2.zhimg.com/v2-4edf83ea78bfbc41bf2856306637337b_r.jpg')}',
    blurHash: 'LZ7:hTR7eoRmpMoHkCWWxwbYWYWB',
    thumbnailPath:
        '/data/user/0/com.example.net_image/net_image/thumbnails/'
        '${ImageUtils.getSafeFileName('https://pic2.zhimg.com/v2-4edf83ea78bfbc41bf2856306637337b_r.jpg')}',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IMImage 图片列表'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '网络图片',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            IMImage(
              imageUrl: networkData.url,
              path: networkData.path,
              width: 300,
              height: 200,
              thumbnailHash: networkData.blurHash,
              thumbnailPath: networkData.thumbnailPath,
              radius: BorderRadius.circular(20),
              // height: 200,
              errorWidget: Container(
                color: Colors.red[100],
                child: const Center(
                  child: Icon(Icons.error, size: 50, color: Colors.red),
                ),
              ),
              downloader: DefaultImageDownloader(),
            ),
            Text(
              '资源图片',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            IMImage.asset(
              path: assetData.path,
              thumbnailHash: assetData.blurHash,
              thumbnailPath: assetData.thumbnailPath,
              width: 300,
              height: 200,
              radius: BorderRadius.circular(20),
              errorWidget: Container(
                color: Colors.red[100],
                child: const Center(
                  child: Icon(Icons.error, size: 50, color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImageModel {
  String? url;
  String path;
  String? blurHash;
  String? thumbnailPath;

  ImageModel({this.url, required this.path, this.blurHash, this.thumbnailPath});
}
