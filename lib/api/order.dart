import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/models/order.dart';
import 'package:hm_shop/models/parsers.dart';
import 'package:hm_shop/utils/dio_request.dart';

/// 获取立即购买结算信息
Future<PreOrderResult> getPreOrderAPI(String skuId, int count) async {
  return PreOrderResult.fromJson(
    asMap(
      await dioRequest.get(
        HttpConstants.preOrder,
        params: {'skuId': skuId, 'count': count},
      ),
    ),
  );
}

/// 提交订单，返回订单号
Future<String> submitOrderAPI(Map<String, dynamic> data) async {
  final result = asMap(await dioRequest.post(HttpConstants.order, data: data));
  return asString(result['id']);
}
