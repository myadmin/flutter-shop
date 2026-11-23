import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hm_shop/api/order.dart';
import 'package:hm_shop/components/Order/hm_order_card.dart';
import 'package:hm_shop/components/Order/hm_order_status_tabs.dart';
import 'package:hm_shop/components/common/app_error_view.dart';
import 'package:hm_shop/components/common/hm_bottom_bar.dart';
import 'package:hm_shop/components/common/hm_empty_view.dart';
import 'package:hm_shop/components/common/hm_list_footer.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/order_list.dart';
import 'package:hm_shop/routes/app_routes.dart';
import 'package:hm_shop/stores/user_controller.dart';
import 'package:hm_shop/utils/api_exception.dart';
import 'package:hm_shop/utils/order_actions.dart';
import 'package:hm_shop/utils/paged_list.dart';
import 'package:hm_shop/utils/toast_utils.dart';

/// 我的订单列表页
///
/// 顶部五个状态 tab 对应 `orderState` 筛选（全部 / 待付款 / 待发货 / 待收货 /
/// 待评价），列表分页加载，支持下拉刷新与滚动到底自动加载下一页。
///
/// 接口只提供「查询」与「删除」，支付、取消、确认收货、评价都没有对应接口，
/// 因此除「再次购买」（复用加购接口）外，主操作按钮只给出说明性提示。
class OrderListPage extends StatefulWidget {
  /// 初始选中的状态 tab，来自路由查询串
  final int initialTab;

  const OrderListPage({super.key, this.initialTab = OrderState.all});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  static const int _pageSize = 10;

  final UserController _userController = Get.find<UserController>();
  final ScrollController _scrollController = ScrollController();

  /// 正在删除 / 加购的订单 id，用于禁用重复点击
  final Set<String> _pending = {};

  late int _state = widget.initialTab;

  /// 分页状态机：切 tab 时先 clear 再 refresh，保证展示的是当前筛选的数据
  late final PagedListController<OrderItem> _orders =
      PagedListController<OrderItem>(
        pageSize: _pageSize,
        loader: (int page) async {
          final OrderListResult result = await getOrderListAPI(
            orderState: _state,
            page: page,
            pageSize: _pageSize,
          );
          return PageResult<OrderItem>(
            items: result.items,
            page: result.page,
            hasMore: result.hasMore,
          );
        },
        firstPageErrorFallback: '订单加载失败',
        onLoadMoreError: (String message) {
          if (mounted) ToastUtils.showToast(context, message);
        },
      );

  late final Worker _userWatcher;

  @override
  void initState() {
    super.initState();
    // 登录 / 退出登录后重新拉取，避免展示上一个账号的订单
    _userWatcher = ever(_userController.user, (_) => _syncWithLoginState());
    _scrollController.addListener(_onScroll);
    _syncWithLoginState();
  }

  @override
  void dispose() {
    _userWatcher.dispose();
    _orders.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 未登录时清空列表（页面会切到「登录后查看订单」），登录后重新加载
  void _syncWithLoginState() {
    if (!_userController.isLoggedIn) {
      _orders.clear();
      return;
    }
    _orders.refresh();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final ScrollPosition position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _orders.loadMore();
    }
  }

  void _onStateChanged(int state) {
    if (state == _state) return;
    setState(() {
      _state = state;
    });
    _orders.clear();
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _orders.refresh();
  }

  /// 进入详情页；详情页里删除订单后会回传 `true`，据此刷新列表
  Future<void> _openDetail(OrderItem order) async {
    final bool? changed = await Navigator.pushNamed<bool>(
      context,
      AppRoutes.orderDetail(order.id),
    );
    if (!mounted || changed != true) return;
    await _orders.refresh();
  }

  Future<void> _deleteOrder(OrderItem order) async {
    if (_pending.contains(order.id)) return;

    final bool confirmed = await confirmDeleteOrder(context);
    if (!confirmed || !mounted) return;

    setState(() => _pending.add(order.id));
    try {
      await deleteOrderAPI([order.id]);
      if (!mounted) return;
      _orders.removeWhere((OrderItem item) => item.id == order.id);
      ToastUtils.showToast(context, '订单已删除');
    } catch (e) {
      if (!mounted) return;
      ToastUtils.showToast(context, resolveErrorMessage(e, fallback: '删除订单失败'));
    } finally {
      if (mounted) {
        setState(() => _pending.remove(order.id));
      } else {
        _pending.remove(order.id);
      }
    }
  }

  /// 状态对应的主操作
  ///
  /// 具体行为在 [performOrderPrimaryAction] 里统一实现，订单详情页复用同一套。
  Future<void> _onPrimaryAction(OrderItem order) async {
    if (_pending.contains(order.id)) return;
    await performOrderPrimaryAction(context, order);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 在 Obx 作用域内读一次登录态，登录 / 退出后整页重建
      final bool loggedIn = _userController.isLoggedIn;
      return ListenableBuilder(
        listenable: _orders,
        builder: (BuildContext context, Widget? child) => Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: AppBar(
            title: const Text('我的订单'),
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          body: _buildScaffold(loggedIn),
        ),
      );
    });
  }

  Widget _buildScaffold(bool loggedIn) {
    return Column(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: HmBottomBar.maxContentWidth,
            ),
            child: HmOrderStatusTabs(
              currentState: _state,
              onChanged: _onStateChanged,
            ),
          ),
        ),
        Expanded(child: _buildContent(loggedIn)),
      ],
    );
  }

  Widget _buildContent(bool loggedIn) {
    if (_orders.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!loggedIn) {
      return HmEmptyView(
        icon: Icons.lock_outline,
        title: '登录后查看订单',
        description: '登录即可查看全部订单与物流状态',
        actionText: '去登录',
        onAction: () => Navigator.pushNamed(context, AppRoutes.login),
      );
    }

    if (_orders.errorMessage.isNotEmpty) {
      return AppErrorView(
        message: _orders.errorMessage,
        onRetry: _orders.refresh,
      );
    }

    if (_orders.isEmpty) {
      return HmEmptyView(
        icon: Icons.receipt_long_outlined,
        title: _state == OrderState.all
            ? '还没有订单'
            : '暂无${OrderState.labelOf(_state)}订单',
        description: '去首页挑几件喜欢的商品吧',
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
          onRefresh: _orders.refresh,
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
            itemCount: _orders.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == _orders.length) {
                return HmListFooter(
                  loadingMore: _orders.loadingMore,
                  hasMore: _orders.hasMore,
                  noMoreText: '没有更多订单了',
                );
              }

              final OrderItem order = _orders[index];
              return HmOrderCard(
                order: order,
                onTap: () => _openDetail(order),
                onDelete: _pending.contains(order.id)
                    ? null
                    : () => _deleteOrder(order),
                onPrimaryAction: () => _onPrimaryAction(order),
              );
            },
          ),
        ),
      ),
    );
  }
}
