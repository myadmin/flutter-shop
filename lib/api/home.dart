import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/utils/DioRequest.dart';

Future<List<BannerItem>> getBannerListAPI() async {
  return (await dioRequest.get(HttpConstants.bannerList) as List).map((item) {
    return BannerItem.fromJson(item as Map<String, dynamic>);
  }).toList();
}
