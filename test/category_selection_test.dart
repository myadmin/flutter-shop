import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hm_shop/components/Category/hm_category_rail.dart';
import 'package:hm_shop/components/Home/hm_category.dart';
import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/pages/Category/index.dart';
import 'package:hm_shop/pages/Home/index.dart';
import 'package:hm_shop/pages/Main/index.dart';
import 'package:hm_shop/stores/cart_controller.dart';
import 'package:hm_shop/stores/user_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/mock_http.dart';

/// 一个一级分类，二级分类名字由调用方指定，便于断言「右侧切换到了哪一类」
Map<String, dynamic> _category(
  String id,
  String name,
  List<String> childNames,
) {
  return {
    'id': id,
    'name': name,
    'picture': '',
    'children': <Map<String, dynamic>>[
      for (int index = 0; index < childNames.length; index++)
        {'id': '$id-sub-$index', 'name': childNames[index], 'picture': ''},
    ],
  };
}

List<Map<String, dynamic>> _categories() => [
  _category('c1', '居家', ['床品', '收纳']),
  _category('c2', '美食', ['零食', '生鲜']),
  _category('c3', '服饰', ['男装', '女装']),
];

/// 分类页 / 首页 / 「我的」页会用到的接口
ResponseBody _response(RequestOptions options) {
  switch (options.path) {
    case '/home/category/head':
      return envelope(_categories());
    case '/home/banner':
      return envelope([
        {'id': 'banner-1', 'imgUrl': ''},
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
}

/// 轮播图带自动播放，`pumpAndSettle` 等不到静止，手动推进几帧
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _pumpCategory(
  WidgetTester tester, {
  String? selectedCategoryId,
  int ticket = 0,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CategoryView(
          selectedCategoryId: selectedCategoryId,
          selectionTicket: ticket,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 读左侧导航当前选中的下标
int _selectedRailIndex(WidgetTester tester) {
  return tester
      .widget<HmCategoryRail>(find.byType(HmCategoryRail))
      .selectedIndex;
}

void main() {
  testWidgets('首页分类项可点击，并把被点的分类抛给回调', (tester) async {
    CategoryItem? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HmCategory(
            categoryList: [
              for (final json in _categories()) CategoryItem.fromJson(json),
            ],
            onCategoryTap: (CategoryItem item) => tapped = item,
          ),
        ),
      ),
    );

    await tester.tap(find.text('美食'));
    await tester.pump();

    expect(tapped?.id, 'c2');
    expect(tapped?.name, '美食');
  });

  testWidgets('未传回调时分类项点击不报错', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HmCategory(
            categoryList: [
              for (final json in _categories()) CategoryItem.fromJson(json),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('美食'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  group('分类页支持外部指定选中项', () {
    testWidgets('不传选中项时默认落在第一个分类', (tester) async {
      installMock(_response);
      await _pumpCategory(tester);

      expect(_selectedRailIndex(tester), 0);
      expect(find.text('床品'), findsOneWidget);
    });

    testWidgets('传入分类 id 时首屏就选中该分类', (tester) async {
      installMock(_response);
      await _pumpCategory(tester, selectedCategoryId: 'c2', ticket: 1);

      expect(_selectedRailIndex(tester), 1);
      // 右侧面板换成「美食」的二级分类
      expect(find.text('零食'), findsOneWidget);
      expect(find.text('床品'), findsNothing);
    });

    testWidgets('再次传入同一个分类也会重新应用', (tester) async {
      installMock(_response);
      await _pumpCategory(tester, selectedCategoryId: 'c2', ticket: 1);
      expect(_selectedRailIndex(tester), 1);

      // 模拟用户手动切回第一个分类
      await tester.tap(find.text('居家'));
      await tester.pumpAndSettle();
      expect(_selectedRailIndex(tester), 0);

      // 首页再次点「美食」：id 没变，只有版本号变了
      await _pumpCategory(tester, selectedCategoryId: 'c2', ticket: 2);
      expect(_selectedRailIndex(tester), 1);
      expect(find.text('零食'), findsOneWidget);
    });

    testWidgets('传入不存在的分类 id 时保持默认选中项', (tester) async {
      installMock(_response);
      await _pumpCategory(tester, selectedCategoryId: 'not-exist', ticket: 1);

      expect(_selectedRailIndex(tester), 0);
      expect(find.text('床品'), findsOneWidget);
    });
  });

  testWidgets('首页点分类会切到「分类」tab 并选中同一分类', (tester) async {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.put(UserController(), permanent: true);
    Get.put(CartController(), permanent: true);
    addTearDown(Get.reset);
    installMock(_response);

    await tester.pumpWidget(const MaterialApp(home: MainPage()));
    await _settle(tester);

    // 首页顶部那排分类里的「美食」
    await tester.tap(
      find.descendant(of: find.byType(HmCategory), matching: find.text('美食')),
    );
    await _settle(tester);

    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      1,
    );
    expect(_selectedRailIndex(tester), 1);
    expect(find.text('零食'), findsOneWidget);
  });

  testWidgets('首页没接回调时点分类不会切 tab', (tester) async {
    installMock(_response);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomeView())),
    );
    await _settle(tester);

    await tester.tap(find.text('美食'));
    await _settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });
}
