import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/models/goods.dart';
import 'package:hm_shop/models/parsers.dart';
import 'package:hm_shop/utils/dio_request.dart';

/// 商品详情
Future<GoodsDetail> getGoodsDetailAPI(String id) async {
  return GoodsDetail.fromJson(
    asMap(await dioRequest.get(HttpConstants.goodsDetail, params: {'id': id})),
  );
}
