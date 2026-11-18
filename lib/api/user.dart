import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/models/user.dart';
import 'package:hm_shop/utils/DioRequest.dart';

// 登录
Future<UserInfo> loginAPI(Map<String, dynamic> data) async {
  return UserInfo.fromJson(
    await dioRequest.post(HttpConstants.login, data: data),
  );
}

// 用户信息
Future<UserInfo> getUserInfoAPI() async {
  return UserInfo.fromJson(await dioRequest.get(HttpConstants.userProfile));
}
