import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hm_shop/components/Category/hm_category_rail.dart';
import 'package:hm_shop/components/Home/hm_slider.dart';
import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/pages/Home/index.dart';
import 'package:hm_shop/pages/Main/index.dart';
import 'package:hm_shop/stores/cart_controller.dart';
import 'package:hm_shop/stores/user_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/mock_http.dart';

/// 首页 / 分类 / 「我的」会用到的接口
///
/// [bannerHref] 为 true 时下发的 banner 带跳转信息，否则模拟后端没配 hrefUrl。
ResponseBody Function(RequestOptions) _response({bool bannerHref = true}) {
  return (RequestOptions options) {
    switch (options.path) {
      case '/home/banner':
        return envelope(
          bannerHref
              ? [
                  {
                    'id': 'banner-c',
                    'imgUrl': '',
                    'hrefUrl': '/category/c2',
                    'type': '1',
                  },
                  {
                    'id': 'banner-g',
                    'imgUrl': '',
                    'hrefUrl': '/goods/goods-9',
                    'type': '2',
                  },
                ]
              : [
                  {'id': 'banner-empty', 'imgUrl': ''},
                ],
        );
      case '/home/category/head':
        return envelope([
          {
            'id': 'c1',
            'name': '居家',
            'picture': '',
            'children': [
              {'id': 'c1-sub-0', 'name': '床品', 'picture': ''},
            ],
          },
          {
            'id': 'c2',
            'name': '美食',
            'picture': '',
            'children': [
              {'id': 'c2-sub-0', 'name': '零食', 'picture': ''},
            ],
          },
        ]);
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
      case '/home/goods/guessLike':
      case '/member/order':
        return envelope({
          'counts': 0,
          'pages': 0,
          'page': 1,
          'pageSize': 10,
          'items': <dynamic>[],
        });
      default:
        return envelope(null);
    }
  };
}

/// 轮播图带自动播放，`pumpAndSettle` 等不到静止，手动推进几帧
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// 点轮播图中间位置（避开顶部搜索框与底部指示点）
Future<void> _tapBanner(WidgetTester tester) async {
  // 图片用的是空 URL，占位块要到下一帧才有尺寸，先推进几帧再点，
  // 否则第一帧点下去命中不到 GestureDetector
  await _settle(tester);
  await tester.tapAt(tester.getCenter(find.byType(HmSlider)));
  await _settle(tester);
}

void main() {
  group('BannerItem 跳转信息解析', () {
    test('分类 banner 取 hrefUrl 里的分类 id', () {
      final banner = BannerItem.fromJson({
        'id': '1',
        'imgUrl': '',
        'hrefUrl': '/category/1181622006',
        'type': '1',
      });

      expect(banner.categoryId, '1181622006');
      expect(banner.goodsId, isNull);
    });

    test('商品 banner 取 hrefUrl 里的商品 id', () {
      final banner = BannerItem.fromJson({
        'id': '2',
        'imgUrl': '',
        'hrefUrl': '/goods/1602922',
        'type': '2',
      });

      expect(banner.goodsId, '1602922');
      expect(banner.categoryId, isNull);
    });

    test('外部链接与缺失 hrefUrl 都解析不出目标', () {
      final external = BannerItem.fromJson({
        'id': '3',
        'imgUrl': '',
        'hrefUrl': 'https://example.com/act',
        'type': '3',
      });
      final empty = BannerItem.fromJson({'id': '4', 'imgUrl': ''});

      expect(external.categoryId, isNull);
      expect(external.goodsId, isNull);
      expect(empty.categoryId, isNull);
      expect(empty.goodsId, isNull);
    });
  });

  testWidgets('点轮播图会把当前这张抛给回调', (tester) async {
    final tapped = <BannerItem>[];
    final banners = [
      BannerItem(id: 'b1', imageUrl: '', hrefUrl: '/category/c1', type: '1'),
      BannerItem(id: 'b2', imageUrl: '', hrefUrl: '/category/c2', type: '1'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          // 轮播固定 300 高；这里给个高度约束，否则 Stack 会撑满整屏、
          // 组件中心落到图片下方，点击就打不中
          body: SizedBox(
            height: 300,
            child: HmSlider(
              bannerList: banners,
              autoPlay: false,
              onBannerTap: tapped.add,
            ),
          ),
        ),
      ),
    );

    await _tapBanner(tester);

    expect(tapped, hasLength(1));
    expect(tapped.single.id, 'b1');
  });

  testWidgets('首页点带跳转信息的 banner 交给外层处理', (tester) async {
    installMock(_response());
    final tapped = <BannerItem>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HomeView(onBannerTap: tapped.add)),
      ),
    );
    await _settle(tester);

    await _tapBanner(tester);

    expect(tapped, hasLength(1));
    expect(tapped.single.categoryId, 'c2');
  });

  testWidgets('banner 没有跳转信息时给提示，不交给外层', (tester) async {
    installMock(_response(bannerHref: false));
    final tapped = <BannerItem>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HomeView(onBannerTap: tapped.add)),
      ),
    );
    await _settle(tester);

    await _tapBanner(tester);

    expect(tapped, isEmpty);
    expect(find.text('该活动暂未开放，敬请期待'), findsOneWidget);
  });

  testWidgets('首页点分类 banner 会切到「分类」tab 并选中该分类', (tester) async {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.put(UserController(), permanent: true);
    Get.put(CartController(), permanent: true);
    addTearDown(Get.reset);
    installMock(_response());

    await tester.pumpWidget(const MaterialApp(home: MainPage()));
    await _settle(tester);

    await _tapBanner(tester);

    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      1,
    );
    expect(
      tester.widget<HmCategoryRail>(find.byType(HmCategoryRail)).selectedIndex,
      1,
    );
  });
}
