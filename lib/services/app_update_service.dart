import 'package:flutter/foundation.dart';
import 'package:hm_shop/api/release.dart';
import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/models/app_release.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// 版本更新检查
///
/// 流程：读当前版本（pubspec 的 versionName）→ 拉 GitHub 最新 Release →
/// 语义化比较 → 只有远端更新时才返回，交给页面决定用横幅还是弹窗提示。
///
/// 几个刻意的取舍：
/// - 网络失败一律当成「没有更新」静默吞掉，不能因为检查更新失败打扰用户；
/// - 两次检查之间隔 [cacheTtl]（默认 6 小时），GitHub 未登录接口每小时只给
///   60 次，按出口 IP 算，多人共用很容易打满；
/// - 「跳过此版本」记在本地，同一个版本号不再提示；
/// - debug 构建默认不检查，测试与本地调试都不会产生真实网络请求。
class AppUpdateService {
  AppUpdateService({
    Future<String> Function()? currentVersionLoader,
    Future<AppRelease?> Function()? releaseFetcher,
    Future<bool> Function(Uri url)? urlLauncher,
    this.cacheTtl = const Duration(hours: GlobalConstants.updateCheckHours),
    bool? enabled,
  }) : _loadCurrentVersion = currentVersionLoader ?? _readPackageVersion,
       _fetchRelease = releaseFetcher ?? fetchLatestRelease,
       _launchUrl = urlLauncher ?? _launchExternal,
       enabled = enabled ?? !kDebugMode;

  /// 全局默认实例；测试里可以替换成注入假数据的实例
  static AppUpdateService instance = AppUpdateService();

  /// 上次检查时间
  static const String _lastCheckKey = 'hm_shop_update_last_check';

  /// 用户选择跳过的版本号
  static const String _skipKey = 'hm_shop_update_skip_version';

  /// 是否启用检查（debug 构建默认关闭）
  final bool enabled;

  /// 两次检查之间的最小间隔
  final Duration cacheTtl;

  final Future<String> Function() _loadCurrentVersion;
  final Future<AppRelease?> Function() _fetchRelease;
  final Future<bool> Function(Uri url) _launchUrl;

  /// 检查是否有新版本；没有更新、被跳过、请求失败都返回 null
  ///
  /// [force] 为 true 时忽略时间间隔（手动点「检查更新」用）。
  Future<AppRelease?> check({bool force = false}) async {
    if (!enabled) {
      return null;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!force && _checkedRecently(prefs)) {
      return null;
    }
    // 先记下这次检查时间：即使请求失败也照样节流，避免网络不通时每次启动都重试
    await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());

    AppRelease? release;
    try {
      release = await _fetchRelease();
    } catch (e) {
      debugPrint('检查更新失败: $e');
      return null;
    }
    if (release == null || release.versionName.isEmpty) {
      return null;
    }
    if (prefs.getString(_skipKey) == release.versionName) {
      return null;
    }
    final String current = await _loadCurrentVersion();
    if (current.isEmpty) {
      return null;
    }
    return compareVersions(release.versionName, current) > 0 ? release : null;
  }

  /// 记住「跳过这个版本」，之后不再提示
  Future<void> skip(AppRelease release) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_skipKey, release.versionName);
  }

  /// 当前版本号（读不到时返回空串）
  Future<String> currentVersion() => _loadCurrentVersion();

  /// 打开发布地址：安卓优先直接下安装包，其它平台打开 Release 页面
  Future<bool> openDownload(AppRelease release) async {
    final bool isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final String target = isAndroid
        ? (release.androidApkUrl ?? release.htmlUrl)
        : (release.htmlUrl.isNotEmpty
              ? release.htmlUrl
              : (release.androidApkUrl ?? ''));
    if (target.isEmpty) {
      return false;
    }
    try {
      return await _launchUrl(Uri.parse(target));
    } catch (e) {
      debugPrint('打开更新地址失败: $e');
      return false;
    }
  }

  /// 距离上次检查是否还在间隔内
  bool _checkedRecently(SharedPreferences prefs) {
    final String? raw = prefs.getString(_lastCheckKey);
    if (raw == null || raw.isEmpty) {
      return false;
    }
    final DateTime? last = DateTime.tryParse(raw);
    if (last == null) {
      return false;
    }
    return DateTime.now().difference(last) < cacheTtl;
  }

  /// 读当前版本号（pubspec 的 version 去掉 `+build`）
  static Future<String> _readPackageVersion() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      return normalizeVersion(info.version);
    } catch (e) {
      debugPrint('读取当前版本失败: $e');
      return '';
    }
  }

  static Future<bool> _launchExternal(Uri url) {
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
