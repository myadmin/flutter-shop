import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/models/parsers.dart';
import 'package:hm_shop/models/user.dart';
import 'package:hm_shop/utils/dio_request.dart';

/// 手机号密码登录
Future<UserInfo> loginAPI(Map<String, dynamic> data) async {
  return UserInfo.fromJson(
    asMap(await dioRequest.post(HttpConstants.login, data: data)),
  );
}

/// 当前登录用户信息
Future<UserInfo> getUserInfoAPI() async {
  return UserInfo.fromJson(
    asMap(await dioRequest.get(HttpConstants.userProfile)),
  );
}
