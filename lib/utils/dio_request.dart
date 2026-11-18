import 'package:dio/dio.dart';
import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/stores/token_manager.dart';

class DioRequest {
  static final DioRequest _instance = DioRequest._internal();
  factory DioRequest() => _instance;

  final _dio = Dio();

  DioRequest._internal() {
    _dio.options
      ..baseUrl = GlobalConstants.baseUrl
      ..connectTimeout = Duration(seconds: GlobalConstants.timeout)
      ..sendTimeout = Duration(seconds: GlobalConstants.timeout)
      ..receiveTimeout = Duration(seconds: GlobalConstants.timeout);

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
          String message = '网络连接异常，请检查网络';
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            message = '网络请求超时，请稍后重试';
          } else if (error.response?.data is Map) {
            message = error.response?.data['msg']?.toString() ?? message;
          }
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: error.error,
              message: message,
            ),
          );
        },
      ),
    );
  }

  // 通用GET请求
  Future<dynamic> get(String url, {Map<String, dynamic>? params}) async {
    return await _handleResponse(_dio.get(url, queryParameters: params));
  }

  // 通用POST请求
  Future<dynamic> post(String url, {Map<String, dynamic>? data}) async {
    return await _handleResponse(_dio.post(url, data: data));
  }

  // 处理响应数据
  Future<dynamic> _handleResponse(Future<Response<dynamic>> task) async {
    try {
      Response<dynamic> res = await task;
      if (res.data is Map) {
        final data = res.data as Map;
        if (data['code']?.toString() == GlobalConstants.successCode) {
          return data['result'];
        }
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          message: data['msg']?.toString() ?? "加载数据失败",
        );
      }
      return res.data;
    } catch (e) {
      rethrow;
    }
  }
}

// 单例对象
final dioRequest = DioRequest();
