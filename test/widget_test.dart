import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hm_shop/components/GoodsDetail/hm_action_bar.dart';
import 'package:hm_shop/components/Home/hm_hot.dart';
import 'package:hm_shop/models/goods.dart';
import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/models/order.dart';
import 'package:hm_shop/models/user.dart';
import 'package:hm_shop/pages/Home/skeleton.dart';

void main() {
  group('hm_shop Widget & Model Tests', () {
    testWidgets('HomeSkeleton 能够正常渲染并包含呼吸动画', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomeSkeleton())),
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

    test('GoodsDetail 解析 SKU 并优先选择有库存的规格', () {
      final detail = GoodsDetail.fromJson({
        'id': '4026450',
        'name': '测试商品',
        'price': 89,
        'skus': [
          {
            'id': 'sku-1',
            'price': '89.00',
            'inventory': 0,
            'picture': '',
            'specs': [
              {'name': '颜色', 'valueName': '米白'},
            ],
          },
          {
            'id': 'sku-2',
            'price': '89.00',
            'inventory': 10,
            'picture': '',
            'specs': [
              {'name': '颜色', 'valueName': '暗绿色'},
              {'name': '尺码', 'valueName': '90/3T'},
            ],
          },
        ],
      });

      expect(detail.defaultSku?.id, 'sku-2');
      expect(detail.defaultSku?.specText, '颜色:暗绿色 尺码:90/3T');
    });

    test('PreOrderResult 优先返回默认收货地址', () {
      final result = PreOrderResult.fromJson({
        'userAddresses': [
          {'id': '1', 'receiver': '张三', 'isDefault': 0},
          {'id': '2', 'receiver': '李四', 'isDefault': 1},
        ],
        'goods': [],
        'summary': {'goodsCount': 0, 'totalPayPrice': 90.0},
      });

      expect(result.defaultAddress?.id, '2');
      expect(result.defaultAddress?.receiver, '李四');
      expect(result.summary.totalPayPrice, '90.00');
    });

    testWidgets('HmActionBar 展示单价并触发按钮回调', (WidgetTester tester) async {
      int addCartCount = 0;
      int buyNowCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: HmActionBar(
              price: '89.00',
              onAddCart: () => addCartCount++,
              onBuyNow: () => buyNowCount++,
            ),
          ),
        ),
      );

      expect(find.text('单价'), findsOneWidget);
      expect(find.text('￥89.00'), findsOneWidget);
      expect(find.text('加入购物车'), findsOneWidget);
      expect(find.text('立即购买'), findsOneWidget);

      await tester.tap(find.text('加入购物车'));
      await tester.tap(find.text('立即购买'));

      expect(addCartCount, 1);
      expect(buyNowCount, 1);
    });

    testWidgets('HmActionBar 固定在视口底部且不遮挡滚动内容', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 50,
              itemBuilder: (context, index) {
                return SizedBox(height: 60, child: Text('商品$index'));
              },
            ),
            bottomNavigationBar: const HmActionBar(price: '89.00'),
          ),
        ),
      );

      final Rect barRect = tester.getRect(find.byType(HmActionBar));
      // 操作栏按内容高度收缩，且贴合视口底部
      expect(barRect.height, lessThan(120));
      expect(barRect.bottom, tester.getSize(find.byType(Scaffold)).height);
      // 页面主体仍有可滚动空间
      expect(tester.getRect(find.byType(ListView)).height, greaterThan(0));

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byType(HmActionBar), findsOneWidget);
      expect(tester.getRect(find.byType(HmActionBar)), barRect);
      // 页面内容在操作栏上方结束，说明操作栏未遮挡内容
      expect(
        tester.getRect(find.byType(ListView)).bottom,
        lessThanOrEqualTo(barRect.top),
      );
    });

    testWidgets('HmActionBar 在移动端与 PC 端尺寸下均正常显示', (WidgetTester tester) async {
      addTearDown(tester.view.reset);
      final sizes = <Size>[
        const Size(375, 812), // 移动端
        const Size(768, 1024), // 平板
        const Size(1280, 800), // PC
      ];

      for (final size in sizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox.expand(),
              bottomNavigationBar: HmActionBar(price: '3103.00'),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull, reason: '尺寸 $size 下操作栏渲染异常');
        expect(find.text('￥3103.00'), findsOneWidget);
        expect(find.text('加入购物车'), findsOneWidget);
        expect(find.text('立即购买'), findsOneWidget);
      }
    });
  });
}
