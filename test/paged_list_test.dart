import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hm_shop/components/common/hm_list_footer.dart';
import 'package:hm_shop/utils/paged_list.dart';

/// 造一个可控的 loader：记录每次请求的页码，按 [pages] 返回对应数据
class _FakeLoader {
  _FakeLoader({required this.pages, this.failOn = const <int>{}});

  /// 页码 -> 该页数据
  final Map<int, List<int>> pages;

  /// 需要抛错的页码
  final Set<int> failOn;

  final List<int> requestedPages = [];

  Future<PageResult<int>> call(int page) async {
    requestedPages.add(page);
    if (failOn.contains(page)) {
      throw Exception('第 $page 页加载失败');
    }
    final List<int> items = pages[page] ?? const <int>[];
    return PageResult<int>(
      items: items,
      page: page,
      hasMore: pages.containsKey(page + 1),
    );
  }
}

void main() {
  group('PagedListController', () {
    test('首次加载写入数据与分页状态', () async {
      final _FakeLoader loader = _FakeLoader(
        pages: {
          1: [1, 2],
          2: [3, 4],
        },
      );
      final PagedListController<int> controller = PagedListController<int>(
        pageSize: 2,
        loader: loader.call,
      );
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(controller.items, [1, 2]);
      expect(controller.isLoading, isFalse);
      expect(controller.hasMore, isTrue);
      expect(controller.errorMessage, isEmpty);
      expect(loader.requestedPages, [1]);
    });

    test('加载更多追加下一页，没有下一页后不再请求', () async {
      final _FakeLoader loader = _FakeLoader(
        pages: {
          1: [1, 2],
          2: [3],
        },
      );
      final PagedListController<int> controller = PagedListController<int>(
        pageSize: 2,
        loader: loader.call,
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.loadMore();
      expect(controller.items, [1, 2, 3]);
      expect(controller.hasMore, isFalse);

      // 已经没有下一页，再触发也不会发请求
      await controller.loadMore();
      expect(loader.requestedPages, [1, 2]);
    });

    test('列表为空时不会去请求第二页', () async {
      final _FakeLoader loader = _FakeLoader(pages: {1: const <int>[]});
      final PagedListController<int> controller = PagedListController<int>(
        pageSize: 2,
        loader: loader.call,
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.loadMore();

      expect(controller.items, isEmpty);
      expect(loader.requestedPages, [1]);
    });

    test('首页失败写入错误文案，加载更多失败只回调不清列表', () async {
      final _FakeLoader loader = _FakeLoader(
        pages: {
          1: [1, 2],
          2: [3],
        },
        failOn: {2},
      );
      final List<String> loadMoreErrors = <String>[];
      final PagedListController<int> controller = PagedListController<int>(
        pageSize: 2,
        loader: loader.call,
        onLoadMoreError: loadMoreErrors.add,
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.loadMore();

      expect(loadMoreErrors, hasLength(1));
      expect(loadMoreErrors.single, contains('加载更多失败'));
      expect(controller.items, [1, 2], reason: '加载更多失败不应清掉已有数据');
      expect(controller.errorMessage, isEmpty);
    });

    test('首页失败展示错误文案', () async {
      final _FakeLoader loader = _FakeLoader(
        pages: {
          1: [1, 2],
        },
        failOn: {1},
      );
      final PagedListController<int> controller = PagedListController<int>(
        pageSize: 2,
        loader: loader.call,
        firstPageErrorFallback: '订单加载失败',
      );
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(controller.items, isEmpty);
      expect(controller.errorMessage, contains('订单加载失败'));
      expect(controller.isLoading, isFalse);
    });

    test('clear 清空数据并复位分页状态', () async {
      final _FakeLoader loader = _FakeLoader(
        pages: {
          1: [1, 2],
          2: [3],
        },
      );
      final PagedListController<int> controller = PagedListController<int>(
        pageSize: 2,
        loader: loader.call,
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.loadMore();
      controller.clear();

      expect(controller.items, isEmpty);
      expect(controller.isEmpty, isTrue);
      expect(controller.hasMore, isTrue);
      expect(controller.errorMessage, isEmpty);
    });

    test('removeWhere 本地移除并通知监听者', () async {
      final _FakeLoader loader = _FakeLoader(
        pages: {
          1: [1, 2, 3],
        },
      );
      final PagedListController<int> controller = PagedListController<int>(
        pageSize: 3,
        loader: loader.call,
      );
      addTearDown(controller.dispose);
      await controller.refresh();

      int notified = 0;
      controller.addListener(() => notified++);
      controller.removeWhere((int item) => item == 2);

      expect(controller.items, [1, 3]);
      expect(notified, 1);
    });
  });

  group('HmListFooter', () {
    testWidgets('加载更多时展示小转圈', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HmListFooter(loadingMore: true, hasMore: true)),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('没有更多时展示提示文案', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HmListFooter(
              loadingMore: false,
              hasMore: false,
              noMoreText: '没有更多收藏了',
            ),
          ),
        ),
      );

      expect(find.text('没有更多收藏了'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
