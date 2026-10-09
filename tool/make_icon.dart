// Generates the app icon PNGs in assets/icon. Run: dart run tool/make_icon.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const size = 512;
const ss = 4; // samples per axis for anti-aliasing

typedef Rgb = (int, int, int);
const terracotta = (0xE0, 0x5A, 0x47);
const white = (0xFF, 0xFF, 0xFF);
const cream = (0xF9, 0xF6, 0xF0);
const amber = (0xF2, 0xB5, 0x44);
const sage = (0x4A, 0x7C, 0x59);

bool inCircle(double x, double y, double cx, double cy, double r) =>
    (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r;

/// Colour of the artwork at unit-square point (x, y), or null if transparent.
/// [s] scales the artwork about the centre (smaller for the adaptive foreground).
Rgb? art(double px, double py, double s) {
  final x = 0.5 + (px - 0.5) / s;
  final y = 0.5 + (py - 0.5) / s;

  const r = 0.34;
  if (!inCircle(x, y, 0.5, 0.5, r)) return null;
  // Bite: three overlapping scallops on the upper-right rim.
  for (final deg in [22.0, 45.0, 68.0]) {
    final a = deg * math.pi / 180;
    if (inCircle(x, y, 0.5 + r * math.cos(a), 0.5 - r * math.sin(a), 0.085)) return null;
  }
  // Three ingredients on the plate.
  const dots = [(-90.0, amber), (30.0, terracotta), (150.0, sage)];
  for (final (deg, color) in dots) {
    final a = deg * math.pi / 180;
    if (inCircle(x, y, 0.5 + 0.1 * math.cos(a), 0.5 + 0.1 * math.sin(a), 0.07)) return color;
  }
  if (inCircle(x, y, 0.5, 0.5, 0.265)) return cream;
  return white;
}

img.Image render({required bool background, required double scale}) {
  final out = img.Image(width: size, height: size, numChannels: 4);
  for (var py = 0; py < size; py++) {
    for (var px = 0; px < size; px++) {
      var r = 0, g = 0, b = 0, a = 0;
      for (var sy = 0; sy < ss; sy++) {
        for (var sx = 0; sx < ss; sx++) {
          final c = art((px + (sx + 0.5) / ss) / size, (py + (sy + 0.5) / ss) / size, scale) ??
              (background ? terracotta : null);
          if (c == null) continue;
          r += c.$1;
          g += c.$2;
          b += c.$3;
          a++;
        }
      }
      if (a == 0) {
        out.setPixelRgba(px, py, 0, 0, 0, 0);
      } else {
        out.setPixelRgba(px, py, r ~/ a, g ~/ a, b ~/ a, (255 * a) ~/ (ss * ss));
      }
    }
  }
  return out;
}

void main() {
  File('assets/icon/app_icon.png').writeAsBytesSync(img.encodePng(render(background: true, scale: 1)));
  // Adaptive icons keep ~66% of the foreground visible, so shrink the artwork.
  File('assets/icon/app_icon_foreground.png')
      .writeAsBytesSync(img.encodePng(render(background: false, scale: 0.72)));
}
