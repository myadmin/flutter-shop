import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hm_shop/api/user.dart';
import 'package:hm_shop/constants/app_assets.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/pages/Cart/index.dart';
import 'package:hm_shop/pages/Category/index.dart';
import 'package:hm_shop/pages/Home/index.dart';
import 'package:hm_shop/pages/Mine/index.dart';
import 'package:hm_shop/stores/cart_controller.dart';
import 'package:hm_shop/stores/token_manager.dart';
import 'package:hm_shop/stores/user_controller.dart';
import 'package:hm_shop/utils/dio_request.dart';
import 'package:hm_shop/utils/toast_utils.dart';

// 底部 tab 定义：用 record 而非 Map，避免字符串 key 取值时的空断言
final List<({String icon, String activeIcon, String label})> _tabList = [
  (
    icon: AppAssets.icPublicHomeNormal,
    activeIcon: AppAssets.icPublicHomeActive,
    label: '首页',
  ),
  (
    icon: AppAssets.icPublicProNormal,
    activeIcon: AppAssets.icPublicProActive,
    label: '分类',
  ),
  (
    icon: AppAssets.icPublicCartNormal,
    activeIcon: AppAssets.icPublicCartActive,
    label: '购物车',
  ),
  (
    icon: AppAssets.icPublicMyNormal,
    activeIcon: AppAssets.icPublicMyActive,
    label: '我的',
  ),
];

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // 全局用户态、购物车件数在 main() 中统一注册，这里只取用，不负责创建
  final UserController _userController = Get.find<UserController>();
  final CartController _cartController = Get.find<CartController>();

  /// 购物车在底部 tab 中的下标
  static const int _cartTabIndex = 2;

  int _currentIndex = 0;

  late final Worker _userWatcher;

  @override
  void initState() {
    super.initState();
    // 网络层发现登录态失效时，统一在这里清理用户信息并跳转登录页
    DioRequest.onUnauthorized = _handleUnauthorized;
    // 登录 / 退出登录后刷新购物车角标
    _userWatcher = ever(
      _userController.user,
      (_) => _cartController.refreshCount(),
    );
    // 初始化用户
    _initUser();
  }

  @override
  void dispose() {
    DioRequest.onUnauthorized = null;
    _userWatcher.dispose();
    super.dispose();
  }

  // 登录态失效：清空用户信息并跳转登录页
  void _handleUnauthorized() {
    _userController.clearUserInfo();
    if (!mounted) return;
    ToastUtils.showToast(context, '登录已过期，请重新登录');
    Navigator.pushNamed(context, '/login');
  }

  // 初始化用户
  Future<void> _initUser() async {
    await tokenManager.init();
    if (tokenManager.getToken().isNotEmpty) {
      try {
        final userInfo = await getUserInfoAPI();
        _userController.updateUserInfo(userInfo);
      } catch (e) {
        debugPrint('恢复登录态失败，清除本地失效token: $e');
        await tokenManager.removeToken();
        _userController.clearUserInfo();
      }
    }
    await _cartController.refreshCount();
  }

  /// 购物车图标：有商品时叠加件数角标
  Widget _buildCartIcon(String path) {
    final Widget icon = Image.asset(path, width: 30, height: 30);
    return Obx(() {
      final int count = _cartController.count.value;
      if (count <= 0) return icon;
      return Badge(
        backgroundColor: AppColors.primary,
        label: Text('$count', style: const TextStyle(fontSize: 10)),
        child: icon,
      );
    });
  }

  /// 底部 tab 项；只有购物车需要随角标重建，其余图标每帧重建成本可忽略
  List<BottomNavigationBarItem> _buildTabItems() {
    return [
      for (var index = 0; index < _tabList.length; index++)
        BottomNavigationBarItem(
          icon: index == _cartTabIndex
              ? _buildCartIcon(_tabList[index].icon)
              : Image.asset(_tabList[index].icon, width: 30, height: 30),
          activeIcon: index == _cartTabIndex
              ? _buildCartIcon(_tabList[index].activeIcon)
              : Image.asset(_tabList[index].activeIcon, width: 30, height: 30),
          label: _tabList[index].label,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            const HomeView(),
            const CategoryView(),
            CartView(
              isActive: _currentIndex == _cartTabIndex,
              onGoShopping: () => setState(() => _currentIndex = 0),
            ),
            const MineView(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        showUnselectedLabels: true,
        unselectedItemColor: Colors.black,
        selectedItemColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _buildTabItems(),
      ),
    );
  }
}
