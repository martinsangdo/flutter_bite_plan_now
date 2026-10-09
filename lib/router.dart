import 'package:go_router/go_router.dart';

import 'models/recipe.dart';
import 'screens/cook_screen.dart';
import 'screens/deck_screen.dart';
import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/splash_screen.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(path: '/scan', builder: (_, _) => const ScanScreen()),
    GoRoute(path: '/deck', builder: (_, _) => const DeckScreen()),
    GoRoute(
      path: '/cook',
      redirect: (_, state) => state.extra is Recipe ? null : '/',
      builder: (_, state) => CookScreen(recipe: state.extra! as Recipe),
    ),
  ],
);
