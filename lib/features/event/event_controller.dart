import 'package:flutter/foundation.dart';

// TODO Week 9: Implementasi penuh EventController
// import '../../models/event_model.dart';
// import '../../core/services/hive_service.dart';
// import '../../core/constants/app_constants.dart';

/// Controller untuk CRUD Event secara offline (disimpan ke Hive).
///
/// RULES:
/// - Semua operasi disimpan ke Hive dulu (offline-first)
/// - Validasi: nama wajib diisi, tanggal tidak boleh masa lalu
/// - State di-expose via ValueNotifier — BUKAN setState di View
///
/// Implementasi penuh: Week 9
class EventController {
  static final EventController instance = EventController._internal();
  EventController._internal();

  // TODO Week 9:
  // final ValueNotifier<List<EventModel>> events = ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  // TODO Week 9: createEvent(), updateEvent(), deleteEvent(), loadEvents()
}