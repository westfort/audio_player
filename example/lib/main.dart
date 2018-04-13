import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(new MaterialApp(home: new Scaffold(body: new AudioApp())));
}

enum PlayerState { stopped, playing, paused }

class AudioApp extends StatefulWidget {
  @override
  _AudioAppState createState() => new _AudioAppState();
}

class _AudioAppState extends State<AudioApp> {
  AudioPlayer audioPlayer;

  String localFilePath;

  PlayerState playerState = PlayerState.stopped;

  @override
  void initState() {
    super.initState();
    initAudioPlayer();
  }

  void initAudioPlayer() {
    audioPlayer = AudioPlayer();

    audioPlayer.setDurationHandler((d) => setState(() {
          print('_AudioAppState.setDurationHandler => d ${d}');
        }));

    audioPlayer.setPositionHandler((p) => setState(() {
          print('_AudioAppState.setPositionHandler => p ${p}');
        }));
  }

  void _play() {}

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _PlayerUiWidget(url: 'http://www.largesound.com/ashborytour/sound/brobob.mp3'),
    );
  }
}

class _PlayerUiWidget extends StatefulWidget {
  final String url;

  _PlayerUiWidget({@required this.url});

  @override
  State<StatefulWidget> createState() {
    return _PlayerUiWidgetState(url: url);
  }
}

class _PlayerUiWidgetState extends State<_PlayerUiWidget> {
  String url;
  AudioPlayer _audioPlayer;
  Duration _duration;
  Duration _position;
  double _volume = 1.0;

  PlayerState _playerState = PlayerState.stopped;

  get _isPlaying => _playerState == PlayerState.playing;
  get _isPaused => _playerState == PlayerState.paused;
  get _durationText => _duration?.toString()?.split('.')?.first ?? '';
  get _positionText => _position?.toString()?.split('.')?.first ?? '';

  _PlayerUiWidgetState({@required this.url});

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  @override
  void dispose() {
    super.dispose();
    _audioPlayer.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            new IconButton(
                onPressed: _isPlaying ? null : () => _play(),
                iconSize: 64.0,
                icon: const Icon(Icons.play_arrow),
                color: Colors.black),
            new IconButton(
                onPressed: _isPlaying ? () => _pause() : null,
                iconSize: 64.0,
                icon: const Icon(Icons.pause),
                color: Colors.black),
            new IconButton(
                onPressed: _isPlaying || _isPaused ? () => _stop() : null,
                iconSize: 64.0,
                icon: const Icon(Icons.stop),
                color: Colors.black),
          ],
        ),
        Slider(
          value: _volume,
          min: 0.0,
          max: 1.0,
          onChanged: (double value) {
            _audioPlayer.setVolume(value);
            setState(() => _volume = value);
          },
        ),
        Slider(
          value: _position == null ? 0.0 : _position.inMilliseconds.toDouble(),
          min: 0.0,
          max: _duration == null ? 0.0 : _duration.inMilliseconds.toDouble(),
          onChanged: (double value) {
            _audioPlayer.seek(value);
          },
        ),
        new Text(
          _position != null
            ? "${_positionText ?? ''} / ${_durationText ?? ''}"
            : _duration != null ? _durationText : '',
          style: TextStyle(fontSize: 24.0),
        ),
      ],
    );
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer();

    _audioPlayer.setDurationHandler((d) => setState(() {
          _duration = d;
        }));

    _audioPlayer.setPositionHandler((p) => setState(() {
          _position = p;
        }));

    _audioPlayer.setCompletionHandler(() {
      _onComplete();
      setState(() {
        _position = _duration;
      });
    });
  }

  void _play() {
    _audioPlayer.play(url);
    setState(() {
      _playerState = PlayerState.playing;
    });
  }

  void _pause() {
    _audioPlayer.pause();
    setState(() {
      _playerState = PlayerState.paused;
    });
  }

  void _stop() {
    _audioPlayer.stop();
    setState(() {
      _playerState = PlayerState.stopped;
      _position = Duration();
    });
  }

  void _onComplete() {
    setState(() => _playerState = PlayerState.stopped);
  }
}
