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
    id: json['id'] ?? '',
    account: json['account'] ?? '',
    mobile: json['mobile'] ?? '',
    token: json['token'] ?? '',
    avatar: json['avatar'] ?? '',
    nickname: json['nickname'] ?? '',
    gender: json['gender'] ?? '',
    birthday: json['birthday'] ?? '',
    cityCode: json['cityCode'] ?? '',
    provinceCode: json['provinceCode'] ?? '',
    profession: json['profession'] ?? '',
  );

  bool get isLoggedIn => id.isNotEmpty;
}
