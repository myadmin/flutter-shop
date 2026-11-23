import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hm_shop/api/collect.dart';
import 'package:hm_shop/components/Collect/hm_collect_tile.dart';
import 'package:hm_shop/components/common/app_error_view.dart';
import 'package:hm_shop/components/common/hm_bottom_bar.dart';
import 'package:hm_shop/components/common/hm_empty_view.dart';
import 'package:hm_shop/components/common/hm_list_footer.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/collect.dart';
import 'package:hm_shop/routes/app_routes.dart';
import 'package:hm_shop/stores/user_controller.dart';
import 'package:hm_shop/utils/paged_list.dart';
import 'package:hm_shop/utils/toast_utils.dart';

/// 我的收藏
///
/// 接口只支持读取（`collectType` 必填，收藏与取消收藏的入参未公开），所以这里
/// 只做浏览：分页加载、点击进入商品详情、未登录与空态提示；登录态变化时自动重载。
class CollectPage extends StatefulWidget {
  const CollectPage({super.key});

  @override
  State<CollectPage> createState() => _CollectPageState();
}

class _CollectPageState extends State<CollectPage> {
  static const int _pageSize = 10;
  static const int _collectType = 1;

  final UserController _userController = Get.find<UserController>();
  final ScrollController _scrollController = ScrollController();

  /// 分页状态机：加载中 / 加载更多 / 无更多 / 错误都由它维护
  late final PagedListController<CollectItem> _collect =
      PagedListController<CollectItem>(
        pageSize: _pageSize,
        loader: (int page) async {
          final CollectListResult result = await getCollectListAPI(
            collectType: _collectType,
            page: page,
            pageSize: _pageSize,
          );
          return PageResult<CollectItem>(
            items: result.items,
            page: result.page,
            hasMore: result.hasMore,
          );
        },
        firstPageErrorFallback: '收藏列表加载失败',
        onLoadMoreError: (String message) {
          if (mounted) ToastUtils.showToast(context, message);
        },
      );

  late final Worker _userWatcher;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 登录 / 退出登录后重新拉取，避免展示上一个账号的收藏
    _userWatcher = ever(_userController.user, (_) => _syncWithLoginState());
    _syncWithLoginState();
  }

  @override
  void dispose() {
    _userWatcher.dispose();
    _collect.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 未登录时清空列表（页面会切到「登录后查看收藏」），登录后重新加载
  void _syncWithLoginState() {
    if (!_userController.isLoggedIn) {
      _collect.clear();
      return;
    }
    _collect.refresh();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final ScrollPosition position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _collect.loadMore();
    }
  }

  void _openGoods(CollectItem item) {
    Navigator.pushNamed(context, AppRoutes.goods(item.goodsId));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 在 Obx 作用域内读一次登录态，登录 / 退出后整页重建
      final bool loggedIn = _userController.isLoggedIn;
      return ListenableBuilder(
        listenable: _collect,
        builder: (BuildContext context, Widget? child) => Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: AppBar(
            title: const Text('我的收藏'),
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          body: _buildBody(loggedIn),
        ),
      );
    });
  }

  Widget _buildBody(bool loggedIn) {
    if (_collect.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!loggedIn) {
      return HmEmptyView(
        icon: Icons.lock_outline,
        title: '登录后查看收藏',
        description: '登录即可查看收藏的商品',
        actionText: '去登录',
        onAction: () => Navigator.pushNamed(context, AppRoutes.login),
      );
    }
    if (_collect.errorMessage.isNotEmpty) {
      return AppErrorView(
        message: _collect.errorMessage,
        onRetry: _collect.refresh,
      );
    }
    if (_collect.isEmpty) {
      return HmEmptyView(
        icon: Icons.favorite_border,
        title: '还没有收藏',
        description: '看到喜欢的商品，收藏起来下次好找',
        actionText: '去逛逛',
        onAction: () => Navigator.pushNamed(context, AppRoutes.home),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: HmBottomBar.maxContentWidth,
        ),
        child: RefreshIndicator(
          onRefresh: _collect.refresh,
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
            itemCount: _collect.length + 1,
            separatorBuilder: (BuildContext context, int index) =>
                index < _collect.length - 1
                ? const SizedBox(height: 10)
                : const SizedBox.shrink(),
            itemBuilder: (BuildContext context, int index) {
              if (index == _collect.length) {
                return HmListFooter(
                  loadingMore: _collect.loadingMore,
                  hasMore: _collect.hasMore,
                  noMoreText: '没有更多收藏了',
                );
              }
              final CollectItem item = _collect[index];
              return HmCollectTile(
                item: item,
                onTap: item.canOpenGoods ? () => _openGoods(item) : null,
              );
            },
          ),
        ),
      ),
    );
  }
}
