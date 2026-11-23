import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hm_shop/api/user.dart';
import 'package:hm_shop/constants/app_assets.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/pages/Cart/index.dart';
import 'package:hm_shop/pages/Category/index.dart';
import 'package:hm_shop/pages/Home/index.dart';
import 'package:hm_shop/pages/Mine/index.dart';
import 'package:hm_shop/routes/app_routes.dart';
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

  /// 首页在底部 tab 中的下标
  static const int _homeTabIndex = 0;

  /// 「分类」在底部 tab 中的下标
  static const int _categoryTabIndex = 1;

  /// 购物车在底部 tab 中的下标
  static const int _cartTabIndex = 2;

  /// 「我的」在底部 tab 中的下标
  static const int _mineTabIndex = 3;

  int _currentIndex = _homeTabIndex;

  /// 已经打开过的 tab 下标
  ///
  /// IndexedStack 会把所有子页一次性 build 出来，四个页面的 initState 都在首帧
  /// 执行：登录态下等于启动就发出 14 个请求（首页 6 + 分类 2 + 购物车 1 +
  /// 我的 5），而用户此时可能只想看首页。这里改成「首次切到某个 tab 才真正
  /// 构建它」，打开过的 tab 继续留在 IndexedStack 里保持状态。
  final Set<int> _visitedTabs = <int>{_homeTabIndex};

  /// 首页分类入口请求选中的一级分类 id
  String? _categoryRequestId;

  /// 分类选中请求的版本号
  ///
  /// 每次从首页点分类都自增：同一个分类点第二次时 id 不变，只靠 id
  /// 无法让分类页重新应用这次请求。
  int _categoryRequestTicket = 0;

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

  /// 是否已因登录态失效跳往登录页
  ///
  /// 多个请求同时返回 401 时，只处理第一次，避免把登录页叠加多层。
  bool _redirectingToLogin = false;

  // 登录态失效：清空用户信息并跳转登录页
  void _handleUnauthorized() {
    _userController.clearUserInfo();
    if (!mounted || _redirectingToLogin) return;
    _redirectingToLogin = true;
    ToastUtils.showToast(context, '登录已过期，请重新登录');
    Navigator.pushNamed(
      context,
      AppRoutes.login,
    ).whenComplete(() => _redirectingToLogin = false);
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

  /// 首页点了某个一级分类：切到「分类」tab 并让分类页选中同一分类
  void _onHomeCategoryTap(CategoryItem category) {
    _categoryRequestId = category.id;
    _categoryRequestTicket++;
    _selectTab(_categoryTabIndex);
  }

  /// 切换底部 tab：同时把目标 tab 标记为「已打开」，让它在这一帧真正构建
  void _selectTab(int index) {
    setState(() {
      _currentIndex = index;
      _visitedTabs.add(index);
    });
  }

  /// 按 tab 下标构建页面；没打开过的 tab 先占位，避免启动时就发它的请求
  Widget _buildTabPage(int index) {
    if (!_visitedTabs.contains(index)) {
      return const SizedBox.shrink();
    }
    switch (index) {
      case _categoryTabIndex:
        return CategoryView(
          selectedCategoryId: _categoryRequestId,
          selectionTicket: _categoryRequestTicket,
        );
      case _cartTabIndex:
        return CartView(
          isActive: _currentIndex == _cartTabIndex,
          onGoShopping: () => _selectTab(_homeTabIndex),
        );
      case _mineTabIndex:
        return const MineView();
      case _homeTabIndex:
      default:
        return HomeView(
          onCategoryTap: _onHomeCategoryTap,
          // 只在首页可见时让轮播自动播放：IndexedStack 会把首页留在树上，
          // 不传这个标记的话切到其它 tab 后定时器仍在跑。
          isActive: _currentIndex == _homeTabIndex,
        );
    }
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
    return PopScope(
      // 停在非首页 tab 时，返回键先回到首页，再按一次才退出
      canPop: _currentIndex == _homeTabIndex,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        _selectTab(_homeTabIndex);
      },
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              for (var index = 0; index < _tabList.length; index++)
                _buildTabPage(index),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          showUnselectedLabels: true,
          unselectedItemColor: Colors.black,
          selectedItemColor: Colors.black,
          type: BottomNavigationBarType.fixed,
          onTap: _selectTab,
          items: _buildTabItems(),
        ),
      ),
    );
  }
}
