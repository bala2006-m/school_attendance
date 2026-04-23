// youtube_player_web.dart
//
// Flutter Web implementation.
//
// Strategy: register a unique <iframe> element with the browser via
// dart:ui_web's platformViewRegistry, then render it with HtmlElementView.
//
// WHY THIS INSTEAD OF youtube_player_iframe ON WEB?
// youtube_player_iframe uses webview_flutter under the hood.
// webview_flutter on Web delegates to webview_flutter_web, which wraps an
// <iframe> anyway — but it requires the platform plugin to be registered
// via WebViewPlatform.instance before any controller is constructed.
// If that registration is missing (common in many project setups) you get:
//
//   'WebViewPlatform.instance != null': A platform implementation for
//   `webview_flutter` has not been set.
//
// By registering the iframe directly through dart:ui_web we bypass
// webview_flutter entirely. The result is identical HTML but with no
// dependency on the WebView platform registration.

// ignore_for_file: avoid_web_libraries_in_flutter

// dart:html is only compiled on web; the conditional import in events.dart
// ensures this file is never imported on non-web targets.
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

// Track which video IDs have already been registered so we don't call
// platformViewRegistry.registerViewFactory twice for the same id
// (doing so throws on Flutter Web).
final _registeredIds = <String>{};

/// No-op on Web: controller management is handled by the browser itself.
dynamic createNativeYoutubeController(String videoUrl) => null;

/// No-op on Web.
void pauseNativeYoutubeController(dynamic controller) {}

/// No-op on Web.
void disposeNativeYoutubeController(dynamic controller) {}

/// Renders a YouTube <iframe> using HtmlElementView.
///
/// Each [videoId] gets its own view-type key so multiple videos on the
/// same page don't share the same iframe registration.
Widget buildWebYoutubePlayer(String videoId) {
  final viewType = 'youtube-iframe-$videoId';

  if (!_registeredIds.contains(viewType)) {
    _registeredIds.add(viewType);

    ui_web.platformViewRegistry.registerViewFactory(viewType, (_) {
      // Build the standard YouTube embed URL.
      // - enablejsapi=1  : lets the JS API control playback (optional but useful)
      // - playsinline=1  : prevents iOS Safari from hijacking to fullscreen
      // - rel=0          : don't show unrelated videos at the end
      final src =
          'https://www.youtube.com/embed/$videoId'
          '?enablejsapi=1&playsinline=1&rel=0';

      final iframe =
          html.IFrameElement()
            ..src = src
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            // allow="..." is required by browsers to enable autoplay + fullscreen
            ..setAttribute(
              'allow',
              'accelerometer; autoplay; clipboard-write; '
                  'encrypted-media; gyroscope; picture-in-picture; '
                  'web-share',
            )
            ..setAttribute('allowfullscreen', 'true')
            ..setAttribute('referrerpolicy', 'strict-origin-when-cross-origin');

      return iframe;
    });
  }

  return HtmlElementView(viewType: viewType);
}

/// Not used on Web — native controllers are null on this platform.
Widget buildNativeYoutubePlayer(dynamic controller) => const SizedBox.shrink();
