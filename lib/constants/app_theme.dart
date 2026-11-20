import 'package:flutter/material.dart';

/// 全局设计令牌：颜色、圆角、间距、字号统一在这里定义。
///
/// 之前这些值散落在各个页面里（`Color(0xFFF47D62)` 与
/// `Color.fromARGB(255, 244, 125, 98)` 混用），改一处主色要改十几个文件。
class AppColors {
  const AppColors._();

  /// 主色（价格、主要按钮）
  static const Color primary = Color(0xFFF47D62);

  /// 主色的浅色版本，用于禁用态主按钮
  static const Color primaryDisabled = Color(0xFFF8C4B7);

  /// 主色的极浅背景，用于次要按钮底色与高亮卡片
  static const Color primarySurface = Color(0xFFFFF2E8);

  /// 「我的」页面顶部渐变的收尾色
  static const Color headerGradientEnd = Color(0xFFFDF6F1);

  /// 深棕文字色，用于强调文字（会员卡、爆款标题）
  static const Color darkBrown = Color(0xFF561814);

  /// 浅棕文字色，用于副标题
  static const Color lightBrown = Color(0xFF7C3F3A);

  /// 会员卡上的深红文字/按钮色
  static const Color vipForeground = Color(0xFF7E2B1A);

  /// 页面背景灰
  static const Color pageBackground = Color(0xFFF7F7F7);

  /// 输入框填充底色
  static const Color inputFill = Color(0xFFF5F5F5);

  /// 商品图占位底色
  static const Color imagePlaceholder = Color(0xFFF2F2F2);

  /// 次要文字
  static const Color textSecondary = Color(0xFF999999);

  /// 分割线
  static const Color divider = Color(0xFFE0E0E0);

  /// 分类图标底色
  static const Color categoryTile = Color(0xFFEBEAEA);

  /// 链接文字（隐私政策、用户协议）
  static const Color link = Color(0xFF1E88E5);

  /// 底部操作栏顶部阴影
  static const Color barShadow = Color(0x14000000);

  /// 搜索框半透明黑底
  static const Color searchOverlay = Color(0x66000000);

  /// 爆款推荐模块背景
  static const Color hotBackground = Color(0xFFDDEBF7);

  /// 一站全买模块背景
  static const Color oneStopBackground = Color(0xFFFDF3D8);

  /// 会员卡背景
  static const Color vipBackground = Color(0xFFF0C09B);
}

/// 统一圆角
class AppRadius {
  const AppRadius._();

  static const double card = 8;
  static const double image = 8;
  static const double pill = 28;
  static const double toast = 40;
}

/// 统一间距（含常见模块间距）
class AppSpacing {
  const AppSpacing._();

  /// 列表与模块之间的垂直间距
  static const double module = 10;

  /// 页面左右内边距
  static const double page = 10;

  static const double small = 6;
  static const double medium = 10;
  static const double large = 20;
}
