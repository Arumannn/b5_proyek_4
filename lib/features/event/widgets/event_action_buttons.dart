import 'package:flutter/material.dart';
import '../../../models/event_model.dart';
import '../../attendance/scan_screen.dart';
import '../event_controller.dart';

/// Widget that displays action buttons for an event (Scan, Edit, Delete, Add Sub-Event)
class EventActionButtons extends StatelessWidget {
  final EventModel event;
  final bool canUpdateMainEvent;
  final bool canUpdateSubEvent;
  final bool canDeleteMainEvent;
  final bool canDeleteSubEvent;
  final bool canCreateSubEvent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddSubEvent;
  final String? forcedParentId;
  final EventController controller;

  const EventActionButtons({
    super.key,
    required this.event,
    required this.canUpdateMainEvent,
    required this.canUpdateSubEvent,
    required this.canDeleteMainEvent,
    required this.canDeleteSubEvent,
    required this.canCreateSubEvent,
    required this.onEdit,
    required this.onDelete,
    required this.onAddSubEvent,
    required this.controller,
    this.forcedParentId,
  });

  @override
  Widget build(BuildContext context) {
    final isSubEvent = event.parentEventId != null; // RBAC: Tentukan paket izin per scope.
    final hasSubEvents = !isSubEvent && controller.getSubEvents(event.eventId).isNotEmpty;
    final canEdit = isSubEvent ? canUpdateSubEvent : canUpdateMainEvent; // RBAC: UPDATE berbeda antara main/sub.
    final canScan = canEdit && (isSubEvent || !hasSubEvents);
    final canDelete = isSubEvent ? canDeleteSubEvent : canDeleteMainEvent; // RBAC: DELETE berbeda antara main/sub.
    final canAddSubEvent = !isSubEvent && canCreateSubEvent; // RBAC: CREATE sub-event boleh Executive/Manager pada parent main event.

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (canScan)
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ScanScreen(eventId: event.eventId),
                ),
              );
            },
            icon: const Icon(Icons.qr_code_scanner, size: 18),
            label: const Text('Scan'),
          ),
        if (canEdit)
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
          ),
        if (canDelete)
          OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Hapus'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        if (canAddSubEvent)
          OutlinedButton.icon(
            onPressed: onAddSubEvent,
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Tambah Sub-Event'),
          ),
      ],
    );
  }
}
