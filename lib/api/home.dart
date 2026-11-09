import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/utils/DioRequest.dart';

Future<List<BannerItem>> getBannerListAPI() async {
  return (await dioRequest.get(HttpConstants.bannerList) as List).map((item) {
    return BannerItem.fromJson(item as Map<String, dynamic>);
  }).toList();
}

Future<List<CategoryItem>> getCategoryListAPI() async {
  return (await dioRequest.get(HttpConstants.categoryList) as List).map((item) {
    return CategoryItem.fromJson(item as Map<String, dynamic>);
  }).toList();
}

Future<SpecialRecommendResult> getProductListAPI() async {
  return SpecialRecommendResult.fromJson(
    await dioRequest.get(HttpConstants.productList) as Map<String, dynamic>,
  );
}

// 爆款推荐
Future<SpecialRecommendResult> getInVogueListAPI() async {
  return SpecialRecommendResult.fromJson(
    await dioRequest.get(HttpConstants.inVogueList) as Map<String, dynamic>,
  );
}

// 一站全买
Future<SpecialRecommendResult> getOneStopListAPI() async {
  return SpecialRecommendResult.fromJson(
    await dioRequest.get(HttpConstants.oneStopList) as Map<String, dynamic>,
  );
}

// 推荐列表
Future<List<GoodDetailItem>> getRecommendListAPI(
  Map<String, dynamic> params,
) async {
  return (await dioRequest.get(
    HttpConstants.recommendList,
    params: params,
  ) as List).map((item) {
    return GoodDetailItem.fromJson(item as Map<String, dynamic>);
  }).toList();
}
