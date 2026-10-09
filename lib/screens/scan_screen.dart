import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../providers/providers.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  CameraController? _camera;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) throw CameraException('none', 'No camera found');
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      final c = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await c.initialize();
      if (!mounted) return c.dispose();
      setState(() => _camera = c);
    } on CameraException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.code == 'CameraAccessDenied'
              ? 'Camera permission denied. Enable it in Settings to scan.'
              : 'Camera unavailable (${e.description ?? e.code}).',
        );
      }
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final cam = _camera;
    if (cam == null || _busy) return;
    if (ref.read(scansUsedProvider) >= kMaxScansPerSession) {
      _snack('Scan limit reached ($kMaxScansPerSession per session).');
      return;
    }
    setState(() => _busy = true);
    String? path;
    try {
      path = (await cam.takePicture()).path;
      ref.read(scansUsedProvider.notifier).record();
      final result = await ref.read(visionServiceProvider).scan(path);
      if (!mounted) return;
      if (result.ingredients.isEmpty) {
        _snack('No ingredients recognised. Try a closer, brighter shot.');
      } else {
        context.pop(result.ingredients);
        return;
      }
    } catch (e) {
      if (mounted) _snack('$e');
    } finally {
      if (path != null) File(path).delete().ignore();
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final cam = _camera;
    final left = kMaxScansPerSession - ref.watch(scansUsedProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Quick Scan Pantry',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
          : cam == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                Center(child: CameraPreview(cam)),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _busy
                                ? 'Analysing…'
                                : left <= 0
                                ? 'Scan limit reached'
                                : 'Frame your ingredients and tap · $left left',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: _capture,
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _busy || left <= 0
                                      ? Colors.white38
                                      : AppColors.terracotta,
                                ),
                                child: _busy
                                    ? const Padding(
                                        padding: EdgeInsets.all(18),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
