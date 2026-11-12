import 'package:flutter_test/flutter_test.dart';

import 'package:painting_gallery/main.dart';

void main() {
  testWidgets('启动页展示作品集名称', (WidgetTester tester) async {
    await tester.pumpWidget(const PaintingGalleryApp());

    expect(find.text('绘画作品集'), findsOneWidget);

    // 走完启动页停留时间与转场动画，避免测试结束时残留计时器
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
  });
}
