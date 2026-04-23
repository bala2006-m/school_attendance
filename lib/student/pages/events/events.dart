// ignore_for_file: avoid_web_libraries_in_flutter

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

// ─────────────────────────────────────────────────────────────────────────────
// ROOT CAUSE
// ─────────────────────────────────────────────────────────────────────────────
// `youtube_player_iframe` internally creates a `webview_flutter` WebView.
// On Flutter Web there is no WebView; the platform plugin for webview_flutter
// is `webview_flutter_web`, and it must be registered before the first use.
// If it isn't, every controller construction (even before rendering) throws:
//
//   'WebViewPlatform.instance != null': A platform implementation for
//   `webview_flutter` has not been set.
//
// This exception is caught by _fetchMedia's catch-block and sets _hasError,
// so the page shows the error state immediately after loading — that's why
// the problem appeared to be a networking bug.
//
// SOLUTION
// ─────────────────────────────────────────────────────────────────────────────
// Split YouTube rendering into three platform files using Dart's conditional
// import mechanism:
//
//   youtube_player_stub.dart   – fallback / desktop (no player)
//   youtube_player_web.dart    – Flutter Web  → plain <iframe> via
//                                               dart:ui_web / HtmlElementView
//   youtube_player_native.dart – Android / iOS → youtube_player_iframe
//
// On Web we never instantiate a YoutubePlayerController at all, so the
// webview_flutter assertion is never hit. The browser renders a real
// YouTube iframe natively — which is actually BETTER than a WebView.
// ─────────────────────────────────────────────────────────────────────────────

