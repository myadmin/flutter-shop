import 'package:hm_shop/models/parsers.dart';

// 用户信息（/login 接口返回的 result 数据）
class UserInfo {
  String id;
  String account;
  String mobile;
  String token;
  String avatar;
  String nickname;
  String gender;
  String birthday;
  String cityCode;
  String provinceCode;
  String profession;

  UserInfo({
    required this.id,
    required this.account,
    required this.mobile,
    required this.token,
    required this.avatar,
    required this.nickname,
    required this.gender,
    required this.birthday,
    required this.cityCode,
    required this.provinceCode,
    required this.profession,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
    id: asString(json['id']),
    account: asString(json['account']),
    mobile: asString(json['mobile']),
    token: asString(json['token']),
    avatar: asString(json['avatar']),
    nickname: asString(json['nickname']),
    gender: asString(json['gender']),
    birthday: asString(json['birthday']),
    cityCode: asString(json['cityCode']),
    provinceCode: asString(json['provinceCode']),
    profession: asString(json['profession']),
  );

  /// 空用户，用于「未登录」状态的初值与退出登录后的复位
  factory UserInfo.empty() => UserInfo.fromJson(const <String, dynamic>{});

  bool get isLoggedIn => id.isNotEmpty;
}
