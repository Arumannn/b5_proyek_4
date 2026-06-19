import 'package:b5_proyek_4/data/services/hive_service.dart';
import 'package:b5_proyek_4/domain/models/event/event_model.dart';
import 'package:b5_proyek_4/domain/models/event/event_invitation.dart';

class EventLocalDataSource {
  List<EventModel> getAllEvents() {
    final events = HiveService.events.values.toList();
    events.sort((a, b) => a.tanggalMulai.compareTo(b.tanggalMulai));
    return events;
  }

  EventModel? getEventById(String eventId) {
    return HiveService.events.get(eventId);
  }

  Future<void> saveEvent(EventModel event) async {
    await HiveService.events.put(event.eventId, event);
  }

  Future<void> saveInvitation(EventInvitation invitation) async {
    await HiveService.invitations.put(invitation.compositeKey, invitation);
  }

  bool hasInvitation(String eventId, String nim) {
    return HiveService.invitations.values.any(
      (inv) => inv.eventId == eventId && inv.nim == nim,
    );
  }

  List<EventModel> getPendingSyncedEvents() {
    return HiveService.events.values.where((e) => !e.isSynced).toList();
  }
}
