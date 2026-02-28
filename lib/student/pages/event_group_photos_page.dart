import 'dart:io';
import 'package:school_attendance/utils/utils.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';

class EventGroupPhotosPage extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> images;
  final String schoolId;

  const EventGroupPhotosPage({
    super.key,
    required this.title,
    required this.images,
    required this.schoolId,
  });

  @override
  State<EventGroupPhotosPage> createState() => _EventGroupPhotosPageState();
}

class _EventGroupPhotosPageState extends State<EventGroupPhotosPage> {
  late List<Map<String, dynamic>> _images;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.images);
  }

  Future<void> _downloadImage(String url) async {
    try {
      final dio = Dio();
      final filename = Uri.parse(url).pathSegments.last;

      Directory? dir;
      if (isAndroidPlatform) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else if (isDesktopPlatform) {
        dir = await getDownloadsDirectory();
      }

      dir ??= await getApplicationDocumentsDirectory();

      final savePath = p.join(dir.path, filename);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Downloading $filename...')));
      }

      await dio.download(url, savePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Saved to ${dir.path}'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFilex.open(savePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Text(
          widget.title.isEmpty ? 'Untitled Event' : widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2B7CA8),
      ),
      body:
          _images.isEmpty
              ? const Center(child: Text("No images in this folder"))
              : GridView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: _images.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.of(context).size.width > 900 ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                itemBuilder: (context, i) {
                  final imgData = _images[i];
                  final imgUrl = imgData['link'] ?? '';
                  final title = imgData['title'] ?? 'No Title';
                  final desc = imgData['description'] ?? '';
                  final date =
                      imgData['date'] != null
                          ? DateFormat(
                            'yyyy-MM-dd',
                          ).format(DateTime.parse(imgData['date']))
                          : '';

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => FullscreenImageViewer(
                                        imageUrl: imgUrl,
                                        title: title,
                                      ),
                                ),
                              );
                            },
                            child: CachedNetworkImage(
                              imageUrl: imgUrl,
                              fit: BoxFit.cover,
                              placeholder:
                                  (_, __) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                              errorWidget:
                                  (_, __, ___) => const Icon(Icons.error),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (desc.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  desc,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                date,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.download,
                                  color: Colors.blueAccent,
                                  size: 22,
                                ),
                                onPressed: () => _downloadImage(imgUrl),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}

class FullscreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String title;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PhotoView(
        imageProvider: CachedNetworkImageProvider(imageUrl),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2.5,
        loadingBuilder:
            (context, event) =>
                const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
