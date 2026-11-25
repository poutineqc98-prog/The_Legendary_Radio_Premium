import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/plex_models.dart';

class AudioCastService extends ChangeNotifier {
  static const _nativeChannel = MethodChannel('com.thelegendarycats.legendaryradio/native');

  List<AudioOutputTarget> _targets = [
    const AudioOutputTarget(
      id: 'local_phone',
      name: 'Nothing Phone (Haut-parleur / Casque)',
      protocol: OutputProtocol.localDevice,
      isSupportedOnAndroid: true,
    ),
    const AudioOutputTarget(
      id: 'bluos_home_cinema',
      name: 'Home Cinéma (Bluesound NODE — BluOS)',
      protocol: OutputProtocol.bluOS,
      ipAddress: '192.168.0.50',
      port: 11000,
      isSupportedOnAndroid: true,
      note: 'Diffusion directe haute résolution via API locale BluOS (port 11000)',
    ),
    const AudioOutputTarget(
      id: 'google_cast',
      name: 'Google Cast / Chromecast',
      protocol: OutputProtocol.googleCast,
      isSupportedOnAndroid: true,
      note: 'Sélecteur Google Cast Android natif',
    ),
    const AudioOutputTarget(
      id: 'sonos_upnp',
      name: 'Enceintes Sonos (UPnP / Cast)',
      protocol: OutputProtocol.sonos,
      isSupportedOnAndroid: true,
    ),
    const AudioOutputTarget(
      id: 'alexa_bt',
      name: 'Amazon Alexa / Echo Show (Bluetooth / Cast)',
      protocol: OutputProtocol.alexa,
      isSupportedOnAndroid: true,
      note: 'Via profil Bluetooth A2DP ou passerelle audio locale',
    ),
    const AudioOutputTarget(
      id: 'airplay_raop',
      name: 'Appareils AirPlay (RAOP)',
      protocol: OutputProtocol.airPlay,
      isSupportedOnAndroid: false,
      note: 'AirPlay est propriétaire Apple ; nécessite un pont RAOP sur le réseau local',
    ),
  ];

  AudioOutputTarget _selectedTarget;

  AudioCastService() : _selectedTarget = _defaultTarget();

  static AudioOutputTarget _defaultTarget() => const AudioOutputTarget(
        id: 'local_phone',
        name: 'Nothing Phone (Haut-parleur / Casque)',
        protocol: OutputProtocol.localDevice,
      );

  List<AudioOutputTarget> get targets => _targets;
  AudioOutputTarget get selectedTarget => _selectedTarget;

  void updateBluOsIp(String ip) {
    _targets = _targets.map((t) {
      if (t.protocol == OutputProtocol.bluOS) {
        return AudioOutputTarget(
          id: t.id,
          name: t.name,
          protocol: OutputProtocol.bluOS,
          ipAddress: ip.trim(),
          port: 11000,
          isSupportedOnAndroid: true,
          note: 'Bluesound NODE IP: ${ip.trim()}:11000',
        );
      }
      return t;
    }).toList();
    notifyListeners();
  }

  Future<void> refreshSystemAudioDevices() async {
    try {
      final raw = await _nativeChannel.invokeMethod<List<dynamic>>('getAudioOutputDevices');
      if (raw != null) {
        final systemTargets = raw.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return AudioOutputTarget(
            id: map['id'].toString(),
            name: map['name'].toString(),
            protocol: map['type'] == 'builtin'
                ? OutputProtocol.localDevice
                : OutputProtocol.bluetooth,
          );
        }).toList();

        final networkTargets = _targets
            .where((t) =>
                t.protocol != OutputProtocol.localDevice &&
                t.protocol != OutputProtocol.bluetooth)
            .toList();

        _targets = [...systemTargets, ...networkTargets];
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> selectTarget(AudioOutputTarget target, {String? activeStreamUrl}) async {
    _selectedTarget = target;
    notifyListeners();

    if (target.protocol == OutputProtocol.bluOS &&
        target.ipAddress != null &&
        activeStreamUrl != null &&
        activeStreamUrl.isNotEmpty) {
      await sendStreamToBluOS(target.ipAddress!, target.port ?? 11000, activeStreamUrl);
    }
  }

  /// Sends direct Plex audio stream URL to Bluesound NODE ("Home Cinéma") via BluOS Custom Integration API
  Future<bool> sendStreamToBluOS(String ip, int port, String streamUrl) async {
    try {
      final encodedUrl = Uri.encodeComponent(streamUrl);
      final bluOsUri = Uri.parse('http://$ip:$port/Play?url=$encodedUrl');
      final resp = await http.get(bluOsUri).timeout(const Duration(seconds: 5));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
