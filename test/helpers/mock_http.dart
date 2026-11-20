import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:hm_shop/utils/dio_request.dart';

/// 用脚本化响应替换 Dio 的 HTTP 适配器，避免测试真的发网络请求。
///
/// 页面级测试需要同时断言「界面状态」和「发出了哪些请求」，所以既提供
/// [handler] 生成响应，也把每次请求记录在 [requests] 里供断言。
class MockAdapter implements HttpClientAdapter {
  MockAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;

  final List<RequestOptions> requests = [];

  /// 按 HTTP 方法过滤记录下来的请求
  List<RequestOptions> requestsWhere(String method) => requests
      .where((option) => option.method.toUpperCase() == method.toUpperCase())
      .toList();

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

/// 构造 JSON 响应体
ResponseBody jsonResponse(Object? body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

/// 构造业务成功（code=1）的响应体
ResponseBody envelope(Object? result) {
  return jsonResponse({'code': '1', 'result': result});
}

/// 构造业务失败的响应体，例如 `envelopeError('库存不足', code: '10001')`
ResponseBody envelopeError(String msg, {String code = '10001'}) {
  return jsonResponse({'code': code, 'msg': msg});
}

/// 换上 mock 适配器，返回可用于断言的实例
MockAdapter installMock(ResponseBody Function(RequestOptions options) handler) {
  final adapter = MockAdapter(handler);
  dioRequest.dio.httpClientAdapter = adapter;
  return adapter;
}

/// 一条购物车条目，只覆盖测试关心的字段
Map<String, dynamic> cartItemJson({
  String skuId = 'sku-1',
  String name = '测试商品',
  String nowPrice = '69.90',
  int count = 1,
  bool selected = true,
  int stock = 10,
  bool isEffective = true,
}) {
  return {
    'id': 'goods-1',
    'skuId': skuId,
    'name': name,
    'attrsText': '规格:默认 ',
    'picture': '',
    'price': '89.00',
    'nowPrice': nowPrice,
    'selected': selected,
    'stock': stock,
    'count': count,
    'isEffective': isEffective,
    'postFee': 8,
  };
}

/// 一个一级分类（含两个二级分类）
Map<String, dynamic> categoryJson({String id = 'c1', String name = '测试分类'}) {
  return {
    'id': id,
    'name': name,
    'picture': '',
    'children': [
      {'id': 'sub-1', 'name': '子分类一', 'picture': ''},
      {'id': 'sub-2', 'name': '子分类二', 'picture': ''},
    ],
  };
}

/// 一条推荐商品
Map<String, dynamic> goodsItemJson({
  String id = 'goods-1',
  String name = '推荐商品',
  String price = '69.90',
}) {
  return {
    'id': id,
    'name': name,
    'price': price,
    'picture': '',
    'orderNum': 1,
    'payCount': 12,
  };
}
