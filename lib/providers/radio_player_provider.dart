import 'dart:async';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import '../models/plex_models.dart';
import '../services/audio_cast_service.dart';
import '../services/monsieur_chat_service.dart';
import '../services/plex_service.dart';
import '../theme/legendary_theme.dart';

class LegendaryAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer player = AudioPlayer();

  LegendaryAudioHandler() {
    player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      playing: player.playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: event.currentIndex,
    );
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }
}

class RadioPlayerProvider extends ChangeNotifier {
  static const _spectrumEventChannel = EventChannel('com.thelegendarycats.legendaryradio/spectrum');

  final PlexService plexService;
  final MonsieurChatService monsieurChat;
  final AudioCastService castService;
  final LegendaryThemeController themeController;
  final LegendaryAudioHandler audioHandler;

  List<PlexTrack> _queue = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.off;
  bool _cdJewelCaseMode = true; // true = Boîtier CD, false = Disque en rotation seul
  final Set<String> _favoriteTrackIds = {};

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  List<double> _spectrumBands = List.filled(18, 0.12);
  StreamSubscription? _spectrumSub;

  RadioPlayerProvider({
    required this.plexService,
    required this.monsieurChat,
    required this.castService,
    required this.themeController,
    required this.audioHandler,
  }) {
    _bindPlayerListeners();
    _bindHardwareSpectrum();
  }

  List<PlexTrack> get queue => _queue;
  PlexTrack? get currentTrack =>
      (_queue.isNotEmpty && _currentIndex >= 0 && _currentIndex < _queue.length)
          ? _queue[_currentIndex]
          : null;
  bool get isPlaying => _isPlaying;
  bool get isShuffle => _isShuffle;
  LoopMode get loopMode => _loopMode;
  bool get cdJewelCaseMode => _cdJewelCaseMode;
  Duration get position => _position;
  Duration get duration => _duration;
  List<double> get spectrumBands => _spectrumBands;

  bool isFavorite(String? ratingKey) =>
      ratingKey != null && _favoriteTrackIds.contains(ratingKey);

  void toggleFavorite(String? ratingKey) {
    if (ratingKey == null) return;
    if (_favoriteTrackIds.contains(ratingKey)) {
      _favoriteTrackIds.remove(ratingKey);
    } else {
      _favoriteTrackIds.add(ratingKey);
    }
    notifyListeners();
  }

  void setCdDisplayMode(bool jewelCase) {
    _cdJewelCaseMode = jewelCase;
    notifyListeners();
  }

  void _bindPlayerListeners() {
    final p = audioHandler.player;

    p.playingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    p.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    p.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });

    p.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        await handleTrackCompleted();
      }
    });
  }

  void _bindHardwareSpectrum() {
    _spectrumSub = _spectrumEventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is List && _isPlaying) {
          _spectrumBands = event.map((e) => (e as num).toDouble()).toList();
          notifyListeners();
        }
      },
      onError: (_) {},
    );
  }

  Future<void> playTracks(List<PlexTrack> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;
    _queue = List.of(tracks);
    _currentIndex = startIndex.clamp(0, _queue.length - 1);
    await _loadAndPlayCurrent();
  }

  Future<void> _loadAndPlayCurrent() async {
    final track = currentTrack;
    if (track == null) return;

    themeController.updateFromArtworkUrl(track.thumbUrl);

    audioHandler.mediaItem.add(
      MediaItem(
        id: track.ratingKey,
        album: track.albumTitle,
        title: track.title,
        artist: track.artistName,
        duration: Duration(milliseconds: track.durationMs),
        artUri: track.thumbUrl != null && track.thumbUrl!.isNotEmpty
            ? Uri.parse(track.thumbUrl!)
            : null,
      ),
    );

    if (castService.selectedTarget.protocol == OutputProtocol.bluOS &&
        castService.selectedTarget.ipAddress != null) {
      await castService.sendStreamToBluOS(
        castService.selectedTarget.ipAddress!,
        castService.selectedTarget.port ?? 11000,
        track.streamUrl,
      );
    }

    await audioHandler.player.setUrl(track.streamUrl);
    await audioHandler.play();
    notifyListeners();
  }

  Future<void> handleTrackCompleted() async {
    if (_loopMode == LoopMode.one) {
      await audioHandler.seek(Duration.zero);
      await audioHandler.play();
      return;
    }

    final finishedTrack = currentTrack;
    int nextIdx;
    if (_isShuffle && _queue.length > 1) {
      nextIdx = Random().nextInt(_queue.length);
    } else {
      nextIdx = _currentIndex + 1;
    }

    if (nextIdx >= _queue.length) {
      if (_loopMode == LoopMode.all) {
        nextIdx = 0;
      } else {
        _isPlaying = false;
        notifyListeners();
        return;
      }
    }

    _currentIndex = nextIdx;
    final upcomingTrack = currentTrack;

    // Monsieur Chat speaks naturally between songs without cutting music mid-track
    if (upcomingTrack != null) {
      await monsieurChat.speakBetweenTracks(
        previousTrack: finishedTrack,
        nextTrack: upcomingTrack,
      );
    }

    await _loadAndPlayCurrent();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await audioHandler.pause();
    } else {
      await audioHandler.play();
    }
  }

  Future<void> skipNext() async {
    if (_queue.isEmpty) return;
    final prev = currentTrack;
    _currentIndex = _isShuffle
        ? Random().nextInt(_queue.length)
        : (_currentIndex + 1) % _queue.length;
    final next = currentTrack;
    if (next != null) {
      await monsieurChat.speakBetweenTracks(previousTrack: prev, nextTrack: next);
    }
    await _loadAndPlayCurrent();
  }

  Future<void> skipPrevious() async {
    if (_queue.isEmpty) return;
    if (_position.inSeconds > 4) {
      await audioHandler.seek(Duration.zero);
      return;
    }
    _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    await _loadAndPlayCurrent();
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void cycleLoopMode() {
    _loopMode = switch (_loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    notifyListeners();
  }

  Future<void> seekTo(Duration target) => audioHandler.seek(target);

  @override
  void dispose() {
    _spectrumSub?.cancel();
    super.dispose();
  }
}
