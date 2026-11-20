import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hm_shop/api/mine.dart';
import 'package:hm_shop/components/Home/hm_more_list.dart';
import 'package:hm_shop/components/Mine/hm_guess.dart';
import 'package:hm_shop/components/Mine/hm_mine_header.dart';
import 'package:hm_shop/components/Mine/hm_mine_order_module.dart';
import 'package:hm_shop/components/Mine/hm_mine_quick_actions.dart';
import 'package:hm_shop/components/Mine/hm_mine_vip_card.dart';
import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/stores/token_manager.dart';
import 'package:hm_shop/stores/user_controller.dart';
import 'package:hm_shop/utils/toast_utils.dart';

/// 「我的」页面
///
/// 组合用户信息头部、会员卡、快捷入口、订单管理与「猜你喜欢」列表；
/// 用户信息来自全局 `UserController`，列表数据由本页自身的 `setState` 管理。
class MineView extends StatefulWidget {
  const MineView({super.key});

  @override
  State<MineView> createState() => _MineViewState();
}

class _MineViewState extends State<MineView> {
  static const int _pageSize = 10;

  final UserController _userController = Get.find();
  final ScrollController _controller = ScrollController();

  final List<GoodDetailItem> _list = [];

  /// 用强类型字段保存分页下标，避免对 Map 取值做 dynamic 比较
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _getGuessList();
    _registerEvent();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 尚未开放的功能统一给出提示，避免点击后毫无反馈
  void _showComingSoon(String feature) {
    ToastUtils.showToast(context, '$feature功能开发中，敬请期待');
  }

  /// 二次确认后清除本地 token 与内存登录态
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('确认退出登录吗？'),
          content: const Text('退出登录后将无法继续使用'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    await tokenManager.removeToken();
    _userController.clearUserInfo();
  }

  /// 滚动到底部时加载下一页
  void _registerEvent() {
    _controller.addListener(() {
      if (_controller.position.pixels >=
          _controller.position.maxScrollExtent - 50) {
        _getGuessList();
      }
    });
  }

  Future<void> _getGuessList() async {
    if (_isLoading || !_hasMore) {
      return;
    }
    _isLoading = true;
    try {
      final res = await getGuessListAPI({'page': _page, 'pageSize': _pageSize});
      if (!mounted) return;
      // 列表与分页状态都在 setState 内更新，保证一帧内完成并触发重建
      setState(() {
        _list.addAll(res.items);
        if (_page >= res.pages) {
          _hasMore = false;
        } else {
          _page++;
        }
      });
    } catch (e) {
      debugPrint('获取猜你喜欢列表失败: $e');
    } finally {
      _isLoading = false;
    }
  }

  void _onGoodsTap(GoodDetailItem goods) {
    Navigator.pushNamed(context, '/goods', arguments: goods.id);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _controller,
      slivers: [
        SliverToBoxAdapter(
          child: Obx(
            () => HmMineHeader(
              user: _userController.user.value,
              onLoginTap: () => Navigator.pushNamed(context, '/login'),
              onLogoutTap: _confirmLogout,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: HmMineVipCard(onOpenTap: () => _showComingSoon('会员开通')),
        ),
        SliverToBoxAdapter(
          child: HmMineQuickActions(onEntryTap: _showComingSoon),
        ),
        SliverToBoxAdapter(
          child: HmMineOrderModule(onEntryTap: _showComingSoon),
        ),
        const SliverPersistentHeader(pinned: true, delegate: HmGuess()),
        HmMoreList(recommendList: _list, onItemTap: _onGoodsTap),
      ],
    );
  }
}
