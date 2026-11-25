import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hm_shop/components/Mine/hm_mine_about.dart';
import 'package:hm_shop/constants/index.dart';
import 'package:hm_shop/models/app_release.dart';
import 'package:hm_shop/pages/Mine/index.dart';
import 'package:hm_shop/services/app_update_service.dart';
import 'package:hm_shop/stores/user_controller.dart';

import 'helpers/mock_http.dart';

/// 假的版本更新服务：不发真实请求，记录调用情况
class _FakeUpdateService extends AppUpdateService {
  _FakeUpdateService({
    this.version = '1.0.13',
    this.release,
    this.openResult = true,
  }) : super(enabled: true);

  final String version;
  final AppRelease? release;
  final bool openResult;

  int checkCalls = 0;
  int releasePageCalls = 0;
  bool? lastForce;
  AppRelease? openedRelease;
  AppRelease? skippedRelease;

  @override
  Future<String> currentVersion() async => version;

  @override
  Future<AppRelease?> check({bool force = false}) async {
    checkCalls++;
    lastForce = force;
    return release;
  }

  @override
  Future<bool> openDownload(AppRelease release) async {
    openedRelease = release;
    return openResult;
  }

  @override
  Future<bool> openReleasesPage() async {
    releasePageCalls++;
    return openResult;
  }

  @override
  Future<void> skip(AppRelease release) async {
    skippedRelease = release;
  }
}

AppRelease _release() => AppRelease.fromJson(<String, dynamic>{
  'tag_name': 'v1.0.14',
  'body': '修了点东西',
  'html_url': 'https://github.com/myadmin/flutter-shop/releases/tag/v1.0.14',
  'assets': <dynamic>[
    <String, dynamic>{
      'name': 'app-arm64-v8a-release.apk',
      'browser_download_url': 'https://example.com/app-arm64-v8a-release.apk',
      'size': 19324916,
    },
  ],
});

/// 把「我的」页渲染出来，网络请求全部走 mock
Future<void> _pumpMine(WidgetTester tester, _FakeUpdateService service) async {
  Get.reset();
  Get.put(UserController(), permanent: true);
  addTearDown(Get.reset);
  installMock((options) {
    if (options.uri.path == HttpConstants.guessList) {
      return envelope(<String, dynamic>{
        'counts': 0,
        'pages': 0,
        'page': 1,
        'items': <dynamic>[],
      });
    }
    return envelope(null);
  });
  tester.view.physicalSize = const Size(414, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: MineView(updateService: service)),
    ),
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 50));
}

/// 指定目标平台跑一段用例体：`debugDefaultTargetPlatformOverride` 必须在用例体内复位，
/// 交给 `addTearDown` 会晚于框架的 debug 变量检查。
Future<void> _runMine(
  WidgetTester tester,
  _FakeUpdateService service,
  Future<void> Function() body, {
  TargetPlatform platform = TargetPlatform.iOS,
}) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await _pumpMine(tester, service);
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  group('HmMineAbout', () {
    testWidgets('展示当前版本与两个入口', (tester) async {
      var checked = 0;
      var downloaded = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HmMineAbout(
              versionText: '1.0.13',
              onCheckUpdate: () => checked++,
              onDownload: () => downloaded++,
            ),
          ),
        ),
      );

      expect(find.text('关于'), findsOneWidget);
      expect(find.text('v1.0.13'), findsOneWidget);
      expect(find.text('检查更新'), findsOneWidget);
      expect(find.text('下载 Android 安装包'), findsOneWidget);
      // 「当前版本」行不可点，所以只有两个箭头
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));

      await tester.tap(find.text('检查更新'));
      await tester.tap(find.text('下载 Android 安装包'));
      expect(checked, 1);
      expect(downloaded, 1);
    });

    testWidgets('读不到版本号时展示 --', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HmMineAbout(versionText: '')),
        ),
      );
      expect(find.text('--'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('不传下载回调时不展示下载行', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HmMineAbout(versionText: '1.0.13', onCheckUpdate: () {}),
          ),
        ),
      );
      expect(find.text('下载 Android 安装包'), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });

  group('「我的」页关于卡片', () {
    testWidgets('展示从服务读到的版本号', (tester) async {
      final service = _FakeUpdateService(version: '1.0.13');
      await _pumpMine(tester, service);

      expect(find.text('当前版本'), findsOneWidget);
      expect(find.text('v1.0.13'), findsOneWidget);
    });

    testWidgets('没有新版时提示已是最新，并强制刷新一次', (tester) async {
      final service = _FakeUpdateService(version: '1.0.13');
      await _pumpMine(tester, service);

      await tester.tap(find.text('检查更新'));
      await tester.pumpAndSettle();

      expect(service.checkCalls, 1);
      expect(service.lastForce, isTrue);
      expect(find.text('当前已是最新版本 v1.0.13'), findsOneWidget);
    });

    testWidgets('有新版时弹窗，点立即更新调用下载', (tester) async {
      final service = _FakeUpdateService(
        version: '1.0.13',
        release: _release(),
      );
      await _pumpMine(tester, service);

      await tester.tap(find.text('检查更新'));
      await tester.pumpAndSettle();

      expect(find.text('发现新版本 v1.0.14'), findsOneWidget);
      await tester.tap(find.text('立即更新'));
      await tester.pumpAndSettle();

      expect(service.openedRelease?.versionName, '1.0.14');
    });

    testWidgets('点跳过此版本会写入跳过记录', (tester) async {
      final service = _FakeUpdateService(
        version: '1.0.13',
        release: _release(),
      );
      await _pumpMine(tester, service);

      await tester.tap(find.text('检查更新'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('跳过此版本'));
      await tester.pumpAndSettle();

      expect(service.skippedRelease?.versionName, '1.0.14');
    });

    testWidgets('点下载安装包会打开 Release 页面', (tester) async {
      final service = _FakeUpdateService(version: '1.0.13');
      await _runMine(tester, service, () async {
        await tester.tap(find.text('下载 Android 安装包'));
        await tester.pumpAndSettle();

        expect(service.releasePageCalls, 1);
      });
    });

    testWidgets('打不开下载页时给出提示', (tester) async {
      final service = _FakeUpdateService(version: '1.0.13', openResult: false);
      await _runMine(tester, service, () async {
        await tester.tap(find.text('下载 Android 安装包'));
        await tester.pumpAndSettle();

        expect(find.text('打开下载页失败，请稍后再试'), findsOneWidget);
      });
    });

    testWidgets('安卓端不展示下载入口', (tester) async {
      final service = _FakeUpdateService(version: '1.0.13');
      await _runMine(tester, service, () async {
        expect(find.text('下载 Android 安装包'), findsNothing);
        expect(find.text('检查更新'), findsOneWidget);
      }, platform: TargetPlatform.android);
    });
  });
}
