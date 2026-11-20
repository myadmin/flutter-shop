import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/stores/token_manager.dart';
import 'package:hm_shop/utils/api_exception.dart';

class DioRequest {
  static final DioRequest _instance = DioRequest._internal();
  factory DioRequest() => _instance;

  final _dio = Dio();

  /// 暴露底层 Dio 实例，便于在测试中替换 httpClientAdapter。
  Dio get dio => _dio;

  /// token 失效时的回调，由应用层注册（通常是清除登录态并跳转登录页）。
  ///
  /// 放在这里而不是直接 import 页面，是为了让网络层不依赖 UI 层。
  static VoidCallback? onUnauthorized;

  DioRequest._internal() {
    _dio.options
      ..baseUrl = GlobalConstants.baseUrl
      ..connectTimeout = const Duration(seconds: GlobalConstants.timeout)
      ..sendTimeout = const Duration(seconds: GlobalConstants.timeout)
      ..receiveTimeout = const Duration(seconds: GlobalConstants.timeout);

    _addInterceptor();
  }

  // 添加拦截器
  void _addInterceptor() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          // 注入token，保留原有请求头
          final token = tokenManager.getToken();
          if (token.isNotEmpty) {
            request.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(request);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) {
          // 统一把 Dio 异常翻译成本项目的异常类型，并保留原始堆栈。
          final translated = _translateError(error);
          debugPrint(
            '[DioRequest] ${error.requestOptions.method} '
            '${error.requestOptions.uri} 失败: $translated',
          );
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: translated,
              message: _messageOf(translated) ?? error.message,
              stackTrace: error.stackTrace,
            ),
          );
        },
      ),
    );
  }

  /// 把 Dio 层的异常翻译为面向用户的异常。
  Exception _translateError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return NetworkException('网络请求超时，请稍后重试');
    }

    final statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      // 登录态失效：清理本地 token，并通知应用层跳转登录页。
      tokenManager.removeToken();
      onUnauthorized?.call();
      return NetworkException('登录已过期，请重新登录');
    }

    final data = error.response?.data;
    if (data is Map && data['msg'] != null) {
      return ApiException(data['msg'].toString(), code: statusCode?.toString());
    }

    if (error.type == DioExceptionType.badResponse) {
      return NetworkException(
        '服务异常${statusCode == null ? '' : '（$statusCode）'}',
      );
    }

    return NetworkException('网络连接异常，请检查网络');
  }

  /// 取出本项目异常里的提示文案，非本项目异常返回 null。
  static String? _messageOf(Exception error) {
    if (error is ApiException) return error.message;
    if (error is NetworkException) return error.message;
    return null;
  }

  // 通用GET请求
  Future<dynamic> get(String url, {Map<String, dynamic>? params}) async {
    return await _handleResponse(() => _dio.get(url, queryParameters: params));
  }

  // 通用POST请求
  Future<dynamic> post(String url, {Map<String, dynamic>? data}) async {
    return await _handleResponse(() => _dio.post(url, data: data));
  }

  /// 统一处理响应：校验业务码，成功时返回 `result` 字段。
  ///
  /// [task] 用回调延迟创建请求，这样业务错误可以直接抛出 [ApiException]，
  /// 不会被 catch 分支误判成网络错误。
  Future<dynamic> _handleResponse(
    Future<Response<dynamic>> Function() task,
  ) async {
    final Response<dynamic> res;
    try {
      res = await task();
    } on DioException catch (e) {
      // 拦截器已翻译好异常并存进 error 字段。
      final cause = e.error;
      if (cause is Exception) throw cause;
      throw NetworkException(e.message ?? '网络连接异常，请检查网络');
    }

    final data = res.data;
    if (data is Map) {
      if (data['code']?.toString() == GlobalConstants.successCode) {
        return data['result'];
      }
      throw ApiException(
        data['msg']?.toString() ?? '加载数据失败',
        code: data['code']?.toString(),
      );
    }
    return data;
  }
}

// 单例对象
final dioRequest = DioRequest();
