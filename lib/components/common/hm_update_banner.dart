import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_theme.dart';

/// 版本更新提示横幅
///
/// Web / iOS 上用：这类平台不能自己装包，只能引导用户去发布页，
/// 用横幅比弹窗打扰小，用户想更新时点一下即可。
class HmUpdateBanner extends StatelessWidget {
  const HmUpdateBanner({
    super.key,
    required this.versionName,
    required this.onUpdate,
    this.onClose,
  });

  /// 新版本号，例如 `1.0.13`
  final String versionName;

  /// 点「立即更新」
  final VoidCallback onUpdate;

  /// 点右侧关闭（只在本次运行内隐藏，下次启动还会提示）
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.small,
        AppSpacing.page,
        0,
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.system_update_alt,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '发现新版本 v$versionName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.darkBrown),
            ),
          ),
          TextButton(
            onPressed: onUpdate,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '立即更新',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 16),
              color: AppColors.textSecondary,
              tooltip: '本次不再提示',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            ),
        ],
      ),
    );
  }
}
