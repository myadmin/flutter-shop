import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hm_shop/api/cart.dart';
import 'package:hm_shop/components/Cart/hm_cart_empty.dart';
import 'package:hm_shop/components/Cart/hm_cart_summary_bar.dart';
import 'package:hm_shop/components/Cart/hm_cart_tile.dart';
import 'package:hm_shop/components/common/app_error_view.dart';
import 'package:hm_shop/components/common/hm_bottom_bar.dart';
import 'package:hm_shop/constants/app_text_styles.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/cart.dart';
import 'package:hm_shop/routes/app_routes.dart';
import 'package:hm_shop/stores/cart_controller.dart';
import 'package:hm_shop/stores/user_controller.dart';
import 'package:hm_shop/utils/api_exception.dart';
import 'package:hm_shop/utils/money.dart';
import 'package:hm_shop/utils/toast_utils.dart';

/// 购物车页
///
/// 交互约定：
/// - 勾选、改数量、删除都会立刻请求接口，界面先乐观更新，失败时回滚并提示；
/// - 「全选」按条目逐个请求（接口没有批量选中接口），条数少、串行执行即可；
/// - 结算跳转沿用「立即购买」链路，接口只支持单件商品结算，
///   因此勾选多件时给出提示而不是拼一个不存在的多商品订单。
class CartView extends StatefulWidget {
  /// 当前 tab 是否是购物车；从其它 tab 切回来时重新拉取，保证数据新鲜
  final bool isActive;

  /// 购物车为空时「去逛逛」的动作，由外层切换 tab 实现
  final VoidCallback onGoShopping;

  const CartView({
    super.key,
    required this.isActive,
    required this.onGoShopping,
  });

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  final UserController _userController = Get.find<UserController>();
  final CartController _cartController = Get.find<CartController>();

  final List<CartItem> _items = [];

  /// 有请求在途的规格 id，用于禁用单个条目的交互
  final Set<String> _pending = {};

  bool _isLoading = true;

  String _errorMessage = '';

  /// 全选/批量操作在途
  bool _allBusy = false;

  /// 在途的列表请求，用于合并并发调用
  Future<void>? _loadingFuture;

  late final Worker _userWatcher;

  @override
  void initState() {
    super.initState();
    // 登录 / 退出登录后自动重新拉取，避免展示上一个账号的数据
    _userWatcher = ever(_userController.user, (_) => _loadCart());
    _loadCart();
  }

