import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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
  late String urlBasePath;

  late String thumbnailPath;

  List<ImageModel> data = [];

  // 示例图片URL列表
  final List<Map<String, String>> _imageData = [
    {
      'url': 'https://picsum.photos/400/300?random=1',
      'path': '',
      'title': '随机图片 1',
      'blurHash': 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
      'thumbnailPath': '',
    },
    {
      'url': 'https://picsum.photos/400/300?random=2',
      'title': '随机图片 2',
      'blurHash': 'LGF5]+Yk^6#M@-5c,1J5@[or[Q6.',
      'thumbnailPath': '',
    },
    {
      'url': 'https://picsum.photos/400/300?random=3',
      'title': '随机图片 3',
      'blurHash': 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
      'thumbnailPath': '',
    },
    {
      'url': 'https://picsum.photos/400/300?random=4',
      'title': '随机图片 4',
      'blurHash': 'LGF5]+Yk^6#M@-5c,1J5@[or[Q6.',
      'thumbnailPath': '',
    },
    {
      'url': 'https://picsum.photos/400/300?random=5',
      'title': '随机图片 5',
      'blurHash': 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
      'thumbnailPath': '',
    },
    {
      'url': 'https://picsum.photos/400/300?random=6',
      'title': '随机图片 6',
      'blurHash': 'LGF5]+Yk^6#M@-5c,1J5@[or[Q6.',
      'thumbnailPath': '',
    },
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getData();
  }

  void getData() async {
    final tempDir = await getTemporaryDirectory();
    urlBasePath = '${tempDir.parent.path}/image_cache/image';
    thumbnailPath = '${tempDir.parent.path}/image_cache/thumbnail';
    for (Map<String, String> d in _imageData) {
      ImageModel m = ImageModel(
        url: d['url'],
        path: urlBasePath + ImageUtils.getSafeFileName(d['url']!),
        title: d['title']!,
        blurHash: d['blurHash'],
        thumbnailPath:
            thumbnailPath + ImageUtils.getSafeFileName(d['blurHash']!),
      );
      data.add(m);
    }
    if (mounted) {
      setState(() {
        data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IMImage 图片列表'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final imageData = data[index];
          return ImageListItem(
            title: imageData.title!,
            imageUrl: imageData.url!,
            path: imageData.path!,
            blurHash: imageData.blurHash!,
            thumbnailPath: imageData.thumbnailPath!,
            index: index,
          );
        },
      ),
    );
  }
}

class ImageListItem extends StatefulWidget {
  final String title;
  final String imageUrl;
  final int index;
  final String path;
  final String blurHash;
  final String thumbnailPath;

  const ImageListItem({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.index,
    required this.path,
    required this.blurHash,
    required this.thumbnailPath,
  });

  @override
  State<ImageListItem> createState() => _ImageListItemState();
}

class _ImageListItemState extends State<ImageListItem> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 3),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Center(
              child: IMImage(
                imageUrl: widget.imageUrl,
                path: widget.path,
                thumbnailHash: widget.blurHash,
                thumbnailPath: widget.thumbnailPath,
                width: 300,
                height: 200,
                errorWidget: Container(
                  color: Colors.red[100],
                  child: const Center(
                    child: Icon(Icons.error, size: 50, color: Colors.red),
                  ),
                ),
                downloader: DefaultImageDownloader(),
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
  String? path;
  String? title;
  String? blurHash;
  String? thumbnailPath;

  ImageModel({
    this.url,
    this.path,
    this.title,
    this.blurHash,
    this.thumbnailPath,
  });
}
