import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../dashboard/admin_dashboard.dart';

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
  List<String> uploadedImages = [];
  List<String> uploadedVideos = [];

  final String baseUrl = 'https://smartschoolserver.ramchintech.com';
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
          uploadedImages = List<String>.from(
            data['images'].map((e) => e['link']),
          );
          uploadedVideos = List<String>.from(
            data['videos'].map((e) => e['link']),
          );
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ------------------- Image Upload -------------------
  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    Map<String, String>? details;
    if (mounted) {
      details = await _askForDetails(context);
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
      final res = await http.Response.fromStream(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(res.body);
        setState(() => uploadedImages.insert(0, data['url']));
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
    if (link.isEmpty || !link.contains('youtube')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Enter a valid YouTube URL')),
      );
      return;
    }

    final details = await _askForDetails(context);
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
          uploadedVideos.insert(0, link);
          _videoController.clear();
        });
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
  Future<void> _confirmDeleteImage(String imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Delete Image'),
            content: const Text('Are you sure you want to delete this image?'),
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

    if (confirm == true) _deleteImage(imageUrl);
  }

  Future<void> _confirmDeleteVideo(String link) async {
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

    if (confirm == true) _deleteVideo(link);
  }

  Future<void> _deleteImage(String imageUrl) async {
    final filename = p.basename(imageUrl);
    final uri = Uri.parse('$baseUrl/upload/${widget.schoolId}/$filename');

    try {
      final response = await http.delete(uri);
      if (response.statusCode == 200) {
        setState(() => uploadedImages.remove(imageUrl));
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('🗑️ Image deleted')));
        }
      }
    } catch (e) {
      return;
    }
  }

  void _deleteVideo(String link) {
    setState(() => uploadedVideos.remove(link));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('🗑️ Video deleted')));
  }

  // ------------------- Detail Dialog -------------------
  Future<Map<String, String>?> _askForDetails(BuildContext context) async {
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
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descController,
                        maxLines: 3,
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

    return RefreshIndicator(
      onRefresh: _fetchMedia,
      child: GridView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: uploadedImages.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, i) {
          final img = uploadedImages[i];
          return GestureDetector(
            onLongPress: () => _confirmDeleteImage(img),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              elevation: 6,
              child: CachedNetworkImage(
                imageUrl: img,
                fit: BoxFit.cover,
                placeholder:
                    (_, __) => const Center(child: CircularProgressIndicator()),
              ),
            ),
          );
        },
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
                      final link = uploadedVideos[i];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(
                            Icons.play_circle_fill,
                            color: Colors.redAccent,
                            size: 36,
                          ),
                          title: Text('Video ${i + 1}'),
                          subtitle: Text(link, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () => _confirmDeleteVideo(link),
                          ),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AdminDashboard(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
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
        floatingActionButton:
            _tabController.index == 0
                ? FloatingActionButton(
                  onPressed: _isUploading ? null : _pickAndUploadImage,
                  backgroundColor:
                      _isUploading ? Colors.grey : Colors.blueAccent,
                  child:
                      _isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(Icons.add_a_photo),
                )
                : null,
      ),
    );
  }
}
