import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/theme.dart';

/// Bottom sheet showing three agents "working in parallel" while [work] runs.
/// Pops `true` once [work] completes and the animation has had time to land.
class AgentSheet extends StatefulWidget {
  const AgentSheet({super.key, required this.work});
  final Future<void> work;

  @override
  State<AgentSheet> createState() => _AgentSheetState();
}

class _AgentSheetState extends State<AgentSheet> {
  static const _agents = [
    ('🟡', 'Chef Agent', 'Matching 10-min combo'),
    ('🟢', 'Dietitian Agent', 'Calculating macros'),
    ('🔵', 'Pantry Agent', 'Verifying basic oils'),
  ];
  static const _stagger = Duration(milliseconds: 700);

  final _done = <bool>[false, false, false];
  final _timers = <Timer>[];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _agents.length; i++) {
      _timers.add(
        Timer(_stagger * (i + 1), () {
          if (mounted) setState(() => _done[i] = true);
        }),
      );
    }
    // Real work gates the close; the minimum keeps the sheet from flashing.
    Future.wait([widget.work, Future<void>.delayed(_stagger * 3)]).whenComplete(
      () {
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your chefs are on it…',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < _agents.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child:
                    Row(
                          children: [
                            Text(
                              _agents[i].$1,
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _agents[i].$2,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    _agents[i].$3,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: _done[i]
                                  ? const Icon(
                                      Icons.check_circle,
                                      key: ValueKey('ok'),
                                      color: AppColors.sage,
                                    )
                                  : const SizedBox(
                                      key: ValueKey('wait'),
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(delay: (120 * i).ms)
                        .slideY(begin: 0.3, end: 0),
              ),
          ],
        ),
      ),
    );
  }
}
