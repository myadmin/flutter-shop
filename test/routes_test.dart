import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hm_shop/models/order_list.dart';
import 'package:hm_shop/models/user.dart';
import 'package:hm_shop/pages/Brand/index.dart';
import 'package:hm_shop/pages/Collect/index.dart';
import 'package:hm_shop/pages/CustomerService/index.dart';
import 'package:hm_shop/pages/Footprint/index.dart';
import 'package:hm_shop/pages/GoodsDetail/index.dart';
import 'package:hm_shop/pages/GoodsList/index.dart';
import 'package:hm_shop/pages/OrderConfirm/index.dart';
import 'package:hm_shop/pages/OrderDetail/index.dart';
import 'package:hm_shop/pages/OrderList/index.dart';
import 'package:hm_shop/pages/Profile/index.dart';
import 'package:hm_shop/pages/Vip/index.dart';
import 'package:hm_shop/routes/app_routes.dart';
import 'package:hm_shop/routes/index.dart';
import 'package:hm_shop/stores/cart_controller.dart';
import 'package:hm_shop/stores/user_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/mock_http.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    Get.put(UserController(), permanent: true);
    Get.put(CartController(), permanent: true);
    // 路由表里的页面进入后都会请求接口，统一给一个空结果，避免真实网络
    installMock((options) => envelope(null));
  });

  tearDown(Get.reset);

  /// 通过 pushNamed 打开深链，让目标页拿到带查询串的 RouteSettings
  ///
  /// 不用 `initialRoute`：那会连带把首页（MainPage）也建起来发一堆请求。
  Future<void> pushRoute(WidgetTester tester, String url) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.pushNamed(context, url),
              child: const Text('打开'),
            ),
          ),
        ),
        onGenerateRoute: buildRoute,
      ),
    );
    await tester.tap(find.text('打开'));
    // 目标页里有转圈动画，用有限次 pump 而不是 pumpAndSettle
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('根 Widget', () {
    test('getRootWidget 装配了路由表、深链解析、兜底页与主题', () {
      final app = getRootWidget() as MaterialApp;

      expect(app.title, '美荟商城');
      expect(app.debugShowCheckedModeBanner, isFalse);
      expect(app.routes, contains(AppRoutes.home));
      expect(app.routes, contains(AppRoutes.login));
      expect(app.onGenerateRoute, isNotNull);
      expect(app.onGenerateInitialRoutes, isNotNull);
      expect(app.onUnknownRoute, isNotNull);
      expect(app.theme, isNotNull);
    });
  });

  group('路由表逐条接线', () {
    testWidgets('商品详情按查询串里的 id 传参', (tester) async {
      await pushRoute(tester, AppRoutes.goods('goods-42'));

      final page = tester.widget<GoodsDetailPage>(find.byType(GoodsDetailPage));
      expect(page.goodsId, 'goods-42');
    });

    testWidgets('分类商品列表同时传分类 id 与标题', (tester) async {
      await pushRoute(tester, AppRoutes.goodsList('c-9', '渔夫帽'));

      final page = tester.widget<GoodsListPage>(find.byType(GoodsListPage));
      expect(page.categoryId, 'c-9');
      expect(page.title, '渔夫帽');
    });

    testWidgets('分类商品列表缺少标题时用默认文案', (tester) async {
      await pushRoute(tester, '${AppRoutes.goodsListPath}?categoryId=c-9');

      final page = tester.widget<GoodsListPage>(find.byType(GoodsListPage));
      expect(page.categoryId, 'c-9');
      expect(page.title, '商品列表');
    });

    testWidgets('订单确认解析 skuId 与数量', (tester) async {
      await pushRoute(tester, AppRoutes.orderConfirm('sku-9', 3));

      final page = tester.widget<OrderConfirmPage>(
        find.byType(OrderConfirmPage),
      );
      expect(page.skuId, 'sku-9');
      expect(page.count, 3);
    });

    testWidgets('订单确认缺少数量时默认买 1 件', (tester) async {
      await pushRoute(tester, '${AppRoutes.orderConfirmPath}?skuId=sku-9');

      final page = tester.widget<OrderConfirmPage>(
        find.byType(OrderConfirmPage),
      );
      expect(page.count, 1);
    });

    testWidgets('订单列表按 state 选中对应 tab', (tester) async {
      await pushRoute(tester, AppRoutes.orderList(OrderState.unpaid));

      final page = tester.widget<OrderListPage>(find.byType(OrderListPage));
      expect(page.initialTab, OrderState.unpaid);
    });

    testWidgets('订单列表不带 state 时展示全部', (tester) async {
      await pushRoute(tester, AppRoutes.orderListPath);

      final page = tester.widget<OrderListPage>(find.byType(OrderListPage));
      expect(page.initialTab, OrderState.all);
    });

    testWidgets('订单详情按 id 传参', (tester) async {
      await pushRoute(tester, AppRoutes.orderDetail('order-1'));

      final page = tester.widget<OrderDetailPage>(find.byType(OrderDetailPage));
      expect(page.orderId, 'order-1');
    });

    testWidgets('品牌详情按 id 传参', (tester) async {
      await pushRoute(tester, AppRoutes.brand('brand-7'));

      final page = tester.widget<BrandPage>(find.byType(BrandPage));
      expect(page.brandId, 'brand-7');
    });

    for (final entry in <String, Type>{
      AppRoutes.collectPath: CollectPage,
      AppRoutes.customerServicePath: CustomerServicePage,
      AppRoutes.footprintPath: FootprintPage,
      AppRoutes.vipPath: VipBenefitsPage,
      AppRoutes.profilePath: ProfilePage,
    }.entries) {
      testWidgets('${entry.key} 打开 ${entry.value}', (tester) async {
        await pushRoute(tester, entry.key);

        expect(find.byType(entry.value), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('已登录时「我的」类页面能正常渲染', (tester) async {
      Get.find<UserController>().updateUserInfo(
        UserInfo.fromJson(const {'id': 'u-1', 'nickname': '测试用户'}),
      );

      await pushRoute(tester, AppRoutes.profilePath);
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('路由地址构造的剩余分支', () {
    test('订单列表默认不带 state，指定 state 时编进查询串', () {
      expect(AppRoutes.orderList(), '/orders');
      expect(AppRoutes.orderList(OrderState.unreceived), '/orders?state=3');
    });

    test('订单详情把 id 编进查询串并可被 buildRoute 还原', () {
      final url = AppRoutes.orderDetail('order-00000042');
      expect(url, '/orders/detail?id=order-00000042');

      final route = buildRoute(RouteSettings(name: url));
      expect(
        (route.settings.arguments as Map<String, dynamic>)['id'],
        'order-00000042',
      );
    });
  });
}
