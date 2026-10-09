import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../models/recipe.dart';
import '../providers/providers.dart';
import '../widgets/rewarded_prompt.dart';

class DeckScreen extends ConsumerStatefulWidget {
  const DeckScreen({super.key});

  @override
  ConsumerState<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends ConsumerState<DeckScreen> {
  final _controller = CardSwiperController();
  bool _finished = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    if (!await ensureQuestionQuota(context, ref)) return;
    if (!mounted) return;
    await ref.read(adsProvider).onDeckReload();
    if (!mounted) return;
    setState(() => _finished = false);
    await ref
        .read(deckProvider.notifier)
        .generate(ref.read(pantryProvider).selected.toList());
  }

  Future<void> _afterSwipe(Recipe recipe, bool cook) async {
    await ref.read(adsProvider).onSwipe(cooking: cook);
    if (cook && mounted) context.push('/cook', extra: recipe);
  }

  @override
  Widget build(BuildContext context) {
    final deck = ref.watch(deckProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'AI Recipe Deck',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: deck.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              _Message(text: '$e', action: 'Try again', onTap: _reload),
          data: (recipes) {
            if (recipes.isEmpty || _finished) {
              return _Message(
                text: recipes.isEmpty
                    ? 'No recipes yet.'
                    : "You've seen them all!",
                action: 'Reload deck',
                onTap: _reload,
              );
            }
            return Column(
              children: [
                Expanded(
                  child: CardSwiper(
                    key: ValueKey(recipes.first.id),
                    controller: _controller,
                    cardsCount: recipes.length,
                    numberOfCardsDisplayed: math.min(3, recipes.length),
                    backCardOffset: const Offset(0, 28),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                    allowedSwipeDirection: const AllowedSwipeDirection.only(
                      left: true,
                      right: true,
                    ),
                    onSwipe: (prev, _, dir) {
                      HapticFeedback.selectionClick();
                      _afterSwipe(
                        recipes[prev],
                        dir == CardSwiperDirection.right,
                      );
                      return true;
                    },
                    onEnd: () => setState(() => _finished = true),
                    cardBuilder: (_, i, _, _) =>
                        _RecipeCard(recipe: recipes[i]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD64545),
                          ),
                          onPressed: () =>
                              _controller.swipe(CardSwiperDirection.left),
                          icon: const Text('❌'),
                          label: const Text('Skip'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.sage,
                          ),
                          onPressed: () =>
                              _controller.swipe(CardSwiperDirection.right),
                          icon: const Text('🍳'),
                          label: const Text('Cook Now!'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.text,
    required this.action,
    required this.onTap,
  });
  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onTap, child: Text(action)),
        ],
      ),
    ),
  );
}

class _RecipeCard extends ConsumerWidget {
  const _RecipeCard({required this.recipe});
  final Recipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = recipe;
    final image = ref.watch(recipeImageProvider(r.imageQuery)).value;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            flex: 4,
            child: SizedBox(
              width: double.infinity,
              child: image == null
                  ? const ColoredBox(
                      color: Color(0xFFF3E9DC),
                      child: Center(
                        child: Text('🍽️', style: TextStyle(fontSize: 56)),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      memCacheWidth: 800,
                      fadeInDuration: const Duration(milliseconds: 200),
                      placeholder: (_, _) =>
                          const ColoredBox(color: Color(0xFFF3E9DC)),
                      errorWidget: (_, _, _) => const ColoredBox(
                        color: Color(0xFFF3E9DC),
                        child: Center(
                          child: Text('🍽️', style: TextStyle(fontSize: 56)),
                        ),
                      ),
                    ),
            ),
          ),
          Expanded(
            flex: 6,
            child: ClipRect(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Pill(
                          '⏱️ ${r.prepTime}',
                          AppColors.cream,
                          AppColors.ink,
                        ),
                        _Pill(
                          '${r.calories} • ${r.protein} Protein',
                          const Color(0xFFEEF5F0),
                          AppColors.sage,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Line(
                      label: 'Pantry',
                      value: r.ingredientsUsed.join(', '),
                      color: AppColors.sage,
                    ),
                    if (r.missingStaples.isNotEmpty)
                      _Line(
                        label: 'Missing staples',
                        value: r.missingStaples.join(', '),
                        color: AppColors.terracotta,
                      ),
                    const Spacer(),
                    if (r.chefTip.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '💡 ${r.chefTip}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.amberInk,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
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

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.bg, this.fg);
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 13),
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
          TextSpan(text: value),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 14),
    ),
  );
}
