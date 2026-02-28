import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
// import 'package:photo_view/photo_view.dart';
// import 'package:photo_view/photo_view_gallery.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../Appbar/student_appbar_desktop.dart';
import '../Appbar/student_appbar_mobile.dart';
import 'event_group_photos_page.dart';
import 'student_dashboard.dart';

class Events extends StatefulWidget {
  const Events({
    super.key,
    required this.schoolId,
    required this.username,
    required this.classId,
  });

  final String schoolId;
  final String username;
  final String classId;

  @override
  State<Events> createState() => _EventsState();
}

class _EventsState extends State<Events> with TickerProviderStateMixin {
  bool _isLoading = false;
  List<Map<String, dynamic>> uploadedImages = [];
  List<Map<String, dynamic>> uploadedVideos = [];

  final String baseUrl = 'https://smartschoolserver.ramchintech.com';
  late final String fetchUrl;

  late TabController _tabController;
  final List<YoutubePlayerController> _videoControllers = [];

  @override
  void initState() {
    super.initState();
    fetchUrl = '$baseUrl/upload/${widget.schoolId}';
    _tabController = TabController(length: 2, vsync: this);
    _fetchMedia();
  }

  // 🔹 Fetch images & videos with metadata
  Future<void> _fetchMedia() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(fetchUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          uploadedImages = List<Map<String, dynamic>>.from(data['images']);
          uploadedVideos = List<Map<String, dynamic>>.from(data['videos']);
        });
        _initVideoControllers();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🎬 Initialize YouTube controllers (paused by default)
  void _initVideoControllers() {
    _videoControllers.clear();
    for (final v in uploadedVideos) {
      final link = v['link'];
      final videoId = YoutubePlayer.convertUrlToId(link);
      if (videoId != null) {
        _videoControllers.add(
          YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
              useHybridComposition: true,
            ),
          ),
        );
      }
    }

    _tabController.addListener(() {
      if (_tabController.index != 1) {
        for (final c in _videoControllers) {
          c.pause();
        }
      }
    });
  }

  @override
  void dispose() {
    for (final c in _videoControllers) {
      c.pause();
      c.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  // 🖼️ Photos tab
  Widget _buildPhotosTab() {
    if (_isLoading) {
      return const Center(
        child: SpinKitFadingCircle(color: Colors.blueAccent, size: 60.0),
      );
    }

    if (uploadedImages.isEmpty) {
      return const Center(
        child: Text(
          'No event photos available.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    final groupedImages = groupBy(
      uploadedImages,
      (obj) => (obj['title'] as String?)?.trim() ?? 'No Title',
    );

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedImages.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            MediaQuery.of(context).size.width > 900
                ? 4
                : MediaQuery.of(context).size.width > 600
                ? 3
                : 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final title = groupedImages.keys.elementAt(index);
        final images = groupedImages[title]!;
        final firstImg = images.first;
        final imageUrl = firstImg['link'];
        final count = images.length;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => EventGroupPhotosPage(
                      title: title,
                      images: images,
                      schoolId: widget.schoolId,
                    ),
              ),
            );
          },
          child: Hero(
            tag: imageUrl,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 📸 Background image
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) =>
                              const Icon(Icons.broken_image, color: Colors.red),
                    ),

                    // 🌫️ Gradient overlay (bottom)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color.fromARGB(26, 0, 0, 0),
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),

                    // Folder Icon overlay
                    const Center(
                      child: Icon(
                        Icons.folder_open,
                        color: Colors.white70,
                        size: 40,
                      ),
                    ),

                    // 🏷️ Text content
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.isEmpty ? 'Untitled Event' : title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black54,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$count items',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 🔍 Full-screen gallery
  // void _openFullScreenGallery(int initialIndex) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder:
  //           (context) => Scaffold(
  //             backgroundColor: Colors.black,
  //             body: Stack(
  //               children: [
  //                 PhotoViewGallery.builder(
  //                   itemCount: uploadedImages.length,
  //                   builder:
  //                       (context, index) => PhotoViewGalleryPageOptions(
  //                         imageProvider: CachedNetworkImageProvider(
  //                           uploadedImages[index]['link'],
  //                         ),
  //                         minScale: PhotoViewComputedScale.contained,
  //                         maxScale: PhotoViewComputedScale.covered * 2,
  //                       ),
  //                   backgroundDecoration: const BoxDecoration(
  //                     color: Colors.black,
  //                   ),
  //                   pageController: PageController(initialPage: initialIndex),
  //                 ),
  //                 Positioned(
  //                   top: 40,
  //                   left: 16,
  //                   child: IconButton(
  //                     icon: const Icon(
  //                       Icons.close,
  //                       color: Colors.white,
  //                       size: 30,
  //                     ),
  //                     onPressed: () => Navigator.pop(context),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //     ),
  //   );
  // }

  // 🎥 Videos tab
  Widget _buildVideosTab() {
    if (_isLoading) {
      return const Center(
        child: SpinKitFadingCircle(color: Colors.blueAccent, size: 60),
      );
    }

    if (uploadedVideos.isEmpty) {
      return const Center(
        child: Text(
          'No event videos available.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: uploadedVideos.length,
      itemBuilder: (context, index) {
        final video = uploadedVideos[index];
        final controller = _videoControllers[index];
        final dateStr =
            video['date'] != null
                ? DateFormat(
                  'dd MMM yyyy',
                ).format(DateTime.parse(video['date']))
                : '';

        return Card(
          elevation: 5,
          margin: const EdgeInsets.only(bottom: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              YoutubePlayer(
                controller: controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.blueAccent,
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video['title'] ?? 'Untitled Event',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (video['description'] != null &&
                        video['description'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          video['description'],
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    if (dateStr.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(video['link']);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Open in YouTube'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 150),
        child:
            isMobile
                ? StudentAppbarMobile(
                  schoolId: int.parse(widget.schoolId),
                  username: widget.username,
                  title: 'Events',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    StudentDashboardState.selectedIndex = 2;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => StudentDashboard(
                              username: widget.username,
                              schoolId: int.parse(widget.schoolId),
                            ),
                      ),
                    );
                  },
                )
                : StudentAppbarDesktop(
                  title: 'Events',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    StudentDashboardState.selectedIndex = 2;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => StudentDashboard(
                              username: widget.username,
                              schoolId: int.parse(widget.schoolId),
                            ),
                      ),
                    );
                  },
                ),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueAccent,
            tabs: const [
              Tab(icon: Icon(Icons.photo), text: 'Photos'),
              Tab(icon: Icon(Icons.video_library), text: 'Videos'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildPhotosTab(), _buildVideosTab()],
            ),
          ),
        ],
      ),
    );
  }
}
