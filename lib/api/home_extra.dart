import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/models/home_extra.dart';
import 'package:hm_shop/models/parsers.dart';
import 'package:hm_shop/utils/dio_request.dart';

/// 专题精选（首页大图专题卡）
///
/// 接口只提供列表，没有专题详情接口，所以点卡片只能提示或跳分类。
Future<List<SpecialTopicItem>> getSpecialTopicListAPI() async {
  return asModelList(
    await dioRequest.get(HttpConstants.specialList),
    SpecialTopicItem.fromJson,
  );
}

/// 首页分类楼层（按一级分类分层的商品）
Future<List<HomeFloor>> getHomeFloorListAPI() async {
  return asModelList(
    await dioRequest.get(HttpConstants.homeFloors),
    HomeFloor.fromJson,
  );
}
