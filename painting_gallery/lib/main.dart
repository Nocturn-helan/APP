import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pages/splash_page.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 原型是竖屏手机设计稿（375 × 812），这里锁定竖屏 + 深色状态栏图标
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  runApp(const PaintingGalleryApp());
}

class PaintingGalleryApp extends StatelessWidget {
  const PaintingGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '绘画作品集',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashPage(),
    );
  }
}
