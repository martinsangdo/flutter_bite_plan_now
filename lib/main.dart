import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'providers/providers.dart';
import 'router.dart';
import 'services/ads_service.dart';
import 'services/history_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Future.wait([HistoryService.init(), AdsService.init()]);
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const BitePlanNowApp(),
    ),
  );
}

class BitePlanNowApp extends StatelessWidget {
  const BitePlanNowApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'BitePlanNow',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    routerConfig: router,
  );
}
