// youtube_player_platform_impl_native.dart
//
// Compiled on Android / iOS / Desktop (dart:io targets).
// Uses youtube_player_iframe on supported native targets only.
// Desktop targets like Windows/Linux can hit a webview platform assertion,
// so we intentionally fall back there.

import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

bool _supportsEmbeddedYoutubePlayer() =>
    Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

/// Creates a YoutubePlayerController for [videoUrl].
/// Returns null if the URL isn't a valid YouTube link.
dynamic createNativeYoutubeController(String videoUrl) {
  if (!_supportsEmbeddedYoutubePlayer()) return null;

  final videoId = YoutubePlayerController.convertUrlToId(videoUrl);
  if (videoId == null) return null;
  return YoutubePlayerController.fromVideoId(
    videoId: videoId,
    autoPlay: false,
    params: const YoutubePlayerParams(
      mute: false,
      showControls: true,
      showFullscreenButton: true,
      // Required on iOS Safari — without this the player tries to go
      // fullscreen immediately, which the browser blocks → black box.
      playsInline: true,
    ),
  );
}

void pauseNativeYoutubeController(dynamic controller) {
  if (controller is YoutubePlayerController) {
    controller.pauseVideo().ignore();
  }
}

void disposeNativeYoutubeController(dynamic controller) {
  if (controller is YoutubePlayerController) {
    controller.pauseVideo().ignore();
    controller.close().ignore();
  }
}

/// Not used on native — returns empty widget.
Widget buildWebYoutubePlayer(String videoId) => const SizedBox.shrink();

/// Renders the YoutubePlayer widget for a native controller.
Widget buildNativeYoutubePlayer(dynamic controller) {
  if (!_supportsEmbeddedYoutubePlayer()) return const SizedBox.shrink();
  if (controller is! YoutubePlayerController) return const SizedBox.shrink();
  return YoutubePlayer(controller: controller);
}
