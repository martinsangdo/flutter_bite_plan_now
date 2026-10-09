import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../models/recipe.dart';
import '../providers/providers.dart';

/// Seconds for the first duration mentioned in [step] ("2-3 minutes" -> 180), else null.
int? stepSeconds(String step) {
  final m = RegExp(
    r'(\d+)(?:\s*(?:-|–|to)\s*(\d+))?\s*(seconds?|secs?|minutes?|mins?)\b',
    caseSensitive: false,
  ).firstMatch(step);
  if (m == null) return null;
  final n = int.parse(m.group(2) ?? m.group(1)!);
  return m.group(3)!.toLowerCase().startsWith('s') ? n : n * 60;
}

class CookScreen extends ConsumerStatefulWidget {
  const CookScreen({super.key, required this.recipe});
  final Recipe recipe;

  @override
  ConsumerState<CookScreen> createState() => _CookScreenState();
}

class _CookScreenState extends ConsumerState<CookScreen> {
  final _confetti = ConfettiController(duration: const Duration(seconds: 3));
  int _index = 0;
  bool _saving = false;

  Recipe get _r => widget.recipe;
  bool get _complete => _index >= _r.steps.length;

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _go(int delta) {
    HapticFeedback.selectionClick();
    setState(() => _index = (_index + delta).clamp(0, _r.steps.length));
    if (_complete) _confetti.play();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await ref.read(pointsProvider.notifier).saveMeal(_r);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '+$kPointsPerMeal pts · saved to Meal History'
              : "Couldn't sync history. Saved for this session only.",
        ),
      ),
    );
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final total = _r.steps.length;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Exit',
          onPressed: () => context.pop(),
        ),
        title: Text(
          _r.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: (_complete ? total : _index + 1) / total),
            duration: const Duration(milliseconds: 300),
            builder: (_, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 6,
              color: AppColors.sage,
              backgroundColor: AppColors.border,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            _complete ? _done() : _step(total),
            ConfettiWidget(
              confettiController: _confetti,
              blastDirection: math.pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 18,
              colors: const [
                AppColors.terracotta,
                AppColors.sage,
                Color(0xFFFFC857),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(int total) {
    final text = _r.steps[_index];
    final secs = stepSeconds(text);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STEP ${_index + 1} OF $total',
            style: const TextStyle(
              color: AppColors.terracotta,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  if (secs != null) ...[
                    const SizedBox(height: 28),
                    StepTimer(key: ValueKey(_index), seconds: secs),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 64),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _index == 0 ? null : () => _go(-1),
                  child: const Text(
                    'Previous',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 64),
                    backgroundColor: AppColors.sage,
                  ),
                  onPressed: () => _go(1),
                  child: Text(
                    _index == total - 1 ? 'Finish' : 'Next Step',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _done() => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🎉', style: TextStyle(fontSize: 72)),
        const SizedBox(height: 16),
        const Text(
          'Bon appétit!',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          _r.title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, color: AppColors.muted),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Text('Save to Meal History'),
        ),
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Back to deck'),
        ),
      ],
    ),
  );
}

class StepTimer extends StatefulWidget {
  const StepTimer({super.key, required this.seconds});
  final int seconds;

  @override
  State<StepTimer> createState() => _StepTimerState();
}

class _StepTimerState extends State<StepTimer> {
  Timer? _tick;
  DateTime? _endsAt;
  late int _left = widget.seconds;

  bool get _running => _tick != null;
  bool get _finished => _left == 0;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _tick!.cancel();
      setState(() => _tick = null);
      return;
    }
    if (_finished) _left = widget.seconds;
    // Deadline-based so a backgrounded or throttled app still lands on time.
    _endsAt = DateTime.now().add(Duration(seconds: _left));
    setState(
      () => _tick = Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => _update(),
      ),
    );
  }

  void _update() {
    final left = (_endsAt!.difference(DateTime.now()).inMilliseconds / 1000)
        .ceil()
        .clamp(0, widget.seconds);
    if (left == _left) return;
    setState(() => _left = left);
    if (left == 0) {
      _tick?.cancel();
      setState(() => _tick = null);
      _alert();
    }
  }

  Future<void> _alert() async {
    for (var i = 0; i < 3 && mounted; i++) {
      await HapticFeedback.vibrate();
      await SystemSound.play(SystemSoundType.alert);
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }
  }

  void _reset() {
    _tick?.cancel();
    setState(() {
      _tick = null;
      _left = widget.seconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mm = (_left ~/ 60).toString().padLeft(2, '0');
    final ss = (_left % 60).toString().padLeft(2, '0');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _finished ? const Color(0xFFEEF5F0) : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: cardShadow,
      ),
      child: Column(
        children: [
          Text(
            _finished ? "Time's up!" : '$mm:$ss',
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: _finished ? AppColors.sage : AppColors.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(140, 52)),
                onPressed: _toggle,
                icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                label: Text(
                  _running
                      ? 'Pause'
                      : _finished
                      ? 'Restart'
                      : 'Start',
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _reset,
                tooltip: 'Reset timer',
                icon: const Icon(Icons.replay),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
