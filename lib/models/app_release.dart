import 'package:hm_shop/models/parsers.dart';

/// GitHub Release 里的一个产物文件
class ReleaseAsset {
  const ReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
  });

  /// 文件名，例如 `app-arm64-v8a-release.apk`
  final String name;

  /// 浏览器可直接下载的地址
  final String downloadUrl;

  /// 字节数，用于在弹窗里显示安装包大小
  final int size;

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) {
    return ReleaseAsset(
      name: asString(json['name']),
      downloadUrl: asString(json['browser_download_url']),
      size: asInt(json['size']),
    );
  }

  /// 是否安卓安装包
  bool get isAndroidApk => name.toLowerCase().endsWith('.apk');

  /// 包大小文案，未知时返回空串
  String get sizeText {
    if (size <= 0) {
      return '';
    }
    final double mb = size / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// 一次 GitHub Release（`/releases/latest` 的响应体）
class AppRelease {
  const AppRelease({
    required this.versionName,
    required this.notes,
    required this.htmlUrl,
    required this.assets,
  });

  /// 版本号，已去掉 tag 的 `v` 前缀与 `+build` 后缀，例如 `1.0.13`
  final String versionName;

  /// Release 说明正文（Markdown）
  final String notes;

  /// Release 页面地址，iOS / Web 用它作为更新入口
  final String htmlUrl;

  final List<ReleaseAsset> assets;

  factory AppRelease.fromJson(Map<String, dynamic> json) {
    return AppRelease(
      versionName: normalizeVersion(asString(json['tag_name'])),
      notes: asString(json['body']),
      htmlUrl: asString(json['html_url']),
      assets: asList(json['assets'], ReleaseAsset.fromJson),
    );
  }

  /// 安卓安装包下载地址
  ///
  /// 优先 64 位（绝大多数机型），其次 32 位，最后退到任意一个 apk；
  /// 找不到 apk 时返回 null，调用方改用 [htmlUrl]。
  String? get androidApkUrl {
    final List<ReleaseAsset> apks = assets
        .where((ReleaseAsset asset) => asset.isAndroidApk)
        .toList();
    if (apks.isEmpty) {
      return null;
    }
    for (final String abi in const ['arm64-v8a', 'armeabi-v7a', 'x86_64']) {
      for (final ReleaseAsset apk in apks) {
        if (apk.name.contains(abi)) {
          return apk.downloadUrl;
        }
      }
    }
    return apks.first.downloadUrl;
  }

  /// 推荐安装包的体积文案
  String get androidApkSizeText {
    final String? url = androidApkUrl;
    if (url == null) {
      return '';
    }
    for (final ReleaseAsset apk in assets) {
      if (apk.downloadUrl == url) {
        return apk.sizeText;
      }
    }
    return '';
  }
}

/// 版本号归一化：去掉 `v` 前缀、`+build` 后缀与首尾空白
String normalizeVersion(String raw) {
  String value = raw.trim();
  if (value.startsWith('v') || value.startsWith('V')) {
    value = value.substring(1);
  }
  final int plus = value.indexOf('+');
  if (plus >= 0) {
    value = value.substring(0, plus);
  }
  return value.trim();
}

/// 比较版本号：[a] 比 [b] 新返回 1，相同返回 0，更旧返回 -1
///
/// 只按 `.` 分段比数字，段数不同时缺的段按 0 处理（`1.0` 与 `1.0.0` 相等），
/// 段里带非数字后缀（如 `1.0.13-beta`）时只取前缀数字。
int compareVersions(String a, String b) {
  final List<int> left = _versionSegments(a);
  final List<int> right = _versionSegments(b);
  final int length = left.length > right.length ? left.length : right.length;
  for (var i = 0; i < length; i++) {
    final int l = i < left.length ? left[i] : 0;
    final int r = i < right.length ? right[i] : 0;
    if (l != r) {
      return l > r ? 1 : -1;
    }
  }
  return 0;
}

List<int> _versionSegments(String version) {
  return normalizeVersion(version).split('.').map((String segment) {
    final Match? match = RegExp(r'^\d+').firstMatch(segment.trim());
    return match == null ? 0 : int.tryParse(match.group(0)!) ?? 0;
  }).toList();
}
