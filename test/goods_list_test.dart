import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hm_shop/components/common/app_error_view.dart';
import 'package:hm_shop/components/common/hm_goods_card.dart';
import 'package:hm_shop/pages/Category/index.dart';
import 'package:hm_shop/pages/GoodsList/index.dart';
import 'package:hm_shop/routes/app_routes.dart';

import 'helpers/mock_http.dart';

/// 记录被 push 的路由名，用于断言「点商品卡片进详情页」
class _RouteRecorder extends NavigatorObserver {
  final List<String?> pushedNames = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedNames.add(route.settings.name);
    super.didPush(route, previousRoute);
  }
}

/// 分类商品列表页的主要状态流：成功渲染、跳转详情、切换同级分类、
/// 失败重试、空分类、缺少入参。
void main() {
  /// 挂载页面并等待首屏请求落地
  ///
  /// 默认测试视口 800×600 偏大，商品网格按最大宽度铺开会让断言依赖列数，
  /// 这里统一用手机尺寸，与其它页面级测试保持一致。
  Future<void> pumpPage(
    WidgetTester tester,
    Widget page, {
    Route<dynamic>? Function(RouteSettings settings)? onGenerateRoute,
    List<NavigatorObserver> observers = const [],
  }) async {
    tester.view.physicalSize = const Size(414, 896);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: page,
        onGenerateRoute: onGenerateRoute,
        navigatorObservers: observers,
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
  }

  testWidgets('加载成功展示同级分类、商品数量与商品卡片', (tester) async {
    final adapter = installMock((options) => envelope(categoryGoodsJson()));

    await pumpPage(
      tester,
      const GoodsListPage(categoryId: 'sub-1', title: '子分类一'),
    );

    // 请求带的是接口要求的 id 参数
    expect(adapter.requests.single.uri.queryParameters['id'], 'sub-1');
    expect(find.text('子分类二'), findsOneWidget);
    expect(find.text('共 2 件商品'), findsOneWidget);
    expect(find.text('· 测试分类'), findsOneWidget);
    expect(find.text('分类商品一'), findsOneWidget);
    expect(find.text('￥10.00'), findsOneWidget);
    expect(find.byType(HmGoodsCard), findsNWidgets(2));
    // 分类商品接口只给 orderNum，卡片应回退到销量字段而不是 payCount
    expect(find.text('1人付款'), findsNWidgets(2));
  });

  testWidgets('手机宽度下商品排成两列', (tester) async {
    installMock((options) => envelope(categoryGoodsJson()));

    await pumpPage(
      tester,
      const GoodsListPage(categoryId: 'sub-1', title: '子分类一'),
    );

    // 414 宽、单列最大 210 → 两列：两张卡片落在同一行，右边那张更靠右
    final first = tester.getTopLeft(find.byType(HmGoodsCard).at(0));
    final second = tester.getTopLeft(find.byType(HmGoodsCard).at(1));
    expect(second.dy, first.dy);
    expect(second.dx, greaterThan(first.dx));
  });

  testWidgets('点击商品卡片跳转到商品详情', (tester) async {
    installMock((options) => envelope(categoryGoodsJson()));
    final recorder = _RouteRecorder();

    await pumpPage(
      tester,
      const GoodsListPage(categoryId: 'sub-1', title: '子分类一'),
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('详情页占位')),
        settings: settings,
      ),
      observers: [recorder],
    );

    await tester.tap(find.text('分类商品一'));
    await tester.pumpAndSettle();

    expect(find.text('详情页占位'), findsOneWidget);
    expect(recorder.pushedNames, contains(AppRoutes.goods('goods-1')));
  });

  testWidgets('切换同级分类后重新请求并替换商品', (tester) async {
    final adapter = installMock((options) {
      final id = options.uri.queryParameters['id'] ?? 'sub-1';
      return envelope(
        categoryGoodsJson(
          id: id,
          name: id == 'sub-2' ? '子分类二' : '子分类一',
          goods: [goodsItemJson(id: 'goods-$id', name: '商品-$id')],
        ),
      );
    });

    await pumpPage(
      tester,
      const GoodsListPage(categoryId: 'sub-1', title: '子分类一'),
    );
    expect(find.text('商品-sub-1'), findsOneWidget);

    await tester.tap(find.text('子分类二'));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.last.uri.queryParameters['id'], 'sub-2');
    expect(find.text('商品-sub-2'), findsOneWidget);
    expect(find.text('商品-sub-1'), findsNothing);
  });

  testWidgets('加载失败展示错误视图，点重试后恢复内容', (tester) async {
    var shouldFail = true;
    final adapter = installMock(
      (options) =>
          shouldFail ? envelopeError('分类不存在') : envelope(categoryGoodsJson()),
    );

    await pumpPage(
      tester,
      const GoodsListPage(categoryId: 'sub-1', title: '子分类一'),
    );

    expect(find.byType(AppErrorView), findsOneWidget);
    expect(find.text('分类不存在'), findsOneWidget);

    shouldFail = false;
    await tester.tap(find.text('重新加载'));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    expect(find.byType(AppErrorView), findsNothing);
    expect(find.text('分类商品一'), findsOneWidget);
    expect(adapter.requests, hasLength(2));
  });

  testWidgets('分类下没有商品时展示空态', (tester) async {
    installMock((options) => envelope(categoryGoodsJson(goods: [])));

    await pumpPage(
      tester,
      const GoodsListPage(categoryId: 'sub-1', title: '子分类一'),
    );

    expect(find.text('共 0 件商品'), findsOneWidget);
    expect(find.text('该分类下还没有商品'), findsOneWidget);
    expect(find.text('换个分类看看吧'), findsOneWidget);
    expect(find.byType(HmGoodsCard), findsNothing);
  });

  testWidgets('缺少分类 id 时直接提示且不发请求', (tester) async {
    final adapter = installMock((options) => envelope(categoryGoodsJson()));

    await pumpPage(tester, const GoodsListPage(categoryId: '', title: '商品列表'));

    expect(find.text('分类信息缺失，请返回重新选择'), findsOneWidget);
    expect(adapter.requests, isEmpty);
  });

  testWidgets('分类页点击二级分类跳转到商品列表页', (tester) async {
    installMock((options) {
      final path = options.uri.path;
      if (path.endsWith('/home/category/head')) {
        return envelope([categoryJson()]);
      }
      if (path.endsWith('/home/goods/guessLike')) {
        return envelope({
          'counts': 0,
          'pageSize': 10,
          'pages': 0,
          'page': 1,
          'items': <Map<String, dynamic>>[],
        });
      }
      return envelopeError('未预期的请求: $path');
    });
    final recorder = _RouteRecorder();

    await pumpPage(
      tester,
      const CategoryView(),
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('商品列表占位')),
        settings: settings,
      ),
      observers: [recorder],
    );

    await tester.tap(find.text('子分类一'));
    await tester.pumpAndSettle();

    expect(find.text('商品列表占位'), findsOneWidget);
    expect(
      recorder.pushedNames,
      contains(AppRoutes.goodsList('sub-1', '子分类一')),
    );
  });
}
