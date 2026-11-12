import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../data/work_store.dart';
import '../theme/app_theme.dart';
import '../widgets/bow_logo.dart';
import 'home_page.dart';

/// 启动页：蝴蝶结 Logo 缩放淡入（对应原型 1s 入场动画），2.5s 后进入首页。
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    // 启动时就把本机作品读入内存，首页直接渲染
    WorkStore.instance.load();

    _timer = Timer(const Duration(milliseconds: 2500), _goHome);
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation) =>
            const HomePage(),
        transitionsBuilder: (BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppGradients.splash),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedBuilder(
              animation: _controller,
              child: const BowLogo(size: 140),
              builder: (BuildContext context, Widget? child) {
                final double t =
                    Curves.easeOutCubic.transform(_controller.value);
                return Opacity(
                  opacity: t.clamp(0.0, 1.0).toDouble(),
                  child: Transform.scale(
                    scale: 0.3 + 0.7 * t,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: 12 * (1 - t),
                        sigmaY: 12 * (1 - t),
                      ),
                      child: child,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            AnimatedBuilder(
              animation: _controller,
              child: const Text(
                '绘画作品集',
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 6,
                  color: Color(0xFF4C3C63),
                ),
              ),
              builder: (BuildContext context, Widget? child) {
                // 在第 20% 之后淡入上移
                final double t = Curves.easeOut.transform(
                  ((_controller.value - 0.2) / 0.8).clamp(0.0, 1.0).toDouble(),
                );
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 6 * (1 - t)),
                    child: child,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
