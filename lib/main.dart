import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'theme.dart';
import 'models/app_state.dart';
import 'screens/landing_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1200, 920),
    minimumSize: Size(1000, 820),
    center: true,
    backgroundColor: kBg,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: 'Sweepe',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setResizable(true);
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..loadSession(),
      child: const SweepApp(),
    ),
  );
}

class SweepApp extends StatelessWidget {
  const SweepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sweepe',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      initialRoute: '/',
      routes: {
        '/': (_) => const LandingScreen(),
      },
    );
  }
}
