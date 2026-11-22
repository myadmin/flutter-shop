import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/models/user.dart';
import 'package:hm_shop/pages/Mine/index.dart';
import 'package:hm_shop/pages/Profile/index.dart';
import 'package:hm_shop/stores/token_manager.dart';
import 'package:hm_shop/stores/user_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/mock_http.dart';

/// 记录页面跳转，用于断言「点了之后有没有进到目标页」
class _RouteRecorder extends NavigatorObserver {
  final List<String> pushedNames = [];
  final List<String> poppedNames = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null) {
      pushedNames.add(name);
    }
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null) {
      poppedNames.add(name);
    }
    super.didPop(route, previousRoute);
  }
}

void main() {
  late UserController userController;

  setUp(() {
    Get.reset();
    // 资料保存会把新 token 写进 SharedPreferences，这里用内存实现
    SharedPreferences.setMockInitialValues({});
    userController = Get.put(UserController(), permanent: true);
  });

  tearDown(Get.reset);

  /// 从「上一页」推进资料页：保存成功后页面会 pop，需要下面垫一层路由，
  /// 否则弹掉唯一的路由后 Navigator 里什么都不剩
  Future<_RouteRecorder> pumpProfilePage(WidgetTester tester) async {
    final recorder = _RouteRecorder();
    tester.view.physicalSize = const Size(414, 896);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    settings: const RouteSettings(name: '/profile'),
                    builder: (_) => const ProfilePage(),
                  ),
                ),
                child: const Text('打开资料'),
              ),
            ),
          ),
        ),
        navigatorObservers: [recorder],
      ),
    );
    await tester.tap(find.text('打开资料'));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    return recorder;
  }

  testWidgets('加载成功后回填资料，只读项不可点击', (tester) async {
    installMock((options) => envelope(userProfileJson()));

    await pumpProfilePage(tester);

    expect(find.text('个人资料'), findsOneWidget);
    expect(find.text('晚星12'), findsOneWidget);
    expect(find.text('前端工程师'), findsOneWidget);
    expect(find.text('女'), findsOneWidget);
    expect(find.text('1995-06-18'), findsOneWidget);
    expect(find.text('河南省 郑州市 中原区'), findsOneWidget);
    expect(find.text('用户13800138000'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);
  });

  testWidgets('保存时只提交改动过的字段，并把新 token 写回本地', (tester) async {
    final adapter = installMock((options) {
      if (options.method == 'PUT') {
        return envelope(userProfileJson(nickname: '新昵称'));
      }
      return envelope(userProfileJson());
    });

    final recorder = await pumpProfilePage(tester);
    await tester.enterText(find.byType(TextField).first, '新昵称');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    final put = adapter.requestsWhere('PUT').single;
    expect(put.path, HttpConstants.userProfile);
    expect(put.data, {'nickname': '新昵称'});
    expect(find.text('资料已保存'), findsOneWidget);
    expect(userController.user.value.nickname, '新昵称');
    expect(tokenManager.getToken(), 'token-new');
    // 保存成功后回到上一页
    expect(recorder.poppedNames, contains('/profile'));
    expect(find.text('打开资料'), findsOneWidget);
  });

  testWidgets('没有改动时提示并不发请求', (tester) async {
    final adapter = installMock((options) => envelope(userProfileJson()));

    await pumpProfilePage(tester);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    expect(find.text('资料没有改动'), findsOneWidget);
    expect(adapter.requestsWhere('PUT'), isEmpty);
    // 没有保存成功，仍停留在资料页
    expect(find.text('个人资料'), findsOneWidget);
  });

  testWidgets('昵称为空或超长时拦截保存', (tester) async {
    final adapter = installMock((options) => envelope(userProfileJson()));

    await pumpProfilePage(tester);
    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    expect(find.text('昵称不能为空'), findsOneWidget);
    expect(adapter.requestsWhere('PUT'), isEmpty);
  });

  testWidgets('点击头像给出「不支持修改」的提示', (tester) async {
    installMock((options) => envelope(userProfileJson()));

    await pumpProfilePage(tester);
    await tester.tap(find.text('头像'));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    expect(find.text('演示接口没有头像上传通道，暂不支持修改头像'), findsOneWidget);
  });

  testWidgets('加载失败后可以重试', (tester) async {
    var callCount = 0;
    installMock((options) {
      callCount++;
      if (callCount == 1) {
        return envelopeError('资料服务异常');
      }
      return envelope(userProfileJson());
    });

    await pumpProfilePage(tester);
    expect(find.text('资料服务异常'), findsOneWidget);

    await tester.tap(find.text('重新加载'));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    expect(find.text('晚星12'), findsOneWidget);
    expect(callCount, 2);
  });

  testWidgets('「我的」页点昵称进入个人资料页', (tester) async {
    userController.updateUserInfo(UserInfo.fromJson(userProfileJson()));
    installMock((options) {
      if (options.path == HttpConstants.guessList) {
        return envelope(<String, dynamic>{
          'counts': 0,
          'pages': 0,
          'page': 1,
          'items': <dynamic>[],
        });
      }
      if (options.path == HttpConstants.order) {
        return envelope(
          orderListJson(counts: 0, pages: 0, items: <Map<String, dynamic>>[]),
        );
      }
      return envelope(<String, dynamic>{});
    });

    final recorder = _RouteRecorder();
    tester.view.physicalSize = const Size(414, 896);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(body: MineView()),
        navigatorObservers: [recorder],
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    await tester.tap(find.text('晚星12'));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    expect(recorder.pushedNames, contains('/profile'));
  });
}
