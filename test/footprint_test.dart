import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hm_shop/components/Footprint/hm_footprint_tile.dart';
import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/models/footprint.dart';
import 'package:hm_shop/models/user.dart';
import 'package:hm_shop/pages/Footprint/index.dart';
import 'package:hm_shop/pages/GoodsDetail/index.dart';
import 'package:hm_shop/pages/Mine/index.dart';
import 'package:hm_shop/pages/Vip/index.dart';
import 'package:hm_shop/stores/cart_controller.dart';
import 'package:hm_shop/stores/footprint_store.dart';
import 'package:hm_shop/stores/user_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

FootprintItem _item({
  String goodsId = 'goods-1',
  String name = '测试商品',
  String price = '89.00',
  DateTime? viewedAt,
}) {
  return FootprintItem(
    goodsId: goodsId,
    name: name,
    picture: '',
    price: price,
    viewedAt: viewedAt ?? DateTime.now(),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('本地足迹存储', () {
    test('写入后可读回，同一商品只保留一条并提到最前', () async {
      await FootprintStore.record(_item(goodsId: 'goods-1', name: '商品一'));
      await FootprintStore.record(_item(goodsId: 'goods-2', name: '商品二'));
      final list = await FootprintStore.record(
        _item(goodsId: 'goods-1', name: '商品一（改名）'),
      );

      expect(list.length, 2);
      expect(list.first.goodsId, 'goods-1');
      expect(list.first.name, '商品一（改名）');
      expect(list.last.goodsId, 'goods-2');
    });

    test('超过上限时丢弃最旧的条目', () async {
      for (var index = 0; index <= FootprintStore.maxItems; index++) {
        await FootprintStore.record(_item(goodsId: 'goods-$index'));
      }
      final list = await FootprintStore.load();

      expect(list.length, FootprintStore.maxItems);
      // 最近写入的排在首位，最早的那条已被挤出
      expect(list.first.goodsId, 'goods-${FootprintStore.maxItems}');
      expect(list.any((item) => item.goodsId == 'goods-0'), isFalse);
    });

    test('clear 清空本机足迹', () async {
      await FootprintStore.record(_item());
      await FootprintStore.clear();

      expect(await FootprintStore.load(), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(GlobalConstants.footprintKey), isNull);
    });

    test('存储内容损坏时按空列表处理', () async {
      SharedPreferences.setMockInitialValues({
        GlobalConstants.footprintKey: '不是 JSON',
      });

      expect(await FootprintStore.load(), isEmpty);
    });
  });

  group('足迹分组', () {
    test('按今天 / 昨天 / 更早切分，空分组不出现', () {
      final now = DateTime(2026, 11, 22, 15, 30);
      final groups = groupFootprints([
        _item(goodsId: 'today', viewedAt: DateTime(2026, 11, 22, 9)),
        _item(goodsId: 'yesterday', viewedAt: DateTime(2026, 11, 21, 20)),
        _item(goodsId: 'earlier', viewedAt: DateTime(2026, 10, 1, 8)),
      ], now: now);

      expect(groups.map((group) => group.title), ['今天', '昨天', '更早']);
      expect(groups.first.items.single.goodsId, 'today');
    });

    test('只有今天的记录时不出现昨天与更早', () {
      final now = DateTime(2026, 11, 22, 15, 30);
      final groups = groupFootprints([
        _item(viewedAt: DateTime(2026, 11, 22, 9)),
      ], now: now);

      expect(groups.map((group) => group.title), ['今天']);
    });
  });

  group('我的足迹页', () {
    Future<void> pumpPage(
      WidgetTester tester,
      Widget page, {
      _RouteRecorder? recorder,
    }) async {
      tester.view.physicalSize = const Size(414, 896);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: page,
          navigatorObservers: [?recorder],
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: SizedBox.shrink()),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
    }

    testWidgets('没有足迹时展示空态，可去逛逛', (tester) async {
      final recorder = _RouteRecorder();
      await pumpPage(tester, const FootprintPage(), recorder: recorder);

      expect(find.text('我的足迹'), findsOneWidget);
      expect(find.text('还没有足迹'), findsOneWidget);
      expect(find.textContaining('足迹仅保存在本机'), findsNothing);

      await tester.tap(find.text('去逛逛'));
      await tester.pumpAndSettle();
      expect(recorder.pushedNames, contains('/'));
    });

    testWidgets('有足迹时按分组展示，点击进入商品详情', (tester) async {
      // 分组依赖「今天 / 昨天 / 更早」，时间点必须相对当前时间算，
      // 写死日期的话测试会在某一天之后失效
      final DateTime now = DateTime.now();
      final DateTime yesterday = DateTime(
        now.year,
        now.month,
        now.day,
        20,
      ).subtract(const Duration(days: 1));
      final DateTime earlier = now.subtract(const Duration(days: 30));
      SharedPreferences.setMockInitialValues({
        GlobalConstants.footprintKey:
            '[{"goodsId":"goods-1","name":"昨天看的商品","picture":"",'
            '"price":"89.00","viewedAt":"${yesterday.toIso8601String()}"},'
            '{"goodsId":"goods-2","name":"更早看的商品","picture":"",'
            '"price":"59.00","viewedAt":"${earlier.toIso8601String()}"}]',
      });
      final recorder = _RouteRecorder();

      await pumpPage(tester, const FootprintPage(), recorder: recorder);

      expect(find.byType(HmFootprintTile), findsNWidgets(2));
      expect(find.text('昨天'), findsOneWidget);
      expect(find.text('更早'), findsOneWidget);
      expect(find.text('￥89.00'), findsOneWidget);
      expect(find.text('20:00 浏览'), findsOneWidget);
      expect(find.textContaining('足迹仅保存在本机'), findsOneWidget);

      await tester.tap(find.text('昨天看的商品'));
      await tester.pumpAndSettle();
      expect(recorder.pushedNames, contains('/goods?id=goods-1'));
    });

    testWidgets('清空需要二次确认，确认后列表回到空态', (tester) async {
      SharedPreferences.setMockInitialValues({
        GlobalConstants.footprintKey:
            '[{"goodsId":"goods-1","name":"测试商品","picture":"",'
            '"price":"89.00","viewedAt":"2026-11-22T10:00:00.000"}]',
      });

      await pumpPage(tester, const FootprintPage());
      expect(find.byType(HmFootprintTile), findsOneWidget);

      await tester.tap(find.text('清空'));
      await tester.pumpAndSettle();
      expect(find.text('清空浏览足迹？'), findsOneWidget);
      // 对话框与 AppBar 各有一个「清空」
      await tester.tap(find.widgetWithText(TextButton, '清空').last);
      await tester.pumpAndSettle();

      expect(find.text('还没有足迹'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(GlobalConstants.footprintKey), isNull);
    });

    testWidgets('商品详情加载成功后写入一条本地足迹', (tester) async {
      Get.reset();
      Get.put(CartController(), permanent: true);
      addTearDown(Get.reset);
      installMock((options) => envelope(goodsDetailJson(skus: [skuJson()])));

      await pumpPage(tester, const GoodsDetailPage(goodsId: 'goods-1'));

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(GlobalConstants.footprintKey) ?? '';
      expect(raw, contains('goods-1'));
    });
  });

  group('会员权益页', () {
    testWidgets('展示四项权益，立即开通给出未开放提示', (tester) async {
      tester.view.physicalSize = const Size(414, 896);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: VipBenefitsPage()));
      await tester.pumpAndSettle();

      expect(find.text('会员权益'), findsOneWidget);
      for (final benefit in VipBenefitsPage.benefits) {
        expect(find.text(benefit.title), findsOneWidget);
      }
      expect(find.text('未开通'), findsOneWidget);
      expect(find.textContaining('尚未接入真实开通流程'), findsOneWidget);

      await tester.tap(find.text('立即开通'));
      await tester.pumpAndSettle();
      expect(find.text('会员开通暂未开放，敬请期待'), findsOneWidget);
    });
  });

  group('「我的」页订单角标', () {
    testWidgets('登录后按状态展示订单数量，为 0 的状态不展示', (tester) async {
      Get.reset();
      final userController = Get.put(UserController(), permanent: true);
      userController.updateUserInfo(UserInfo.fromJson({'id': 'u-1'}));
      addTearDown(Get.reset);

      installMock((options) {
        final path = options.uri.path;
        if (path == HttpConstants.guessList) {
          return envelope(<String, dynamic>{
            'counts': 0,
            'pages': 0,
            'page': 1,
            'items': <dynamic>[],
          });
        }
        if (path == HttpConstants.order) {
          final state = options.uri.queryParameters['orderState'] ?? '';
          final counts = {'1': 2, '2': 3, '3': 0, '4': 4};
          return envelope(orderListJson(counts: counts[state] ?? 0, items: []));
        }
        return envelope(null);
      });

      tester.view.physicalSize = const Size(414, 896);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MineView())),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      // 待付款 2、待发货 3、待评价 4；待收货为 0 不展示数字
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('未登录时不请求订单数量接口', (tester) async {
      Get.reset();
      Get.put(UserController(), permanent: true);
      addTearDown(Get.reset);

      final adapter = installMock((options) {
        if (options.uri.path == HttpConstants.guessList) {
          return envelope(<String, dynamic>{
            'counts': 0,
            'pages': 0,
            'page': 1,
            'items': <dynamic>[],
          });
        }
        return envelope(null);
      });

      tester.view.physicalSize = const Size(414, 896);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MineView())),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      expect(
        adapter
            .requestsWhere('GET')
            .where((options) => options.uri.path == HttpConstants.order),
        isEmpty,
      );
    });
  });
}
