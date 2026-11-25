import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/app_release.dart';

/// 弹出「发现新版本」对话框（安卓用，能直接下安装包）
///
/// 关闭方式：点「稍后」或点空白处都只是本次不更新；「跳过此版本」会记到本地，
/// 之后同一个版本号不再提示。
Future<void> showAppUpdateDialog(
  BuildContext context, {
  required AppRelease release,
  required String currentVersion,
  required VoidCallback onUpdate,
  required VoidCallback onSkip,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      final String sizeText = release.androidApkSizeText;
      return AlertDialog(
        title: Text('发现新版本 v${release.versionName}'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sizeText.isEmpty
                      ? '当前版本 $currentVersion'
                      : '当前版本 $currentVersion · 安装包 $sizeText',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (release.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    release.notes.trim(),
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: AppColors.darkBrown,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onSkip();
            },
            child: const Text('跳过此版本'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('稍后'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onUpdate();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('立即更新'),
          ),
        ],
      );
    },
  );
}
