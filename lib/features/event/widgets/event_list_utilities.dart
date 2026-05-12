import 'package:flutter/material.dart';

/// Utility methods for event list view formatting and styling
class EventListUtilities {
  /// Format date as DD/MM/YYYY
  static String formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }

  /// Format date and time as DD/MM/YYYY HH:MM
  static String formatDateTime(DateTime date) {
    final datePart = formatDate(date);
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$datePart $hh:$mm';
  }

  /// Get color based on event jenis (type)
  static Color getJenisColor(String jenis) {
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
}
