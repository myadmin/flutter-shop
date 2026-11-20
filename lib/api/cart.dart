import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/models/cart.dart';
import 'package:hm_shop/models/parsers.dart';
import 'package:hm_shop/utils/dio_request.dart';

/// 购物车列表
Future<List<CartItem>> getCartListAPI() async {
  return asModelList(
    await dioRequest.get(HttpConstants.cart),
    CartItem.fromJson,
  );
}

/// 购物车商品件数，用于底部 tab 角标
Future<int> getCartCountAPI() async {
  final result = await dioRequest.get(HttpConstants.cartCount);
  // 接口目前返回 {"count": 13}，这里兼容直接返回数字的情况
  if (result is num) return result.toInt();
  return asInt(asMap(result)['count']);
}

/// 加入购物车；同一规格重复加入时接口会累加数量并返回该条目
Future<CartItem> addCartAPI(String skuId, int count) async {
  return CartItem.fromJson(
    asMap(
      await dioRequest.post(
        HttpConstants.cart,
        data: {'skuId': skuId, 'count': count},
      ),
    ),
  );
}

/// 修改指定规格的数量 / 选中状态，未传的字段保持不变
Future<CartItem> updateCartItemAPI(
  String skuId, {
  int? count,
  bool? selected,
}) async {
  final data = <String, dynamic>{};
  if (count != null) data['count'] = count;
  if (selected != null) data['selected'] = selected;
  return CartItem.fromJson(
    asMap(await dioRequest.put('${HttpConstants.cart}/$skuId', data: data)),
  );
}

/// 删除购物车条目；接口按规格 id 批量删除，参数放在请求体里
Future<bool> deleteCartItemsAPI(List<String> skuIds) async {
  final result = await dioRequest.delete(
    HttpConstants.cart,
    data: {'ids': skuIds},
  );
  return asBool(result);
}
