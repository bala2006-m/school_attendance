import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
// import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../../../utils/utils.dart';
import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../dashboard/admin_dashboard.dart';
import 'group_photos_page.dart';

class UploadImagesVideos extends StatefulWidget {
  const UploadImagesVideos({
    super.key,
    required this.username,
    required this.schoolId,
  });

  final String username;
  final String schoolId;

  @override
  State<UploadImagesVideos> createState() => _UploadImagesVideosState();
}

class _UploadImagesVideosState extends State<UploadImagesVideos>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _videoController = TextEditingController();

  bool _isUploading = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> uploadedImages = [];
  List<Map<String, dynamic>> uploadedVideos = [];
  List<dynamic> imageTitles = [];
  List<dynamic> videoTitles = [];
  late final String uploadUrl;
  late final String uploadVideoUrl;
  late final String fetchUrl;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    uploadUrl = '$baseUrl/upload';
    uploadVideoUrl = '$baseUrl/upload/video';
    fetchUrl = '$baseUrl/upload/${widget.schoolId}';
    _tabController = TabController(length: 2, vsync: this);
    _fetchMedia();
  }

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
      }
      fetchTitles();
    } catch (e) {
      setState(() => _isLoading = false);
      fetchTitles();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> fetchTitles() async {
    final response1 = await http.get(
      Uri.parse('$baseUrl/upload/titles/image/${widget.schoolId}'),
    );
    final response2 = await http.get(
      Uri.parse('$baseUrl/upload/titles/video/${widget.schoolId}'),
    );
    if (response1.statusCode == 200 || response1.statusCode == 201) {
      final data = jsonDecode(response1.body);
      setState(() {
        imageTitles = data;
      });
    }
    if (response2.statusCode == 200 || response2.statusCode == 201) {
      final data = jsonDecode(response2.body);
      setState(() {
        videoTitles = data;
      });
    }
  }

  // ------------------- Image Upload -------------------
  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final existingTitles =
        uploadedImages
            .map((e) => e['title'] as String? ?? '')
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();

    Map<String, String>? details;
    if (mounted) {
      details = await _askForDetails(context, existingTitles);
    }
    if (details == null) return;

    setState(() => _isUploading = true);

    try {
      final uri = Uri.parse(uploadUrl);
      final request =
          http.MultipartRequest('POST', uri)
            ..files.add(
              await http.MultipartFile.fromPath('file', pickedFile.path),
            )
            ..fields.addAll({
              'schoolId': widget.schoolId,
              'username': widget.username,
              'title': details['title'] ?? '',
              'description': details['description'] ?? '',
              'date': details['date'] ?? DateTime.now().toIso8601String(),
            });

      final response = await request.send();
      await http.Response.fromStream(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh list to get new image with ID
        await _fetchMedia();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Image uploaded successfully')),
          );
        }
      } else {}
    } catch (e) {
      setState(() => _isUploading = false);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // ------------------- Video Upload -------------------
  Future<void> _addVideoLink() async {
    final link = _videoController.text.trim();
    // if (link.isEmpty || !link.contains('youtube')) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('⚠️ Enter a valid YouTube URL')),
    //   );
    //   return;
    // }

    final existingTitles =
        uploadedVideos
            .map((e) => e['title'] as String? ?? '')
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();

    final details = await _askForDetails(context, existingTitles);
    if (details == null) return;

    try {
      final body = jsonEncode({
        "schoolId": widget.schoolId,
        "link": link,
        "title": details['title'],
        "description": details['description'],
        "date": details['date'],
      });

      final response = await http.post(
        Uri.parse(uploadVideoUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _videoController.clear();
        });
        await _fetchMedia();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Video added successfully')),
          );
        }
      } else {}
    } catch (e) {
      return;
    }
  }

  // ------------------- Delete Confirmations -------------------
  // Future<void> _confirmDeleteImage(String imageUrl) async {
  //   final confirm = await showDialog<bool>(
  //     context: context,
  //     builder:
  //         (context) => AlertDialog(
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(16),
  //           ),
  //           title: const Text('Delete Image'),
  //           content: const Text('Are you sure you want to delete this image?'),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context, false),
  //               child: const Text('Cancel'),
  //             ),
  //             ElevatedButton(
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: Colors.redAccent,
  //               ),
  //               onPressed: () => Navigator.pop(context, true),
  //               child: const Text(
  //                 'Delete',
  //                 style: TextStyle(color: Colors.white),
  //               ),
  //             ),
  //           ],
  //         ),
  //   );
  //
  //   if (confirm == true) _deleteImage(imageUrl);
  // }

  Future<void> _confirmDeleteVideo(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Delete Video'),
            content: const Text('Are you sure you want to delete this video?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) _deleteVideo(id);
  }

  // Future<void> _deleteImage(String imageUrl) async {
  //   final filename = Uri.parse(imageUrl).pathSegments.last;
  //   final uri = Uri.parse('$baseUrl/upload/${widget.schoolId}/$filename');
  //
  //   try {
  //     final response = await http.delete(uri);
  //     if (response.statusCode == 200) {
  //       setState(() {
  //         uploadedImages.removeWhere((element) => element['link'] == imageUrl);
  //       });
  //       if (mounted) {
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(const SnackBar(content: Text('🗑️ Image deleted')));
  //       }
  //     }
  //   } catch (e) {
  //     return;
  //   }
  // }

  Future<void> _deleteVideo(int id) async {
    final uri = Uri.parse('$baseUrl/upload/videos/$id');

    try {
      final response = await http.delete(uri);
      if (response.statusCode == 200) {
        setState(() {
          uploadedVideos.removeWhere((element) => element['id'] == id);
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('🗑️ Video deleted')));
        }
      }
    } catch (e) {
      return;
    }
  }

  // void _deleteVideo(String link) {
  //   setState(() => uploadedVideos.remove(link));
  //   ScaffoldMessenger.of(
  //     context,
  //   ).showSnackBar(const SnackBar(content: Text('🗑️ Video deleted')));
  // }

  // ------------------- Detail Dialog -------------------
  Future<Map<String, String>?> _askForDetails(
    BuildContext context,
    List<String> existingTitles,
  ) async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Add Details'),
          content: StatefulBuilder(
            builder:
                (context, setState) => SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text == '') {
                            return const Iterable<String>.empty();
                          }
                          return existingTitles.where((String option) {
                            return option.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            );
                          });
                        },
                        onSelected: (String selection) {
                          titleController.text = selection;
                        },
                        fieldViewBuilder: (
                          BuildContext context,
                          TextEditingController fieldTextEditingController,
                          FocusNode fieldFocusNode,
                          VoidCallback onFieldSubmitted,
                        ) {
                          // Sync internal controller with our controller if needed,
                          // or just use the fieldTextEditingController.
                          // Here we listen to changes to update our titleController
                          fieldTextEditingController.addListener(() {
                            titleController.text =
                                fieldTextEditingController.text;
                          });
                          return TextField(
                            controller: fieldTextEditingController,
                            focusNode: fieldFocusNode,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              border: OutlineInputBorder(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descController,
                        maxLines: 3,
                        maxLength: 190,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.date_range),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => selectedDate = picked);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'title': titleController.text,
                  'description': descController.text,
                  'date': selectedDate.toIso8601String(),
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // ------------------- UI -------------------
  Widget _buildEmptyState(String message, IconData icon) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 10),
        Text(message, style: const TextStyle(color: Colors.grey, fontSize: 16)),
      ],
    ),
  );

  Widget _buildImagesTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (uploadedImages.isEmpty) {
      return _buildEmptyState('No images uploaded yet', Icons.photo);
    }

    final groupedImages = groupBy(
      uploadedImages,
      (obj) => (obj['title'] as String?)?.trim() ?? 'No Title',
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _pickAndUploadImage,
        backgroundColor: _isUploading ? Colors.grey : Colors.blueAccent,
        child:
            _isUploading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.add_a_photo),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMedia,
        child: GridView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: groupedImages.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, i) {
            final title = groupedImages.keys.elementAt(i);
            final images = groupedImages[title]!;
            final firstImg = images.first;
            final imgUrl = firstImg['link'] ?? '';
            final count = images.length;

            return GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => GroupPhotosPage(
                          title: title,
                          images: images,
                          schoolId: widget.schoolId,
                        ),
                  ),
                );

                if (result == true) {
                  _fetchMedia();
                }
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: imgUrl,
                            fit: BoxFit.cover,
                            placeholder:
                                (_, __) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                            errorWidget:
                                (_, __, ___) => const Icon(Icons.error),
                          ),
                          Container(
                            color: Colors.black26,
                            child: const Center(
                              child: Icon(
                                Icons.folder_open,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Text(
                            title.isEmpty ? 'No Title' : title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$count items',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                              // IconButton(
                              //   icon: const Icon(
                              //     Icons.delete,
                              //     color: Colors.redAccent,
                              //     size: 20,
                              //   ),
                              //   onPressed: () => _confirmDeleteImage(imgUrl),
                              // ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideosTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _videoController,
                  decoration: InputDecoration(
                    hintText: 'Enter YouTube video link',
                    prefixIcon: const Icon(Icons.video_library),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _addVideoLink,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Add', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              uploadedVideos.isEmpty
                  ? _buildEmptyState('No videos added yet', Icons.video_library)
                  : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: uploadedVideos.length,
                    itemBuilder: (context, i) {
                      final vidData = uploadedVideos[i];
                      final link = vidData['link'] ?? '';
                      final title = vidData['title'] ?? 'Video ${i + 1}';
                      final desc = vidData['description'] ?? '';
                      final date =
                          vidData['date'] != null
                              ? DateFormat(
                                'yyyy-MM-dd',
                              ).format(DateTime.parse(vidData['date']))
                              : '';

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            ListTile(
                              leading: IconButton(
                                icon: const Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.redAccent,
                                  size: 36,
                                ),
                                onPressed: () async {
                                  final uri = Uri.parse(link);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Could not launch video',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                              title: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                link,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed:
                                    () => _confirmDeleteVideo(vidData['id']),
                              ),
                            ),
                            if (desc.isNotEmpty || date.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 72,
                                  right: 16,
                                  bottom: 12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (desc.isNotEmpty)
                                      Text(
                                        desc,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    if (date.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        date,
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 2;
    Navigator.pop(context);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) {
          onWillPop();
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Events',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: onWillPop,
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Events',
                    onBack: onWillPop,
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
                children: [_buildImagesTab(), _buildVideosTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
