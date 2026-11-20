import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hm_shop/models/user.dart';
import 'package:hm_shop/stores/user_controller.dart';

void main() {
  group('UserController 全局用户态', () {
    late UserController controller;

    setUp(() {
      Get.reset();
      controller = Get.put(UserController(), permanent: true);
    });

    tearDown(Get.reset);

    test('初始状态为未登录', () {
      expect(controller.user.value.isLoggedIn, isFalse);
      expect(controller.isLoggedIn, isFalse);
      expect(controller.user.value.id, '');
    });

    test('updateUserInfo 后进入已登录状态', () {
      controller.updateUserInfo(
        UserInfo.fromJson(<String, dynamic>{
          'id': '4026450',
          'nickname': '测试账号',
          'token': 'token-123',
        }),
      );

      expect(controller.isLoggedIn, isTrue);
      expect(controller.user.value.nickname, '测试账号');
    });

    test('clearUserInfo 能恢复到未登录状态', () {
      controller.updateUserInfo(
        UserInfo.fromJson(<String, dynamic>{'id': '1', 'nickname': '测试'}),
      );
      expect(controller.isLoggedIn, isTrue);

      controller.clearUserInfo();

      expect(controller.isLoggedIn, isFalse);
      expect(controller.user.value.id, '');
    });

    test('user 是响应式的，赋值会触发监听', () {
      var notified = 0;
      final worker = ever(controller.user, (_) => notified++);

      controller.updateUserInfo(
        UserInfo.fromJson(<String, dynamic>{'id': '1'}),
      );
      controller.updateUserInfo(
        UserInfo.fromJson(<String, dynamic>{'id': '2'}),
      );
      controller.clearUserInfo();

      expect(notified, 3);
      worker.dispose();
    });

    test('重复 Get.put 不会替换已注册的实例', () {
      final again = Get.put(UserController(), permanent: true);

      // 注册点统一在 main()，页面侧重复 put 只会拿到同一个实例
      expect(identical(again, controller), isTrue);
    });
  });
}
