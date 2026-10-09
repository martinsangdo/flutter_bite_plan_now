import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import '../providers/providers.dart';

void _snack(BuildContext context, String m) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(m)));

/// Asks whether to watch a rewarded ad for [message], then shows it.
/// Returns true only if the user earned the reward.
Future<bool> watchAdFor(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String message,
}) async {
  final watch = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Watch ad'),
        ),
      ],
    ),
  );
  if (watch != true || !context.mounted) return false;
  final earned = await ref.read(adsProvider).showRewarded();
  if (!earned && context.mounted) {
    _snack(context, 'No ad available right now. Try again in a moment.');
  }
  return earned;
}

/// Gate for a recipe request. True if it may proceed: within the free
/// allowance, or after the user unlocked one more by watching an ad.
Future<bool> ensureQuestionQuota(BuildContext context, WidgetRef ref) async {
  final quota = ref.read(questionQuotaProvider);
  if (quota.canAsk) return true;
  if (!quota.canEarn) {
    _snack(
      context,
      'Daily limit of $kMaxQuestionsPerDay recipe requests reached. Come back tomorrow.',
    );
    return false;
  }
  final earned = await watchAdFor(
    context,
    ref,
    title: 'Want more recipes?',
    message:
        "You've used your $kFreeQuestionsPerDay free requests today. Watch a short ad to unlock 1 more.",
  );
  if (earned) ref.read(questionQuotaProvider.notifier).grantBonus();
  return earned;
}
