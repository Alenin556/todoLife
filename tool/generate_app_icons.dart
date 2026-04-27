import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

int _luma(img.Color c) {
  // ITU-R BT.601
  final r = c.r.toInt();
  final g = c.g.toInt();
  final b = c.b.toInt();
  return (0.299 * r + 0.587 * g + 0.114 * b).round();
}

({int x, int y, int size}) _autoCropSquare(img.Image src) {
  // Find the "dark content" area and crop a square around it.
  // Works well for the engraving eye reference where background is lighter.
  final step = max(1, (min(src.width, src.height) / 400).round());
  final lumSamples = <int>[];
  for (int y = 0; y < src.height; y += step) {
    for (int x = 0; x < src.width; x += step) {
      lumSamples.add(_luma(src.getPixel(x, y)));
    }
  }
  lumSamples.sort();
  final p10 = lumSamples[(lumSamples.length * 0.10).floor().clamp(0, lumSamples.length - 1)];
  final threshold = min(255, p10 + 18);

  int minX = src.width, minY = src.height, maxX = -1, maxY = -1;
  for (int y = 0; y < src.height; y += step) {
    for (int x = 0; x < src.width; x += step) {
      final lum = _luma(src.getPixel(x, y));
      if (lum <= threshold) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (maxX < 0 || maxY < 0) {
    final s = min(src.width, src.height);
    return (x: ((src.width - s) / 2).round(), y: ((src.height - s) / 2).round(), size: s);
  }

  // Expand box + make it square.
  final boxW = maxX - minX;
  final boxH = maxY - minY;
  final boxSize = max(boxW, boxH);
  final pad = (boxSize * 0.25).round();
  final cx = (minX + maxX) ~/ 2;
  final cy = (minY + maxY) ~/ 2;
  var size = boxSize + pad * 2;
  size = size.clamp(1, max(src.width, src.height));
  var x0 = cx - size ~/ 2;
  var y0 = cy - size ~/ 2;
  x0 = x0.clamp(0, src.width - 1);
  y0 = y0.clamp(0, src.height - 1);
  if (x0 + size > src.width) x0 = max(0, src.width - size);
  if (y0 + size > src.height) y0 = max(0, src.height - size);
  size = min(size, min(src.width - x0, src.height - y0));

  return (x: x0, y: y0, size: size);
}

img.Image _renderIcon({
  required int size,
  required img.Image eyeCrop,
}) {
  final im = img.Image(width: size, height: size, numChannels: 4);

  img.fillRect(
    im,
    x1: 0,
    y1: 0,
    x2: size - 1,
    y2: size - 1,
    color: img.ColorUint8.rgba(0, 0, 0, 0),
  );

  // Place the cropped eye image, centered, with padding so it doesn't touch edges.
  final target = (size * 0.86).round();
  final resized = img.copyResize(
    eyeCrop,
    width: target,
    height: target,
    interpolation: img.Interpolation.cubic,
  );
  final dx = ((size - resized.width) / 2).round();
  final dy = ((size - resized.height) / 2).round();
  img.compositeImage(im, resized, dstX: dx, dstY: dy);

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

  final eyePath = '$root/assets/icons/eye_reference.png';
  final eyeBytes = await File(eyePath).readAsBytes();
  final decoded = img.decodeImage(eyeBytes);
  if (decoded == null) {
    throw StateError('Failed to decode eye reference image at $eyePath');
  }
  final crop = _autoCropSquare(decoded);
  final eyeCrop = img.copyCrop(
    decoded,
    x: crop.x,
    y: crop.y,
    width: crop.size,
    height: crop.size,
  );

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

  // Export standard PNG sizes + 1024 master.
  for (final s in standardSizes) {
    final im = _renderIcon(size: s, eyeCrop: eyeCrop);
    await _writePng('$outPng/todolife_$s.png', im);
  }
  final im1024 = _renderIcon(size: 1024, eyeCrop: eyeCrop);
  await _writePng('$outPng/todolife_1024.png', im1024);

  // iOS: write AppIcon files.
  final iosDir = '$root/ios/Runner/Assets.xcassets/AppIcon.appiconset';
  await _ensureDir(iosDir);
  for (final entry in iosPxSizes.entries) {
    final im = _renderIcon(
      size: entry.value,
      eyeCrop: eyeCrop,
    );
    await _writePng('$iosDir/${entry.key}', im);
  }

  // Android: create mipmap PNGs.
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
    final im = _renderIcon(size: m.value, eyeCrop: eyeCrop);
    await _writePng('$dir/ic_launcher.png', im);
    await _writePng('$dir/ic_launcher_round.png', im);
  }

  stdout.writeln('Generated icons from $eyePath into assets/icons/png, iOS AppIcon, and Android mipmaps.');
}

