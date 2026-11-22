// 路由配置
import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/pages/Collect/index.dart';
import 'package:hm_shop/pages/CustomerService/index.dart';
import 'package:hm_shop/pages/Footprint/index.dart';
import 'package:hm_shop/pages/GoodsDetail/index.dart';
import 'package:hm_shop/pages/GoodsList/index.dart';
import 'package:hm_shop/pages/Main/index.dart';
import 'package:hm_shop/pages/Login/index.dart';
import 'package:hm_shop/pages/OrderConfirm/index.dart';
import 'package:hm_shop/pages/OrderDetail/index.dart';
import 'package:hm_shop/pages/OrderList/index.dart';
import 'package:hm_shop/pages/Profile/index.dart';
import 'package:hm_shop/pages/Unknown/index.dart';
import 'package:hm_shop/pages/Vip/index.dart';
import 'package:hm_shop/routes/app_routes.dart';

Widget getRootWidget() {
  return MaterialApp(
    title: '美荟商城',
    debugShowCheckedModeBanner: false,
    // 不写死 initialRoute：交给平台默认路由（Web 上是地址栏里的
    // `/goods/list?...`，原生上是 '/'），这样分享出去的深链能直接打开对应页面
    routes: getRootRoutes(),
    // 深链（/goods?id=42）的名字带查询串，routes 表里查不到，交给 buildRoute 拆解
    onGenerateRoute: buildRoute,
    // 初始路由栈自己拼：默认行为会把 `/goods/list?...` 逐段拆成
    // `/` → `/goods` → `/goods/list?...`，中间那个 `/goods` 是参数为空的
    // 商品详情页（返回时落在「商品信息缺失」错误态）
    onGenerateInitialRoutes: buildInitialRoutes,
    // 连路径都对不上时展示兜底页，而不是白屏
    onUnknownRoute: buildUnknownRoute,
    theme: buildAppTheme(),
  );
}

/// 统一的路由生成入口
///
/// 启用真实路径策略后，浏览器直接访问的深链在 Flutter 侧表现为
/// 「路径 + 查询串」的 initialRoute（例如 `/goods?id=42`），而 `routes`
/// 表是按精确名字匹配的，所以这里先用 [Uri] 拆出路径去查表、再把查询参数
/// 变成这条路由的 arguments：
/// - 深链（`/goods?id=42`）→ arguments 由查询串拼成 Map；
/// - 站内跳转（`pushNamed('/goods', arguments: id)`）→ 沿用调用方给的 arguments；
/// - 路径查不到 → 交给兜底页。
///
/// 注意路由名保留完整查询串（而不是只留 path）：地址栏的 URL 就是取
/// `RouteSettings.name`，保留查询串才能让「刷新/分享」还原到同一件商品。
Route<dynamic>? buildRoute(RouteSettings settings) {
  final name = settings.name ?? '/';
  final uri = Uri.tryParse(name);
  final path = uri != null && uri.path.isNotEmpty ? uri.path : name;
  final builder = getRootRoutes()[path];
  if (builder == null) {
    return buildUnknownRoute(settings);
  }
  final query = uri?.queryParameters ?? const <String, String>{};
  final arguments =
      settings.arguments ??
      (query.isEmpty ? null : <String, dynamic>{...query});
  return MaterialPageRoute<void>(
    builder: builder,
    settings: RouteSettings(name: name, arguments: arguments),
  );
}

/// 初始路由栈
///
/// Flutter 默认把带路径的 initialRoute 逐段拆分压栈：`/goods/list?...` 会变成
/// `/` → `/goods` → `/goods/list?...`。中间那层 `/goods` 没有 id，是「商品信息
/// 缺失」的错误页，从深链返回时会先落到它上面。这里改成「首页 + 目标页」两层：
/// 深链直接落到目标页，返回键回到首页，也不会多建一层空参数页面。
List<Route<dynamic>> buildInitialRoutes(String initialRoute) {
  final home = buildRoute(const RouteSettings(name: AppRoutes.home));
  final path = Uri.tryParse(initialRoute)?.path ?? initialRoute;
  if (path.isEmpty || path == AppRoutes.home) {
    return home == null ? const [] : [home];
  }
  final target = buildRoute(RouteSettings(name: initialRoute));
  if (target == null) {
    return home == null ? const [] : [home];
  }
  return [?home, target];
}

