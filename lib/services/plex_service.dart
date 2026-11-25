import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/plex_models.dart';

class PlexService {
  static const _storage = FlutterSecureStorage();
  static const _keyServerUrl = 'plex_server_url';
  static const _keyToken = 'plex_auth_token';
  static const _keyMusicSectionId = 'plex_music_section_id';

  String? serverUrl;
  String? token;
  String? musicSectionId;

  bool get isConfigured =>
      serverUrl != null &&
      serverUrl!.isNotEmpty &&
      token != null &&
      token!.isNotEmpty;

  Future<void> loadCredentials() async {
    serverUrl = await _storage.read(key: _keyServerUrl);
    token = await _storage.read(key: _keyToken);
    musicSectionId = await _storage.read(key: _keyMusicSectionId);
  }

  Future<void> saveCredentials({
    required String url,
    required String authToken,
    String? sectionId,
  }) async {
    final cleanedUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    serverUrl = cleanedUrl;
    token = authToken.trim();
    await _storage.write(key: _keyServerUrl, value: serverUrl);
    await _storage.write(key: _keyToken, value: token);

    if (sectionId != null && sectionId.isNotEmpty) {
      musicSectionId = sectionId;
    } else {
      musicSectionId = await detectMusicLibrarySectionId();
    }
    if (musicSectionId != null) {
      await _storage.write(key: _keyMusicSectionId, value: musicSectionId);
    }
  }

  Map<String, String> get _headers => {
        'X-Plex-Token': token ?? '',
        'Accept': 'application/json',
        'X-Plex-Product': 'The Legendary Radio',
        'X-Plex-Version': '4.1.0',
        'X-Plex-Client-Identifier': 'the-legendary-radio-android-01',
      };

  String buildArtworkUrl(String? thumbPath, {int width = 500, int height = 500}) {
    if (thumbPath == null || thumbPath.isEmpty || !isConfigured) return '';
    if (thumbPath.startsWith('http')) return thumbPath;
    final encoded = Uri.encodeComponent(thumbPath);
    return '$serverUrl/photo/:/transcode?width=$width&height=$height&minSize=1&upscale=1&url=$encoded&X-Plex-Token=$token';
  }

