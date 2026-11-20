import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hm_shop/api/user.dart';
import 'package:hm_shop/pages/Cart/index.dart';
import 'package:hm_shop/pages/Category/index.dart';
import 'package:hm_shop/pages/Home/index.dart';
import 'package:hm_shop/pages/Mine/index.dart';
import 'package:hm_shop/stores/token_manager.dart';
import 'package:hm_shop/stores/user_controller.dart';
import 'package:hm_shop/utils/dio_request.dart';
import 'package:hm_shop/utils/toast_utils.dart';

// 定义 tabbar 数据
final List<Map<String, String>> _tabList = [
  {
    'icon': 'lib/assets/ic_public_home_normal.png',
    'activeIcon': 'lib/assets/ic_public_home_active.png',
    'title': '首页',
  },
  {
    'icon': 'lib/assets/ic_public_pro_normal.png',
    'activeIcon': 'lib/assets/ic_public_pro_active.png',
    'title': '分类',
  },
  {
    'icon': 'lib/assets/ic_public_cart_normal.png',
    'activeIcon': 'lib/assets/ic_public_cart_active.png',
    'title': '购物车',
  },
  {
    'icon': 'lib/assets/ic_public_my_normal.png',
    'activeIcon': 'lib/assets/ic_public_my_active.png',
    'title': '我的',
  },
];

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // 全局用户态在 main() 中统一注册，这里只取用，不负责创建
  final UserController _userController = Get.find<UserController>();

  // 底部渲染的tabbar items
  List<BottomNavigationBarItem> _getTabBarWidgets() {
    return List.generate(_tabList.length, (index) {
      return BottomNavigationBarItem(
        icon: Image.asset(_tabList[index]['icon']!, width: 30, height: 30),
        activeIcon: Image.asset(
          _tabList[index]['activeIcon']!,
          width: 30,
          height: 30,
        ),
        label: _tabList[index]['title']!,
      );
    });
  }

  int _currentIndex = 0;

  late final List<Widget> _children = [
    const HomeView(),
    const CategoryView(),
    const CartView(),
    const MineView(),
  ];

  @override
  void initState() {
    super.initState();
    // 网络层发现登录态失效时，统一在这里清理用户信息并跳转登录页
    DioRequest.onUnauthorized = _handleUnauthorized;
    // 初始化用户
    _initUser();
  }

  @override
  void dispose() {
    DioRequest.onUnauthorized = null;
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: _children),
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
        items: _getTabBarWidgets(),
      ),
    );
  }
}