/// 未知路由兜底
///
/// 单独抽成函数而不是内联闭包，方便测试直接断言这层「路由表未命中 →
/// 展示兜底页」的接线是否正确。
Route<dynamic>? buildUnknownRoute(RouteSettings settings) {
  return MaterialPageRoute<void>(
    builder: (_) => UnknownRoutePage(location: settings.name),
    settings: settings,
  );
}

/// 应用主题：把设计令牌里的颜色映射到 Material 主题，
/// 让未显式指定颜色的组件（SnackBar、Dialog、按钮等）也保持统一观感。
ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.white,
    splashFactory: InkSparkle.splashFactory,
  );
}

Map<String, Widget Function(BuildContext)> getRootRoutes() {
  return {
    AppRoutes.home: (context) => const MainPage(), // 主页路由
    AppRoutes.login: (context) => const LoginPage(), // 登录路由
    AppRoutes.goodsPath: (context) {
      // 商品详情：站内跳转与深链都会把 id 编进查询串（由 buildRoute 解析成 Map）
      final arguments = ModalRoute.of(context)?.settings.arguments;
      final goodsId = arguments is String
          ? arguments
          : arguments is Map
          ? arguments['id']?.toString() ?? ''
          : '';
      return GoodsDetailPage(goodsId: goodsId);
    }, // 商品详情路由
    AppRoutes.goodsListPath: (context) {
      // 分类商品列表：分类 id 与分类名都来自查询串
      final arguments = ModalRoute.of(context)?.settings.arguments;
      final params = arguments is Map ? arguments : <String, dynamic>{};
      return GoodsListPage(
        categoryId: params['categoryId']?.toString() ?? '',
        title: params['title']?.toString() ?? '商品列表',
      );
    }, // 分类商品列表路由
    AppRoutes.orderConfirmPath: (context) {
      // 订单确认：skuId 与购买数量同样来自查询串
      final arguments = ModalRoute.of(context)?.settings.arguments;
      final params = arguments is Map ? arguments : <String, dynamic>{};
      return OrderConfirmPage(
        skuId: params['skuId']?.toString() ?? '',
        count: int.tryParse(params['count']?.toString() ?? '') ?? 1,
      );
    }, // 订单确认路由
    AppRoutes.orderListPath: (context) {
      // 我的订单：`/orders?state=2`，不带 state 时展示「全部」
      final arguments = ModalRoute.of(context)?.settings.arguments;
      final params = arguments is Map ? arguments : <String, dynamic>{};
      return OrderListPage(
        initialTab: int.tryParse(params['state']?.toString() ?? '') ?? 0,
      );
    }, // 我的订单路由
    AppRoutes.orderDetailPath: (context) {
      // 订单详情：`/orders/detail?id=<订单 id>`
      final arguments = ModalRoute.of(context)?.settings.arguments;
      final params = arguments is Map ? arguments : <String, dynamic>{};
      return OrderDetailPage(orderId: params['id']?.toString() ?? '');
    }, // 订单详情路由
    AppRoutes.collectPath: (context) => const CollectPage(), // 我的收藏路由
    AppRoutes.customerServicePath: (context) =>
        const CustomerServicePage(), // 客服中心路由
    AppRoutes.footprintPath: (context) => const FootprintPage(), // 我的足迹路由
    AppRoutes.vipPath: (context) => const VipBenefitsPage(), // 会员权益路由
    AppRoutes.profilePath: (context) => const ProfilePage(), // 个人资料路由
  };
}
