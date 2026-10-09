import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'router.dart';
import 'services/ads_service.dart';
import 'services/history_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Future.wait([HistoryService.init(), AdsService.init()]);
  runApp(const ProviderScope(child: BitePlanNowApp()));
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
