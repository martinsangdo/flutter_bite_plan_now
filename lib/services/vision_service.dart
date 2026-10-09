import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image/image.dart' as img;

import '../core/config.dart';
import '../core/ingredients.dart';
import 'ai_service.dart';

class ScanResult {
  final List<String> ingredients;
  final bool usedCloud;
  const ScanResult(this.ingredients, {required this.usedCloud});
}

/// On-device ML Kit first; Gemini when nothing is recognised at >= 70%.
class VisionService {
  VisionService(this._ai);
  final AiService _ai;

  Future<ScanResult> scan(String imagePath) async {
    final jpeg = await compute(_downscale, imagePath);
    final local = await _detectLocally(imagePath, jpeg);
    if (local.isNotEmpty) return ScanResult(local, usedCloud: false);

    final cloud = await _ai.detectIngredients(jpeg);
    return ScanResult(
      {for (final n in cloud) matchCatalog(n) ?? titleCase(n)}.toList(),
      usedCloud: true,
    );
  }

  Future<List<String>> _detectLocally(
    String originalPath,
    Uint8List jpeg,
  ) async {
    final small = File('$originalPath.640.jpg');
    await small.writeAsBytes(jpeg, flush: true);
    final detector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      ),
    );
    try {
      final objects = await detector.processImage(
        InputImage.fromFilePath(small.path),
      );
      final found = <String>{};
      for (final o in objects) {
        for (final l in o.labels) {
          if (l.confidence < kLocalConfidence) continue;
          final name = matchCatalog(l.text);
          if (name != null) found.add(name);
        }
      }
      return found.toList();
    } finally {
      await detector.close();
      if (small.existsSync()) small.deleteSync();
    }
  }
}

/// Decodes, fixes EXIF rotation and shrinks to at most 640x640 (runs in an isolate).
Uint8List _downscale(String path) {
  final decoded = img.decodeImage(File(path).readAsBytesSync());
  if (decoded == null) throw AiException('Could not read the captured photo.');
  final oriented = img.bakeOrientation(decoded);
  final longest = oriented.width > oriented.height
      ? oriented.width
      : oriented.height;
  final resized = longest <= 640
      ? oriented
      : oriented.width >= oriented.height
      ? img.copyResize(oriented, width: 640)
      : img.copyResize(oriented, height: 640);
  return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
}
