import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hm_shop/api/cart.dart';
import 'package:hm_shop/stores/token_manager.dart';

/// 购物车全局状态
///
/// 目前只有「商品件数」需要跨页面共享：底部 tab 的角标、商品详情页加购后刷新。
/// 购物车**列表本身**只属于购物车页面，仍由页面用 `setState` 管理，
/// 这样才能保留「滚动位置 / 勾选态 / 数量」等局部交互。
///
/// 与 [UserController] 一样在 `main()` 中 `Get.put(..., permanent: true)`
/// 注册一次，页面侧用 `Get.find<CartController>()` 取用。
class CartController extends GetxController {
  /// 购物车商品件数，供 `Obx` 读取
  final count = 0.obs;

  /// 在途的件数请求，用于合并并发调用
  Future<void>? _refreshing;

  /// 拉取件数；未登录时直接归零，不发起请求
  ///
  /// 启动阶段「恢复登录态」和「监听用户态变化」会几乎同时触发本方法，
  /// 这里复用同一个在途请求，避免对 `/member/cart/count` 重复发车。
  Future<void> refreshCount() {
    return _refreshing ??= _doRefreshCount().whenComplete(() {
      _refreshing = null;
    });
  }

  Future<void> _doRefreshCount() async {
    if (tokenManager.getToken().isEmpty) {
      count.value = 0;
      return;
    }
    try {
      count.value = await getCartCountAPI();
    } catch (e) {
      // 角标只是辅助信息，失败时保持原值，不打断用户操作
      debugPrint('获取购物车件数失败: $e');
    }
  }

  /// 本地已知件数（页面增删改后调用，省掉一次请求）
  void setCount(int value) => count.value = value < 0 ? 0 : value;

  /// 退出登录 / 登录态失效时清空
  void clear() => count.value = 0;
}
