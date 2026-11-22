import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/models/collect.dart';
import 'package:hm_shop/models/parsers.dart';
import 'package:hm_shop/utils/dio_request.dart';

/// 我的收藏列表
///
/// `collectType` 是必填参数（不传会 500），接口只接受 1 / 2 两种值：
/// 传 0 或 9 会在 SQL 层报 `Error: Method queryTotal execution error`。
/// 演示账号的收藏为空，页面只读取 `collectType = 1` 的商品收藏。
Future<CollectListResult> getCollectListAPI({
  int collectType = 1,
  int page = 1,
  int pageSize = 10,
}) async {
  return CollectListResult.fromJson(
    asMap(
      await dioRequest.get(
        HttpConstants.collect,
        params: {
          'collectType': collectType,
          'page': page,
          'pageSize': pageSize,
        },
      ),
    ),
  );
}
