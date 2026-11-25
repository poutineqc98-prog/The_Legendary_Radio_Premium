import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

enum ColorThemeMode {
  dynamicAlbum,
  fixedNeon,
  customColor,
}

class LegendaryThemeController extends ChangeNotifier {
  ColorThemeMode _mode = ColorThemeMode.dynamicAlbum;
  Color _primaryNeon = const Color(0xFFFF2E97); // Neon Pink from reference
  Color _secondaryNeon = const Color(0xFF00F0FF); // Neon Cyan from reference
  Color _accentPurple = const Color(0xFF8B5CF6); // Neon Purple
  Color _customBase = const Color(0xFFFF2E97);

  ColorThemeMode get mode => _mode;
  Color get primaryNeon => _primaryNeon;
  Color get secondaryNeon => _secondaryNeon;
  Color get accentPurple => _accentPurple;

  static const Color deepBlack = Color(0xFF07060C);
  static const Color surfaceDark = Color(0xFF110F1D);
  static const Color glassBorder = Color(0x33FFFFFF);

  void setMode(ColorThemeMode newMode) {
    _mode = newMode;
    if (_mode == ColorThemeMode.fixedNeon) {
      _primaryNeon = const Color(0xFFFF2E97);
      _secondaryNeon = const Color(0xFF00F0FF);
      _accentPurple = const Color(0xFF8B5CF6);
    } else if (_mode == ColorThemeMode.customColor) {
      _primaryNeon = _customBase;
      _secondaryNeon = HSLColor.fromColor(_customBase)
          .withHue((HSLColor.fromColor(_customBase).hue + 160) % 360)
          .toColor();
    }
    notifyListeners();
  }

  void setCustomColor(Color color) {
    _customBase = color;
    if (_mode == ColorThemeMode.customColor) {
      setMode(ColorThemeMode.customColor);
    }
  }

  Future<void> updateFromArtworkUrl(String? imageUrl) async {
    if (_mode != ColorThemeMode.dynamicAlbum || imageUrl == null || imageUrl.isEmpty) {
      return;
    }
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(120, 120),
        maximumColorCount: 12,
      );
      _primaryNeon = palette.vibrantColor?.color ??
          palette.lightVibrantColor?.color ??
          const Color(0xFFFF2E97);
      _secondaryNeon = palette.lightVibrantColor?.color ??
          palette.dominantColor?.color ??
          const Color(0xFF00F0FF);
      _accentPurple = palette.darkVibrantColor?.color ?? const Color(0xFF8B5CF6);
      notifyListeners();
    } catch (_) {
      // Retain current palette if artwork cannot be decoded
    }
  }
}
