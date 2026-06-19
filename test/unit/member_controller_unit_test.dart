import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:b5_proyek_4/data/services/hive_service.dart';
import 'package:b5_proyek_4/domain/controllers/users/member_controller.dart';
import 'package:b5_proyek_4/domain/models/users/member_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late final Directory testDocumentsDir;

  final controller = MemberController.instance;

  setUpAll(() async {
    testDocumentsDir = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}member_controller_${DateTime.now().microsecondsSinceEpoch}',
    );
    testDocumentsDir.createSync(recursive: true);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return testDocumentsDir.path;
      }
      return testDocumentsDir.path;
    });

    const connectivityChannel = MethodChannel('dev.fluttercommunity.plus/connectivity');
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
        .setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/connectivity'), null);
  });

  setUp(() async {
    await HiveService.members.clear();
    // Reset controller states
    controller.members.value = [];
    controller.filteredMembers.value = [];
    controller.searchQuery.value = '';
    controller.selectedDivision.value = 'Semua';
    controller.availableDivisions.value = ['Semua'];
  });

  group('MemberController Tests', () {
    test('loadMembers extracts unique divisions and updates availableDivisions', () async {
      // Seed some members
      await HiveService.members.put('111', MemberModel(
        nama: 'Alice',
        nim: '111',
        divisi: 'Web',
        role: 'member',
        password: 'pw1',
        qrCodeValue: 'QR111',
      ));
      await HiveService.members.put('222', MemberModel(
        nama: 'Bob',
        nim: '222',
        divisi: 'Mobile',
        role: 'member',
        password: 'pw2',
        qrCodeValue: 'QR222',
      ));
      await HiveService.members.put('333', MemberModel(
        nama: 'Charlie',
        nim: '333',
        divisi: 'Web',
        role: 'member',
        password: 'pw3',
        qrCodeValue: 'QR333',
      ));

      controller.loadMembers();

      expect(controller.members.value.length, equals(3));
      expect(controller.filteredMembers.value.length, equals(3));
      // Division set is {'Mobile', 'Web'} sorted alphabetically -> ['Semua', 'Mobile', 'Web']
      expect(controller.availableDivisions.value, equals(['Semua', 'Mobile', 'Web']));
    });

    test('setSearchQuery filters members by name or NIM', () async {
      await HiveService.members.put('111', MemberModel(
        nama: 'Alice Smith',
        nim: '111222',
        divisi: 'Web',
        role: 'member',
        password: 'pw',
        qrCodeValue: 'QR111',
      ));
      await HiveService.members.put('222', MemberModel(
        nama: 'Bob Johnson',
        nim: '222333',
        divisi: 'Mobile',
        role: 'member',
        password: 'pw',
        qrCodeValue: 'QR222',
      ));

      controller.loadMembers();

      // Search by name (case insensitive)
      controller.setSearchQuery('alice');
      expect(controller.filteredMembers.value.length, equals(1));
      expect(controller.filteredMembers.value.first.nama, equals('Alice Smith'));

      // Search by NIM
      controller.setSearchQuery('222333');
      expect(controller.filteredMembers.value.length, equals(1));
      expect(controller.filteredMembers.value.first.nama, equals('Bob Johnson'));

      // Non-matching search
      controller.setSearchQuery('Zack');
      expect(controller.filteredMembers.value, isEmpty);
    });

    test('setDivision filters members by selected division', () async {
      await HiveService.members.put('111', MemberModel(
        nama: 'Alice',
        nim: '111',
        divisi: 'Web',
        role: 'member',
        password: 'pw',
        qrCodeValue: 'QR111',
      ));
      await HiveService.members.put('222', MemberModel(
        nama: 'Bob',
        nim: '222',
        divisi: 'Mobile',
        role: 'member',
        password: 'pw',
        qrCodeValue: 'QR222',
      ));

      controller.loadMembers();

      controller.setDivision('Web');
      expect(controller.filteredMembers.value.length, equals(1));
      expect(controller.filteredMembers.value.first.nama, equals('Alice'));

      controller.setDivision('Semua');
      expect(controller.filteredMembers.value.length, equals(2));
    });

    test('getDivisionCount returns correct member count per division', () async {
      await HiveService.members.put('111', MemberModel(
        nama: 'Alice',
        nim: '111',
        divisi: 'Web',
        role: 'member',
        password: 'pw',
        qrCodeValue: 'QR111',
      ));
      await HiveService.members.put('222', MemberModel(
        nama: 'Bob',
        nim: '222',
        divisi: 'Mobile',
        role: 'member',
        password: 'pw',
        qrCodeValue: 'QR222',
      ));
      await HiveService.members.put('333', MemberModel(
        nama: 'Charlie',
        nim: '333',
        divisi: 'Web',
        role: 'member',
        password: 'pw',
        qrCodeValue: 'QR333',
      ));

      controller.loadMembers();

      expect(controller.getDivisionCount('Semua'), equals(3));
      expect(controller.getDivisionCount('Web'), equals(2));
      expect(controller.getDivisionCount('Mobile'), equals(1));
      expect(controller.getDivisionCount('Design'), equals(0));
    });

    test('Filters combine search query and division filter correctly', () async {
      await HiveService.members.put('111', MemberModel(
        nama: 'Alice Smith',
        nim: '111',
        divisi: 'Web',
        role: 'member',
        password: 'pw',
        qrCodeValue: 'QR111',
      ));
      await HiveService.members.put('222', MemberModel(
        nama: 'Alice Cooper',
        nim: '222',
        divisi: 'Mobile',
        role: 'member',
        password: 'pw',
        qrCodeValue: 'QR222',
      ));

      controller.loadMembers();

      // Filter to division 'Web' and search query 'Alice' -> only Alice Smith (Web) matches
      controller.setDivision('Web');
      controller.setSearchQuery('Alice');

      expect(controller.filteredMembers.value.length, equals(1));
      expect(controller.filteredMembers.value.first.nama, equals('Alice Smith'));
    });
  });
}
