import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hm_shop/components/Mine/hm_mine_header.dart';
import 'package:hm_shop/components/Mine/hm_mine_order_module.dart';
import 'package:hm_shop/components/Mine/hm_mine_quick_actions.dart';
import 'package:hm_shop/models/user.dart';

void main() {
  group('「我的」页面组件', () {
    Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

    testWidgets('HmMineHeader 未登录时展示立即登录并回调', (tester) async {
      var loginTapped = false;
      await tester.pumpWidget(
        wrap(
          HmMineHeader(
            user: UserInfo.empty(),
            onLoginTap: () => loginTapped = true,
            onLogoutTap: () {},
          ),
        ),
      );

      expect(find.text('立即登录'), findsOneWidget);
      expect(find.text('退出'), findsNothing);

      await tester.tap(find.text('立即登录'));
      await tester.pump();
      expect(loginTapped, isTrue);
    });

    testWidgets('HmMineHeader 已登录时展示昵称与退出入口', (tester) async {
      var logoutTapped = false;
      await tester.pumpWidget(
        wrap(
          HmMineHeader(
            user: UserInfo.fromJson(const {
              'id': '4026450',
              'account': 'hm123456',
              'nickname': '美荟用户',
            }),
            onLoginTap: () {},
            onLogoutTap: () => logoutTapped = true,
          ),
        ),
      );

      expect(find.text('美荟用户'), findsOneWidget);
      expect(find.text('立即登录'), findsNothing);

      await tester.tap(find.text('退出'));
      await tester.pump();
      expect(logoutTapped, isTrue);
    });

    testWidgets('HmMineHeader 昵称为空时回退展示账号', (tester) async {
      await tester.pumpWidget(
        wrap(
          HmMineHeader(
            user: UserInfo.fromJson(const {
              'id': '4026450',
              'account': 'hm123456',
            }),
            onLoginTap: () {},
            onLogoutTap: () {},
          ),
        ),
      );

      expect(find.text('hm123456'), findsOneWidget);
    });

    testWidgets('HmMineQuickActions 渲染三个入口并按名称回调', (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(wrap(HmMineQuickActions(onEntryTap: tapped.add)));

      expect(find.text('我的收藏'), findsOneWidget);
      expect(find.text('我的足迹'), findsOneWidget);
      expect(find.text('我的客服'), findsOneWidget);

      await tester.tap(find.text('我的客服'));
      await tester.pump();
      expect(tapped, ['我的客服']);
    });

    testWidgets('HmMineOrderModule 渲染五个订单入口并按名称回调', (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(wrap(HmMineOrderModule(onEntryTap: tapped.add)));

      expect(find.text('订单管理'), findsOneWidget);
      for (final label in ['我的订单', '待付款', '待发货', '待收货', '待评价']) {
        expect(find.text(label), findsOneWidget);
      }

      await tester.tap(find.text('待发货'));
      await tester.pump();
      expect(tapped, ['待发货']);
    });
  });
}
