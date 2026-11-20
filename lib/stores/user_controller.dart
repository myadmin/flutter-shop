import 'package:get/get.dart';
import 'package:hm_shop/models/user.dart';

/// 全局用户态
///
/// 状态分工约定：
/// - **跨页面共享**、需要多个页面同时响应的数据放在这里（GetX 控制器 + `Obx`）；
/// - **页面内私有**、只影响单个页面渲染的数据用 `State` + `setState`。
///
/// 目前只有用户登录信息属于前者，其余（列表数据、加载态、错误文案）
/// 都是页面私有的临时状态，因此仍用 `setState` 管理。
///
/// 本控制器在 `main()` 中通过 `Get.put(..., permanent: true)` 注册一次，
/// 页面侧一律用 `Get.find<UserController>()` 取用，
/// 不要在各页面里重复 `Get.put`（重复注册会被 GetX 静默忽略并丢弃新实例）。
class UserController extends GetxController {
  final user = UserInfo.empty().obs;

  /// 是否已登录，供 `Obx` 直接读取
  bool get isLoggedIn => user.value.isLoggedIn;

  void updateUserInfo(UserInfo newUser) {
    user.value = newUser;
  }

  /// 退出登录 / 登录态失效时清空用户信息
  void clearUserInfo() {
    user.value = UserInfo.empty();
  }
}
