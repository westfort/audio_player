library audioplayer;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

typedef void TimeChangeHandler(Duration duration);
typedef void ErrorHandler(String message);

class AudioPlayer {
  static final MethodChannel _channel =
  MethodChannel('co.westfort.flutter/audio')
    ..setMethodCallHandler(platformCallHandler);
  static final audioPlayers = Map<String, AudioPlayer>();
  static final uuid = Uuid();

  TimeChangeHandler durationHandler;
  TimeChangeHandler positionHandler;
  VoidCallback completionHandler;
  ErrorHandler errorHandler;
  String playerId;

  AudioPlayer() {
    playerId = uuid.v4();
    audioPlayers[playerId] = this;
  }

  void play(String url) => _channel.invokeMethod('play', {
    'playerId': playerId,
    'url': url,
  });

  void pause() => _channel.invokeMethod('pause', {
    'playerId': playerId,
  });

  void stop() => _channel.invokeMethod('stop', {
    'playerId': playerId,
  });

  void seek(double position) => _channel.invokeMethod('seek', {
    'playerId': playerId,
    'position': position,
  });

  void setVolume(double volume) => _channel.invokeMethod('volume', {
    'playerId': playerId,
    'volume': volume,
  });

  void setDurationHandler(TimeChangeHandler handler) =>
    durationHandler = handler;

  void setCompletionHandler(VoidCallback handler) =>
    completionHandler = handler;

  void setPositionHandler(TimeChangeHandler handler) =>
    positionHandler = handler;

  static Future platformCallHandler(MethodCall call) async {
    Map arguments = call.arguments as Map;
    String playerId = arguments['playerId'];
    AudioPlayer player = audioPlayers[playerId];
    dynamic value = arguments['value'];

    switch (call.method) {
      case 'audio.onDuration':
        if (player.durationHandler != null) {
          player.durationHandler(Duration(milliseconds: value));
        }
        break;
      case 'audio.onCurrentPosition':
        if (player.positionHandler != null) {
          player.positionHandler(Duration(milliseconds: value));
        }
        break;
      case 'audio.onComplete':
        if (player.completionHandler != null) {
          player.completionHandler();
        }
        break;
      default:
        break;
    }
  }
}
