import 'package:flutter/material.dart';
import '../../../models/event_model.dart';
import '../event_permission.dart';

/// Reusable expandable event card for list views
class EventListCard extends StatefulWidget {
  final EventModel event;
  final List<EventModel> subEvents;
  final VoidCallback onAddSubEvent;
  final VoidCallback onEditEvent;
  final VoidCallback onDeleteEvent;
  final VoidCallback onScanEvent;
  final Function(EventModel) onEditSubEvent;
  final Function(EventModel) onDeleteSubEvent;
  final Function(EventModel) onScanSubEvent;
  final Color Function(String) getJenisColor;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatDateTime;
  final bool canCreateSubEvent;
  final bool canUpdateMainEvent;
  final bool canDeleteMainEvent;
  final bool canUpdateSubEvent;
  final bool canDeleteSubEvent;
  final Map<String, bool> expandedState;
  final ValueChanged<bool> onExpandedChanged;

  const EventListCard({
    super.key,
    required this.event,
    this.subEvents = const [],
    required this.onAddSubEvent,
    required this.onEditEvent,
    required this.onDeleteEvent,
    required this.onScanEvent,
    required this.onEditSubEvent,
    required this.onDeleteSubEvent,
    required this.onScanSubEvent,
    required this.getJenisColor,
    required this.formatDate,
    required this.formatDateTime,
    required this.canCreateSubEvent,
    required this.canUpdateMainEvent,
    required this.canDeleteMainEvent,
    required this.canUpdateSubEvent,
    required this.canDeleteSubEvent,
    required this.expandedState,
    required this.onExpandedChanged,
  });

  @override
  State<EventListCard> createState() => _EventListCardState();
}

class _EventListCardState extends State<EventListCard> {
  @override
  Widget build(BuildContext context) {
    final eventId = widget.event.eventId;
    final isExpanded = widget.expandedState[eventId] ?? false;
    final hasSubEvents = widget.subEvents.isNotEmpty;
    final hasLocation = (widget.event.lokasi ?? '').trim().isNotEmpty;
    final dateLabel = widget.formatDateTime(
      widget.event.jamMulai ?? widget.event.tanggalMulai,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: hasSubEvents
            ? () => widget.onExpandedChanged(!isExpanded)
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.getJenisColor(widget.event.jenis)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  widget.event.jenis.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: widget.getJenisColor(widget.event.jenis),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // ── Header Row ────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.nama,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dateLabel,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        if (hasLocation) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.event.lokasi!.trim(),
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Expand/Collapse Icon
                  if (hasSubEvents)
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  else if (widget.canCreateSubEvent)
                    IconButton(
                      tooltip: 'Tambah Sub Event',
                      onPressed: widget.onAddSubEvent,
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  PopupMenuButton<String>(
                    tooltip: 'Aksi',
                    onSelected: (value) {
                      if (value == 'edit') {
                        widget.onEditEvent();
                      } else if (value == 'delete') {
                        widget.onDeleteEvent();
                      }
                    },
                    itemBuilder: (context) {
                      return <PopupMenuEntry<String>>[
                        if (widget.canUpdateMainEvent)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                        if (widget.canDeleteMainEvent)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Hapus'),
                          ),
                      ];
                    },
                  ),
                ],
              ),
              if (hasSubEvents) ...[
                const SizedBox(height: 8),
                Text(
                  '${widget.subEvents.length} sub event',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
              const SizedBox(height: 12),
              // ── Action Buttons ────────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!hasSubEvents)
                    if (widget.canUpdateMainEvent)
                      FilledButton.icon(
                        onPressed: widget.onScanEvent,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                ],
              ),
              // ── Sub Events (Expandable) ───────────────
              if (hasSubEvents && isExpanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  'Sub Event',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                ...widget.subEvents.map(
                  (subEvent) => _buildSubEventItem(context, subEvent),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubEventItem(BuildContext context, EventModel subEvent) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.subdirectory_arrow_right,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subEvent.nama,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Aksi',
                onSelected: (value) {
                  if (value == 'edit') {
                    widget.onEditSubEvent(subEvent);
                  } else if (value == 'delete') {
                    widget.onDeleteSubEvent(subEvent);
                  }
                },
                itemBuilder: (context) {
                  return <PopupMenuEntry<String>>[
                    if (widget.canUpdateSubEvent)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                    if (widget.canDeleteSubEvent)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus'),
                      ),
                  ];
                },
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.getJenisColor(subEvent.jenis)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  subEvent.jenis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.getJenisColor(subEvent.jenis),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                widget.formatDateTime(subEvent.tanggalMulai),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (widget.canUpdateSubEvent)
                TextButton.icon(
                  onPressed: () {
                    widget.onScanSubEvent(subEvent);
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 16),
                  label: const Text('Scan'),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    foregroundColor: const Color(0xFF1D4ED8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
