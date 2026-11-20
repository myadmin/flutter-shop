import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/models/goods.dart';
import 'package:hm_shop/utils/dio_request.dart';

// 获取商品详情
Future<GoodsDetail> getGoodsDetailAPI(String id) async {
  return GoodsDetail.fromJson(
    await dioRequest.get(HttpConstants.goodsDetail, params: {'id': id})
        as Map<String, dynamic>,
  );
}
