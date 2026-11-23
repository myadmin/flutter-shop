import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hm_shop/models/user.dart';
import 'package:hm_shop/pages/Cart/index.dart';
import 'package:hm_shop/pages/Category/index.dart';
import 'package:hm_shop/pages/Login/index.dart';
import 'package:hm_shop/stores/cart_controller.dart';
import 'package:hm_shop/stores/token_manager.dart';
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
  });

  tearDown(Get.reset);

  /// 让当前测试处于「已登录」状态
  Future<void> login() async {
    SharedPreferences.setMockInitialValues({'hm_shop_token': 'test-token'});
    await tokenManager.init();
    Get.find<UserController>().updateUserInfo(
      UserInfo.fromJson(const {
        'id': 'u-1',
        'account': 'hm123456',
        'nickname': '测试用户',
      }),
    );
  }

  group('购物车页', () {
    testWidgets('未登录时展示登录引导', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CartView(isActive: true, onGoShopping: () {})),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('登录后查看购物车'), findsOneWidget);
      expect(find.text('去登录'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('已登录时展示条目并计算合计金额', (tester) async {
      await login();
      installMock(
        (options) => envelope([cartItemJson(count: 2, nowPrice: '69.90')]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CartView(isActive: true, onGoShopping: () {})),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('测试商品'), findsOneWidget);
      // 2 件 × 69.90
      expect(find.text('￥139.80'), findsOneWidget);
      expect(find.textContaining('结算(1)'), findsOneWidget);
    });

    testWidgets('空购物车展示空态并可去逛逛', (tester) async {
      await login();
      installMock((options) => envelope(<dynamic>[]));
      var goShopping = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartView(
              isActive: true,
              onGoShopping: () => goShopping = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('购物车还是空的'), findsOneWidget);
      await tester.tap(find.text('去逛逛'));
      await tester.pumpAndSettle();
      expect(goShopping, isTrue);
    });

    testWidgets('切换勾选会向服务端发 PUT 请求', (tester) async {
      await login();
      final adapter = installMock((options) {
        if (options.method.toUpperCase() == 'PUT') {
          return envelope(cartItemJson(selected: false));
        }
        return envelope([cartItemJson()]);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CartView(isActive: true, onGoShopping: () {})),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      final puts = adapter.requestsWhere('PUT');
      expect(puts, hasLength(1));
      expect(puts.first.path, contains('/member/cart/sku-1'));
    });

    testWidgets('加载失败展示服务端错误信息', (tester) async {
      await login();
      installMock((options) => envelopeError('购物车服务异常'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CartView(isActive: true, onGoShopping: () {})),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('购物车服务异常'), findsOneWidget);
      expect(find.text('重新加载'), findsOneWidget);
    });

    testWidgets('点击商品进入商品详情页', (tester) async {
      await login();
      installMock((options) => envelope([cartItemJson()]));

      final recorder = _RouteRecorder();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CartView(isActive: true, onGoShopping: () {})),
          navigatorObservers: [recorder],
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: SizedBox.shrink()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('测试商品'));
      await tester.pumpAndSettle();

      // 购物车条目的 id 就是商品 id，详情页用它拼路由
      expect(recorder.pushedNames, contains('/goods?id=goods-1'));
    });

    testWidgets('失效商品点击不跳转，只提示已失效', (tester) async {
      await login();
      installMock((options) => envelope([cartItemJson(isEffective: false)]));

      final recorder = _RouteRecorder();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CartView(isActive: true, onGoShopping: () {})),
          navigatorObservers: [recorder],
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: SizedBox.shrink()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('测试商品'));
      await tester.pumpAndSettle();

      // 初始路由本身也会被记为 '/'，这里只关心有没有跳去详情页
      expect(
        recorder.pushedNames.where((name) => name.startsWith('/goods')),
        isEmpty,
      );
      expect(find.text('商品已失效，无法查看详情'), findsOneWidget);
    });
  });

  group('登录页', () {
    testWidgets('空表单提交时展示校验文案且不发请求', (tester) async {
      final adapter = installMock((options) => envelope(null));
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, '登录'));
      await tester.pumpAndSettle();

      // 空值时占位文案与校验文案相同，会同时出现，这里只要求出现
      expect(find.text('请输入账号'), findsWidgets);
      expect(find.text('请输入密码'), findsWidgets);
      expect(adapter.requestsWhere('POST'), isEmpty);
    });

    testWidgets('未勾选协议时只提示不发起登录请求', (tester) async {
      final adapter = installMock((options) => envelope(null));
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '13800138000');
      await tester.enterText(fields.at(1), '123456');
      await tester.tap(find.widgetWithText(ElevatedButton, '登录'));
      await tester.pumpAndSettle();

      expect(find.text('请勾选隐私条款和用户协议'), findsOneWidget);
      expect(adapter.requestsWhere('POST'), isEmpty);
    });

    testWidgets('密码可见性可切换', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      final password = tester.widget<EditableText>(
        find.byType(EditableText).last,
      );
      expect(password.obscureText, isFalse);
    });
  });

  group('分类页', () {
    ResponseBody route(RequestOptions options) {
      final path = options.path;
      if (path.contains('/home/category/head')) {
        return envelope([
          categoryJson(id: 'c1', name: '居家'),
          categoryJson(id: 'c2', name: '美食'),
        ]);
      }
      if (path.contains('/home/goods/guessLike')) {
        return envelope({
          'counts': 1,
          'pages': 1,
          'page': 1,
          'pageSize': 10,
          'items': [goodsItemJson()],
        });
      }
      return envelope(null);
    }

    testWidgets('加载后展示一级分类与二级宫格', (tester) async {
      installMock(route);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CategoryView())),
      );
      await tester.pumpAndSettle();

      // 左侧导航与右侧面板标题都会出现当前一级分类
      expect(find.text('居家'), findsNWidgets(2));
      expect(find.text('美食'), findsOneWidget);
      // 右侧面板展示当前一级分类下的二级分类
      expect(find.text('子分类一'), findsOneWidget);
      expect(find.text('共 2 个分类'), findsOneWidget);
    });

    testWidgets('分类加载失败展示错误态并可重试', (tester) async {
      var failed = false;
      final adapter = installMock((options) {
        if (options.path.contains('/home/category/head')) {
          failed = true;
          return envelopeError('分类服务异常');
        }
        return envelope(null);
      });

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CategoryView())),
      );
      await tester.pumpAndSettle();

      expect(failed, isTrue);
      expect(find.text('分类服务异常'), findsOneWidget);

      final before = adapter.requests.length;
      await tester.tap(find.text('重新加载'));
      await tester.pumpAndSettle();
      expect(adapter.requests.length, greaterThan(before));
    });
  });
}

/// 记录被 push 的路由名，用来断言页面跳转目标
class _RouteRecorder extends NavigatorObserver {
  final List<String> pushedNames = <String>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null) pushedNames.add(name);
    super.didPush(route, previousRoute);
  }
}
