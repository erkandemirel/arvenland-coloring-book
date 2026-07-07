import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ArvenlandApp());
}

class ArvenlandApp extends StatelessWidget {
  const ArvenlandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arvenland',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      scrollBehavior: const _AppScrollBehavior(),
      home: const HomeScreen(),
    );
  }
}

// Masaüstü/web'de fare sürüklemesiyle de kaydırmaya izin verir.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}
