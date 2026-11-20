// 路由配置
import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/pages/GoodsDetail/index.dart';
import 'package:hm_shop/pages/Main/index.dart';
import 'package:hm_shop/pages/Login/index.dart';
import 'package:hm_shop/pages/OrderConfirm/index.dart';

Widget getRootWidget() {
  return MaterialApp(
    title: '美荟商城',
    debugShowCheckedModeBanner: false,
    initialRoute: '/',
    routes: getRootRoutes(),
    theme: buildAppTheme(),
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
    '/': (context) => const MainPage(), // 主页路由
    '/login': (context) => const LoginPage(), // 登录路由
    '/goods': (context) {
      // 商品详情路由，商品 id 由列表项点击时通过 arguments 传入
      final arguments = ModalRoute.of(context)?.settings.arguments;
      return GoodsDetailPage(goodsId: arguments is String ? arguments : '');
    }, // 商品详情路由
    '/order/confirm': (context) {
      // 订单确认路由，skuId 与购买数量由立即购买时通过 arguments 传入
      final arguments = ModalRoute.of(context)?.settings.arguments;
      final params = arguments is Map ? arguments : <String, dynamic>{};
      return OrderConfirmPage(
        skuId: params['skuId']?.toString() ?? '',
        count: int.tryParse(params['count']?.toString() ?? '') ?? 1,
      );
    }, // 订单确认路由
  };
}
