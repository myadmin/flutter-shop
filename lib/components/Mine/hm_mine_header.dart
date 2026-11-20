import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_assets.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/user.dart';

/// 「我的」页面顶部用户信息区
///
/// 未登录时展示「立即登录」并响应点击；已登录时展示昵称（缺省回退账号）
/// 与退出入口。
class HmMineHeader extends StatelessWidget {
  const HmMineHeader({
    super.key,
    required this.user,
    required this.onLoginTap,
    required this.onLogoutTap,
  });

  final UserInfo user;
  final VoidCallback onLoginTap;
  final VoidCallback onLogoutTap;

  /// 头像展示边长：`CircleAvatar.radius * 2`
  static const double _avatarSize = 52;

  String get _displayName {
    if (!user.isLoggedIn) {
      return '立即登录';
    }
    return user.nickname.isNotEmpty ? user.nickname : user.account;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primarySurface, AppColors.headerGradientEnd],
        ),
      ),
      padding: const EdgeInsets.only(left: 20, right: 40, top: 40, bottom: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: _avatarSize / 2,
            backgroundColor: Colors.white,
            // 头像按显示尺寸解码，避免把原图整张解到内存里
            backgroundImage: user.avatar.isEmpty
                ? const AssetImage(AppAssets.goodsAvatar)
                : ResizeImage(
                    NetworkImage(user.avatar),
                    width: (_avatarSize * 3).round(),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: user.isLoggedIn ? null : onLoginTap,
                  child: Text(
                    _displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (user.isLoggedIn)
            GestureDetector(
              onTap: onLogoutTap,
              child: const Text(
                '退出',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
