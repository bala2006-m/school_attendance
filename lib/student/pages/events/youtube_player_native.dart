// youtube_player_native.dart
//
// Android / iOS / Desktop implementation.
// Uses the youtube_player_iframe package as before.
//
// This file is only compiled on dart:io targets (Android, iOS, macOS,
// Windows, Linux). It is NEVER compiled on Flutter Web, so the
// webview_flutter assertion cannot be triggered from this file.

import 'package:flutter/widgets.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Creates a [YoutubePlayerController] for the given YouTube URL.
/// Returns null if the URL is not a recognisable YouTube link.
dynamic createNativeYoutubeController(String videoUrl) {
  final videoId = YoutubePlayerController.convertUrlToId(videoUrl);
  if (videoId == null) return null;

  return YoutubePlayerController.fromVideoId(
    videoId: videoId,
    autoPlay: false,
    params: const YoutubePlayerParams(
      mute: false,
      showControls: true,
      showFullscreenButton: true,
      // playsInline: true is REQUIRED on iOS Safari.
      // Without it the player attempts an immediate fullscreen transition,
      // which the browser blocks, producing a black box.
      playsInline: true,
    ),
  );
}

/// Pauses a [YoutubePlayerController]. Safe to call even if already paused.
void pauseNativeYoutubeController(dynamic controller) {
  if (controller is YoutubePlayerController) {
    // unawaited is intentional — we don't need to await pause during tab switch
    controller.pauseVideo().ignore();
  }
}

/// Pauses then closes a [YoutubePlayerController].
void disposeNativeYoutubeController(dynamic controller) {
  if (controller is YoutubePlayerController) {
    controller.pauseVideo().ignore();
    controller.close().ignore();
  }
}

/// Not used on native — the web iframe builder is web-only.
Widget buildWebYoutubePlayer(String videoId) => const SizedBox.shrink();

/// Renders a [YoutubePlayer] for the given controller.
Widget buildNativeYoutubePlayer(dynamic controller) {
  if (controller is! YoutubePlayerController) return const SizedBox.shrink();
  return YoutubePlayer(controller: controller);
}