// Single import — this file re-exports the correct platform implementation
// at compile time using `export ... if (dart.library.html)`.
// See youtube_player_platform.dart for the routing logic.
import '../../Appbar/student_appbar_desktop.dart';
import '../../Appbar/student_appbar_mobile.dart';
import '../event_group_photos_page.dart';
import '../student_dashboard.dart';
import './youtube_player_platform.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Responsive breakpoints – single source of truth
// ─────────────────────────────────────────────────────────────────────────────
class _BP {
  static bool isMobile(BuildContext ctx) => MediaQuery.sizeOf(ctx).width < 500;
  static bool isNarrow(BuildContext ctx) => MediaQuery.sizeOf(ctx).width < 900;
  static int photoColumns(BuildContext ctx) {
    final w = MediaQuery.sizeOf(ctx).width;
    if (w > 900) return 4;
    if (w > 600) return 3;
    return 2;
  }
}

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

  /// Native-only: keyed by video list index.
  /// On Web this map stays empty — iframes are stateless widgets.
  final Map<int, dynamic> _videoControllers = {};

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
    _tabController.addListener(_pauseVideosOnTabSwitch);
    _fetchMedia();
  }

  // ── Networking ──────────────────────────────────────────────────────────────
  Future<void> _fetchMedia() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await http
          .get(Uri.parse(fetchUrl), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          uploadedImages = List<Map<String, dynamic>>.from(
            (data['images'] as List?) ?? [],
          );
          uploadedVideos = List<Map<String, dynamic>>.from(
            (data['videos'] as List?) ?? [],
          );
        });
        // On Web we render iframes directly — no controller needed.
        // On native we create YoutubePlayerControllers here.
        if (!kIsWeb) _initNativeControllers();
        _fadeController.forward(from: 0);
      } else {
        setState(() => _hasError = true);
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _hasError = true);
    } catch (e) {
      debugPrint('[Events] _fetchMedia error: $e');
      if (!mounted) return;
      setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Native controller lifecycle ──────────────────────────────────────────────
  void _initNativeControllers() {
    _disposeNativeControllers();
    for (final entry in uploadedVideos.asMap().entries) {
      final link = entry.value['link']?.toString() ?? '';
      final ctrl = createNativeYoutubeController(link);
      if (ctrl != null) _videoControllers[entry.key] = ctrl;
    }
  }

  void _pauseVideosOnTabSwitch() {
    // We just moved TO the Photos tab — pause any playing native video
    if (_tabController.index != 0) return;
    if (kIsWeb) return;
    for (final c in _videoControllers.values) {
      pauseNativeYoutubeController(c);
    }
  }

  void _disposeNativeControllers() {
    for (final c in _videoControllers.values) {
      disposeNativeYoutubeController(c);
    }
    _videoControllers.clear();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  String _formatDate(dynamic v) {
    if (v == null) return '';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse('$v'));
    } catch (_) {
      return '';
    }
  }

  String _resolveImageUrl(dynamic rawUrl) {
    var url = rawUrl?.toString().trim() ?? '';
    if (url.isEmpty) return '';
    url = url.replaceAll('\\', '/');

    final base = Uri.parse(baseUrl);

    if (url.startsWith('//')) {
      url = '${base.scheme}:$url';
    }

    var parsed = Uri.tryParse(url);
    if (parsed != null && parsed.hasScheme) {
      final looksLikeMediaPath =
          parsed.path.contains('/upload') || parsed.path.contains('/uploads');
      final hostMismatch = parsed.host.isNotEmpty && parsed.host != base.host;
      final shouldUseBaseHost = hostMismatch && looksLikeMediaPath;

      if (shouldUseBaseHost ||
          (kIsWeb && parsed.scheme == 'http' && base.scheme == 'https')) {
        parsed = base.replace(
          path: parsed.path,
          query: parsed.query.isEmpty ? null : parsed.query,
          fragment: parsed.fragment.isEmpty ? null : parsed.fragment,
        );
      }

      url = parsed.toString();
    } else {
      final drivePath = RegExp(r'^[A-Za-z]:/');
      if (drivePath.hasMatch(url)) {
        final lower = url.toLowerCase();
        final uploadsIndex = lower.lastIndexOf('/uploads/');
        if (uploadsIndex >= 0) {
          url = url.substring(uploadsIndex);
        }
      }

      final normalizedPath = url.startsWith('/') ? url : '/$url';
      url = base.resolve(normalizedPath).toString();
    }

    if (kIsWeb && url.startsWith('http://')) {
      url = url.replaceFirst('http://', 'https://');
    }

    return url;
  }

  @override
  void dispose() {
    _tabController.removeListener(_pauseVideosOnTabSwitch);
    if (!kIsWeb) _disposeNativeControllers();
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════
  //  TAB BAR
  // ══════════════════════════════════════
  Widget _buildTabBar() {
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
                  _badge(
                    groupBy(
                      uploadedImages,
                      (o) => (o['title'] as String?)?.trim() ?? '',
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
                  _badge(uploadedVideos.length.toString(), Colors.red),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      t,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c),
    ),
  );

  // ══════════════════════════════════════
  //  EMPTY / ERROR
  // ══════════════════════════════════════
  Widget _emptyState({
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

  Widget _errorState() => Center(
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
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  // ══════════════════════════════════════
  //  SHIMMER
  // ══════════════════════════════════════
  Widget _loadingGrid(BuildContext ctx) => GridView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 6,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: _BP.photoColumns(ctx),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 0.8,
    ),
    itemBuilder: (_, __) => const _ShimmerCard(),
  );

  Widget _loadingList() => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 3,
    itemBuilder: (_, __) => const _ShimmerVideoCard(),
  );

  // ══════════════════════════════════════
  //  PHOTOS TAB
  // ══════════════════════════════════════
  Widget _photosTab(BuildContext ctx) {
    if (_isLoading) return _loadingGrid(ctx);
    if (_hasError) return _errorState();
    if (uploadedImages.isEmpty) {
      return _emptyState(
        icon: Icons.photo_library_outlined,
        title: 'No Photos Yet',
        subtitle: 'Event photos will appear here once uploaded by your school.',
      );
    }

    final grouped = groupBy(
      uploadedImages,
      (o) => (o['title'] as String?)?.trim() ?? 'No Title',
    );

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
          itemCount: grouped.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _BP.photoColumns(ctx),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (c, i) {
            final title = grouped.keys.elementAt(i);
            final images = grouped[title]!;
            final previewUrl = _resolveImageUrl(images.first['link']);
            return _PhotoGroupCard(
              title: title,
              imageUrl: previewUrl,
              count: images.length,
              index: i,
              onTap:
                  () => Navigator.push(
                    c,
                    PageRouteBuilder(
                      pageBuilder:
                          (_, __, ___) => EventGroupPhotosPage(
                            title: title,
                            images: images,
                            schoolId: widget.schoolId,
                          ),
                      transitionsBuilder:
                          (_, a, __, ch) =>
                              FadeTransition(opacity: a, child: ch),
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  ),
            );
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  //  VIDEOS TAB
  // ══════════════════════════════════════
  Widget _videosTab(BuildContext ctx) {
    if (_isLoading) return _loadingList();
    if (_hasError) return _errorState();
    if (uploadedVideos.isEmpty) {
      return _emptyState(
        icon: Icons.videocam_off_outlined,
        title: 'No Videos Yet',
        subtitle: 'Event videos will appear here once uploaded by your school.',
      );
    }

    final hPad = _BP.isNarrow(ctx) ? 16.0 : 80.0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _fetchMedia,
        color: Colors.indigo,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 16),
          itemCount: uploadedVideos.length,
          itemBuilder:
              (_, i) => _VideoCard(
                video: uploadedVideos[i],
                nativeController: kIsWeb ? null : _videoControllers[i],
                dateStr: _formatDate(uploadedVideos[i]['date']),
                index: i,
              ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final mob = _BP.isMobile(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(mob ? 190 : 150),
        child:
            mob
                ? StudentAppbarMobile(
                  schoolId: int.parse(widget.schoolId),
                  username: widget.username,
                  title: 'Events',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: _back,
                )
                : StudentAppbarDesktop(
                  title: 'Events',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: _back,
                ),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Builder(builder: _photosTab),
                Builder(builder: _videosTab),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _back() {
    StudentDashboardState.selectedIndex = 2;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => StudentDashboard(
              username: widget.username,
              schoolId: int.parse(widget.schoolId),
            ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
//  VIDEO CARD  (platform-aware player)
// ═════════════════════════════════════════════════════════════
class _VideoCard extends StatefulWidget {
  const _VideoCard({
    required this.video,
    required this.nativeController,
    required this.dateStr,
    required this.index,
  });

  final Map<String, dynamic> video;
  final dynamic nativeController;
  final String dateStr;
  final int index;

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    _fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));

    Future.delayed(
      Duration(milliseconds: (100 * widget.index).clamp(0, 600)),
      () {
        if (mounted) _ac.forward();
      },
    );
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  static String? _videoId(String url) {
    for (final p in [
      RegExp(r'youtu\.be/([^?&]+)'),
      RegExp(r'[?&]v=([^?&]+)'),
      RegExp(r'/embed/([^?&]+)'),
      RegExp(r'/shorts/([^?&]+)'),
    ]) {
      final m = p.firstMatch(url);
      if (m != null) return m.group(1);
    }
    return null;
  }

  Widget _buildPlayer() {
    final link = widget.video['link']?.toString() ?? '';
    final id = _videoId(link);

    if (id == null) {
      return _fallback('Preview unavailable for this link.');
    }

    if (kIsWeb) {
      // ── Web: native browser <iframe>, zero WebView involved ──
      return AspectRatio(aspectRatio: 16 / 9, child: buildWebYoutubePlayer(id));
    }

    // ── Native: YoutubePlayerController from youtube_player_iframe ──
    if (widget.nativeController == null) {
      return _posterPlayer(id);
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: buildNativeYoutubePlayer(widget.nativeController),
    );
  }

  Widget _posterPlayer(String id) {
    final thumbUrl = 'https://img.youtube.com/vi/$id/hqdefault.jpg';
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Material(
        color: Colors.black,
        child: InkWell(
          onTap: _openLink,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: thumbUrl,
                fit: BoxFit.cover,
                errorWidget:
                    (_, __, ___) => Container(
                      color: Colors.black87,
                      alignment: Alignment.center,
                    ),
              ),
              Container(color: Colors.black.withValues(alpha: 0.28)),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback(String msg) => AspectRatio(
    aspectRatio: 16 / 9,
    child: Container(
      color: Colors.black87,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  Future<void> _openLink() async {
    final link = widget.video['link']?.toString() ?? '';
    if (link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    await launchUrl(
      uri,
      mode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.video;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
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
                _buildPlayer(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v['title']?.toString() ?? 'Untitled Event',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      if ((v['description']?.toString() ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          v['description'].toString(),
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (widget.dateStr.isNotEmpty)
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
                          const Spacer(),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: _openLink,
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

// ═════════════════════════════════════════════════════════════
//  PHOTO GROUP CARD
// ═════════════════════════════════════════════════════════════
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
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  Widget _buildPreviewImage() {
    if (kIsWeb) {
      return Image.network(
        widget.imageUrl,
        fit: BoxFit.cover,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder:
            (_, __, ___) => Container(
              color: Colors.grey.shade200,
              child: Icon(
                Icons.broken_image_rounded,
                color: Colors.grey.shade400,
                size: 40,
              ),
            ),
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: BoxFit.cover,
      placeholder:
          (_, __) => Container(
            color: Colors.grey.shade200,
            child: Center(
              child: SpinKitPulse(color: Colors.grey.shade400, size: 30),
            ),
          ),
      errorWidget:
          (_, __, ___) => Container(
            color: Colors.grey.shade200,
            child: Icon(
              Icons.broken_image_rounded,
              color: Colors.grey.shade400,
              size: 40,
            ),
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(
      Duration(milliseconds: (80 * widget.index).clamp(0, 600)),
      () {
        if (mounted) _ctrl.forward();
      },
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
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
                  _buildPreviewImage(),
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
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
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

// ═════════════════════════════════════════════════════════════
//  SHIMMER PLACEHOLDERS
// ═════════════════════════════════════════════════════════════
class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder:
        (_, __) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _c.value, 0),
              end: Alignment(1.0 + 2.0 * _c.value, 0),
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
            ),
          ),
        ),
  );
}

class _ShimmerVideoCard extends StatefulWidget {
  const _ShimmerVideoCard();
  @override
  State<_ShimmerVideoCard> createState() => _ShimmerVideoCardState();
}

class _ShimmerVideoCardState extends State<_ShimmerVideoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) {
      final g = LinearGradient(
        begin: Alignment(-1.0 + 2.0 * _c.value, 0),
        end: Alignment(1.0 + 2.0 * _c.value, 0),
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
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  gradient: g,
                ),
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
                      gradient: g,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: g,
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
