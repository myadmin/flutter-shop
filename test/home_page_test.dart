import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hm_shop/components/common/app_error_view.dart';
import 'package:hm_shop/pages/Home/index.dart';
import 'package:hm_shop/pages/Home/skeleton.dart';

import 'helpers/mock_http.dart';

/// 首页六个接口的默认 mock 响应
ResponseBody _homeResponse(RequestOptions options) {
  switch (options.path) {
    case '/home/banner':
      return envelope([
        {'imgUrl': 'banner-1.png'},
        {'imgUrl': 'banner-2.png'},
      ]);
    case '/home/category/head':
      return envelope([
        categoryJson(name: '居家'),
        categoryJson(id: 'c2', name: '美食'),
      ]);
    case '/hot/preference':
    case '/hot/inVogue':
    case '/hot/oneStop':
      return envelope({
        'id': 'module-1',
        'title': '专题',
        'subTypes': [
          {
            'id': 'sub-1',
            'title': '子类',
            'goodsItems': {
              'page': 1,
              'pages': 1,
              'pageSize': 2,
              'counts': 2,
              'items': [goodsItemJson()],
            },
          },
        ],
      });
    case '/home/recommend':
      return envelope([
        goodsItemJson(),
        goodsItemJson(id: 'goods-2', name: '推荐商品二'),
      ]);
    case '/home/new':
      return envelope([goodsItemJson(id: 'new-1', name: '新品一')]);
    case '/hot/new':
      return envelope(hotResultJson());
    case '/home/brand':
      return envelope([brandItemJson()]);
    default:
      return envelope(null);
  }
}

/// 轮播图带自动播放，`pumpAndSettle` 会一直等不到静止，这里手动推进几帧
///
/// 多推几帧是为了让「首屏出图后再补三个模块」的第二批请求也跑完
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

Future<void> _pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: HomeView())));
}

void main() {
  group('首页数据加载', () {
    testWidgets('首屏并发拉取六个接口，加载完成后替换骨架屏', (tester) async {
      final adapter = installMock(_homeResponse);

      await _pumpHome(tester);
      // 请求还没回来时展示骨架屏
      expect(find.byType(HomeSkeleton), findsOneWidget);

      await _settle(tester);

      expect(find.byType(HomeSkeleton), findsNothing);
      expect(find.byType(AppErrorView), findsNothing);
      // 首屏 6 个接口 + 首屏出图后补的 5 个（新品 / 榜单 / 品牌 / 专题 / 楼层）
      expect(adapter.requests.length, 11);
      expect(
        adapter.requests.where((option) => option.path == '/home/recommend'),
        hasLength(1),
      );
      // 推荐接口只传 limit，不传 page/pageSize
      final recommendOption = adapter.requests.firstWhere(
        (option) => option.path == '/home/recommend',
      );
      expect(recommendOption.queryParameters['limit'], 10);
      expect(recommendOption.queryParameters.containsKey('page'), isFalse);
    });

    testWidgets('单个模块失败不影响整页展示', (tester) async {
      installMock((options) {
        if (options.path == '/home/banner') {
          return envelopeError('轮播图服务异常');
        }
        return _homeResponse(options);
      });

      await _pumpHome(tester);
      await _settle(tester);

      // 只有轮播图失败，其余模块正常渲染，不应该显示整页错误
      expect(find.byType(AppErrorView), findsNothing);
      expect(find.byType(HomeSkeleton), findsNothing);
      expect(find.text('特惠推荐'), findsOneWidget);
    });

    testWidgets('全部模块失败展示整页错误态，重试会重新拉取', (tester) async {
      var failAll = true;
      final adapter = installMock((options) {
        if (failAll) {
          return envelopeError('服务不可用');
        }
        return _homeResponse(options);
      });

      await _pumpHome(tester);
      await _settle(tester);

      expect(find.byType(AppErrorView), findsOneWidget);
      expect(find.text('服务不可用'), findsOneWidget);
      expect(find.text('重新加载'), findsOneWidget);
      final firstRound = adapter.requests.length;
      expect(firstRound, 6);

      failAll = false;
      await tester.tap(find.text('重新加载'));
      await _settle(tester);

      expect(adapter.requests.length, greaterThan(firstRound));
      expect(find.byType(AppErrorView), findsNothing);
      expect(find.text('特惠推荐'), findsOneWidget);
    });
  });
}
