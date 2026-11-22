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

/// 更新当前登录用户资料
///
/// 接口按「传了才改、没传保持原值」处理（实测只传 `nickname` 时性别与生日不变），
/// 所以页面只提交用户真正改过的字段；返回体里同时带一个 `token`，
/// 调用方需要的话可以据此刷新本地 token。
Future<UserInfo> updateProfileAPI(Map<String, dynamic> data) async {
  return UserInfo.fromJson(
    asMap(await dioRequest.put(HttpConstants.userProfile, data: data)),
  );
}
