import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hm_shop/components/Home/hm_hot.dart';
import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/models/user.dart';
import 'package:hm_shop/pages/Home/skeleton.dart';

void main() {
  group('hm_shop Widget & Model Tests', () {
    testWidgets('HomeSkeleton 能够正常渲染并包含呼吸动画', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeSkeleton(),
          ),
        ),
      );

      expect(find.byType(HomeSkeleton), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(HomeSkeleton),
          matching: find.byType(FadeTransition),
        ),
        findsOneWidget,
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('HmHot 能够根据配置正确渲染爆款推荐与一站全买标题', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                HmHot(
                  config: HmHotConfig.inVogue,
                  result: SpecialRecommendResult(
                    id: '1',
                    title: '爆款推荐',
                    subTypes: [],
                  ),
                ),
                HmHot(
                  config: HmHotConfig.oneStop,
                  result: SpecialRecommendResult(
                    id: '2',
                    title: '一站全买',
                    subTypes: [],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('爆款推荐'), findsOneWidget);
      expect(find.text('最受欢迎'), findsOneWidget);
      expect(find.text('一站全买'), findsOneWidget);
      expect(find.text('精心优选'), findsOneWidget);
    });

    test('UserInfo 能够正确从 json 解析并判断登录态', () {
      final guest = UserInfo.fromJson({});
      expect(guest.isLoggedIn, isFalse);

      final user = UserInfo.fromJson({
        'id': '1001',
        'account': 'test_user',
        'nickname': '测试账号',
        'token': 'mock_token',
      });
      expect(user.isLoggedIn, isTrue);
      expect(user.account, 'test_user');
      expect(user.nickname, '测试账号');
    });
  });
}
