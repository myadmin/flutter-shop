import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:hm_shop/api/mine.dart';
import 'package:hm_shop/components/Home/hm_more_list.dart';
import 'package:hm_shop/components/Mine/hm_entry_item.dart';
import 'package:hm_shop/components/Mine/hm_guess.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/stores/token_manager.dart';
import 'package:hm_shop/stores/user_controller.dart';
import 'package:hm_shop/utils/toast_utils.dart';

class MineView extends StatefulWidget {
  const MineView({super.key});

  @override
  State<MineView> createState() => _MineViewState();
}

class _MineViewState extends State<MineView> {
  final UserController _userController = Get.find();

  Widget _getLogout() {
    return _userController.user.value.isLoggedIn
        ? GestureDetector(
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    title: const Text("确认退出登录吗？"),
                    content: const Text("退出登录后将无法继续使用"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        child: const Text("取消"),
                      ),
                      TextButton(
                        onPressed: () async {
                          // 先关闭确认弹窗，再清除本地 token 与内存登录态
                          Navigator.pop(dialogContext);
                          await tokenManager.removeToken();
                          _userController.clearUserInfo();
                        },
                        child: const Text("确认"),
                      ),
                    ],
                  );
                },
              );
            },
            child: const Text(
              "退出",
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  /// 尚未开放的功能统一给出提示，避免点击后毫无反馈。
  void _showComingSoon(String feature) {
    ToastUtils.showToast(context, '$feature功能开发中，敬请期待');
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primarySurface, AppColors.headerGradientEnd],
        ),
      ),
      padding: const EdgeInsets.only(left: 20, right: 40, top: 40, bottom: 20),
      child: Row(
        children: [
          Obx(() {
            return CircleAvatar(
              radius: 26,
              backgroundImage: _userController.user.value.avatar.isNotEmpty
                  ? NetworkImage(_userController.user.value.avatar)
                  : const AssetImage("lib/assets/goods_avatar.png"),
              backgroundColor: Colors.white,
            );
          }),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  return GestureDetector(
                    onTap: () {
                      if (!_userController.user.value.isLoggedIn) {
                        Navigator.pushNamed(context, '/login');
                      }
                    },
                    child: Text(
                      _userController.user.value.isLoggedIn
                          ? (_userController.user.value.nickname.isNotEmpty
                                ? _userController.user.value.nickname
                                : _userController.user.value.account)
                          : "立即登录",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          Obx(() => _getLogout()),
        ],
      ),
    );
  }

  Widget _buildVipCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.vipBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        child: Row(
          children: [
            Image.asset("lib/assets/ic_user_vip.png", width: 30, height: 30),
            const SizedBox(width: 10),
            const Expanded(
              // 按可用宽度等比缩小，保证各类机型下文案都只占一行
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '升级美荟商城会员，尊享无限免邮',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.vipForeground,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => _showComingSoon('会员开通'),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.vipForeground,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('立即开通', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            HmEntryItem(
              icon: "lib/assets/ic_user_collect.png",
              label: "我的收藏",
              onTap: () => _showComingSoon('我的收藏'),
            ),
            HmEntryItem(
              icon: "lib/assets/ic_user_history.png",
              label: "我的足迹",
              onTap: () => _showComingSoon('我的足迹'),
            ),
            HmEntryItem(
              icon: "lib/assets/ic_user_service.png",
              label: "我的客服",
              onTap: () => _showComingSoon('我的客服'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderModule() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "订单管理",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  HmEntryItem(
                    icon: "lib/assets/ic_user_order.png",
                    label: "我的订单",
                    onTap: () => _showComingSoon('我的订单'),
                  ),
                  HmEntryItem(
                    icon: "lib/assets/ic_user_obligation.png",
                    label: "待付款",
                    onTap: () => _showComingSoon('待付款'),
                  ),
                  HmEntryItem(
                    icon: "lib/assets/ic_user_unshipped.png",
                    label: "待发货",
                    onTap: () => _showComingSoon('待发货'),
                  ),
                  HmEntryItem(
                    icon: "lib/assets/ic_user_unreceived.png",
                    label: "待收货",
                    onTap: () => _showComingSoon('待收货'),
                  ),
                  HmEntryItem(
                    icon: "lib/assets/ic_user_unevaluated.png",
                    label: "待评价",
                    onTap: () => _showComingSoon('待评价'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  final List<GoodDetailItem> _list = [];
  // 用强类型字段保存分页下标，避免对 Map 取值做 dynamic 比较。
  int _page = 1;
  static const int _pageSize = 10;
  // 阀门控制
  bool _isLoading = false;
  bool _hasMore = true;

  void _getGuessList() async {
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

  // 点击商品跳转商品详情页
  void _onGoodsTap(GoodDetailItem goods) {
    Navigator.pushNamed(context, '/goods', arguments: goods.id);
  }

  final ScrollController _controller = ScrollController();

  void _registerEvent() {
    _controller.addListener(() {
      // 滚动到底部时触发加载下一页
      if (_controller.position.pixels >=
          _controller.position.maxScrollExtent - 50) {
        _getGuessList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _controller,
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: _buildVipCard()),
        SliverToBoxAdapter(child: _buildQuickActions()),
        SliverToBoxAdapter(child: _buildOrderModule()),
        const SliverPersistentHeader(pinned: true, delegate: HmGuess()), // 猜你喜欢
        HmMoreList(
          recommendList: _list,
          onItemTap: _onGoodsTap, // 点击商品跳转详情
        ),
      ],
    );
  }
}