  @override
  void didUpdateWidget(CartView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _loadCart();
    }
  }

  @override
  void dispose() {
    _userWatcher.dispose();
    super.dispose();
  }

  /// 参与结算的条目（已勾选且有效）
  List<CartItem> get _selectedItems =>
      _items.where((item) => item.isCheckoutSelected).toList();

  /// 有效商品是否全部勾选
  bool get _allSelected {
    final effective = _items.where((item) => item.isEffective).toList();
    if (effective.isEmpty) return false;
    return effective.every((item) => item.selected);
  }

  /// 合计金额（不含运费）
  ///
  /// 以「分」为单位做整数累加，避免多条商品浮点相加后差一分。
  String get _totalAmount {
    final totalCents = _selectedItems.fold<int>(
      0,
      (sum, item) => sum + item.nowPriceCents * item.count,
    );
    return formatCents(totalCents);
  }

  /// 购物车商品总件数
  int get _totalCount => _items.fold<int>(0, (sum, item) => sum + item.count);

  /// 拉取购物车列表
  ///
  /// 初始化、切回购物车 tab、登录态变化都会触发；并发时复用同一个在途请求，
  /// 避免同时对 `/member/cart` 发车。
  Future<void> _loadCart() {
    return _loadingFuture ??= _doLoadCart().whenComplete(() {
      _loadingFuture = null;
    });
  }

  Future<void> _doLoadCart() async {
    if (!_userController.isLoggedIn) {
      if (!mounted) return;
      setState(() {
        _items.clear();
        _isLoading = false;
        _errorMessage = '';
      });
      _cartController.clear();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final items = await getCartListAPI();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _isLoading = false;
      });
      _cartController.setCount(_totalCount);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = resolveErrorMessage(e, fallback: '购物车加载失败');
      });
    }
  }

  /// 用接口返回的最新条目替换本地同规格数据
  void _replaceItem(CartItem updated) {
    final index = _items.indexWhere((item) => item.skuId == updated.skuId);
    if (index >= 0) _items[index] = updated;
  }

  Future<void> _toggleSelected(CartItem item, bool selected) async {
    if (_pending.contains(item.skuId)) return;
    final original = item;
    setState(() {
      _replaceItem(item.copyWith(selected: selected));
      _pending.add(item.skuId);
    });

    try {
      final updated = await updateCartItemAPI(item.skuId, selected: selected);
      if (!mounted) return;
      setState(() => _replaceItem(updated));
    } catch (e) {
      if (!mounted) return;
      setState(() => _replaceItem(original));
      ToastUtils.showToast(
        context,
        resolveErrorMessage(e, fallback: '修改选中状态失败'),
      );
    } finally {
      if (mounted) {
        setState(() => _pending.remove(item.skuId));
      } else {
        _pending.remove(item.skuId);
      }
    }
  }

  Future<void> _changeCount(CartItem item, int count) async {
    if (_pending.contains(item.skuId)) return;
    if (count < 1 || count > item.stock) return;

    final original = item;
    setState(() {
      _replaceItem(item.copyWith(count: count));
      _pending.add(item.skuId);
    });

    try {
      final updated = await updateCartItemAPI(item.skuId, count: count);
      if (!mounted) return;
      setState(() => _replaceItem(updated));
      _cartController.setCount(_totalCount);
    } catch (e) {
      if (!mounted) return;
      setState(() => _replaceItem(original));
      ToastUtils.showToast(
        context,
        resolveErrorMessage(e, fallback: '修改商品数量失败'),
      );
    } finally {
      if (mounted) {
        setState(() => _pending.remove(item.skuId));
      } else {
        _pending.remove(item.skuId);
      }
    }
  }

  Future<void> _deleteItem(CartItem item) async {
    if (_pending.contains(item.skuId)) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text('确定要删除这件商品吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _pending.add(item.skuId));
    try {
      await deleteCartItemsAPI([item.skuId]);
      if (!mounted) return;
      setState(() => _items.removeWhere((e) => e.skuId == item.skuId));
      _cartController.setCount(_totalCount);
      ToastUtils.showToast(context, '已删除');
    } catch (e) {
      if (!mounted) return;
      ToastUtils.showToast(context, resolveErrorMessage(e, fallback: '删除商品失败'));
    } finally {
      if (mounted) {
        setState(() => _pending.remove(item.skuId));
      } else {
        _pending.remove(item.skuId);
      }
    }
  }

  Future<void> _toggleAll(bool selected) async {
    if (_allBusy) return;
    final targets = _items
        .where((item) => item.isEffective && item.selected != selected)
        .toList();
    if (targets.isEmpty) return;

    setState(() => _allBusy = true);
    try {
      // 接口没有批量接口，按条目串行提交，避免并发写同一条购物车记录
      for (final item in targets) {
        final updated = await updateCartItemAPI(item.skuId, selected: selected);
        if (!mounted) return;
        setState(() => _replaceItem(updated));
      }
    } catch (e) {
      if (!mounted) return;
      ToastUtils.showToast(
        context,
        resolveErrorMessage(e, fallback: '批量修改选中状态失败'),
      );
      await _loadCart();
    } finally {
      if (mounted) setState(() => _allBusy = false);
    }
  }

  void _checkout() {
    final selected = _selectedItems;
    if (selected.isEmpty) {
      ToastUtils.showToast(context, '请选择要结算的商品');
      return;
    }
    if (selected.length > 1) {
      ToastUtils.showToast(context, '演示接口仅支持单件商品结算，请只勾选一件');
      return;
    }
    final item = selected.first;
    Navigator.pushNamed(
      context,
      AppRoutes.orderConfirm(item.skuId, item.count),
    );
  }

  /// 点击条目进入商品详情页
  ///
  /// 失效商品（下架 / 无货）没有可展示的详情，只给一句提示；
  /// 从详情页返回后刷新一次购物车，避免加购、库存变化后列表还是旧的。
  Future<void> _openGoodsDetail(CartItem item) async {
    if (!item.isEffective) {
      ToastUtils.showToast(context, '商品已失效，无法查看详情');
      return;
    }
    if (item.id.isEmpty) {
      ToastUtils.showToast(context, '商品信息缺失，请稍后重试');
      return;
    }
    await Navigator.pushNamed(context, AppRoutes.goods(item.id));
    if (!mounted) return;
    await _loadCart();
  }

  @override
  Widget build(BuildContext context) {
    // 登录态变化（含 401 失效）时自动重绘为空购物车 / 未登录态
    return Obx(() => _buildScaffold(_userController.isLoggedIn));
  }

  Widget _buildScaffold(bool loggedIn) {
    return Container(
      color: AppColors.pageBackground,
      child: Column(
        children: [
          _buildHeader(loggedIn),
          Expanded(child: _buildContent(loggedIn)),
          if (loggedIn &&
              !_isLoading &&
              _errorMessage.isEmpty &&
              _items.isNotEmpty)
            HmCartSummaryBar(
              allSelected: _allSelected,
              onAllSelectedChanged: _toggleAll,
              selectedCount: _selectedItems.length,
              totalAmount: _totalAmount,
              onCheckout: _checkout,
              busy: _allBusy,
            ),
        ],
      ),
    );
  }

  /// 宽屏下把正文收窄到与底部结算栏一致的内容宽度，避免条目被拉得过长
  Widget _buildHeader(bool loggedIn) {
    return Container(
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: HmBottomBar.maxContentWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                const Text(
                  '购物车',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                if (loggedIn && _items.isNotEmpty)
                  Text('共 $_totalCount 件', style: AppTextStyles.caption),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool loggedIn) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!loggedIn) {
      return HmCartEmpty(
        icon: Icons.lock_outline,
        title: '登录后查看购物车',
        description: '登录即可同步购物车里的商品与选中状态',
        actionText: '去登录',
        onAction: () => Navigator.pushNamed(context, AppRoutes.login),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return AppErrorView(message: _errorMessage, onRetry: _loadCart);
    }

    if (_items.isEmpty) {
      return HmCartEmpty(
        icon: Icons.shopping_cart_outlined,
        title: '购物车还是空的',
        description: '挑几件喜欢的商品放进来吧',
        actionText: '去逛逛',
        onAction: widget.onGoShopping,
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: HmBottomBar.maxContentWidth,
        ),
        child: RefreshIndicator(
          onRefresh: _loadCart,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            itemCount: _items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = _items[index];
              return HmCartTile(
                item: item,
                busy: _pending.contains(item.skuId),
                onTap: () => _openGoodsDetail(item),
                onSelectedChanged: (value) => _toggleSelected(item, value),
                onCountChanged: (count) => _changeCount(item, count),
                onDelete: () => _deleteItem(item),
              );
            },
          ),
        ),
      ),
    );
  }
}
