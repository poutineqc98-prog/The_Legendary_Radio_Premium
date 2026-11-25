import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plex_models.dart';
import '../providers/radio_player_provider.dart';
import '../services/plex_service.dart';
import '../theme/legendary_theme.dart';
import '../widgets/cd_boombox_widgets.dart';

enum AlbumLibraryViewMode {
  cdShelf,
  coverFlow,
  gridList,
}

class AlbumsScreen extends StatefulWidget {
  final VoidCallback onSwitchToPlayer;

  const AlbumsScreen({super.key, required this.onSwitchToPlayer});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  AlbumLibraryViewMode _viewMode = AlbumLibraryViewMode.cdShelf;
  List<PlexAlbum> _albums = [];
  String _searchQuery = '';
  bool _loading = true;
  late PageController _coverFlowController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _coverFlowController = PageController(viewportFraction: 0.56);
    _coverFlowController.addListener(() {
      setState(() {
        _currentPage = _coverFlowController.page ?? 0.0;
      });
    });
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    setState(() => _loading = true);
    try {
      final plex = context.read<PlexService>();
      final fetched = await plex.fetchAlbums();
      if (mounted) {
        setState(() {
          _albums = fetched;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openAndPlayAlbum(PlexAlbum album) async {
    final plex = context.read<PlexService>();
    final player = context.read<RadioPlayerProvider>();
    final tracks = await plex.fetchAlbumTracks(album.ratingKey);
    if (tracks.isNotEmpty) {
      await player.playTracks(tracks, startIndex: 0);
      widget.onSwitchToPlayer();
    }
  }

  @override
  void dispose() {
    _coverFlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<LegendaryThemeController>();
    final filtered = _albums.where((a) {
      final q = _searchQuery.toLowerCase();
      return a.title.toLowerCase().contains(q) || a.artistName.toLowerCase().contains(q);
    }).toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                CatPawDjLogo(size: 38, primaryNeon: theme.primaryNeon, secondaryNeon: theme.secondaryNeon),
                const SizedBox(width: 10),
                const Text(
                  '💿 Bibliothèque CD',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadAlbums,
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Rechercher un album ou un artiste',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF141122),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: theme.primaryNeon),
                ),
              ),
            ),
          ),

          // View Mode Tabs: Étagère CD | Cover Flow | Liste
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _ModeTab(
                  label: 'Étagère CD',
                  selected: _viewMode == AlbumLibraryViewMode.cdShelf,
                  neon: theme.primaryNeon,
                  onTap: () => setState(() => _viewMode = AlbumLibraryViewMode.cdShelf),
                ),
                const SizedBox(width: 8),
                _ModeTab(
                  label: 'Cover Flow',
                  selected: _viewMode == AlbumLibraryViewMode.coverFlow,
                  neon: theme.primaryNeon,
                  onTap: () => setState(() => _viewMode = AlbumLibraryViewMode.coverFlow),
                ),
                const SizedBox(width: 8),
                _ModeTab(
                  label: 'Liste',
                  selected: _viewMode == AlbumLibraryViewMode.gridList,
                  neon: theme.primaryNeon,
                  onTap: () => setState(() => _viewMode = AlbumLibraryViewMode.gridList),
                ),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: theme.primaryNeon))
                : filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun album Plex trouvé.
Vérifie la connexion dans Réglages.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60),
                        ),
                      )
                    : switch (_viewMode) {
                        AlbumLibraryViewMode.cdShelf => _buildCdWoodenShelves(filtered, theme),
                        AlbumLibraryViewMode.coverFlow => _build3dCoverFlow(filtered, theme),
                        AlbumLibraryViewMode.gridList => _buildGridList(filtered, theme),
                      },
          ),
        ],
      ),
    );
  }

  /// Physical Illuminated Wooden CD Shelves with Vertical Spines & Front-Facing Showcase Cases
  Widget _buildCdWoodenShelves(List<PlexAlbum> albums, LegendaryThemeController theme) {
    const int perShelf = 14;
    final shelfCount = (albums.length / perShelf).ceil();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: shelfCount,
      itemBuilder: (context, shelfIndex) {
        final start = shelfIndex * perShelf;
        final end = math.min(start + perShelf, albums.length);
        final shelfAlbums = albums.sublist(start, end);

        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF150D09),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF5A3722), width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black87, blurRadius: 12, offset: Offset(0, 6)),
            ],
          ),
          child: Column(
            children: [
              // Warm Top Shelf Spotlights
              Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 4.5,
                    colors: [Colors.amber.withOpacity(0.55), Colors.transparent],
                  ),
                ),
              ),
              SizedBox(
                height: 158,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  itemCount: shelfAlbums.length,
                  itemBuilder: (context, idx) {
                    final album = shelfAlbums[idx];
                    final isFaceOut = idx == 0 || idx == shelfAlbums.length - 1;
                    if (isFaceOut) {
                      return GestureDetector(
                        onTap: () => _openAndPlayAlbum(album),
                        child: Container(
                          width: 132,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white54, width: 1.2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: album.thumbUrl != null && album.thumbUrl!.isNotEmpty
                                ? CachedNetworkImage(imageUrl: album.thumbUrl!, fit: BoxFit.cover)
                                : Container(color: const Color(0xFF221B35)),
                          ),
                        ),
                      );
                    }
                    // Vertical CD Jewel Case Spine
                    return GestureDetector(
                      onTap: () => _openAndPlayAlbum(album),
                      child: Container(
                        width: 24,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                        decoration: BoxDecoration(
                          color: Colors.primaries[album.title.hashCode % Colors.primaries.length]
                              .shade900,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: Colors.white38, width: 0.8),
                        ),
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            '${album.artistName} — ${album.title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Wooden Plank Base
              Container(
                height: 10,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3E2415), Color(0xFF6B4229), Color(0xFF3E2415)],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// iPod-inspired 3D Cover Flow with Perspective & Floor Reflections
  Widget _build3dCoverFlow(List<PlexAlbum> albums, LegendaryThemeController theme) {
    final activeIndex = _currentPage.round().clamp(0, albums.length - 1);
    final activeAlbum = albums[activeIndex];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 290,
          child: PageView.builder(
            controller: _coverFlowController,
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              final delta = index - _currentPage;
              final angleY = delta.clamp(-1.0, 1.0) * 0.75;
              final scale = (1.0 - (delta.abs() * 0.18)).clamp(0.75, 1.0);

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0018)
                  ..rotateY(angleY)
                  ..scale(scale),
                child: GestureDetector(
                  onTap: () => _openAndPlayAlbum(album),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 205,
                        height: 205,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: delta.abs() < 0.3 ? theme.primaryNeon : Colors.white38,
                            width: 1.8,
                          ),
                          boxShadow: [
                            if (delta.abs() < 0.3)
                              BoxShadow(color: theme.primaryNeon.withOpacity(0.5), blurRadius: 22),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: album.thumbUrl != null && album.thumbUrl!.isNotEmpty
                              ? CachedNetworkImage(imageUrl: album.thumbUrl!, fit: BoxFit.cover)
                              : Container(color: const Color(0xFF1D1830)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Mirror Floor Reflection
                      Opacity(
                        opacity: 0.22,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.diagonal3Values(1, -0.32, 1),
                          child: SizedBox(
                            width: 205,
                            height: 60,
                            child: album.thumbUrl != null && album.thumbUrl!.isNotEmpty
                                ? CachedNetworkImage(imageUrl: album.thumbUrl!, fit: BoxFit.cover)
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          activeAlbum.title,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          '${activeAlbum.artistName}${activeAlbum.year != null ? ' (${activeAlbum.year})' : ''}',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildGridList(List<PlexAlbum> albums, LegendaryThemeController theme) {
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.76,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: albums.length,
      itemBuilder: (context, idx) {
        final album = albums[idx];
        return GestureDetector(
          onTap: () => _openAndPlayAlbum(album),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF12101E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    child: album.thumbUrl != null && album.thumbUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: album.thumbUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(color: const Color(0xFF1E1A30)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        '${album.artistName}${album.year != null ? ' • ${album.year}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final Color neon;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.selected,
    required this.neon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? neon.withOpacity(0.28) : const Color(0xFF141122),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? neon : Colors.white24, width: 1.4),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
