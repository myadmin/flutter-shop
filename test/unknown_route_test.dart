import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hm_shop/pages/Unknown/index.dart';
import 'package:hm_shop/routes/app_routes.dart';
import 'package:hm_shop/routes/index.dart';

/// 假路由表：只用极简页面占位，避免真实首页发起网络请求
Map<String, Widget Function(BuildContext)> _stubRoutes() =>
    <String, Widget Function(BuildContext)>{
      '/': (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.pushNamed(context, '/not-exist'),
            child: const Text('跳到不存在的路由'),
          ),
        ),
      ),
    };

/// 把 onUnknownRoute 接到真实路由表上，并用首页按钮触发一次「跳到不存在的路由」
///
/// 注意不能同时给 `home` 和 `routes['/']`，框架会断言二者重复。
Widget _appWithUnknownRoute() {
  return MaterialApp(routes: _stubRoutes(), onUnknownRoute: buildUnknownRoute);
}

void main() {
  group('未知路由兜底', () {
    testWidgets('未命中路由时展示兜底页并带上原始地址', (tester) async {
      await tester.pumpWidget(_appWithUnknownRoute());
      await tester.tap(find.text('跳到不存在的路由'));
      await tester.pumpAndSettle();

      final page = tester.widget<UnknownRoutePage>(
        find.byType(UnknownRoutePage),
      );
      expect(page.location, '/not-exist');
      expect(find.text('没有找到这个页面'), findsOneWidget);
      expect(find.text('地址 /not-exist'), findsOneWidget);
    });

    testWidgets('未提供地址时展示通用提示', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: UnknownRoutePage()));
      await tester.pumpAndSettle();

      expect(find.text('地址可能已经失效，回首页继续逛逛吧'), findsOneWidget);
      expect(find.text('没有找到这个页面'), findsOneWidget);
    });

    testWidgets('点「返回首页」清空栈并回到根路由', (tester) async {
      await tester.pumpWidget(_appWithUnknownRoute());
      await tester.tap(find.text('跳到不存在的路由'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('返回首页'));
      await tester.pumpAndSettle();

      expect(find.text('跳到不存在的路由'), findsOneWidget);
      expect(find.byType(UnknownRoutePage), findsNothing);
    });

    testWidgets('页面标题与图标齐全', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: UnknownRoutePage(location: '/x')),
      );
      await tester.pumpAndSettle();

      expect(find.text('页面不存在'), findsOneWidget);
      expect(find.byIcon(Icons.explore_off_outlined), findsOneWidget);
    });

    testWidgets('buildUnknownRoute 直接返回可用的 MaterialPageRoute', (tester) async {
      final route = buildUnknownRoute(const RouteSettings(name: '/whatever'));
      expect(route, isA<MaterialPageRoute<void>>());
    });
  });

  group('深链路由解析', () {
    test('带查询串的深链会拆出路径与参数', () {
      final route = buildRoute(const RouteSettings(name: '/goods?id=42'));
      expect(route, isA<MaterialPageRoute<void>>());

      final settings = route.settings;
      // 路由名保留完整查询串：地址栏 URL 取的就是 name，保留才能刷新还原
      expect(settings.name, '/goods?id=42');
      expect(settings.arguments, isA<Map<String, dynamic>>());
      expect((settings.arguments as Map<String, dynamic>)['id'], '42');
    });

    test('订单确认深链的多个参数都能解析', () {
      final route = buildRoute(
        const RouteSettings(name: '/order/confirm?skuId=sku-9&count=3'),
      );
      final arguments = route.settings.arguments as Map<String, dynamic>;
      expect(route.settings.name, '/order/confirm?skuId=sku-9&count=3');
      expect(arguments['skuId'], 'sku-9');
      expect(arguments['count'], '3');
    });

    test('站内跳转传入的 arguments 优先于查询串', () {
      final route = buildRoute(
        const RouteSettings(name: '/goods', arguments: 'sku-from-list'),
      );
      expect(route.settings.arguments, 'sku-from-list');
      expect(route.settings.name, '/goods');
    });

    test('路径不存在时生成兜底页路由', () {
      final route = buildRoute(const RouteSettings(name: '/nope?x=1'));
      final page = (route as MaterialPageRoute<void>).builder(
        // builder 只用 settings，不依赖真实 context
        _FakeContext(),
      );
      expect(page, isA<UnknownRoutePage>());
      expect((page as UnknownRoutePage).location, '/nope?x=1');
    });

    test('根路径照常命中首页路由', () {
      final route = buildRoute(const RouteSettings(name: '/'));
      expect(route.settings.name, '/');
      expect(route.settings.arguments, isNull);
    });
  });

  group('初始路由栈', () {
    test('根路径只压一层首页', () {
      final routes = buildInitialRoutes('/');
      expect(routes, hasLength(1));
      expect(routes.single.settings.name, '/');
    });

    test('深链压成「首页 + 目标页」两层，不会多出空参数页面', () {
      final url = AppRoutes.goodsList('c1', '渔夫帽');
      final routes = buildInitialRoutes(url);

      expect(routes, hasLength(2));
      expect(routes.first.settings.name, '/');
      expect(routes.last.settings.name, url);
      // 默认的逐段拆分会产生 `/goods` 这一层（参数为空的商品详情页）
      expect(
        routes.map((route) => route.settings.name),
        isNot(contains('/goods')),
      );
      expect(
        (routes.last.settings.arguments as Map<String, dynamic>)['categoryId'],
        'c1',
      );
    });

    test('对不上的深链也先落到首页，再压一层兜底页', () {
      final routes = buildInitialRoutes('/nope?x=1');

      expect(routes, hasLength(2));
      expect(routes.first.settings.name, '/');
      expect(routes.last.settings.name, '/nope?x=1');
    });
  });

  group('路由地址构造', () {
    test('商品详情把 id 编进查询串并可被 buildRoute 还原', () {
      expect(AppRoutes.goods('42'), '/goods?id=42');

      final route = buildRoute(RouteSettings(name: AppRoutes.goods('42')));
      expect(route.settings.name, '/goods?id=42');
      expect((route.settings.arguments as Map<String, dynamic>)['id'], '42');
    });

    test('特殊字符会被转义，不会拼出坏 URL', () {
      final url = AppRoutes.goods('a b&c=d');
      expect(url, '/goods?id=a+b%26c%3Dd');

      final route = buildRoute(RouteSettings(name: url));
      expect(
        (route.settings.arguments as Map<String, dynamic>)['id'],
        'a b&c=d',
      );
    });

    test('订单确认同时带上 skuId 与数量', () {
      expect(
        AppRoutes.orderConfirm('sku-9', 3),
        '/order/confirm?skuId=sku-9&count=3',
      );

      final route = buildRoute(
        RouteSettings(name: AppRoutes.orderConfirm('sku-9', 3)),
      );
      final arguments = route.settings.arguments as Map<String, dynamic>;
      expect(route.settings.name, '/order/confirm?skuId=sku-9&count=3');
      expect(arguments['skuId'], 'sku-9');
      expect(arguments['count'], '3');
    });

    test('无参页面使用常量路由名', () {
      expect(AppRoutes.home, '/');
      expect(AppRoutes.login, '/login');
    });
  });
}

/// buildRoute 的 builder 只读取 RouteSettings，这里给个最小占位 context
class _FakeContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
