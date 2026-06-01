import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:b5_proyek_4/core/services/hive_service.dart';
import 'package:b5_proyek_4/features/attendance/permission_form_view.dart';
import 'package:b5_proyek_4/features/auth/auth_controller.dart';
import 'package:b5_proyek_4/models/member_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  const connectivityChannel = MethodChannel('dev.fluttercommunity.plus/connectivity');

  late Directory _tmpDir;

  setUpAll(() async {
    _tmpDir = Directory.systemTemp.createTempSync('hive_perm_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory' ||
          methodCall.method == 'getTemporaryDirectory') {
        return _tmpDir.path;
      }
      return _tmpDir.path;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (methodCall) async {
      if (methodCall.method == 'check') return <String>['none'];
      return null;
    });

    await HiveService.init();
  });

  tearDownAll(() async {
    await HiveService.closeAll();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, null);
    try {
      if (await _tmpDir.exists()) {
        await _tmpDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  setUp(() async {
    await HiveService.permissions.clear();
    await HiveService.members.clear();
  });

  testWidgets('Displays event title and submits permission', (WidgetTester tester) async {
    // Arrange: set current user
    final member = MemberModel(
      nama: 'Bob',
      nim: 'B2',
      divisi: 'Dev',
      role: 'member',
      password: 'pass',
      qrCodeValue: 'qr',
    );
    await tester.runAsync(() async {
      await HiveService.members.put(member.nim, member);
    });
    AuthController.instance.currentUser.value = member;

    var submitted = false;

    await tester.pumpWidget(MaterialApp(
      home: PermissionFormView(
        eventId: 'evt-1',
        eventTitle: 'Event Test',
        onSuccessSubmit: () => submitted = true,
      ),
    ));

    await tester.pump();

    // Verify event title is shown
    expect(find.text('Event Test'), findsOneWidget);

    // Submit form
    await tester.runAsync(() async {
      await tester.tap(find.text('Kirim Pengajuan'));
      // Allow some time for real filesystem writes in the async flow to complete
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    
    await tester.pump();

    // Assert: permission saved and callback invoked
    expect(submitted, isTrue);
    expect(HiveService.permissions.values.length, 1);
    final saved = HiveService.permissions.values.first;
    expect(saved.eventId, 'evt-1');
    expect(saved.nim, member.nim);

    // Settle all remaining animations and timers (e.g. SnackBar)
    await tester.pumpAndSettle();
  });
}
