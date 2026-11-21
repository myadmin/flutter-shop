import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/models/category_goods.dart';
import 'package:hm_shop/models/parsers.dart';
import 'package:hm_shop/utils/dio_request.dart';

/// 分类下的商品
///
/// 接口只认 `id` 参数（传 `categoryId` 会 500），并且不分页：单个二级分类
/// 最多十几件商品，一次返回全部，同时带回同级分类供列表页顶部切换。
Future<CategoryGoodsResult> getCategoryGoodsAPI(String categoryId) async {
  return CategoryGoodsResult.fromJson(
    asMap(
      await dioRequest.get(
        HttpConstants.categoryGoods,
        params: {'id': categoryId},
      ),
    ),
  );
}
