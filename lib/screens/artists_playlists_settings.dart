import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plex_models.dart';
import '../providers/radio_player_provider.dart';
import '../services/audio_cast_service.dart';
import '../services/monsieur_chat_service.dart';
import '../services/plex_service.dart';
import '../theme/legendary_theme.dart';

/// 1. ARTISTES TAB — Strict Album Artist Grouping
class ArtistsScreen extends StatefulWidget {
  final VoidCallback onSwitchToPlayer;

  const ArtistsScreen({super.key, required this.onSwitchToPlayer});

  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  List<PlexArtist> _artists = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  Future<void> _loadArtists() async {
    setState(() => _loading = true);
    try {
      final list = await context.read<PlexService>().fetchAlbumArtists();
      if (mounted) {
        setState(() {
          _artists = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _playAllArtistAlbums(PlexArtist artist) async {
    final plex = context.read<PlexService>();
    final player = context.read<RadioPlayerProvider>();
    final albums = await plex.fetchAlbums(artistRatingKey: artist.ratingKey);
    final allTracks = <PlexTrack>[];
    for (final album in albums) {
      allTracks.addAll(await plex.fetchAlbumTracks(album.ratingKey));
    }
    if (allTracks.isNotEmpty) {
      await player.playTracks(allTracks, startIndex: 0);
      widget.onSwitchToPlayer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<LegendaryThemeController>();
    final filtered = _artists
        .where((a) => a.title.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                const Text(
                  'Artistes (Album Artist)',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadArtists,
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Filtrer les artistes de l’album...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF141122),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: theme.primaryNeon))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final artist = filtered[index];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF1E1933),
                          backgroundImage: artist.thumbUrl != null && artist.thumbUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(artist.thumbUrl!)
                              : null,
                          child: (artist.thumbUrl == null || artist.thumbUrl!.isEmpty)
                              ? const Icon(Icons.person, color: Colors.white60)
                              : null,
                        ),
                        title: Text(artist.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text('${artist.albumCount} album(s)',
                            style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        trailing: IconButton(
                          icon: Icon(Icons.play_circle_fill, color: theme.primaryNeon, size: 32),
                          tooltip: 'Lire toute la discographie',
                          onPressed: () => _playAllArtistAlbums(artist),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// 2. PLAYLISTS TAB — Direct Plex Audio Playlists
class PlaylistsScreen extends StatefulWidget {
  final VoidCallback onSwitchToPlayer;

  const PlaylistsScreen({super.key, required this.onSwitchToPlayer});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  List<PlexPlaylist> _playlists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() => _loading = true);
    try {
      final list = await context.read<PlexService>().fetchPlaylists();
      if (mounted) {
        setState(() {
          _playlists = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _playPlaylist(PlexPlaylist pl, {bool shuffle = false}) async {
    final plex = context.read<PlexService>();
    final player = context.read<RadioPlayerProvider>();
    final tracks = await plex.fetchPlaylistTracks(pl.ratingKey);
    if (tracks.isNotEmpty) {
      if (shuffle && !player.isShuffle) {
        player.toggleShuffle();
      }
      await player.playTracks(tracks, startIndex: 0);
      widget.onSwitchToPlayer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<LegendaryThemeController>();
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                const Text(
                  'Playlists Plex',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadPlaylists,
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: theme.primaryNeon))
                : ListView.builder(
                    itemCount: _playlists.length,
                    itemBuilder: (context, idx) {
                      final pl = _playlists[idx];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: pl.thumbUrl != null && pl.thumbUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: pl.thumbUrl!,
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 52,
                                  height: 52,
                                  color: const Color(0xFF1F1936),
                                  child: const Icon(Icons.queue_music, color: Colors.white60),
                                ),
                        ),
                        title: Text(pl.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text('${pl.leafCount} chansons',
                            style: const TextStyle(color: Colors.white60)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.shuffle, color: theme.secondaryNeon),
                              onPressed: () => _playPlaylist(pl, shuffle: true),
                            ),
                            IconButton(
                              icon: Icon(Icons.play_arrow, color: theme.primaryNeon, size: 30),
                              onPressed: () => _playPlaylist(pl),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// 3. COMPLETE SETTINGS PAGE
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _plexUrlController = TextEditingController();
  final _plexTokenController = TextEditingController();
  final _bluOsIpController = TextEditingController(text: '192.168.0.50');
  final _cityController = TextEditingController();
  bool _glyphEnabled = true;

  @override
  void initState() {
    super.initState();
    final plex = context.read<PlexService>();
    final dj = context.read<MonsieurChatService>();
    _plexUrlController.text = plex.serverUrl ?? 'http://192.168.0.11:32400';
    _plexTokenController.text = plex.token ?? '';
    _cityController.text = dj.city;
  }

  @override
  Widget build(BuildContext context) {
    final plex = context.watch<PlexService>();
    final dj = context.watch<MonsieurChatService>();
    final theme = context.watch<LegendaryThemeController>();
    final cast = context.watch<AudioCastService>();

    return Scaffold(
      backgroundColor: LegendaryThemeController.deepBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Réglages — The Legendary Radio'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('CONNEXION SERVEUR PLEX',
              style: TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _plexUrlController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Adresse du serveur Plex (ex: http://192.168.0.11:32400)',
              labelStyle: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _plexTokenController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Jeton X-Plex-Token (stocké de façon chiffrée)',
              labelStyle: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: theme.primaryNeon),
            onPressed: () async {
              await plex.saveCredentials(
                url: _plexUrlController.text,
                authToken: _plexTokenController.text,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Connexion Plex enregistrée et sécurisée !')),
                );
              }
            },
            icon: const Icon(Icons.lock_outline, color: Colors.white),
            label: const Text('Enregistrer la connexion Plex', style: TextStyle(color: Colors.white)),
          ),

          const Divider(height: 32, color: Colors.white24),
          const Text('MONSIEUR CHAT — ANIMATEUR VIRTUEL',
              style: TextStyle(color: Color(0xFFFF2E97), fontWeight: FontWeight.bold)),
          DropdownButtonFormField<DjLanguageMode>(
            value: dj.languageMode,
            dropdownColor: const Color(0xFF181429),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Langue'),
            items: const [
              DropdownMenuItem(
                  value: DjLanguageMode.frenchCanadian,
                  child: Text('Français canadien (Québec)')),
              DropdownMenuItem(
                  value: DjLanguageMode.englishCanadian,
                  child: Text('Anglais canadien')),
              DropdownMenuItem(
                  value: DjLanguageMode.bilingual,
                  child: Text('Mode bilingue FR / EN')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => dj.languageMode = v);
            },
          ),
          DropdownButtonFormField<DjInterventionFrequency>(
            value: dj.frequency,
            dropdownColor: const Color(0xFF181429),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Fréquence des interventions'),
            items: const [
              DropdownMenuItem(value: DjInterventionFrequency.off, child: Text('Désactivé')),
              DropdownMenuItem(value: DjInterventionFrequency.rare, child: Text('Rare (toutes les 6 pistes)')),
              DropdownMenuItem(
                  value: DjInterventionFrequency.occasional,
                  child: Text('Occasionnelle (toutes les 3 pistes)')),
              DropdownMenuItem(
                  value: DjInterventionFrequency.frequent,
                  child: Text('Fréquente (entre chaque chanson)')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => dj.frequency = v);
            },
          ),
          TextField(
            controller: _cityController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Ville pour la météo locale'),
            onChanged: (v) => dj.city = v,
          ),

          const Divider(height: 32, color: Colors.white24),
          const Text('APPARENCE & NOTHING PHONE GLYPH',
              style: TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold)),
          DropdownButtonFormField<ColorThemeMode>(
            value: theme.mode,
            dropdownColor: const Color(0xFF181429),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Thème de couleurs'),
            items: const [
              DropdownMenuItem(
                  value: ColorThemeMode.dynamicAlbum,
                  child: Text('Couleurs dynamiques selon la pochette')),
              DropdownMenuItem(
                  value: ColorThemeMode.fixedNeon,
                  child: Text('Néon fixe (Rose / Violet / Cyan)')),
              DropdownMenuItem(
                  value: ColorThemeMode.customColor,
                  child: Text('Couleur personnalisée')),
            ],
            onChanged: (v) {
              if (v != null) theme.setMode(v);
            },
          ),
          SwitchListTile(
            title: const Text('Effets lumineux Nothing Phone Glyph',
                style: TextStyle(color: Colors.white)),
            subtitle: const Text('Synchronisation avec les basses et la voix de Monsieur Chat',
                style: TextStyle(color: Colors.white60, fontSize: 12)),
            value: _glyphEnabled,
            activeColor: theme.primaryNeon,
            onChanged: (val) => setState(() => _glyphEnabled = val),
          ),

          const Divider(height: 32, color: Colors.white24),
          const Text('BLUESOUND NODE (« HOME CINÉMA »)',
              style: TextStyle(color: Color(0xFFFF2E97), fontWeight: FontWeight.bold)),
          TextField(
            controller: _bluOsIpController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Adresse IP locale du Bluesound NODE',
            ),
            onChanged: cast.updateBluOsIp,
          ),
        ],
      ),
    );
  }
}
