import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hm_shop/components/common/app_error_view.dart';
import 'package:hm_shop/components/Home/hm_brand_strip.dart';
import 'package:hm_shop/components/Home/hm_new_goods.dart';
import 'package:hm_shop/components/Home/hm_rank_list.dart';
import 'package:hm_shop/models/brand.dart';
import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/pages/Brand/index.dart';
import 'package:hm_shop/pages/Home/index.dart';

import 'helpers/mock_http.dart';

/// 记录被压栈的路由名，用于断言跳转目标
class _RouteRecorder extends NavigatorObserver {
  final List<String?> pushedNames = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedNames.add(route.settings.name);
    super.didPush(route, previousRoute);
  }
}

/// 首页会用到的接口；[withModules] 为 false 时新品 / 榜单 / 品牌返回空
ResponseBody Function(RequestOptions) _response({bool withModules = true}) {
  return (RequestOptions options) {
    switch (options.path) {
      case '/home/banner':
        return envelope([
          {'id': 'banner-1', 'imgUrl': ''},
        ]);
      case '/home/category/head':
        return envelope([categoryJson(name: '居家')]);
      case '/hot/preference':
      case '/hot/inVogue':
      case '/hot/oneStop':
        return envelope({
          'id': 'module-1',
          'title': '专题',
          'subTypes': <dynamic>[],
        });
      case '/home/recommend':
        return envelope([goodsItemJson()]);
      case '/home/new':
        return withModules
            ? envelope([
                goodsItemJson(id: 'new-1', name: '新品一'),
                goodsItemJson(id: 'new-2', name: '新品二'),
              ])
            : envelope(<dynamic>[]);
      case '/hot/new':
        return withModules
            ? envelope(
                hotResultJson(
                  items: [
                    goodsItemJson(id: 'rank-1', name: '榜单商品一'),
                    goodsItemJson(id: 'rank-2', name: '榜单商品二'),
                  ],
                ),
              )
            : envelope({
                'id': 'rank-1',
                'title': '新鲜好物',
                'subTypes': <dynamic>[],
              });
      case '/home/brand':
        return withModules
            ? envelope([
                brandItemJson(),
                brandItemJson(id: 'brand-2', name: '第二品牌'),
              ])
            : envelope(<dynamic>[]);
      default:
        return envelope(null);
    }
  };
}

/// 轮播图带自动播放，`pumpAndSettle` 等不到静止，手动推进几帧
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

GoodsItem _goods(String id, String name) {
  return GoodsItem(
    id: id,
    name: name,
    price: '69.90',
    picture: '',
    orderNum: 12,
  );
}

