import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hm_shop/components/Collect/hm_collect_tile.dart';
import 'package:hm_shop/components/common/app_error_view.dart';
import 'package:hm_shop/models/user.dart';
import 'package:hm_shop/pages/Collect/index.dart';
import 'package:hm_shop/pages/CustomerService/index.dart';
import 'package:hm_shop/pages/Mine/index.dart';
import 'package:hm_shop/stores/user_controller.dart';

import 'helpers/mock_http.dart';

/// 记录 `Navigator.pushNamed` 的目标，用于断言「点了之后去哪」
class _RouteRecorder extends NavigatorObserver {
  final List<String> pushedNames = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedNames.add(route.settings.name ?? '');
    super.didPush(route, previousRoute);
  }
}

/// 我的收藏页、客服中心页与「我的」页快捷入口的接线
void main() {
  late UserController userController;

  setUp(() {
    Get.reset();
    userController = Get.put(UserController(), permanent: true);
  });

  tearDown(Get.reset);

  void login() {
    userController.updateUserInfo(
      UserInfo.fromJson({'id': 'u-1', 'nickname': '晚星12'}),
    );
  }

  Future<void> pumpPage(
    WidgetTester tester,
    Widget page, {
    _RouteRecorder? recorder,
    bool scaffold = false,
  }) async {
    tester.view.physicalSize = const Size(414, 896);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        // 「我的」页是纯 sliver 列表，真实场景挂在 Main 的 Scaffold 里；
        // 单独测它时需要自己补一层 Scaffold（toast 也依赖 Scaffold）
        home: scaffold ? Scaffold(body: page) : page,
        navigatorObservers: [?recorder],
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
  }

  group('我的收藏页', () {
    testWidgets('加载成功展示收藏项，请求带 collectType', (tester) async {
      login();
      final adapter = installMock((options) => envelope(collectListJson()));
      final recorder = _RouteRecorder();

      await pumpPage(tester, const CollectPage(), recorder: recorder);

      expect(find.text('我的收藏'), findsOneWidget);
      expect(find.byType(HmCollectTile), findsOneWidget);
      expect(find.text('测试收藏商品'), findsOneWidget);
      expect(find.text('￥59.00'), findsOneWidget);
      expect(find.text('收藏于 2026-11-20 09:00:00'), findsOneWidget);
      // 只有一页时展示结束提示
      expect(find.text('没有更多收藏了'), findsOneWidget);
      expect(find.byType(AppErrorView), findsNothing);

      final query = adapter.requests.single.uri.queryParameters;
      expect(query['collectType'], '1');
      expect(query['page'], '1');
      expect(query['pageSize'], '10');

      // 点击收藏项进入商品详情
      await tester.tap(find.byType(HmCollectTile));
      await tester.pumpAndSettle();
      expect(recorder.pushedNames, contains('/goods?id=goods-1'));
    });

    testWidgets('字段全空的收藏项降级展示，不出现 ￥0.00', (tester) async {
      login();
      installMock(
        (options) => envelope(
          collectListJson(
            items: [
              collectItemJson(
                id: 'collect-2',
                goodsId: '',
                name: '',
                price: '0.00',
                createTime: '',
              ),
            ],
          ),
        ),
      );

      await pumpPage(tester, const CollectPage());

      expect(find.text('商品信息已失效'), findsOneWidget);
      expect(find.text('￥0.00'), findsNothing);
      expect(find.textContaining('收藏于'), findsNothing);
    });

    testWidgets('未登录时提示登录且不发请求', (tester) async {
      final adapter = installMock((options) => envelope(collectListJson()));
      final recorder = _RouteRecorder();

      await pumpPage(tester, const CollectPage(), recorder: recorder);

      expect(find.text('登录后查看收藏'), findsOneWidget);
      expect(find.byType(HmCollectTile), findsNothing);
      expect(adapter.requests, isEmpty);

      await tester.tap(find.text('去登录'));
      await tester.pumpAndSettle();
      expect(recorder.pushedNames, contains('/login'));
    });

    testWidgets('空收藏展示引导文案并可去逛逛', (tester) async {
      login();
      installMock(
        (options) => envelope(
          collectListJson(counts: 0, pages: 0, items: <Map<String, dynamic>>[]),
        ),
      );
      final recorder = _RouteRecorder();

      await pumpPage(tester, const CollectPage(), recorder: recorder);

      expect(find.text('还没有收藏'), findsOneWidget);
      expect(find.byType(HmCollectTile), findsNothing);

      await tester.tap(find.text('去逛逛'));
      await tester.pumpAndSettle();
      expect(recorder.pushedNames, contains('/'));
    });

    testWidgets('加载失败展示错误视图，重试后恢复', (tester) async {
      login();
      var callCount = 0;
      installMock((options) {
        callCount++;
        return callCount == 1
            ? envelopeError('收藏服务异常')
            : envelope(collectListJson());
      });

      await pumpPage(tester, const CollectPage());

      expect(find.byType(AppErrorView), findsOneWidget);
      expect(find.text('收藏服务异常'), findsOneWidget);

      await tester.tap(find.text('重新加载'));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      expect(find.byType(AppErrorView), findsNothing);
      expect(find.byType(HmCollectTile), findsOneWidget);
      expect(callCount, 2);
    });
  });

  group('客服中心页', () {
    testWidgets('展示服务时间、联系方式与常见问题', (tester) async {
      await pumpPage(tester, const CustomerServicePage());

      expect(find.text('客服中心'), findsOneWidget);
      expect(find.text('在线客服'), findsOneWidget);
      expect(find.text(CustomerServicePage.serviceTime), findsOneWidget);
      expect(find.text(CustomerServicePage.hotline), findsOneWidget);
      expect(find.text(CustomerServicePage.email), findsOneWidget);
      for (final faq in CustomerServicePage.faqs) {
        expect(find.text(faq.question), findsOneWidget);
      }
    });

    testWidgets('点击常见问题展开回答', (tester) async {
      await pumpPage(tester, const CustomerServicePage());

      // 未展开时不显示回答
      expect(find.textContaining('签收后 7 天内'), findsNothing);

      await tester.tap(find.text('如何申请退换货？'));
      await tester.pumpAndSettle();

      expect(find.textContaining('签收后 7 天内'), findsOneWidget);
    });

    testWidgets('在线客服入口给出演示提示', (tester) async {
      await pumpPage(tester, const CustomerServicePage());

      await tester.tap(find.text('联系客服'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('演示接口未提供在线客服'), findsOneWidget);
    });
  });

  group('我的页快捷入口', () {
    /// 「猜你喜欢」返回空页，避免干扰入口断言
    Map<String, dynamic> emptyGuess() => {
      'counts': 0,
      'pages': 0,
      'page': 1,
      'items': <Map<String, dynamic>>[],
    };

    testWidgets('已登录点击「我的收藏」进入收藏页', (tester) async {
      login();
      installMock((options) => envelope(emptyGuess()));
      final recorder = _RouteRecorder();

      await pumpPage(
        tester,
        const MineView(),
        scaffold: true,
        recorder: recorder,
      );
      await tester.tap(find.text('我的收藏'));
      await tester.pumpAndSettle();

      expect(recorder.pushedNames, contains('/collect'));
    });

    testWidgets('未登录点击「我的收藏」先跳登录页', (tester) async {
      installMock((options) => envelope(emptyGuess()));
      final recorder = _RouteRecorder();

      await pumpPage(
        tester,
        const MineView(),
        scaffold: true,
        recorder: recorder,
      );
      await tester.tap(find.text('我的收藏'));
      await tester.pumpAndSettle();

      expect(recorder.pushedNames, contains('/login'));
      expect(recorder.pushedNames, isNot(contains('/collect')));
    });

    testWidgets('点击「我的客服」进入客服中心', (tester) async {
      installMock((options) => envelope(emptyGuess()));
      final recorder = _RouteRecorder();

      await pumpPage(
        tester,
        const MineView(),
        scaffold: true,
        recorder: recorder,
      );
      await tester.tap(find.text('我的客服'));
      await tester.pumpAndSettle();

      expect(recorder.pushedNames, contains('/customer-service'));
    });
  });
}
