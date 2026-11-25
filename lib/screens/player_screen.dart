import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../providers/radio_player_provider.dart';
import '../services/audio_cast_service.dart';
import '../services/monsieur_chat_service.dart';
import '../theme/legendary_theme.dart';
import '../widgets/cd_boombox_widgets.dart';

class PlayerScreen extends StatelessWidget {
  final VoidCallback onOpenSettings;

  const PlayerScreen({super.key, required this.onOpenSettings});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showCastBottomSheet(BuildContext context) {
    final castService = context.read<AudioCastService>();
    final player = context.read<RadioPlayerProvider>();
    castService.refreshSystemAudioDevices();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF120F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return Consumer<AudioCastService>(
          builder: (context, cast, _) {
            return Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DIFFUSER VERS UN APPAREIL AUDIO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...cast.targets.map((target) {
                    final selected = cast.selectedTarget.id == target.id;
                    return ListTile(
                      leading: Icon(
                        target.protocol == OutputProtocol.bluOS
                            ? Icons.speaker_group
                            : target.protocol == OutputProtocol.googleCast
                                ? Icons.cast
                                : Icons.bluetooth_audio,
                        color: selected ? const Color(0xFF00F0FF) : Colors.white70,
                      ),
                      title: Text(
                        target.name,
                        style: TextStyle(
                          color: selected ? const Color(0xFF00F0FF) : Colors.white,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: target.note != null
                          ? Text(target.note!, style: const TextStyle(color: Colors.white54, fontSize: 11))
                          : null,
                      trailing: selected
                          ? const Icon(Icons.check_circle, color: Color(0xFFFF2E97))
                          : null,
                      onTap: () {
                        cast.selectTarget(
                          target,
                          activeStreamUrl: player.currentTrack?.streamUrl,
                        );
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<LegendaryThemeController>();
    final player = context.watch<RadioPlayerProvider>();
    final dj = context.watch<MonsieurChatService>();
    final track = player.currentTrack;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // Top Brand Header matching 8243.png
            Row(
              children: [
                CatPawDjLogo(
                  size: 46,
                  primaryNeon: theme.primaryNeon,
                  secondaryNeon: theme.secondaryNeon,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THE LEGENDARY RADIO',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        'LA RADIO DE TA COLLECTION CD',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (track != null) {
                      dj.speakBetweenTracks(nextTrack: track, force: true);
                    }
                  },
                  icon: Icon(Icons.mic, color: dj.isOnAir ? theme.primaryNeon : Colors.white),
                  tooltip: 'Faire parler Monsieur Chat',
                ),
                IconButton(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  tooltip: 'Réglages',
                ),
              ],
            ),

            const SizedBox(height: 10),

            // "EN ONDES" + Monsieur Chat Studio Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1A112B),
                    theme.primaryNeon.withOpacity(0.24),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.primaryNeon.withOpacity(0.75), width: 1.4),
                boxShadow: [
                  BoxShadow(color: theme.primaryNeon.withOpacity(0.25), blurRadius: 14),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2B0B1E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.primaryNeon),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle, size: 8, color: theme.primaryNeon),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'EN ONDES',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'En ondes avec Monsieur Chat 🐾',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dj.currentScript,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.primaryNeon.withOpacity(0.3),
                    child: const Text('🐱🎧', style: TextStyle(fontSize: 22)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Mode Switcher: "Boîtier CD" vs "Disque en rotation"
            Row(
              children: [
                Expanded(
                  child: _NeonPillToggle(
                    label: 'Boîtier CD',
                    icon: Icons.album_outlined,
                    active: player.cdJewelCaseMode,
                    neonColor: theme.primaryNeon,
                    onTap: () => player.setCdDisplayMode(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NeonPillToggle(
                    label: 'Disque en rotation',
                    icon: Icons.sync,
                    active: !player.cdJewelCaseMode,
                    neonColor: theme.primaryNeon,
                    onTap: () => player.setCdDisplayMode(false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Central CD Jewel Case / Spinning Compact Disc
            CdJewelCasePlayer(
              track: track,
              isPlaying: player.isPlaying,
              jewelCaseMode: player.cdJewelCaseMode,
              primaryNeon: theme.primaryNeon,
              secondaryNeon: theme.secondaryNeon,
            ),

            const SizedBox(height: 12),

            // Track Metadata + Favorite + Cast Output
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track?.title ?? 'Sélectionne un album Plex',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        track != null
                            ? '${track.artistName} • ${track.albumTitle}'
                            : 'Connecte ton serveur Plex dans Réglages',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => player.toggleFavorite(track?.ratingKey),
                  icon: Icon(
                    player.isFavorite(track?.ratingKey)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: theme.primaryNeon,
                  ),
                ),
                IconButton(
                  onPressed: () => _showCastBottomSheet(context),
                  icon: Icon(Icons.cast_connected, color: theme.secondaryNeon),
                  tooltip: 'Diffuser (Home Cinéma, Cast, Bluetooth)',
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Boombox & Real-Time Audio Spectrum
            BoomboxVisualizerDeck(
              spectrumBands: player.spectrumBands,
              isPlaying: player.isPlaying,
              primaryNeon: theme.primaryNeon,
              secondaryNeon: theme.secondaryNeon,
            ),

            const SizedBox(height: 10),

            // Interactive Scrubber + Elapsed/Remaining Time
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: theme.primaryNeon,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                trackHeight: 3.5,
              ),
              child: Slider(
                value: player.duration.inMilliseconds > 0
                    ? player.position.inMilliseconds
                        .clamp(0, player.duration.inMilliseconds)
                        .toDouble()
                    : 0,
                max: player.duration.inMilliseconds > 0
                    ? player.duration.inMilliseconds.toDouble()
                    : 1,
                onChanged: (val) => player.seekTo(Duration(milliseconds: val.toInt())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(player.position),
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(_formatDuration(player.duration),
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Transport Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: player.toggleShuffle,
                  icon: Icon(
                    Icons.shuffle,
                    color: player.isShuffle ? theme.primaryNeon : Colors.white60,
                  ),
                ),
                IconButton(
                  onPressed: player.skipPrevious,
                  iconSize: 32,
                  icon: const Icon(Icons.skip_previous, color: Colors.white),
                ),
                GestureDetector(
                  onTap: player.togglePlayPause,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.primaryNeon.withOpacity(0.25),
                      border: Border.all(color: theme.primaryNeon, width: 2.5),
                      boxShadow: [
                        BoxShadow(color: theme.primaryNeon.withOpacity(0.55), blurRadius: 18),
                      ],
                    ),
                    child: Icon(
                      player.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: player.skipNext,
                  iconSize: 32,
                  icon: const Icon(Icons.skip_next, color: Colors.white),
                ),
                IconButton(
                  onPressed: player.cycleLoopMode,
                  icon: Icon(
                    player.loopMode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                    color: player.loopMode != LoopMode.off ? theme.secondaryNeon : Colors.white60,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NeonPillToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color neonColor;
  final VoidCallback onTap;

  const _NeonPillToggle({
    required this.label,
    required this.icon,
    required this.active,
    required this.neonColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        decoration: BoxDecoration(
          color: active ? neonColor.withOpacity(0.25) : const Color(0xFF141122),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active ? neonColor : Colors.white24,
            width: 1.5,
          ),
          boxShadow: active
              ? [BoxShadow(color: neonColor.withOpacity(0.35), blurRadius: 12)]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
