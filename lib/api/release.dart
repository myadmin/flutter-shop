import 'package:dio/dio.dart';
import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/models/app_release.dart';
import 'package:hm_shop/models/parsers.dart';

/// 查最新版本专用的 Dio
///
/// 不能用 `dioRequest`：它的 baseUrl 指向商城后端，拦截器还会给每个请求
/// 挂上登录 token，而 GitHub 的接口两者都不需要。
final Dio releaseDio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    headers: const {'Accept': 'application/vnd.github+json'},
  ),
);

/// 拉取 GitHub 上最新的一条 Release
///
/// 仓库还没发过 Release 时 GitHub 返回 404，这里转成 null 由调用方忽略。
Future<AppRelease?> fetchLatestRelease() async {
  try {
    final Response<dynamic> response = await releaseDio.get<dynamic>(
      GlobalConstants.latestReleaseUrl,
    );
    return AppRelease.fromJson(asMap(response.data));
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) {
      return null;
    }
    rethrow;
  }
}
