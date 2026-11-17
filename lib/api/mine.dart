import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/utils/DioRequest.dart';

// 获取猜你喜欢列表
Future<GoodsDetailsItems> getGuessListAPI(Map<String, dynamic> params) async {
  return GoodsDetailsItems.fromJson(
    await dioRequest.get(HttpConstants.guessList, params: params),
  );
}
