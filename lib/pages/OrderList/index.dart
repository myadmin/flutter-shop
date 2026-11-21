import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hm_shop/api/order.dart';
import 'package:hm_shop/components/Order/hm_order_card.dart';
import 'package:hm_shop/components/Order/hm_order_status_tabs.dart';
import 'package:hm_shop/components/common/app_error_view.dart';
import 'package:hm_shop/components/common/hm_bottom_bar.dart';
import 'package:hm_shop/components/common/hm_empty_view.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/order_list.dart';
import 'package:hm_shop/routes/app_routes.dart';
import 'package:hm_shop/stores/user_controller.dart';
import 'package:hm_shop/utils/api_exception.dart';
import 'package:hm_shop/utils/order_actions.dart';
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

  final List<OrderItem> _items = [];

  /// 正在删除 / 加购的订单 id，用于禁用重复点击
  final Set<String> _pending = {};

  late int _state = widget.initialTab;

  int _page = 1;

  bool _isLoading = true;

  bool _loadingMore = false;

  bool _hasMore = false;

  String _errorMessage = '';

  late final Worker _userWatcher;

  @override
  void initState() {
    super.initState();
    // 登录 / 退出登录后重新拉取，避免展示上一个账号的订单
    _userWatcher = ever(_userController.user, (_) => _load(reset: true));
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _userWatcher.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _load(reset: false);
    }
  }

  /// 拉取订单列表
  ///
  /// [reset] 为 true 时回到第一页并清空旧数据（首次进入、下拉刷新、切换 tab），
  /// 为 false 时追加下一页。
  Future<void> _load({required bool reset}) async {
    if (!_userController.isLoggedIn) {
      if (!mounted) return;
      setState(() {
        _items.clear();
        _isLoading = false;
        _loadingMore = false;
        _hasMore = false;
        _errorMessage = '';
      });
      return;
    }

    if (reset) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    } else {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      final result = await getOrderListAPI(
        orderState: _state,
        page: reset ? 1 : _page + 1,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(result.items);
          _page = 1;
        } else {
          _items.addAll(result.items);
          _page += 1;
        }
        _hasMore = result.hasMore;
        _isLoading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadingMore = false;
        if (reset) _errorMessage = resolveErrorMessage(e, fallback: '订单加载失败');
      });
      if (!reset) {
        ToastUtils.showToast(
          context,
          resolveErrorMessage(e, fallback: '加载更多失败'),
        );
      }
    }
  }

  void _onStateChanged(int state) {
    if (state == _state) return;
    setState(() {
      _state = state;
      _items.clear();
      _hasMore = false;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _load(reset: true);
  }

  /// 进入详情页；详情页里删除订单后会回传 `true`，据此刷新列表
  Future<void> _openDetail(OrderItem order) async {
    final changed = await Navigator.pushNamed<bool>(
      context,
      AppRoutes.orderDetail(order.id),
    );
    if (!mounted || changed != true) return;
    await _load(reset: true);
  }

  Future<void> _deleteOrder(OrderItem order) async {
    if (_pending.contains(order.id)) return;

    final confirmed = await confirmDeleteOrder(context);
    if (!confirmed || !mounted) return;

    setState(() => _pending.add(order.id));
    try {
      await deleteOrderAPI([order.id]);
      if (!mounted) return;
      setState(() => _items.removeWhere((item) => item.id == order.id));
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
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('我的订单'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Obx(() => _buildScaffold(_userController.isLoggedIn)),
    );
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
    if (_isLoading) {
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

    if (_errorMessage.isNotEmpty) {
      return AppErrorView(
        message: _errorMessage,
        onRetry: () => _load(reset: true),
      );
    }

    if (_items.isEmpty) {
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
          onRefresh: () => _load(reset: true),
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
            itemCount: _items.length + 1,
            itemBuilder: (context, index) {
              if (index == _items.length) return _buildFooter();

              final order = _items[index];
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

  Widget _buildFooter() {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_hasMore) return const SizedBox(height: 8);

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(
          '没有更多订单了',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
