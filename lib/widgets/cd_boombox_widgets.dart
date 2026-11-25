import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/plex_models.dart';

/// Custom Painter for the signature Cat Paw DJ Icon (Pink/Cyan Neon)
class CatPawDjLogo extends StatelessWidget {
  final double size;
  final Color primaryNeon;
  final Color secondaryNeon;

  const CatPawDjLogo({
    super.key,
    this.size = 44,
    this.primaryNeon = const Color(0xFFFF2E97),
    this.secondaryNeon = const Color(0xFF00F0FF),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0B0814),
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(color: primaryNeon, width: 1.8),
        boxShadow: [
          BoxShadow(color: primaryNeon.withOpacity(0.5), blurRadius: 12),
          BoxShadow(color: secondaryNeon.withOpacity(0.25), blurRadius: 18),
        ],
      ),
      child: CustomPaint(
        painter: _CatPawDjPainter(
          primaryNeon: primaryNeon,
          secondaryNeon: secondaryNeon,
        ),
      ),
    );
  }
}

class _CatPawDjPainter extends CustomPainter {
  final Color primaryNeon;
  final Color secondaryNeon;

  _CatPawDjPainter({required this.primaryNeon, required this.secondaryNeon});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final wavePaint = Paint()
      ..color = secondaryNeon
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;

    // Radio waves at top
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.25), width: w * 0.52, height: h * 0.25),
      math.pi * 1.15,
      math.pi * 0.7,
      false,
      wavePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.29), width: w * 0.32, height: h * 0.16),
      math.pi * 1.15,
      math.pi * 0.7,
      false,
      wavePaint,
    );

    final toePaint = Paint()..color = primaryNeon;
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.23, h * 0.49), width: w * 0.14, height: h * 0.19), toePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.41, h * 0.37), width: w * 0.15, height: h * 0.21), toePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.59, h * 0.37), width: w * 0.15, height: h * 0.21), toePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.77, h * 0.49), width: w * 0.14, height: h * 0.19), toePaint);

    // Main pad as vinyl disc
    final center = Offset(w * 0.5, h * 0.72);
    canvas.drawOval(Rect.fromCenter(center: center, width: w * 0.46, height: h * 0.38), toePaint);
    canvas.drawCircle(center, w * 0.17, Paint()..color = const Color(0xFF131528));
    canvas.drawCircle(center, w * 0.06, Paint()..color = secondaryNeon);
    canvas.drawCircle(center, w * 0.02, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(covariant _CatPawDjPainter oldDelegate) =>
      oldDelegate.primaryNeon != primaryNeon || oldDelegate.secondaryNeon != secondaryNeon;
}

/// Realistic Compact Disc with Album Artwork Printed on Surface, Iridescent Reflections, and Smooth Rotation
class RealisticCompactDisc extends StatefulWidget {
  final String? artworkUrl;
  final bool isPlaying;
  final double diameter;
  final Color glowColor;

  const RealisticCompactDisc({
    super.key,
    required this.artworkUrl,
    required this.isPlaying,
    this.diameter = 215,
    this.glowColor = const Color(0xFFFF2E97),
  });

  @override
  State<RealisticCompactDisc> createState() => _RealisticCompactDiscState();
}

