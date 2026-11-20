/// 静态资源路径
///
/// 与 `pubspec.yaml` 的 `assets` 声明一一对应：新增图片时两处都要补一行，
/// 这里的常量让拼错的路径在编译期就报错，而不是等到运行时白屏。
class AppAssets {
  const AppAssets._();

  // ---- 通用 ----
  /// 默认用户头像
  static const String goodsAvatar = 'lib/assets/goods_avatar.png';

  // ---- 首页活动图 ----
  // 两张装饰图原为 PNG（合计 287 KB），改用 WebP 后合计约 18 KB
  /// 特惠推荐左侧活动图
  static const String homeCmdInner = 'lib/assets/home_cmd_inner.webp';

  /// 特惠推荐卡片背景图
  static const String homeCmdSm = 'lib/assets/home_cmd_sm.webp';

  // ---- 底部导航 ----
  static const String icPublicHomeNormal =
      'lib/assets/ic_public_home_normal.png';
  static const String icPublicHomeActive =
      'lib/assets/ic_public_home_active.png';
  static const String icPublicProNormal = 'lib/assets/ic_public_pro_normal.png';
  static const String icPublicProActive = 'lib/assets/ic_public_pro_active.png';

  static const String icPublicCartNormal =
      'lib/assets/ic_public_cart_normal.png';
  static const String icPublicCartActive =
      'lib/assets/ic_public_cart_active.png';

  static const String icPublicMyNormal = 'lib/assets/ic_public_my_normal.png';
  static const String icPublicMyActive = 'lib/assets/ic_public_my_active.png';

  // ---- 「我的」页面 ----
  /// 会员卡图标
  static const String icUserVip = 'lib/assets/ic_user_vip.png';

  static const String icUserCollect = 'lib/assets/ic_user_collect.png';
  static const String icUserHistory = 'lib/assets/ic_user_history.png';
  static const String icUserService = 'lib/assets/ic_user_service.png';

  /// 全部订单
  static const String icUserOrder = 'lib/assets/ic_user_order.png';

  /// 待付款
  static const String icUserObligation = 'lib/assets/ic_user_obligation.png';

  /// 待发货
  static const String icUserUnshipped = 'lib/assets/ic_user_unshipped.png';

  /// 待收货
  static const String icUserUnreceived = 'lib/assets/ic_user_unreceived.png';

  /// 待评价
  static const String icUserUnevaluated = 'lib/assets/ic_user_unevaluated.png';
}
