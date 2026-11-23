import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:hm_shop/utils/api_exception.dart';

/// 分页接口返回的一页数据
///
/// 各接口的返回结构不同（`OrderListResult` / `CollectListResult` / `GoodsDetailsItems`），
/// 由调用方在 loader 里转换成本类型，状态机只关心「这一页有哪些数据、还有没有下一页」。
@immutable
class PageResult<T> {
  const PageResult({
    required this.items,
    required this.page,
    required this.hasMore,
  });

  /// 本页数据
  final List<T> items;

  /// 本页页码（部分接口会回传当前页码，缺省时用请求的页码）
  final int page;

  /// 是否还有下一页
  final bool hasMore;
}

/// 分页列表状态机
///
/// 把「首次加载 / 下拉刷新 / 上拉加载更多」三件事的 `isLoading`、`loadingMore`、
/// `hasMore`、`errorMessage` 收敛到一处，页面只负责给 loader 和渲染列表。
///
/// 约定：
/// - [refresh] 回到第一页并覆盖数据，已有内容时不再显示整页转圈（交给 RefreshIndicator）；
/// - [loadMore] 追加下一页，重复触发由内部状态挡掉，列表为空时不会去请求第二页；
/// - 首页失败写 [errorMessage] 供页面展示错误态，加载更多失败只回调 [onLoadMoreError]
///   （页面通常弹 toast），不会清掉已有列表。
class PagedListController<T> extends ChangeNotifier {
  PagedListController({
    required this.pageSize,
    required this.loader,
    this.firstPageErrorFallback = '加载失败',
    this.loadMoreErrorFallback = '加载更多失败',
    this.onLoadMoreError,
  });

  /// 每页条数，由页面传给接口
  final int pageSize;

  /// 取第 page 页数据
  final Future<PageResult<T>> Function(int page) loader;

  /// 首页失败时的兜底文案
  final String firstPageErrorFallback;

  /// 加载更多失败时的兜底文案
  final String loadMoreErrorFallback;

  /// 加载更多失败的回调（参数已转成可直接展示的文案）
  final ValueChanged<String>? onLoadMoreError;

  final List<T> _items = <T>[];

  int _page = 1;
  bool _isLoading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String _errorMessage = '';
  bool _disposed = false;

  /// 已加载的数据（只读）
  List<T> get items => UnmodifiableListView<T>(_items);

  int get length => _items.length;

  T operator [](int index) => _items[index];

  /// 是否正在加载第一页（列表已有内容时为 false，下拉刷新用自带的转圈）
  bool get isLoading => _isLoading;

  /// 是否正在加载下一页
  bool get loadingMore => _loadingMore;

  /// 是否还有下一页
  bool get hasMore => _hasMore;

  /// 首页加载失败的错误文案，空串表示没有错误
  String get errorMessage => _errorMessage;

  bool get isEmpty => _items.isEmpty;

  /// 首次进入、下拉刷新、切换筛选条件时调用
  Future<void> refresh() async {
    if (_disposed) return;
    _isLoading = _items.isEmpty;
    _loadingMore = false;
    _errorMessage = '';
    _hasMore = true;
    notifyListeners();
    await _fetch(page: 1, reset: true);
  }

  /// 滚动到底部时调用
  Future<void> loadMore() async {
    if (_disposed ||
        _isLoading ||
        _loadingMore ||
        !_hasMore ||
        _items.isEmpty) {
      return;
    }
    _loadingMore = true;
    notifyListeners();
    await _fetch(page: _page + 1, reset: false);
  }

  /// 本地移除若干条（例如删除订单后同步列表，不重新请求）
  void removeWhere(bool Function(T item) test) {
    if (_disposed) return;
    final int before = _items.length;
    _items.removeWhere(test);
    if (_items.length != before) notifyListeners();
  }

  /// 清空列表与状态（退出登录、切换筛选条件后重新加载前调用）
  void clear() {
    if (_disposed) return;
    _items.clear();
    _page = 1;
    _isLoading = false;
    _loadingMore = false;
    _hasMore = true;
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> _fetch({required int page, required bool reset}) async {
    try {
      final PageResult<T> result = await loader(page);
      if (_disposed) return;
      if (reset) {
        _items
          ..clear()
          ..addAll(result.items);
      } else {
        _items.addAll(result.items);
      }
      _page = result.page > 0 ? result.page : page;
      _hasMore = result.hasMore && result.items.isNotEmpty;
    } catch (error) {
      if (_disposed) return;
      final String message = resolveErrorMessage(
        error,
        fallback: reset ? firstPageErrorFallback : loadMoreErrorFallback,
      );
      if (reset) {
        _errorMessage = message;
      } else {
        onLoadMoreError?.call(message);
      }
    } finally {
      if (!_disposed) {
        _isLoading = false;
        _loadingMore = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
