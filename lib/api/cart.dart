import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/utils/dio_request.dart';

// 加入购物车
Future<void> addCartAPI(String skuId, int count) async {
  await dioRequest.post(
    HttpConstants.cart,
    data: {'skuId': skuId, 'count': count},
  );
}
