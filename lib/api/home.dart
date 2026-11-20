import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/models/parsers.dart';
import 'package:hm_shop/utils/dio_request.dart';

/// 首页轮播图
Future<List<BannerItem>> getBannerListAPI() async {
  return asModelList(
    await dioRequest.get(HttpConstants.bannerList),
    BannerItem.fromJson,
  );
}

/// 分类金刚区
Future<List<CategoryItem>> getCategoryListAPI() async {
  return asModelList(
    await dioRequest.get(HttpConstants.categoryList),
    CategoryItem.fromJson,
  );
}

/// 专题推荐（特惠推荐）
Future<SpecialRecommendResult> getProductListAPI() async {
  return SpecialRecommendResult.fromJson(
    asMap(await dioRequest.get(HttpConstants.productList)),
  );
}

/// 爆款推荐
Future<SpecialRecommendResult> getInVogueListAPI() async {
  return SpecialRecommendResult.fromJson(
    asMap(await dioRequest.get(HttpConstants.inVogueList)),
  );
}

/// 一站全买
Future<SpecialRecommendResult> getOneStopListAPI() async {
  return SpecialRecommendResult.fromJson(
    asMap(await dioRequest.get(HttpConstants.oneStopList)),
  );
}

/// 推荐列表
///
/// 该接口只支持 `limit`，不支持 `page`/`pageSize`：每次返回前 limit 条，
/// 顺序稳定，所以调用方用递增 limit 的方式累积加载。
Future<List<GoodDetailItem>> getRecommendListAPI(
  Map<String, dynamic> params,
) async {
  return asModelList(
    await dioRequest.get(HttpConstants.recommendList, params: params),
    GoodDetailItem.fromJson,
  );
}
