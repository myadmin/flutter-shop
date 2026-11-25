import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_theme.dart';

/// 全库复用的文字样式
///
/// 之前同一个样式（例如「12 号次要说明文字」）在十几个文件里各写一遍内联
/// `TextStyle`，改字号或颜色时得全局搜索。这里把出现频率最高的几档收敛成常量，
/// 页面里直接引用；需要微调的场合仍可用 `style: AppTextStyles.caption.copyWith(...)`。
abstract final class AppTextStyles {
  /// 次要说明文字（12 号）
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  /// 更小的次要说明文字（11 号），用于时间、单位等附注
  static const TextStyle captionSmall = TextStyle(
    fontSize: 11,
    color: AppColors.textSecondary,
  );

  /// 角标、标签里的小字（10 号）
  static const TextStyle label = TextStyle(
    fontSize: 10,
    color: AppColors.textSecondary,
  );

  /// 正文（14 号，默认颜色）
  static const TextStyle body = TextStyle(fontSize: 14);

  /// 正文强调（14 号、半粗、黑色）
  static const TextStyle bodyStrong = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  /// 小号正文（12 号，默认颜色）
  static const TextStyle bodySmall = TextStyle(fontSize: 12);

  /// 商品价格（16 号、加粗、主色）
  static const TextStyle price = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  /// 列表条目标题（14 号、1.35 行高、黑色）
  static const TextStyle tileTitle = TextStyle(
    fontSize: 14,
    height: 1.35,
    color: Colors.black,
  );

  /// 页面大标题（20 号、特粗、黑色）
  static const TextStyle pageTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: Colors.black,
  );

  /// 分区标题（16 号、加粗、深棕）
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.darkBrown,
  );
}
