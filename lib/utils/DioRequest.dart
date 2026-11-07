import 'package:dio/dio.dart';
import 'package:hm_shop/constants/index.dart';

class DioRequest {
  final _dio = Dio();

  DioRequest() {
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
          return handler.next(request);
        },
        onResponse: (response, handler) {
          if (response.statusCode! >= 200 && response.statusCode! < 300) {
            return handler.next(response);
          }
          return handler.reject(
            DioException(requestOptions: response.requestOptions),
          );
        },
        onError: (error, handler) {
          return handler.next(error);
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

  // 处理响应数据F
  Future<dynamic> _handleResponse(Future<Response<dynamic>> task) async {
    try {
      Response<dynamic> res = await task;
      final data = res.data as Map<String, dynamic>;
      if (data['code'] == GlobalConstants.successCode) {
        return data['result'];
      }
      throw Exception(data['msg'] ?? '请求失败');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

// 单例对象
final dioRequest = DioRequest();
