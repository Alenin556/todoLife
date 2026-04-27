import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

class _ThemeSpec {
  const _ThemeSpec({
    required this.name,
    required this.bgHex,
    required this.strokeHex,
  });

  final String name;
  final String bgHex;
  final String strokeHex;
}

img.Color _c(String hex) => img.ColorUint8.rgba(
      (int.parse(hex.substring(1, 3), radix: 16)),
      (int.parse(hex.substring(3, 5), radix: 16)),
      (int.parse(hex.substring(5, 7), radix: 16)),
      255,
    );

void _drawCircleStroke(img.Image im, int cx, int cy, int r, int stroke, img.Color color) {
  final half = max(1, stroke ~/ 2);
  for (int t = -half; t <= half; t++) {
    img.drawCircle(im, x: cx, y: cy, radius: r + t, color: color, antialias: true);
  }
}

img.Image _renderIcon({
  required int size,
  required img.Color bg,
  required img.Color stroke,
}) {
  final im = img.Image(width: size, height: size, numChannels: 4);

  // Background squircle
  final pad = (size * 0.0625).round(); // ~64 at 1024
  final radius = (size * 0.215).round(); // ~220 at 1024
  img.fillRect(
    im,
    x1: 0,
    y1: 0,
    x2: size - 1,
    y2: size - 1,
    color: img.ColorUint8.rgba(0, 0, 0, 0),
  );
  img.fillRect(
    im,
    x1: pad,
    y1: pad,
    x2: size - pad - 1,
    y2: size - pad - 1,
    radius: radius,
    color: bg,
  );

  // Coin stroke
  final cx = (size * 0.5).round();
  final cy = (size * 0.535).round(); // slightly lower, matches mock
  final r = (size * 0.254).round(); // ~260 at 1024
  final strokeW = max(2, (size * 0.043).round()); // ~44 at 1024
  _drawCircleStroke(im, cx, cy, r, strokeW, stroke);

  // Eye mark (centered)
  final eyeW = (r * 1.45).round();
  final eyeH = (r * 0.72).round();
  final steps = 48;

  List<Point<int>> makeEyePoints(bool top) {
    final pts = <Point<int>>[];
    for (int i = 0; i <= steps; i++) {
      final t = i / steps; // 0..1
      final x = (t * 2 - 1); // -1..1
      // Smooth arc: y = sin(pi*(1-|x|)) gives 0 at edges, 1 at center.
      final k = sin(pi * (1 - x.abs()));
      final y = (top ? -1 : 1) * k;
      final px = cx + (x * (eyeW / 2)).round();
      final py = cy + (y * (eyeH / 2)).round();
      pts.add(Point(px, py));
    }
    return pts;
  }

  final topPts = makeEyePoints(true);
  final bottomPts = makeEyePoints(false);

  void drawPolyline(List<Point<int>> pts) {
    for (int i = 0; i < pts.length - 1; i++) {
      img.drawLine(
        im,
        x1: pts[i].x,
        y1: pts[i].y,
        x2: pts[i + 1].x,
        y2: pts[i + 1].y,
        color: stroke,
        antialias: true,
        thickness: max(2, (strokeW * 0.55).round()),
      );
    }
  }

  drawPolyline(topPts);
  drawPolyline(bottomPts.reversed.toList(growable: false));

  // Iris + pupil
  final irisR = (r * 0.22).round();
  final pupilR = (r * 0.11).round();
  img.drawCircle(im, x: cx, y: cy, radius: irisR, color: stroke, antialias: true);
  img.drawCircle(
    im,
    x: cx,
    y: cy,
    radius: pupilR,
    color: bg,
    antialias: true,
  );

  return im;
}

Future<void> _ensureDir(String path) async {
  final d = Directory(path);
  if (!await d.exists()) {
    await d.create(recursive: true);
  }
}

Future<void> _writePng(String path, img.Image image) async {
  final bytes = img.encodePng(image, level: 6);
  await File(path).writeAsBytes(bytes, flush: true);
}

Future<void> main(List<String> args) async {
  final root = Directory.current.path;

  final themes = const [
    _ThemeSpec(name: 'light', bgHex: '#2D2D2D', strokeHex: '#E0E0E0'),
    _ThemeSpec(name: 'dark', bgHex: '#F5F5F5', strokeHex: '#424242'),
  ];

  final standardSizes = const [48, 72, 96, 144, 192, 512];

  // iOS AppIcon sizes derived from Contents.json (px).
  final iosPxSizes = <String, int>{
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
  };

  final outSvg = '$root/assets/icons/svg';
  final outPng = '$root/assets/icons/png';
  await _ensureDir(outSvg);
  await _ensureDir(outPng);

  // Export standard PNG sizes for both themes.
  for (final t in themes) {
    final themeDir = '$outPng/${t.name}';
    await _ensureDir(themeDir);
    for (final s in standardSizes) {
      final im = _renderIcon(size: s, bg: _c(t.bgHex), stroke: _c(t.strokeHex));
      await _writePng('$themeDir/todolife_${t.name}_$s.png', im);
    }
    // Store also 1024 for marketing / master PNG.
    final im1024 = _renderIcon(size: 1024, bg: _c(t.bgHex), stroke: _c(t.strokeHex));
    await _writePng('$themeDir/todolife_${t.name}_1024.png', im1024);
  }

  // iOS: write AppIcon files (use light theme as default launcher).
  final iosDir = '$root/ios/Runner/Assets.xcassets/AppIcon.appiconset';
  await _ensureDir(iosDir);
  for (final entry in iosPxSizes.entries) {
    final im = _renderIcon(
      size: entry.value,
      bg: _c(themes.first.bgHex),
      stroke: _c(themes.first.strokeHex),
    );
    await _writePng('$iosDir/${entry.key}', im);
  }

  // Android: create mipmap PNGs (use light theme as default launcher).
  // Typical launcher sizes:
  // mdpi 48, hdpi 72, xhdpi 96, xxhdpi 144, xxxhdpi 192.
  final androidRes = '$root/android/app/src/main/res';
  final mipmaps = <String, int>{
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };
  for (final m in mipmaps.entries) {
    final dir = '$androidRes/${m.key}';
    await _ensureDir(dir);
    final im = _renderIcon(size: m.value, bg: _c(themes.first.bgHex), stroke: _c(themes.first.strokeHex));
    await _writePng('$dir/ic_launcher.png', im);
    await _writePng('$dir/ic_launcher_round.png', im);
  }

  stdout.writeln('Generated icons into assets/icons/png, iOS AppIcon, and Android mipmaps.');
}

