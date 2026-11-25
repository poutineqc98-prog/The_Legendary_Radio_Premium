import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/radio_player_provider.dart';
import 'screens/albums_screen.dart';
import 'screens/artists_playlists_settings.dart';
import 'screens/player_screen.dart';
import 'services/audio_cast_service.dart';
import 'services/monsieur_chat_service.dart';
import 'services/plex_service.dart';
import 'theme/legendary_theme.dart';

late LegendaryAudioHandler _audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _audioHandler = await AudioService.init(
    builder: () => LegendaryAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.thelegendarycats.legendaryradio.audio',
      androidNotificationChannelName: 'The Legendary Radio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: false,
    ),
  );

  final plexService = PlexService();
  await plexService.loadCredentials();

  runApp(
    MultiProvider(
      providers: [
        Provider<PlexService>.value(value: plexService),
        ChangeNotifierProvider(create: (_) => LegendaryThemeController()),
        ChangeNotifierProvider(create: (_) => MonsieurChatService()),
        ChangeNotifierProvider(create: (_) => AudioCastService()),
        ChangeNotifierProvider(
          create: (ctx) => RadioPlayerProvider(
            plexService: plexService,
            monsieurChat: ctx.read<MonsieurChatService>(),
            castService: ctx.read<AudioCastService>(),
            themeController: ctx.read<LegendaryThemeController>(),
            audioHandler: _audioHandler,
          ),
        ),
      ],
      child: const TheLegendaryRadioApp(),
    ),
  );
}

class TheLegendaryRadioApp extends StatelessWidget {
  const TheLegendaryRadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<LegendaryThemeController>();
    return MaterialApp(
      title: 'The Legendary Radio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: LegendaryThemeController.deepBlack,
        colorScheme: ColorScheme.dark(
          primary: theme.primaryNeon,
          secondary: theme.secondaryNeon,
          surface: LegendaryThemeController.surfaceDark,
        ),
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 2; // Opens directly on LECTEUR as in mockup

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<LegendaryThemeController>();

    final screens = [
      ArtistsScreen(onSwitchToPlayer: () => setState(() => _selectedIndex = 2)),
      AlbumsScreen(onSwitchToPlayer: () => setState(() => _selectedIndex = 2)),
      PlayerScreen(onOpenSettings: _openSettings),
      PlaylistsScreen(onSwitchToPlayer: () => setState(() => _selectedIndex = 2)),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0812),
          border: Border(
            top: BorderSide(color: theme.primaryNeon.withOpacity(0.35), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (idx) => setState(() => _selectedIndex = idx),
          backgroundColor: const Color(0xFF0A0812),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: theme.primaryNeon,
          unselectedItemColor: Colors.white60,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Artistes'),
            BottomNavigationBarItem(icon: Icon(Icons.album_outlined), label: 'Albums'),
            BottomNavigationBarItem(icon: Icon(Icons.equalizer), label: 'Lecteur'),
            BottomNavigationBarItem(icon: Icon(Icons.queue_music), label: 'Playlists'),
          ],
        ),
      ),
    );
  }
}