  Future<String?> detectMusicLibrarySectionId() async {
    if (!isConfigured) return null;
    final uri = Uri.parse('$serverUrl/library/sections');
    final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) return null;
    final data = jsonDecode(resp.body);
    final dirs = data['MediaContainer']?['Directory'] as List<dynamic>? ?? [];
    for (final dir in dirs) {
      if (dir['type'] == 'artist') {
        return dir['key']?.toString();
      }
    }
    return null;
  }

  /// Fetches strictly Album Artists (Plex type=8) so compilation/featured track artists do not pollute the list
  Future<List<PlexArtist>> fetchAlbumArtists() async {
    if (!isConfigured) return [];
    final secId = musicSectionId ?? await detectMusicLibrarySectionId();
    if (secId == null) return [];

    final uri = Uri.parse('$serverUrl/library/sections/$secId/all?type=8');
    final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) {
      throw Exception('Erreur Plex (${resp.statusCode}) lors du chargement des artistes.');
    }

    final data = jsonDecode(resp.body);
    final metadata = data['MediaContainer']?['Metadata'] as List<dynamic>? ?? [];
    return metadata.map((item) {
      return PlexArtist(
        ratingKey: item['ratingKey'].toString(),
        title: (item['title'] ?? 'Artiste inconnu').toString(),
        thumbUrl: buildArtworkUrl(item['thumb']?.toString(), width: 400, height: 400),
        summary: item['summary']?.toString(),
        albumCount: int.tryParse(item['childCount']?.toString() ?? '0') ?? 0,
      );
    }).toList();
  }

  /// Fetches Albums (Plex type=9) grouped by Album Artist (`parentTitle`)
  Future<List<PlexAlbum>> fetchAlbums({String? artistRatingKey}) async {
    if (!isConfigured) return [];
    final secId = musicSectionId ?? await detectMusicLibrarySectionId();
    if (secId == null) return [];

    final endpoint = artistRatingKey != null
        ? '$serverUrl/library/metadata/$artistRatingKey/children'
        : '$serverUrl/library/sections/$secId/all?type=9';

    final resp = await http.get(Uri.parse(endpoint), headers: _headers).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw Exception('Erreur Plex (${resp.statusCode}) lors du chargement des albums.');
    }

    final data = jsonDecode(resp.body);
    final metadata = data['MediaContainer']?['Metadata'] as List<dynamic>? ?? [];
    return metadata.map((item) {
      return PlexAlbum(
        ratingKey: item['ratingKey'].toString(),
        title: (item['title'] ?? 'Album sans titre').toString(),
        artistName: (item['parentTitle'] ?? 'Artiste inconnu').toString(),
        year: int.tryParse(item['year']?.toString() ?? ''),
        thumbUrl: buildArtworkUrl(item['thumb']?.toString(), width: 600, height: 600),
      );
    }).toList();
  }

  Future<List<PlexTrack>> fetchAlbumTracks(String albumRatingKey) async {
    if (!isConfigured) return [];
    final uri = Uri.parse('$serverUrl/library/metadata/$albumRatingKey/children');
    final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return [];

    final data = jsonDecode(resp.body);
    final metadata = data['MediaContainer']?['Metadata'] as List<dynamic>? ?? [];
    return metadata.map((item) {
      final mediaList = item['Media'] as List<dynamic>? ?? [];
      final firstMedia = mediaList.isNotEmpty ? mediaList.first : null;
      final parts = firstMedia?['Part'] as List<dynamic>? ?? [];
      final partKey = parts.isNotEmpty ? parts.first['key']?.toString() : null;

      final streamUrl = partKey != null
          ? '$serverUrl$partKey?X-Plex-Token=$token'
          : '$serverUrl/library/metadata/${item['ratingKey']}?X-Plex-Token=$token';

      return PlexTrack(
        ratingKey: item['ratingKey'].toString(),
        title: (item['title'] ?? 'Piste').toString(),
        artistName: (item['grandparentTitle'] ?? item['originalTitle'] ?? 'Artiste').toString(),
        albumTitle: (item['parentTitle'] ?? 'Album').toString(),
        albumRatingKey: albumRatingKey,
        index: int.tryParse(item['index']?.toString() ?? '1') ?? 1,
        durationMs: int.tryParse(item['duration']?.toString() ?? '0') ?? 0,
        thumbUrl: buildArtworkUrl(item['thumb']?.toString() ?? item['parentThumb']?.toString()),
        streamUrl: streamUrl,
        codec: firstMedia?['audioCodec']?.toString(),
        bitrate: int.tryParse(firstMedia?['bitrate']?.toString() ?? ''),
      );
    }).toList();
  }

  Future<List<PlexPlaylist>> fetchPlaylists() async {
    if (!isConfigured) return [];
    final uri = Uri.parse('$serverUrl/playlists?playlistType=audio');
    final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return [];

    final data = jsonDecode(resp.body);
    final metadata = data['MediaContainer']?['Metadata'] as List<dynamic>? ?? [];
    return metadata.map((item) {
      return PlexPlaylist(
        ratingKey: item['ratingKey'].toString(),
        title: (item['title'] ?? 'Playlist').toString(),
        leafCount: int.tryParse(item['leafCount']?.toString() ?? '0') ?? 0,
        thumbUrl: buildArtworkUrl(item['composite']?.toString() ?? item['thumb']?.toString()),
      );
    }).toList();
  }

  Future<List<PlexTrack>> fetchPlaylistTracks(String playlistRatingKey) async {
    if (!isConfigured) return [];
    final uri = Uri.parse('$serverUrl/playlists/$playlistRatingKey/items');
    final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) return [];

    final data = jsonDecode(resp.body);
    final metadata = data['MediaContainer']?['Metadata'] as List<dynamic>? ?? [];
    return metadata.map((item) {
      final mediaList = item['Media'] as List<dynamic>? ?? [];
      final firstMedia = mediaList.isNotEmpty ? mediaList.first : null;
      final parts = firstMedia?['Part'] as List<dynamic>? ?? [];
      final partKey = parts.isNotEmpty ? parts.first['key']?.toString() : null;
      final streamUrl = partKey != null
          ? '$serverUrl$partKey?X-Plex-Token=$token'
          : '';

      return PlexTrack(
        ratingKey: item['ratingKey'].toString(),
        title: (item['title'] ?? 'Piste').toString(),
        artistName: (item['grandparentTitle'] ?? 'Artiste').toString(),
        albumTitle: (item['parentTitle'] ?? 'Album').toString(),
        albumRatingKey: (item['parentRatingKey'] ?? '').toString(),
        index: int.tryParse(item['index']?.toString() ?? '1') ?? 1,
        durationMs: int.tryParse(item['duration']?.toString() ?? '0') ?? 0,
        thumbUrl: buildArtworkUrl(item['thumb']?.toString() ?? item['parentThumb']?.toString()),
        streamUrl: streamUrl,
        codec: firstMedia?['audioCodec']?.toString(),
        bitrate: int.tryParse(firstMedia?['bitrate']?.toString() ?? ''),
      );
    }).toList();
  }
}
