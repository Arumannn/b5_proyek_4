import 'package:flutter/foundation.dart';

import 'package:b5_proyek_4/domain/models/attendance/attendance_record.dart';

import 'package:b5_proyek_4/data/datasources/local/attendance/attendance_local_data_source.dart';
import 'package:b5_proyek_4/data/datasources/remote/attendance/attendance_remote_data_source.dart';
import 'package:b5_proyek_4/data/repositories/attendance/attendance_repository.dart';

enum AttendanceResult {
  successHadir,
  successTerlambat,
  duplicate,
  memberNotFound,
  eventNotFound,
  mainEventHasSubEvents,
  error,
}

class AttendanceController {
  static final AttendanceController instance = AttendanceController._internal();
  
  late final AttendanceRepository _repository;

  AttendanceController._internal() {
    _repository = AttendanceRepository(
      AttendanceLocalDataSource(),
      AttendanceRemoteDataSource(),
    );
  }

  final ValueNotifier<bool> isProcessing = ValueNotifier(false);
  final ValueNotifier<AttendanceResult?> lastResult = ValueNotifier(null);
  final ValueNotifier<String?> lastScannedName = ValueNotifier(null);
  final ValueNotifier<String?> lastFailureReason = ValueNotifier(null);

  Future<AttendanceResult> recordAttendance({
    required String eventId,
    required String scannedQrValue,
  }) async {
    if (isProcessing.value) return AttendanceResult.error;
    isProcessing.value = true;
    lastResult.value = null;
    lastFailureReason.value = null;

    try {
      final resultData = await _repository.recordAttendance(
        eventId: eventId,
        scannedQrValue: scannedQrValue,
      );

      lastScannedName.value = resultData.scannedName;
      lastFailureReason.value = resultData.failureReason;

      final resultEnum = _mapStatusToEnum(resultData.status);
      lastResult.value = resultEnum;

      return resultEnum;
    } catch (e) {
      lastFailureReason.value = 'Exception: $e';
      lastResult.value = AttendanceResult.error;
      return AttendanceResult.error;
    } finally {
      isProcessing.value = false;
    }
  }

  List<AttendanceRecord> getAttendanceByEvent(String eventId) {
    return _repository.getAttendanceByEvent(eventId);
  }

  List<AttendanceRecord> getAttendanceByMember(String nim) {
    return _repository.getAttendanceByMember(nim);
  }

  Future<void> preloadMembersFromCloudToHive() async {
    await _repository.preloadMembersFromCloudToHive();
  }

  Future<bool> overrideAttendanceStatus({
    required String recordId,
    required String newStatus,
    required String overrideById,
  }) async {
    return await _repository.overrideAttendanceStatus(
      recordId: recordId,
      newStatus: newStatus,
      overrideById: overrideById,
    );
  }

  Future<void> generateAlphaRecords(String eventId) async {
    await _repository.generateAlphaRecords(eventId);
  }

  Future<bool> addManualAttendance({
    required String eventId,
    required String nim,
    required String status,
  }) async {
    final result = await _repository.addManualAttendance(
      eventId: eventId,
      nim: nim,
      status: status,
    );
    if (result.failureReason != null) {
      lastFailureReason.value = result.failureReason;
    }
    return result.status == 'success';
  }

  Future<bool> deleteAttendanceRecord(String recordId) async {
    return await _repository.deleteAttendanceRecord(recordId);
  }

  void dispose() {
    isProcessing.dispose();
    lastResult.dispose();
    lastScannedName.dispose();
    lastFailureReason.dispose();
  }

  AttendanceResult _mapStatusToEnum(String status) {
    switch (status) {
      case 'successHadir':
        return AttendanceResult.successHadir;
      case 'successTerlambat':
        return AttendanceResult.successTerlambat;
      case 'duplicate':
        return AttendanceResult.duplicate;
      case 'memberNotFound':
        return AttendanceResult.memberNotFound;
      case 'eventNotFound':
        return AttendanceResult.eventNotFound;
      case 'mainEventHasSubEvents':
        return AttendanceResult.mainEventHasSubEvents;
      default:
        return AttendanceResult.error;
    }
  }
}
