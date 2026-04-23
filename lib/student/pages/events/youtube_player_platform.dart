// youtube_player_platform.dart
//
// Single import surface used by events.dart.
// - Web: render a plain browser iframe (no webview_flutter dependency).
// - IO: use youtube_player_iframe on supported native platforms.
// - Fallback: stub placeholders for unsupported/unknown targets.

export 'youtube_player_stub.dart'
    if (dart.library.html) 'youtube_player_web.dart'
    if (dart.library.io) 'youtube_player_platform_impl_native.dart';
