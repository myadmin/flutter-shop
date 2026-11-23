import 'package:carousel_slider/carousel_slider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hm_shop/models/user.dart';
import 'package:hm_shop/pages/Main/index.dart';
import 'package:hm_shop/stores/cart_controller.dart';
import 'package:hm_shop/stores/user_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/mock_http.dart';

/// 底部 tab 容器会用到的接口；其余一律返回空 result
ResponseBody _response(RequestOptions options) {
  switch (options.path) {
    case '/home/banner':
      return envelope([
        {'id': 'banner-1', 'imgUrl': ''},
      ]);
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
    case '/home/new':
      return envelope(<dynamic>[]);
    case '/hot/new':
      return envelope({
        'id': 'rank-1',
        'title': '新鲜好物',
        'subTypes': <dynamic>[],
      });
    case '/home/brand':
      return envelope(<dynamic>[]);
    case '/home/goods/guessLike':
      return envelope({
        'counts': 0,
        'pages': 0,
        'page': 1,
        'pageSize': 10,
        'items': <dynamic>[],
      });
    case '/member/order':
      return envelope({
        'counts': 2,
        'pages': 1,
        'page': 1,
        'items': <dynamic>[],
      });
    default:
      return envelope(null);
  }
}

/// 轮播图带自动播放，`pumpAndSettle` 等不到静止，手动推进几帧
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// 准备全局控制器与 mock 适配器（未登录状态）
MockAdapter _boot() {
  SharedPreferences.setMockInitialValues({});
  Get.reset();
  Get.put(UserController(), permanent: true);
  Get.put(CartController(), permanent: true);
  addTearDown(Get.reset);
  return installMock(_response);
}

/// 点底部 tab（用底部导航栏里的文案定位，避免和页面内的同名文字冲突）
Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text(label),
    ),
  );
}

/// 某个接口被请求了多少次
int _count(MockAdapter mock, String path) {
  return mock.requests
      .where((RequestOptions option) => option.path == path)
      .length;
}

void main() {
  testWidgets('启动时只加载首页，其它 tab 不构建也不发请求', (tester) async {
    final MockAdapter mock = _boot();

    await tester.pumpWidget(const MaterialApp(home: MainPage()));
    await _settle(tester);

    // 首页自己的 9 个请求：首屏 6 个（轮播 / 分类 / 特惠 / 爆款 / 一站 / 推荐）
    // + 首屏出图后补的 3 个（新品 / 榜单 / 品牌）
    expect(mock.requests.length, 9);
    expect(_count(mock, '/home/banner'), 1);
    expect(_count(mock, '/home/recommend'), 1);
    // 分类页（会再拉一次 /home/category/head）与「我的」页都还没构建
    expect(_count(mock, '/home/goods/guessLike'), 0);
    expect(_count(mock, '/member/order'), 0);
  });

  testWidgets('切到「分类」tab 后才加载分类页数据', (tester) async {
    final MockAdapter mock = _boot();

    await tester.pumpWidget(const MaterialApp(home: MainPage()));
    await _settle(tester);

    await _tapTab(tester, '分类');
    await _settle(tester);

    // 首页一次 + 分类页一次
    expect(_count(mock, '/home/category/head'), 2);
    // 分类页底部推荐位
    expect(_count(mock, '/home/goods/guessLike'), 1);
    expect(find.text('床品'), findsOneWidget);
  });

  testWidgets('切到「我的」tab 后才加载订单角标与猜你喜欢', (tester) async {
    final MockAdapter mock = _boot();
    // 订单角标只在登录态才查；这里直接塞用户信息（不写 token，避免多出购物车件数请求）
    Get.find<UserController>().updateUserInfo(
      UserInfo.fromJson({'id': 'u-1', 'nickname': '晚星12'}),
    );

    await tester.pumpWidget(const MaterialApp(home: MainPage()));
    await _settle(tester);
    // 还没点「我的」，四个角标查询一次都不该发
    expect(_count(mock, '/member/order'), 0);

    await _tapTab(tester, '我的');
    await _settle(tester);

    // 待付款 / 待发货 / 待收货 / 待评价 各查一次数量
    expect(_count(mock, '/member/order'), 4);
    expect(_count(mock, '/home/goods/guessLike'), 1);
  });

  testWidgets('来回切 tab 不会重新加载首页数据', (tester) async {
    final MockAdapter mock = _boot();

    await tester.pumpWidget(const MaterialApp(home: MainPage()));
    await _settle(tester);

    await _tapTab(tester, '分类');
    await _settle(tester);
    await _tapTab(tester, '首页');
    await _settle(tester);

    // IndexedStack 保活：首页只加载过一次
    expect(_count(mock, '/home/banner'), 1);
    expect(_count(mock, '/home/recommend'), 1);
  });

  testWidgets('首页轮播在切到其它 tab 后暂停，回到首页再继续', (tester) async {
    _boot();

    await tester.pumpWidget(const MaterialApp(home: MainPage()));
    await _settle(tester);

    bool autoPlay() {
      // 首页切走后被 IndexedStack 放到 offstage，查找时要显式带上 skipOffstage: false
      return tester
          .widget<CarouselSlider>(
            find.byType(CarouselSlider, skipOffstage: false),
          )
          .options
          .autoPlay;
    }

    expect(autoPlay(), isTrue);

    await _tapTab(tester, '购物车');
    await _settle(tester);
    expect(autoPlay(), isFalse);

    await _tapTab(tester, '首页');
    await _settle(tester);
    expect(autoPlay(), isTrue);
  });
}
