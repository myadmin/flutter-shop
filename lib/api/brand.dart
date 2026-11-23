import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/models/brand.dart';
import 'package:hm_shop/models/parsers.dart';
import 'package:hm_shop/utils/dio_request.dart';

/// 品牌好店列表（首页品牌模块）
Future<List<BrandItem>> getBrandListAPI() async {
  return asModelList(
    await dioRequest.get(HttpConstants.brandList),
    BrandItem.fromJson,
  );
}

/// 品牌详情：`/brand/<品牌 id>`
Future<BrandDetail> getBrandDetailAPI(String brandId) async {
  return BrandDetail.fromJson(
    asMap(
      await dioRequest.get(
        '${HttpConstants.brandDetail}/${Uri.encodeComponent(brandId)}',
      ),
    ),
  );
}
