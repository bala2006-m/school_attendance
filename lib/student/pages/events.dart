import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

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
  bool _hasError = false;
  List<Map<String, dynamic>> uploadedImages = [];
  List<Map<String, dynamic>> uploadedVideos = [];

  final String baseUrl = 'https://smartschoolserver.ramchintech.com';
  late final String fetchUrl;

  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final Map<int, YoutubePlayerController> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    fetchUrl = '$baseUrl/upload/${widget.schoolId}';
    _tabController = TabController(length: 2, vsync: this);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _tabController.addListener(_pauseVideosWhenLeavingTab);

    _fetchMedia();
  }

  Future<void> _fetchMedia() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final response = await http
          .get(Uri.parse(fetchUrl))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          uploadedImages = List<Map<String, dynamic>>.from(data['images']);
          uploadedVideos = List<Map<String, dynamic>>.from(data['videos']);
        });
        _initVideoControllers();
        _fadeController.forward(from: 0);
      } else {
        if (!mounted) return;
        setState(() => _hasError = true);
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _hasError = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _hasError = true);
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _initVideoControllers() {
    _disposeVideoControllers();
    for (final entry in uploadedVideos.asMap().entries) {
      final link = entry.value['link']?.toString() ?? '';
      final videoId = YoutubePlayerController.convertUrlToId(link);
      if (videoId != null) {
        _videoControllers[entry.key] = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: false,
          params: const YoutubePlayerParams(
            mute: false,
            showControls: true,
            showFullscreenButton: true,
          ),
        );
      }
    }
  }

  void _pauseVideosWhenLeavingTab() {
    if (_tabController.index == 1) return;
    for (final controller in _videoControllers.values) {
      unawaited(controller.pauseVideo());
    }
  }

  void _disposeVideoControllers() {
    for (final controller in _videoControllers.values) {
      unawaited(controller.pauseVideo());
      unawaited(controller.close());
    }
    _videoControllers.clear();
  }

  String _formatVideoDate(dynamic dateValue) {
    if (dateValue == null) return '';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse('$dateValue'));
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_pauseVideosWhenLeavingTab);
    _disposeVideoControllers();
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════
  //  CUSTOM TAB BAR
  // ════════════════════════════════════════
  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.indigo.shade700,
        unselectedLabelColor: Colors.grey.shade500,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_library_rounded, size: 20),
                const SizedBox(width: 8),
                const Text('Photos'),
                if (uploadedImages.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _buildBadge(
                    groupBy(
                      uploadedImages,
                      (obj) => (obj['title'] as String?)?.trim() ?? 'No Title',
                    ).length.toString(),
                    Colors.indigo,
                  ),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_outline_rounded, size: 20),
                const SizedBox(width: 8),
                const Text('Videos'),
                if (uploadedVideos.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _buildBadge(uploadedVideos.length.toString(), Colors.red),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  //  EMPTY STATE
  // ════════════════════════════════════════
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 52, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  //  ERROR STATE
  // ════════════════════════════════════════
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: Colors.red.shade300,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Could not load events. Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _fetchMedia,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  //  LOADING SHIMMER
  // ════════════════════════════════════════
  Widget _buildLoadingGrid() {
    final crossAxisCount =
        MediaQuery.of(context).size.width > 900
            ? 4
            : MediaQuery.of(context).size.width > 600
            ? 3
            : 2;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        return _ShimmerCard();
      },
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => _ShimmerVideoCard(),
    );
  }

  // ════════════════════════════════════════
  //  PHOTOS TAB
  // ════════════════════════════════════════
  Widget _buildPhotosTab() {
    if (_isLoading) return _buildLoadingGrid();
    if (_hasError) return _buildErrorState();

    if (uploadedImages.isEmpty) {
      return _buildEmptyState(
        icon: Icons.photo_library_outlined,
        title: 'No Photos Yet',
        subtitle: 'Event photos will appear here once uploaded by your school.',
      );
    }

    final groupedImages = groupBy(
      uploadedImages,
      (obj) => (obj['title'] as String?)?.trim() ?? 'No Title',
    );

    final crossAxisCount =
        MediaQuery.of(context).size.width > 900
            ? 4
            : MediaQuery.of(context).size.width > 600
            ? 3
            : 2;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _fetchMedia,
        color: Colors.indigo,
        child: GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(16),
          itemCount: groupedImages.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            final title = groupedImages.keys.elementAt(index);
            final images = groupedImages[title]!;
            final firstImg = images.first;
            final imageUrl = firstImg['link'];
            final count = images.length;

            return _PhotoGroupCard(
              title: title,
              imageUrl: imageUrl,
              count: count,
              index: index,
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder:
                        (_, __, ___) => EventGroupPhotosPage(
                          title: title,
                          images: images,
                          schoolId: widget.schoolId,
                        ),
                    transitionsBuilder: (_, animation, __, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  //  VIDEOS TAB
  // ════════════════════════════════════════
  Widget _buildVideosTab() {
    if (_isLoading) return _buildLoadingList();
    if (_hasError) return _buildErrorState();

    if (uploadedVideos.isEmpty) {
      return _buildEmptyState(
        icon: Icons.videocam_off_outlined,
        title: 'No Videos Yet',
        subtitle: 'Event videos will appear here once uploaded by your school.',
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _fetchMedia,
        color: Colors.indigo,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: uploadedVideos.length,
          itemBuilder: (context, index) {
            final video = uploadedVideos[index];
            final controller = _videoControllers[index];
            final dateStr = _formatVideoDate(video['date']);

            return _VideoCard(
              video: video,
              controller: controller,
              dateStr: dateStr,
              index: index,
            );
          },
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
          _buildCustomTabBar(),
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

// ════════════════════════════════════════════════════════════
//  PHOTO GROUP CARD (Extracted for clean staggered animation)
// ════════════════════════════════════════════════════════════
class _PhotoGroupCard extends StatefulWidget {
  const _PhotoGroupCard({
    required this.title,
    required this.imageUrl,
    required this.count,
    required this.index,
    required this.onTap,
  });

  final String title;
  final String imageUrl;
  final int count;
  final int index;
  final VoidCallback onTap;

  @override
  State<_PhotoGroupCard> createState() => _PhotoGroupCardState();
}

class _PhotoGroupCardState extends State<_PhotoGroupCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Staggered entrance
    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── Background Image ──
                  CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: SpinKitPulse(
                              color: Colors.grey.shade400,
                              size: 30,
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: Colors.grey.shade400,
                            size: 40,
                          ),
                        ),
                  ),

                  // ── Gradient Overlay ──
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.4, 1.0],
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),

                  // ── Folder Icon ──
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.folder_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),

                  // ── Image Count Badge ──
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_outlined,
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.count}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Title ──
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                      child: Text(
                        widget.title.isEmpty ? 'Untitled Event' : widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.3,
                          shadows: [
                            Shadow(
                              blurRadius: 6,
                              color: Colors.black45,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  VIDEO CARD
// ════════════════════════════════════════════════════════════
class _VideoCard extends StatefulWidget {
  const _VideoCard({
    required this.video,
    required this.controller,
    required this.dateStr,
    required this.index,
  });

  final Map<String, dynamic> video;
  final YoutubePlayerController? controller;
  final String dateStr;
  final int index;

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _playerLoadTimer;
  StreamSubscription<YoutubePlayerValue>? _playerSubscription;
  bool _playerLoadTimedOut = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) _animController.forward();
    });
    _startPlayerLoadWatch();
  }

  @override
  void didUpdateWidget(covariant _VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _clearPlayerLoadWatch();
      _startPlayerLoadWatch();
    }
  }

  @override
  void dispose() {
    _clearPlayerLoadWatch();
    _animController.dispose();
    super.dispose();
  }

  void _startPlayerLoadWatch() {
    final controller = widget.controller;
    if (controller == null) return;

    void resolveLoaded(YoutubePlayerValue value) {
      if (value.playerState == PlayerState.unknown && !value.hasError) return;
      _playerLoadTimer?.cancel();
      if (_playerLoadTimedOut && mounted) {
        setState(() => _playerLoadTimedOut = false);
      }
    }

    resolveLoaded(controller.value);
    _playerSubscription = controller.stream.listen(resolveLoaded);

    _playerLoadTimer = Timer(const Duration(seconds: 12), () {
      final value = controller.value;
      if (!mounted) return;
      if (value.playerState != PlayerState.unknown || value.hasError) return;
      setState(() => _playerLoadTimedOut = true);
    });
  }

  void _clearPlayerLoadWatch() {
    _playerSubscription?.cancel();
    _playerSubscription = null;
    _playerLoadTimer?.cancel();
    _playerLoadTimer = null;
  }

  Widget _buildVideoFallback({required String message}) {
    return Container(
      height: 210,
      color: Colors.black87,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    final controller = widget.controller;
    if (controller == null) {
      return _buildVideoFallback(
        message: 'Preview is unavailable for this video link.',
      );
    }
    if (_playerLoadTimedOut) {
      return _buildVideoFallback(
        message: 'Preview is taking too long. Open in YouTube below.',
      );
    }

    return YoutubePlayer(
      controller: controller,
      aspectRatio: 16 / 9,
    );
  }

  Future<void> _openVideoLink(String videoLink) async {
    if (videoLink.isEmpty) return;
    final uri = Uri.tryParse(videoLink);
    if (uri == null) return;
    await launchUrl(
      uri,
      mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final videoLink = video['link']?.toString() ?? '';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── YouTube Player ──
                _buildVideoPreview(),

                // ── Video Info ──
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title Row ──
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              video['title'] ?? 'Untitled Event',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ── Description ──
                      if (video['description'] != null &&
                          video['description'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            video['description'],
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      const SizedBox(height: 12),

                      // ── Date + YouTube Button Row ──
                      Row(
                        children: [
                          if (widget.dateStr.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    widget.dateStr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () async {
                                await _openVideoLink(videoLink);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.play_arrow_rounded,
                                      size: 18,
                                      color: Colors.red.shade500,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'YouTube',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
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
  }
}

// ════════════════════════════════════════════════════════════
//  SHIMMER PLACEHOLDERS
// ════════════════════════════════════════════════════════════
class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(1.0 + 2.0 * _controller.value, 0),
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerVideoCard extends StatefulWidget {
  @override
  State<_ShimmerVideoCard> createState() => _ShimmerVideoCardState();
}

class _ShimmerVideoCardState extends State<_ShimmerVideoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shimmerColor = LinearGradient(
          begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
          end: Alignment(1.0 + 2.0 * _controller.value, 0),
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  gradient: shimmerColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: shimmerColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: shimmerColor,
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
}
