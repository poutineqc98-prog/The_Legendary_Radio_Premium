import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/plex_models.dart';

enum DjLanguageMode {
  frenchCanadian,
  englishCanadian,
  bilingual,
}

enum DjInterventionFrequency {
  off,
  rare,       // Every 6 tracks
  occasional, // Every 3 tracks (Default preferred)
  frequent,   // Every track
}

class MonsieurChatService extends ChangeNotifier {
  static const _nativeChannel = MethodChannel('com.thelegendarycats.legendaryradio/native');
  final FlutterTts _localTts = FlutterTts();

  DjLanguageMode languageMode = DjLanguageMode.frenchCanadian;
  DjInterventionFrequency frequency = DjInterventionFrequency.occasional;
  String city = 'Saint-Charles-sur-Richelieu';
  bool enableWeather = true;
  bool enableNews = true;
  bool enableTrivia = true;
  bool enableJingle = true;

  String? azureSpeechKey;
  String? azureSpeechRegion;

  bool _isOnAir = false;
  String _currentScript = 'Prêt en studio sur The Legendary Radio.';
  int _tracksSinceLastSpeech = 0;

  bool get isOnAir => _isOnAir;
  String get currentScript => _currentScript;

  MonsieurChatService() {
    _initLocalTts();
  }

  Future<void> _initLocalTts() async {
    await _localTts.setSpeechRate(0.50);
    await _localTts.setPitch(0.95);
    _localTts.setCompletionHandler(() {
      _setOnAir(false);
    });
  }

  void _setOnAir(bool active) {
    _isOnAir = active;
    _nativeChannel.invokeMethod('pulseGlyphForDj', {'active': active}).catchError((_) {});
    notifyListeners();
  }

  bool shouldInterveneNow() {
    if (frequency == DjInterventionFrequency.off) return false;
    _tracksSinceLastSpeech++;
    final threshold = switch (frequency) {
      DjInterventionFrequency.off => 999,
      DjInterventionFrequency.rare => 6,
      DjInterventionFrequency.occasional => 3,
      DjInterventionFrequency.frequent => 1,
    };
    if (_tracksSinceLastSpeech >= threshold) {
      _tracksSinceLastSpeech = 0;
      return true;
    }
    return false;
  }

  Future<String> _fetchLiveWeatherSummary(bool isFrench) async {
    try {
      final encodedCity = Uri.encodeComponent(city);
      final geoUri = Uri.parse('https://geocoding-api.open-meteo.com/v1/search?name=$encodedCity&count=1&language=fr');
      final geoResp = await http.get(geoUri).timeout(const Duration(seconds: 4));
      if (geoResp.statusCode == 200) {
        final geoData = jsonDecode(geoResp.body);
        final results = geoData['results'] as List<dynamic>? ?? [];
        if (results.isNotEmpty) {
          final lat = results.first['latitude'];
          final lon = results.first['longitude'];
          final weatherUri = Uri.parse(
              'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true');
          final wResp = await http.get(weatherUri).timeout(const Duration(seconds: 4));
          if (wResp.statusCode == 200) {
            final wData = jsonDecode(wResp.body);
            final temp = wData['current_weather']?['temperature'];
            if (temp != null) {
              return isFrench
                  ? 'Côté météo à $city, il fait présentement $temp degrés Celsius.'
                  : 'Checking the weather in $city, it is currently $temp degrees Celsius.';
            }
          }
        }
      }
    } catch (_) {}
    return '';
  }

  Future<void> speakBetweenTracks({
    PlexTrack? previousTrack,
    required PlexTrack nextTrack,
    bool force = false,
  }) async {
    if (!force && !shouldInterveneNow()) return;

    final now = DateTime.now();
    final timeFr = DateFormat('H 'heures' mm').format(now);
    final timeEn = DateFormat('h:mm a').format(now);

    final useFrench = switch (languageMode) {
      DjLanguageMode.frenchCanadian => true,
      DjLanguageMode.englishCanadian => false,
      DjLanguageMode.bilingual => Random().nextBool(),
    };

    final weatherLine = enableWeather ? await _fetchLiveWeatherSummary(useFrench) : '';

    final String script;
    if (useFrench) {
      final prevIntro = previousTrack != null
          ? 'Vous venez d’entendre « ${previousTrack.title} » de ${previousTrack.artistName}. '
          : '';
      script =
          'Ici Monsieur Chat en direct dans le studio de The Legendary Radio ! $prevIntro'
          'Il est $timeFr. $weatherLine '
          'On poursuit tout de suite votre session hi-fi avec « ${nextTrack.title} », tiré de l’album ${nextTrack.albumTitle} par ${nextTrack.artistName}. Bonne écoute !';
    } else {
      final prevIntro = previousTrack != null
          ? 'That was "${previousTrack.title}" by ${previousTrack.artistName}. '
          : '';
      script =
          'You are tuned in to The Legendary Radio with Monsieur Chat! $prevIntro'
          'The time is $timeEn. $weatherLine '
          'Coming up next from the album ${nextTrack.albumTitle}, here is "${nextTrack.title}" by ${nextTrack.artistName}.';
    }

    _currentScript = script;
    _setOnAir(true);

    try {
      await _localTts.setLanguage(useFrench ? 'fr-CA' : 'en-CA');
      await _localTts.speak(script);
    } catch (_) {
      _setOnAir(false);
    }
  }

  Future<void> stopSpeaking() async {
    await _localTts.stop();
    _setOnAir(false);
  }
}
