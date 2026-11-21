import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/models/order.dart';
import 'package:hm_shop/models/order_list.dart';
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

/// 我的订单列表
///
/// [orderState] 传 0 表示全部，其余取值见 [OrderState]；
/// 接口按 `orderState` 过滤并分页返回。
Future<OrderListResult> getOrderListAPI({
  int orderState = OrderState.all,
  int page = 1,
  int pageSize = 10,
}) async {
  final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
  if (orderState != OrderState.all) {
    params['orderState'] = orderState;
  }
  return OrderListResult.fromJson(
    asMap(await dioRequest.get(HttpConstants.order, params: params)),
  );
}

/// 订单详情
Future<OrderDetail> getOrderDetailAPI(String orderId) async {
  return OrderDetail.fromJson(
    asMap(await dioRequest.get('${HttpConstants.order}/$orderId')),
  );
}

/// 删除订单（接口要求 id 放在请求体的 `ids` 数组里，支持批量）
Future<void> deleteOrderAPI(List<String> orderIds) async {
  await dioRequest.delete(HttpConstants.order, data: {'ids': orderIds});
}