void main() {
  group('新品首发', () {
    testWidgets('展示商品名、价格与销量，点击回调拿到商品', (tester) async {
      final tapped = <GoodsItem>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HmNewGoods(
              goodsList: [_goods('new-1', '新品一'), _goods('new-2', '新品二')],
              onGoodsTap: tapped.add,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('新品首发'), findsOneWidget);
      expect(find.text('新品一'), findsOneWidget);
      expect(find.text('￥69.90'), findsNWidgets(2));
      expect(find.text('已售12'), findsNWidgets(2));

      await tester.tap(find.text('新品一'));
      await tester.pump();

      expect(tapped.single.id, 'new-1');
    });

    testWidgets('没有商品时整块不渲染', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HmNewGoods(goodsList: [])),
        ),
      );

      expect(find.text('新品首发'), findsNothing);
    });
  });

  group('人气好物榜', () {
    testWidgets('按名次展示商品，点击回调拿到商品', (tester) async {
      final tapped = <GoodsItem>[];
      final result = SpecialRecommendResult.fromJson(
        hotResultJson(
          items: [
            goodsItemJson(id: 'rank-1', name: '榜单商品一'),
            goodsItemJson(id: 'rank-2', name: '榜单商品二'),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HmRankList(result: result, onGoodsTap: tapped.add),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('人气好物榜'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('榜单商品一'), findsOneWidget);

      await tester.tap(find.text('榜单商品一'));
      await tester.pump();

      expect(tapped.single.id, 'rank-1');
    });

    testWidgets('没有子分类时整块不渲染', (tester) async {
      final result = SpecialRecommendResult.fromJson({
        'id': 'rank-1',
        'title': '新鲜好物',
        'subTypes': <dynamic>[],
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HmRankList(result: result)),
        ),
      );

      expect(find.text('人气好物榜'), findsNothing);
    });
  });

  group('品牌好店', () {
    testWidgets('展示品牌名，点击回调拿到品牌', (tester) async {
      final tapped = <BrandItem>[];
      final brands = [
        BrandItem.fromJson(brandItemJson()),
        BrandItem.fromJson(brandItemJson(id: 'brand-2', name: '第二品牌')),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HmBrandStrip(brandList: brands, onBrandTap: tapped.add),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('品牌好店'), findsOneWidget);
      expect(find.text('测试品牌'), findsOneWidget);

      await tester.tap(find.text('测试品牌'));
      await tester.pump();

      expect(tapped.single.id, 'brand-1');
    });

    testWidgets('没有品牌时整块不渲染', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HmBrandStrip(brandList: [])),
        ),
      );

      expect(find.text('品牌好店'), findsNothing);
    });
  });

  group('首页接入新模块', () {
    testWidgets('三个模块排在推荐列表之上，点品牌卡进品牌详情', (tester) async {
      final adapter = installMock(_response());
      final recorder = _RouteRecorder();

      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(body: HomeView()),
          navigatorObservers: [recorder],
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: SizedBox.shrink()),
          ),
        ),
      );
      await _settle(tester);

      // 新品 / 榜单 / 品牌各请求一次
      expect(
        adapter.requests.where((option) => option.path == '/home/new'),
        hasLength(1),
      );
      expect(
        adapter.requests.where((option) => option.path == '/home/brand'),
        hasLength(1),
      );

      // 三个模块在首屏之下，按顺序滚到各自位置再断言
      final scrollable = find.byType(Scrollable).first;
      for (final title in ['新品首发', '人气好物榜', '品牌好店']) {
        await tester.scrollUntilVisible(
          find.text(title),
          200,
          scrollable: scrollable,
        );
        expect(find.text(title), findsOneWidget);
      }

      await tester.scrollUntilVisible(
        find.text('测试品牌'),
        100,
        scrollable: scrollable,
      );
      await tester.tap(find.text('测试品牌'));
      await _settle(tester);

      expect(recorder.pushedNames, contains('/brand?id=brand-1'));
    });

    testWidgets('三个接口都失败时首页仍正常展示首屏内容', (tester) async {
      installMock(_response(withModules: false));

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomeView())),
      );
      await _settle(tester);

      expect(find.byType(AppErrorView), findsNothing);
      expect(find.text('特惠推荐'), findsOneWidget);
      expect(find.text('新品首发'), findsNothing);
      expect(find.text('品牌好店'), findsNothing);
    });
  });

  group('品牌详情页', () {
    testWidgets('展示品牌名、产地、口号与品牌故事', (tester) async {
      installMock((options) {
        if (options.path == '/brand/brand-1') {
          return envelope(brandDetailJson());
        }
        return envelope(null);
      });

      await tester.pumpWidget(
        const MaterialApp(home: BrandPage(brandId: 'brand-1')),
      );
      await _settle(tester);

      expect(find.text('品牌详情'), findsOneWidget);
      expect(find.text('测试品牌'), findsOneWidget);
      expect(find.text('产地：中国'), findsOneWidget);
      expect(find.text('为热爱而造'), findsOneWidget);
      expect(find.text('品牌故事正文'), findsOneWidget);
    });

    testWidgets('缺少品牌 id 时给出提示且不发请求', (tester) async {
      final adapter = installMock(_response());

      await tester.pumpWidget(const MaterialApp(home: BrandPage(brandId: '')));
      await tester.pump();

      expect(find.text('品牌信息缺失，请返回重新进入'), findsOneWidget);
      expect(adapter.requests, isEmpty);
    });

    testWidgets('加载失败展示错误态，重试后恢复', (tester) async {
      var fail = true;
      var callCount = 0;
      installMock((options) {
        if (options.path != '/brand/brand-1') {
          return envelope(null);
        }
        callCount++;
        return fail ? envelopeError('品牌服务异常') : envelope(brandDetailJson());
      });

      await tester.pumpWidget(
        const MaterialApp(home: BrandPage(brandId: 'brand-1')),
      );
      await _settle(tester);

      expect(find.text('品牌服务异常'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('重新加载'));
      await _settle(tester);

      expect(callCount, 2);
      expect(find.text('测试品牌'), findsOneWidget);
    });
  });
}
