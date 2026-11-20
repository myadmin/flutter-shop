import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/stores/token_manager.dart';
import 'package:hm_shop/utils/api_exception.dart';
import 'package:hm_shop/utils/dio_request.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用脚本化响应替换 Dio 的 HTTP 适配器，避免测试真的发网络请求。
class _MockAdapter implements HttpClientAdapter {
  _MockAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, dynamic> body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  // TokenManager 依赖 SharedPreferences，需要先初始化测试 binding
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DioRequest 网络层', () {
    setUp(() {
      DioRequest.onUnauthorized = null;
      // 每个用例都用一份干净的假存储，避免 token 互相污染
      SharedPreferences.setMockInitialValues({});
    });
    tearDown(() => DioRequest.onUnauthorized = null);

    /// 换上 mock 适配器，返回可用于断言的 adapter 实例
    _MockAdapter install(
      ResponseBody Function(RequestOptions options) handler,
    ) {
      final adapter = _MockAdapter(handler);
      dioRequest.dio.httpClientAdapter = adapter;
      return adapter;
    }

    test('业务码为成功码时返回 result 字段', () async {
      install(
        (_) => _json({
          'code': '1',
          'result': <String>['a', 'b'],
        }),
      );

      final result = await dioRequest.get('/test');

      expect(result, ['a', 'b']);
    });

    test('业务码失败时抛出 ApiException 并带上服务端 msg', () async {
      install((_) => _json({'code': '0', 'msg': '库存不足'}));

      await expectLater(
        dioRequest.post('/test', data: {'skuId': '1'}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', '库存不足')
              .having((e) => e.code, 'code', '0'),
        ),
      );
    });

    test('业务码失败但没有 msg 时使用兜底文案', () async {
      install((_) => _json({'code': '0'}));

      await expectLater(
        dioRequest.get('/test'),
        throwsA(
          isA<ApiException>().having((e) => e.message, 'message', '加载数据失败'),
        ),
      );
    });

    test('超时会翻译成 NetworkException 而不是裸 DioException', () async {
      install((options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        );
      });

      await expectLater(
        dioRequest.get('/test'),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.message,
            'message',
            '网络请求超时，请稍后重试',
          ),
        ),
      );
    });

    test('401 会清空 token 并触发 onUnauthorized 回调', () async {
      await tokenManager.setToken('token-under-test');
      expect(tokenManager.getToken(), 'token-under-test');

      var unauthorized = 0;
      DioRequest.onUnauthorized = () => unauthorized++;

      install(
        (options) => _json({'code': '0', 'msg': '请先登录'}, statusCode: 401),
      );

      await expectLater(
        dioRequest.get('/test'),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.message,
            'message',
            '登录已过期，请重新登录',
          ),
        ),
      );

      expect(tokenManager.getToken(), isEmpty);
      expect(unauthorized, 1);
    });

    test('已登录时请求头会带上 Authorization', () async {
      await tokenManager.setToken('abc123');
      final adapter = install((_) => _json({'code': '1', 'result': 'ok'}));

      await dioRequest.get('/test');

      expect(adapter.requests.single.headers['Authorization'], 'Bearer abc123');
    });

    test('未登录时不会注入 Authorization', () async {
      await tokenManager.removeToken();
      final adapter = install((_) => _json({'code': '1', 'result': 'ok'}));

      await dioRequest.get('/test');

      expect(
        adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('baseUrl 与超时取自全局常量', () {
      final options = dioRequest.dio.options;
      expect(options.baseUrl, GlobalConstants.baseUrl);
      expect(
        options.connectTimeout,
        const Duration(seconds: GlobalConstants.timeout),
      );
    });
  });
}