class _RealisticCompactDiscState extends State<RealisticCompactDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );
    if (widget.isPlaying) {
      _spinController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RealisticCompactDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_spinController.isAnimating) {
      _spinController.repeat();
    } else if (!widget.isPlaying && _spinController.isAnimating) {
      _spinController.stop();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _spinController,
      child: Container(
        width: widget.diameter,
        height: widget.diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.glowColor.withOpacity(0.35),
              blurRadius: 18,
              spreadRadius: 1,
            ),
            const BoxShadow(
              color: Colors.black87,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Printed Album Cover Surface
              if (widget.artworkUrl != null && widget.artworkUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: widget.artworkUrl!,
                  width: widget.diameter,
                  height: widget.diameter,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2B1347), Color(0xFF0E2942), Color(0xFF421238)],
                    ),
                  ),
                ),

              // Iridescent Rainbow Prismatic CD Sheen
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Colors.white.withOpacity(0.05),
                      const Color(0xFF00F0FF).withOpacity(0.28),
                      const Color(0xFFFF2E97).withOpacity(0.28),
                      Colors.white.withOpacity(0.35),
                      const Color(0xFF8B5CF6).withOpacity(0.24),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                ),
              ),

              // Outer polycarbonate rim
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.45), width: 2.0),
                ),
              ),

              // Inner Silver Clamping Ring
              Container(
                width: widget.diameter * 0.34,
                height: widget.diameter * 0.34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.24),
                  border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                ),
              ),

              // Transparent Inner Hub
              Container(
                width: widget.diameter * 0.22,
                height: widget.diameter * 0.22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF09070F).withOpacity(0.75),
                  border: Border.all(color: Colors.white.withOpacity(0.45), width: 1.2),
                ),
              ),

              // Spindle Center Hole
              Container(
                width: widget.diameter * 0.13,
                height: widget.diameter * 0.13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF07060C),
                  border: Border.all(color: Colors.white54, width: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Transparent CD Jewel Case with Left Spine Hinges, Plastic Glare, and Disc Protruding on the Right
class CdJewelCasePlayer extends StatelessWidget {
  final PlexTrack? track;
  final bool isPlaying;
  final bool jewelCaseMode;
  final Color primaryNeon;
  final Color secondaryNeon;

  const CdJewelCasePlayer({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.jewelCaseMode,
    required this.primaryNeon,
    required this.secondaryNeon,
  });

  @override
  Widget build(BuildContext context) {
    if (!jewelCaseMode) {
      return Center(
        child: RealisticCompactDisc(
          artworkUrl: track?.thumbUrl,
          isPlaying: isPlaying,
          diameter: 235,
          glowColor: primaryNeon,
        ),
      );
    }

    return SizedBox(
      height: 215,
      width: 315,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Protruding Spinning Disc on the Right
          Positioned(
            right: 4,
            child: RealisticCompactDisc(
              artworkUrl: track?.thumbUrl,
              isPlaying: isPlaying,
              diameter: 196,
              glowColor: secondaryNeon,
            ),
          ),

          // Transparent Acrylic CD Jewel Case on the Left
          Container(
            width: 218,
            height: 206,
            decoration: BoxDecoration(
              color: const Color(0xFF141122),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withOpacity(0.55), width: 1.6),
              boxShadow: [
                BoxShadow(
                  color: primaryNeon.withOpacity(0.35),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
                const BoxShadow(
                  color: Colors.black,
                  blurRadius: 16,
                  offset: Offset(6, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Clear Ribbed Spine with Hinges
                Container(
                  width: 18,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    border: Border(
                      right: BorderSide(color: Colors.white.withOpacity(0.35), width: 1.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      12,
                      (_) => Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        color: Colors.white.withOpacity(0.28),
                      ),
                    ),
                  ),
                ),

                // Front Booklet Artwork + Diagonal Plastic Glare
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (track?.thumbUrl != null && track!.thumbUrl!.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: track!.thumbUrl!,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primaryNeon.withOpacity(0.45),
                                const Color(0xFF0E0B1C),
                                secondaryNeon.withOpacity(0.35),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.album, size: 64, color: Colors.white38),
                          ),
                        ),

                      // Acrylic Plastic Specular Reflection
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: const [0.0, 0.35, 0.38, 1.0],
                            colors: [
                              Colors.white.withOpacity(0.24),
                              Colors.white.withOpacity(0.04),
                              Colors.transparent,
                              Colors.white.withOpacity(0.08),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Boombox Deck with Left/Right Metallic Speakers & Live Audio Spectrum Analyzer
class BoomboxVisualizerDeck extends StatelessWidget {
  final List<double> spectrumBands;
  final bool isPlaying;
  final Color primaryNeon;
  final Color secondaryNeon;
  final VoidCallback? onTapFullscreen;

  const BoomboxVisualizerDeck({
    super.key,
    required this.spectrumBands,
    required this.isPlaying,
    required this.primaryNeon,
    required this.secondaryNeon,
    this.onTapFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapFullscreen,
      child: Container(
        height: 112,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1F1D2B), Color(0xFF0E0D15), Color(0xFF181622)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24, width: 1.4),
          boxShadow: [
            BoxShadow(color: primaryNeon.withOpacity(0.22), blurRadius: 16),
          ],
        ),
        child: Row(
          children: [
            _BoomboxSpeakerCone(neonColor: primaryNeon, pulse: isPlaying ? spectrumBands.first : 0.0),
            const SizedBox(width: 8),
            // Central Digital Spectrum Screen
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF060812),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: secondaryNeon.withOpacity(0.55), width: 1.2),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(spectrumBands.length, (i) {
                          final level = isPlaying ? spectrumBands[i].clamp(0.08, 1.0) : 0.08;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 1.0),
                              child: FractionallySizedBox(
                                heightFactor: level,
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        secondaryNeon,
                                        const Color(0xFF8B5CF6),
                                        primaryNeon,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('64Hz', style: TextStyle(fontSize: 8, color: secondaryNeon.withOpacity(0.8))),
                        Text('1kHz', style: TextStyle(fontSize: 8, color: Colors.white54)),
                        Text('16kHz', style: TextStyle(fontSize: 8, color: primaryNeon.withOpacity(0.8))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _BoomboxSpeakerCone(neonColor: primaryNeon, pulse: isPlaying ? spectrumBands[1] : 0.0),
          ],
        ),
      ),
    );
  }
}

class _BoomboxSpeakerCone extends StatelessWidget {
  final Color neonColor;
  final double pulse;

  const _BoomboxSpeakerCone({required this.neonColor, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 + (pulse * 0.06);
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFF2B2838), Color(0xFF100E18), Color(0xFF272434)],
          ),
          border: Border.all(color: neonColor.withOpacity(0.85), width: 2.2),
          boxShadow: [
            BoxShadow(color: neonColor.withOpacity(0.35), blurRadius: 10),
          ],
        ),
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF12101A),
              border: Border.all(color: Colors.white30, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
