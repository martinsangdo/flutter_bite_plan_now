import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config.dart';
import '../core/ingredients.dart';
import '../core/theme.dart';
import '../providers/providers.dart';
import '../widgets/ad_banner.dart';
import '../widgets/agent_sheet.dart';
import '../widgets/glass.dart';
import '../widgets/ingredient_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  void _toggle(String name) {
    if (!ref.read(pantryProvider.notifier).toggle(name)) {
      HapticFeedback.heavyImpact();
      _toast('Max $kMaxIngredients ingredients. Deselect one first.');
    }
  }

  void _addCustom() {
    final text = _search.text;
    if (!ref.read(pantryProvider.notifier).addCustom(text)) {
      _toast('Max $kMaxIngredients ingredients. Deselect one first.');
      return;
    }
    _search.clear();
    setState(() => _query = '');
    FocusScope.of(context).unfocus();
  }

  Future<void> _scan() async {
    if (ref.read(scansUsedProvider) >= kMaxScansPerSession) {
      _toast(
        'Scan limit reached ($kMaxScansPerSession per session). Pick ingredients manually.',
      );
      return;
    }
    final found = await context.push<List<String>>('/scan');
    if (found == null || found.isEmpty || !mounted) return;
    final dropped = ref.read(pantryProvider.notifier).addDetected(found);
    HapticFeedback.mediumImpact();
    _toast(
      dropped > 0
          ? 'Found ${found.length}; kept the first $kMaxIngredients.'
          : 'Found ${found.join(', ')}',
    );
  }

  Future<void> _findRecipes() async {
    final selected = ref.read(pantryProvider).selected.toList();
    final deck = ref.read(deckProvider.notifier);
    final work = deck.generate(selected);
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AgentSheet(work: work),
    );
    if (!mounted) return;
    final result = ref.read(deckProvider);
    if (result.hasError) {
      _toast('${result.error}');
    } else {
      context.push('/deck');
    }
  }

  void _openSettings() => showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    builder: (_) => const _SettingsSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final pantry = ref.watch(pantryProvider);
    final q = _query.trim().toLowerCase();
    final items = [
      for (final i in catalog) (i.name, i.emoji),
      for (final c in pantry.custom) (c, emojiFor(c)),
    ].where((e) => q.isEmpty || e.$1.toLowerCase().contains(q)).toList();
    final canAdd = q.isNotEmpty && !items.any((e) => e.$1.toLowerCase() == q);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scan,
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        label: const Text(
          '📸 Quick Scan Pantry',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SelectionBar(onFind: _findRecipes),
            const AdBanner(),
          ],
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, top + 84, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _SearchField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    onSubmit: canAdd ? _addCustom : null,
                  ),
                ),
              ),
              if (canAdd)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ActionChip(
                        avatar: const Icon(Icons.add, size: 18),
                        label: Text('Add “${titleCase(_query)}”'),
                        onPressed: _addCustom,
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final (name, emoji) = items[i];
                    return IngredientCard(
                      key: ValueKey(name),
                      name: name,
                      emoji: emoji,
                      selected: pantry.selected.contains(name),
                      onTap: () => _toggle(name),
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            top: top + 8,
            left: 16,
            right: 16,
            child: _Header(onSettings: _openSettings),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.onSettings});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pts = ref.watch(pointsProvider).value ?? 0;
    return Glass(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      child: Row(
        children: [
          const Text('🍳', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'BitePlanNow',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.amber,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '⚡ ${_fmt(pts)} pts',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.amberInk,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            onPressed: onSettings,
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  static String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onSubmit,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    onSubmitted: (_) => onSubmit?.call(),
    textInputAction: TextInputAction.done,
    decoration: InputDecoration(
      hintText: 'Search or add an ingredient',
      prefixIcon: const Icon(Icons.search),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

class _SelectionBar extends ConsumerWidget {
  const _SelectionBar({required this.onFind});
  final VoidCallback onFind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(pantryProvider.select((p) => p.selected.length));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Glass(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$n / $kMaxIngredients Selected',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: n == kMaxIngredients ? AppColors.sage : AppColors.ink,
                ),
              ),
            ),
            FilledButton(
              onPressed: n == 0 ? null : onFind,
              child: const Text('Find Recipes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget row(String label, bool ok) => ListTile(
      dense: true,
      title: Text(label),
      trailing: Icon(
        ok ? Icons.check_circle : Icons.error_outline,
        color: ok ? AppColors.sage : AppColors.terracotta,
      ),
    );
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Services',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          row('Recipes (Groq)', Config.groqApiKey.isNotEmpty),
          row('Vision fallback (Gemini)', Config.geminiApiKey.isNotEmpty),
          row('Dish photos (Pexels)', Config.pexelsApiKey.isNotEmpty),
          row('Meal history (Supabase)', Config.supabaseEnabled),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('Clear selection'),
            onTap: () {
              ref.read(pantryProvider.notifier).clear();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
