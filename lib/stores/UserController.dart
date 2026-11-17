import 'package:get/get.dart';
import 'package:hm_shop/models/user.dart';

class UserController extends GetxController {
  var user = UserInfo.fromJson({}).obs;

  void updateUserInfo(UserInfo newUser) {
    user.value = newUser;
  }
}
