import 'package:flutter/material.dart';
import '../../../core/services/hive_service.dart';
import '../../../models/event_model.dart';
import '../../../models/attendance_record.dart';

/// Data class for event form submission
class EventFormData {
  const EventFormData({
    required this.name,
    required this.date,
    required this.jenis,
    this.parentEventId,
    this.lokasi,
    this.deskripsi,
    this.targetPeserta = const <String>[],
  });

  final String name;
  final DateTime date;
  final String jenis;
  final String? parentEventId;
  final String? lokasi;
  final String? deskripsi;
  final List<String> targetPeserta;
}

/// Utility class for event-related helper methods
class EventUtilities {
  /// Format DateTime to DD/MM/YYYY format
  static String formatDate(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    return '$dd/$mm/$yyyy';
  }

  /// Get color for event type chip
  static Color chipColor(String jenis) {
    switch (jenis) {
      case 'Rapat':
        return Colors.blue;
      case 'Acara':
        return Colors.purple;
      case 'Kegiatan':
        return Colors.green;
      case 'Lainnya':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Get attendance records for an event
  static List<AttendanceRecord> attendanceForEvent(String eventId) {
    return HiveService.attendance.values
        .where((record) => record.eventId == eventId)
        .toList(growable: false);
  }

  /// Get event status label (Selesai/Berlangsung)
  static String eventStatusLabel(EventModel event) {
    final now = DateTime.now();
    final isCompleted = now.isAfter(event.tanggalMulai.add(const Duration(hours: 1)));
    return isCompleted ? 'Selesai' : 'Berlangsung';
  }

  /// Get color for event status
  static Color eventStatusColor(EventModel event) {
    final now = DateTime.now();
    final isCompleted = now.isAfter(event.tanggalMulai.add(const Duration(hours: 1)));
    return isCompleted ? const Color(0xFF22C55E) : const Color(0xFF2563EB);
  }

  /// Get background color for event status badge
  static Color eventStatusBgColor(EventModel event) {
    final now = DateTime.now();
    final isCompleted = now.isAfter(event.tanggalMulai.add(const Duration(hours: 1)));
    return isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE);
  }

  /// Get location text or default
  static String eventLocation(EventModel event) {
    final lokasiValue = event.lokasi?.trim();
    if (lokasiValue != null && lokasiValue.isNotEmpty) return lokasiValue;
    return 'Lokasi belum diatur';
  }

  /// Calculate target count for attendance
  static int targetCount(EventModel event, int presentCount) {
    final target = event.targetPeserta.length;
    if (target > 0) return target;
    return presentCount > 0 ? presentCount : 1;
  }

  /// Normalize status string
  static String normalizedStatus(String value) {
    return value.trim().toLowerCase();
  }

  /// Get accent color based on event status
  static Color eventAccentColor(EventModel event) {
    final status = normalizedStatus(event.statusEvent);
    if (status.contains('selesai')) return const Color(0xFF22C55E);
    if (status.contains('berlangsung') || status.contains('berjalan')) return const Color(0xFF2563EB);
    return const Color(0xFFF97316);
  }

  /// Get tint color based on event accent
  static Color eventTintColor(EventModel event) {
    final accent = eventAccentColor(event);
    if (accent == const Color(0xFF2563EB)) return const Color(0xFFDBEAFE);
    if (accent == const Color(0xFF22C55E)) return const Color(0xFFDCFCE7);
    return const Color(0xFFFFF7ED);
  }

  /// Get event status title
  static String eventStatusTitle(EventModel event) {
    final status = normalizedStatus(event.statusEvent);
    if (status.contains('selesai')) return 'Selesai';
    if (status.contains('berlangsung') || status.contains('berjalan')) return 'Berlangsung';
    return 'Mendatang';
  }
}
