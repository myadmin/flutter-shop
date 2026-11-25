import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_theme.dart';

/// 「我的」页底部的「关于」卡片
///
/// 展示当前版本，并提供「检查更新」与「下载 Android 安装包」两个入口——
/// 之前版本号只写在构建产物里，用户既看不到自己装的是哪一版，也没有手动更新的入口。
class HmMineAbout extends StatelessWidget {
  const HmMineAbout({
    super.key,
    required this.versionText,
    this.onCheckUpdate,
    this.onDownload,
  });

  /// 当前版本号；读不到时传空串，展示为 `--`
  final String versionText;

  /// 手动检查更新，为空时该行不可点
  final VoidCallback? onCheckUpdate;

  /// 打开安装包下载页，为空时不展示该行（安卓端本身就是安装包，不需要再下载）
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '关于',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.darkBrown,
            ),
          ),
          const SizedBox(height: 4),
          _AboutRow(
            label: '当前版本',
            value: versionText.isEmpty ? '--' : 'v$versionText',
          ),
          if (onCheckUpdate != null)
            _AboutRow(label: '检查更新', onTap: onCheckUpdate),
          if (onDownload != null)
            _AboutRow(label: '下载 Android 安装包', onTap: onDownload),
        ],
      ),
    );
  }
}

/// 「关于」卡片里的一行：左侧标题，右侧说明与箭头
class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, this.value = '', this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 13)),
              const Spacer(),
              if (value.isNotEmpty)
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              if (onTap != null)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
