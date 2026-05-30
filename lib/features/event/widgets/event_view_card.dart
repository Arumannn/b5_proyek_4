import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/event_model.dart';
import '../../../core/enums/status_enums.dart';
import '../../auth/auth_controller.dart';
import '../event_controller.dart';
import '../event_detail_view.dart';
import 'event_action_buttons.dart';
import 'event_utilities.dart';

/// Widget that displays a single event card with attendance, sub-events, and actions
/// Used in EventView for the detailed card display with expandable sub-events
class EventViewCard extends StatefulWidget {
  final EventModel event;
  final EventController controller;
  final Map<String, bool> expandedState;
  final bool canUpdateMainEvent;
  final bool canUpdateSubEvent;
  final bool canDeleteMainEvent;
  final bool canDeleteSubEvent;
  final bool canCreateSubEvent;
  final bool hasAnyCrudAccess;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddSubEvent;
  final VoidCallback onExpandedChanged;

  const EventViewCard({
    super.key,
    required this.event,
    required this.controller,
    required this.expandedState,
    required this.canUpdateMainEvent,
    required this.canUpdateSubEvent,
    required this.canDeleteMainEvent,
    required this.canDeleteSubEvent,
    required this.canCreateSubEvent,
    required this.hasAnyCrudAccess,
    required this.onEdit,
    required this.onDelete,
    required this.onAddSubEvent,
    required this.onExpandedChanged,
  });

  @override
  State<EventViewCard> createState() => _EventViewCardState();
}

class _EventViewCardState extends State<EventViewCard> {
  @override
  Widget build(BuildContext context) {
    final subEvents = widget.controller.getSubEvents(widget.event.eventId);
    final isExpanded = widget.expandedState[widget.event.eventId] ?? false;
    final attendance = EventUtilities.attendanceForEvent(widget.event.eventId);
    final presentCount = attendance.where((r) => r.statusEnum == AttendanceStatus.hadir || r.statusEnum == AttendanceStatus.terlambat).length;
    final targetCount = EventUtilities.targetCount(widget.event, presentCount);
    final attendancePercent = targetCount == 0 ? 0.0 : (presentCount / targetCount).clamp(0.0, 1.0);
    final attendanceText = '$presentCount/$targetCount hadir';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final role = AuthController.instance.currentUser.value?.role ?? AppConstants.roleMember;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EventDetailView(event: widget.event, userRole: role)),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.nama,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937),
                              ),
                        ),
                        const SizedBox(height: 10),
                        _buildMetaRow(
                          Icons.schedule_outlined,
                          '${EventUtilities.formatDate(widget.event.tanggalMulai)} • ${widget.event.jamMulai != null ? '${widget.event.jamMulai!.hour.toString().padLeft(2, '0')}:${widget.event.jamMulai!.minute.toString().padLeft(2, '0')} WIB' : 'WIB'}',
                        ),
                        const SizedBox(height: 8),
                        _buildMetaRow(
                          Icons.location_on_outlined,
                          EventUtilities.eventLocation(widget.event),
                        ),
                        const SizedBox(height: 8),
                        _buildMetaRow(
                          Icons.badge_outlined,
                          widget.event.penanggungJawab?.trim().isNotEmpty == true
                              ? widget.event.penanggungJawab!
                              : 'Penanggung jawab belum diatur',
                        ),
                        const SizedBox(height: 8),
                        _buildMetaRow(
                          Icons.groups_outlined,
                          attendanceText,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: EventUtilities.eventStatusBgColor(widget.event),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: EventUtilities.eventStatusColor(widget.event)),
                      const SizedBox(width: 6),
                      Text(
                        EventUtilities.eventStatusLabel(widget.event),
                        style: TextStyle(
                          color: EventUtilities.eventStatusColor(widget.event),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildAttendanceProgressBar(attendancePercent),
            if (widget.hasAnyCrudAccess || subEvents.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (subEvents.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        widget.expandedState[widget.event.eventId] = !isExpanded;
                        widget.onExpandedChanged();
                      },
                      icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                      label: Text(isExpanded ? 'Tutup Sub-Event' : 'Lihat Sub-Event'),
                    ),
                  const Spacer(),
                  if (widget.canUpdateMainEvent || widget.canDeleteMainEvent || widget.canCreateSubEvent)
                    EventActionButtons(
                      event: widget.event,
                      canUpdateMainEvent: widget.canUpdateMainEvent,
                      canUpdateSubEvent: widget.canUpdateSubEvent,
                      canDeleteMainEvent: widget.canDeleteMainEvent,
                      canDeleteSubEvent: widget.canDeleteSubEvent,
                      canCreateSubEvent: widget.canCreateSubEvent,
                      onEdit: widget.onEdit,
                      onDelete: widget.onDelete,
                      onAddSubEvent: widget.onAddSubEvent,
                      controller: widget.controller,
                    ),
                ],
              ),
            ],
            if (subEvents.isNotEmpty && isExpanded) ...[
              const SizedBox(height: 12),
              ..._buildSubEventsList(subEvents),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: const Color(0xFF9CA3AF)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, color: Color(0xFF4B5563)),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceProgressBar(double attendancePercent) {
    return Row(
      children: [
        const Text(
          'Kehadiran',
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: attendancePercent,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(
                attendancePercent >= 0.9
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF3B82F6),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${(attendancePercent * 100).round()}%',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSubEventsList(List<EventModel> subEvents) {
    return subEvents.map((sub) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sub.nama,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text('${sub.jenis} • ${EventUtilities.formatDate(sub.tanggalMulai)}'),
            const SizedBox(height: 8),
            EventActionButtons(
              event: sub,
              canUpdateMainEvent: widget.canUpdateMainEvent,
              canUpdateSubEvent: widget.canUpdateSubEvent,
              canDeleteMainEvent: widget.canDeleteMainEvent,
              canDeleteSubEvent: widget.canDeleteSubEvent,
              canCreateSubEvent: widget.canCreateSubEvent,
              onEdit: widget.onEdit,
              onDelete: widget.onDelete,
              onAddSubEvent: widget.onAddSubEvent,
              controller: widget.controller,
              forcedParentId: widget.event.eventId,
            ),
          ],
        ),
      );
    }).toList();
  }
}
