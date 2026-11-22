import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hm_shop/api/collect.dart';
import 'package:hm_shop/components/Collect/hm_collect_tile.dart';
import 'package:hm_shop/components/common/app_error_view.dart';
import 'package:hm_shop/components/common/hm_bottom_bar.dart';
import 'package:hm_shop/components/common/hm_empty_view.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/collect.dart';
import 'package:hm_shop/routes/app_routes.dart';
import 'package:hm_shop/stores/user_controller.dart';
import 'package:hm_shop/utils/api_exception.dart';
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

  final UserController _userController = Get.find();
  final ScrollController _scrollController = ScrollController();
  final List<CollectItem> _items = [];

  int _page = 1;
  bool _isLoading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    ever(_userController.user, (_) => _load(reset: true));
    _load(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _load(reset: false);
    }
  }

  /// 取收藏列表：`reset` 为 true 时回到第一页并覆盖，否则追加下一页
  Future<void> _load({required bool reset}) async {
    if (!_userController.isLoggedIn) {
      if (!mounted) return;
      setState(() {
        _items.clear();
        _isLoading = false;
        _hasMore = false;
      });
      return;
    }
    if (reset) {
      setState(() {
        _isLoading = _items.isEmpty;
        _errorMessage = '';
        _hasMore = true;
      });
    } else {
      if (_isLoading || _loadingMore || !_hasMore) return;
      _loadingMore = true;
    }
    try {
      final result = await getCollectListAPI(
        collectType: _collectType,
        page: reset ? 1 : _page + 1,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(result.items);
        } else {
          _items.addAll(result.items);
        }
        _page = result.page;
        _hasMore = result.hasMore && result.items.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('获取收藏列表失败: $e');
      if (!mounted) return;
      final message = resolveErrorMessage(e, fallback: '收藏列表加载失败');
      if (reset) {
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
      } else {
        ToastUtils.showToast(context, message);
      }
    } finally {
      if (mounted) {
        _loadingMore = false;
      }
    }
  }

  void _openGoods(CollectItem item) {
    Navigator.pushNamed(context, AppRoutes.goods(item.goodsId));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: AppBar(
          title: const Text('我的收藏'),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: _buildBody(_userController.isLoggedIn),
      ),
    );
  }

  Widget _buildBody(bool loggedIn) {
    if (_isLoading) {
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
    if (_errorMessage.isNotEmpty) {
      return AppErrorView(
        message: _errorMessage,
        onRetry: () => _load(reset: true),
      );
    }
    if (_items.isEmpty) {
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
          onRefresh: () => _load(reset: true),
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
            itemCount: _items.length + 1,
            separatorBuilder: (_, index) => index < _items.length - 1
                ? const SizedBox(height: 10)
                : const SizedBox.shrink(),
            itemBuilder: (context, index) {
              if (index == _items.length) {
                return _buildFooter();
              }
              final item = _items[index];
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

  Widget _buildFooter() {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_hasMore) {
      return const SizedBox(height: 8);
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(
          '没有更多收藏了',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
