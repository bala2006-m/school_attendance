// youtube_player_stub.dart
//
// Fallback used when neither dart:html nor dart:io is available
// (e.g. unit tests, unknown targets).  Exposes the same surface
// as the web and native variants so the main file always compiles.

import 'package:flutter/material.dart';

/// Called from _EventsState._initNativeControllers() on native platforms.
/// Returns null on stub so _VideoCard shows the fallback widget.
dynamic createNativeYoutubeController(String videoUrl) => null;

/// Pause a native controller. No-op on stub.
void pauseNativeYoutubeController(dynamic controller) {}

/// Dispose a native controller. No-op on stub.
void disposeNativeYoutubeController(dynamic controller) {}

/// Build the web iframe player. Returns a placeholder on stub.
Widget buildWebYoutubePlayer(String videoId) =>
    const Center(child: Text('YouTube player not available on this platform.'));

/// Build the native YoutubePlayer widget. Returns a placeholder on stub.
Widget buildNativeYoutubePlayer(dynamic controller) =>
    const Center(child: Text('YouTube player not available on this platform.'));
