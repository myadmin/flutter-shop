import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/models/parsers.dart';
import 'package:hm_shop/utils/dio_request.dart';

/// 猜你喜欢列表
Future<GoodsDetailsItems> getGuessListAPI(Map<String, dynamic> params) async {
  return GoodsDetailsItems.fromJson(
    asMap(await dioRequest.get(HttpConstants.guessList, params: params)),
  );
}
