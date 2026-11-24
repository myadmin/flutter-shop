import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hm_shop/models/user.dart';
import 'package:hm_shop/pages/Cart/index.dart';
import 'package:hm_shop/stores/cart_controller.dart';
import 'package:hm_shop/stores/token_manager.dart';
import 'package:hm_shop/stores/user_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/mock_http.dart';

/// 购物车页的交互分支：改数量、删除、全选、结算、刷新、跳登录
///
/// 这些动作都会「先改本地再发请求」，所以要同时断言界面状态与请求参数。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    Get.put(UserController(), permanent: true);
    Get.put(CartController(), permanent: true);
  });

  tearDown(Get.reset);

  Future<void> login() async {
    SharedPreferences.setMockInitialValues({'hm_shop_token': 'test-token'});
    await tokenManager.init();
    Get.find<UserController>().updateUserInfo(
      UserInfo.fromJson(const {'id': 'u-1', 'nickname': '测试用户'}),
    );
  }

  /// 装好购物车页；[onGenerateRoute] 用来捕获跳转目标
  Future<_RouteRecorder> pumpCart(
    WidgetTester tester, {
    VoidCallback? onGoShopping,
  }) async {
    final recorder = _RouteRecorder();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CartView(isActive: true, onGoShopping: onGoShopping ?? () {}),
        ),
        navigatorObservers: [recorder],
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return recorder;
  }

  group('购物车页交互', () {
    testWidgets('点「+」改数量会发 PUT 并带上新数量', (tester) async {
      await login();
      final adapter = installMock((options) {
        if (options.method.toUpperCase() == 'PUT') {
          return envelope(cartItemJson(count: 2));
        }
        return envelope([cartItemJson()]);
      });
      await pumpCart(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      final puts = adapter.requestsWhere('PUT');
      expect(puts, hasLength(1));
      expect(puts.first.path, contains('/member/cart/sku-1'));
      expect(puts.first.data, containsPair('count', 2));
      // 件数变化后底栏合计跟着变
      expect(find.text('￥139.80'), findsOneWidget);
    });

    testWidgets('数量为 1 时「−」禁用，不会发出请求', (tester) async {
      await login();
      final adapter = installMock((options) => envelope([cartItemJson()]));
      await pumpCart(tester);

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();

      expect(adapter.requestsWhere('PUT'), isEmpty);
    });

    testWidgets('改数量失败时回滚为原值并提示', (tester) async {
      await login();
      installMock((options) {
        if (options.method.toUpperCase() == 'PUT') {
          return envelopeError('库存不足');
        }
        return envelope([cartItemJson(count: 2)]);
      });
      await pumpCart(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('库存不足'), findsOneWidget);
      // 回滚到服务端的 2 件 × 69.90
      expect(find.text('￥139.80'), findsOneWidget);
    });

    testWidgets('删除条目需要二次确认，确认后发 DELETE', (tester) async {
      await login();
      final adapter = installMock((options) {
        if (options.method.toUpperCase() == 'DELETE') {
          return envelope(true);
        }
        return envelope([cartItemJson()]);
      });
      await pumpCart(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('确定要删除这件商品吗？'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, '删除'));
      await tester.pumpAndSettle();

      final deletes = adapter.requestsWhere('DELETE');
      expect(deletes, hasLength(1));
      expect(deletes.first.data, containsPair('ids', ['sku-1']));
      expect(find.text('已删除'), findsOneWidget);
      // 列表清空后回到空态
      expect(find.text('购物车还是空的'), findsOneWidget);
    });

    testWidgets('删除对话框点取消不发请求', (tester) async {
      await login();
      final adapter = installMock((options) => envelope([cartItemJson()]));
      await pumpCart(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '取消'));
      await tester.pumpAndSettle();

      expect(adapter.requestsWhere('DELETE'), isEmpty);
      expect(find.text('测试商品'), findsOneWidget);
    });

    testWidgets('全选会把未选中的条目逐个发 PUT', (tester) async {
      await login();
      final adapter = installMock((options) {
        if (options.method.toUpperCase() == 'PUT') {
          return envelope(cartItemJson(selected: true));
        }
        return envelope([
          cartItemJson(skuId: 'sku-1', selected: false),
          cartItemJson(skuId: 'sku-2', selected: false),
        ]);
      });
      await pumpCart(tester);

      await tester.tap(find.text('全选'));
      await tester.pumpAndSettle();

      final puts = adapter.requestsWhere('PUT');
      expect(puts, hasLength(2));
      final paths = puts.map((option) => option.path).toList();
      expect(paths, contains(contains('/member/cart/sku-1')));
      expect(paths, contains(contains('/member/cart/sku-2')));
      expect(puts.first.data, containsPair('selected', true));
    });

    testWidgets('全选失败时重新拉取列表', (tester) async {
      await login();
      final adapter = installMock((options) {
        if (options.method.toUpperCase() == 'PUT') {
          return envelopeError('网络开小差');
        }
        return envelope([cartItemJson(selected: false)]);
      });
      await pumpCart(tester);
      final before = adapter.requestsWhere('GET').length;

      await tester.tap(find.text('全选'));
      await tester.pumpAndSettle();

      expect(find.text('网络开小差'), findsOneWidget);
      expect(adapter.requestsWhere('GET').length, greaterThan(before));
    });

    testWidgets('未勾选任何商品时结算只提示，不跳转', (tester) async {
      await login();
      installMock((options) => envelope([cartItemJson(selected: false)]));
      final recorder = await pumpCart(tester);

      await tester.tap(find.textContaining('结算'));
      await tester.pumpAndSettle();

      expect(find.text('请选择要结算的商品'), findsOneWidget);
      expect(recorder.pushedNames, isEmpty);
    });

    testWidgets('勾选多件时结算提示只支持单件', (tester) async {
      await login();
      installMock(
        (options) => envelope([
          cartItemJson(skuId: 'sku-1'),
          cartItemJson(skuId: 'sku-2'),
        ]),
      );
      final recorder = await pumpCart(tester);

      await tester.tap(find.text('结算(2)'));
      await tester.pumpAndSettle();

      expect(find.text('演示接口仅支持单件商品结算，请只勾选一件'), findsOneWidget);
      expect(recorder.pushedNames, isEmpty);
    });

    testWidgets('勾选单件时跳到订单确认页并带上 skuId 与数量', (tester) async {
      await login();
      installMock((options) => envelope([cartItemJson(count: 3)]));
      final recorder = await pumpCart(tester);

      await tester.tap(find.text('结算(1)'));
      await tester.pumpAndSettle();

      expect(
        recorder.pushedNames,
        contains('/order/confirm?skuId=sku-1&count=3'),
      );
    });

    testWidgets('下拉刷新会重新请求列表', (tester) async {
      await login();
      final adapter = installMock((options) => envelope([cartItemJson()]));
      await pumpCart(tester);
      final before = adapter.requestsWhere('GET').length;

      await tester.fling(find.text('测试商品'), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(adapter.requestsWhere('GET').length, greaterThan(before));
    });

    testWidgets('未登录时点「去登录」跳到登录页', (tester) async {
      installMock((options) => envelope(null));
      final recorder = await pumpCart(tester);

      await tester.tap(find.text('去登录'));
      await tester.pumpAndSettle();

      expect(recorder.pushedNames, contains('/login'));
    });

    testWidgets('从详情页返回后刷新一次购物车', (tester) async {
      await login();
      final adapter = installMock((options) => envelope([cartItemJson()]));
      final recorder = await pumpCart(tester);
      final before = adapter.requestsWhere('GET').length;

      await tester.tap(find.text('测试商品'));
      await tester.pumpAndSettle();
      expect(recorder.pushedNames, contains('/goods?id=goods-1'));

      // 模拟从详情页返回
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      expect(adapter.requestsWhere('GET').length, greaterThan(before));
    });

    testWidgets('失效商品不能被勾选', (tester) async {
      await login();
      final adapter = installMock(
        (options) => envelope([cartItemJson(isEffective: false)]),
      );
      await pumpCart(tester);

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox).first);
      expect(checkbox.onChanged, isNull);
      expect(find.text('商品已失效'), findsOneWidget);
      expect(adapter.requestsWhere('PUT'), isEmpty);
    });

    testWidgets('切换勾选失败时回滚并提示', (tester) async {
      await login();
      installMock((options) {
        if (options.method.toUpperCase() == 'PUT') {
          return envelopeError('选中状态同步失败');
        }
        return envelope([cartItemJson()]);
      });
      await pumpCart(tester);

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(find.text('选中状态同步失败'), findsOneWidget);
      // 回滚成服务端返回的「已勾选」
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox).first);
      expect(checkbox.value, isTrue);
    });

    testWidgets('删除失败时提示且条目仍在', (tester) async {
      await login();
      installMock((options) {
        if (options.method.toUpperCase() == 'DELETE') {
          return envelopeError('删除失败，请稍后重试');
        }
        return envelope([cartItemJson()]);
      });
      await pumpCart(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '删除'));
      await tester.pumpAndSettle();

      expect(find.text('删除失败，请稍后重试'), findsOneWidget);
      expect(find.text('测试商品'), findsOneWidget);
    });

    testWidgets('条目缺少商品 id 时点击只提示，不跳转', (tester) async {
      await login();
      installMock(
        (options) => envelope([
          <String, dynamic>{...cartItemJson(), 'id': ''},
        ]),
      );
      final recorder = await pumpCart(tester);

      await tester.tap(find.text('测试商品'));
      await tester.pumpAndSettle();

      expect(find.text('商品信息缺失，请稍后重试'), findsOneWidget);
      expect(recorder.pushedNames, isEmpty);
    });

    testWidgets('请求在途时重复点击不会叠加请求', (tester) async {
      await login();
      final adapter = installMock((options) {
        if (options.method.toUpperCase() == 'PUT') {
          return envelope(cartItemJson(selected: false));
        }
        return envelope([cartItemJson()]);
      });
      await pumpCart(tester);

      await tester.tap(find.byType(Checkbox).first);
      // 不等待完成就再点一次
      await tester.pump();
      await tester.tap(find.byType(Checkbox).first, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(adapter.requestsWhere('PUT'), hasLength(1));
    });
  });

  group('购物车页 tab 切换', () {
    testWidgets('从其它 tab 切回时重新拉取', (tester) async {
      await login();
      final adapter = installMock((options) => envelope([cartItemJson()]));

      Widget build(bool isActive) => MaterialApp(
        home: Scaffold(
          body: CartView(isActive: isActive, onGoShopping: () {}),
        ),
      );

      await tester.pumpWidget(build(false));
      await tester.pumpAndSettle();
      final before = adapter.requestsWhere('GET').length;

      await tester.pumpWidget(build(true));
      await tester.pumpAndSettle();

      expect(adapter.requestsWhere('GET').length, greaterThan(before));
    });

    testWidgets('登录态变化后重新拉取并同步角标', (tester) async {
      installMock((options) {
        if (options.path.contains('/member/cart/count')) {
          return envelope({'count': 5});
        }
        return envelope([cartItemJson(count: 2)]);
      });

      await pumpCart(tester);
      expect(find.text('登录后查看购物车'), findsOneWidget);

      await login();
      await tester.pumpAndSettle();

      expect(find.text('测试商品'), findsOneWidget);
      expect(Get.find<CartController>().count.value, 2);
    });
  });
}

/// 记录被 push 的路由名，用来断言页面跳转目标
class _RouteRecorder extends NavigatorObserver {
  /// 不含初始路由 '/'，只关心测试里触发的跳转
  final List<String> pushedNames = <String>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final String? name = route.settings.name;
    if (name != null && name != '/') pushedNames.add(name);
    super.didPush(route, previousRoute);
  }
}
