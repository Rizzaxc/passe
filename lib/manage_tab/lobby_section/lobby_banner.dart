import 'package:flutter/material.dart';

class LobbyBanner extends StatelessWidget {
  final String name;
  final double height;

  const LobbyBanner({super.key, required this.name, this.height = 110});

  static const _palettes = [
    [Color(0xFF6B73FF), Color(0xFF000DFF)],
    [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFFC5C7D), Color(0xFF6A3093)],
    [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    [Color(0xFFF7971E), Color(0xFFFFD200)],
    [Color(0xFF764BA2), Color(0xFF667EEA)],
    [Color(0xFF0BA360), Color(0xFF3CBA92)],
  ];

  static List<Color> paletteFor(String name) =>
      _palettes[name.codeUnits.fold(0, (a, b) => a + b) % _palettes.length];

  @override
  Widget build(BuildContext context) {
    final palette = paletteFor(name);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: height * 0.47,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
