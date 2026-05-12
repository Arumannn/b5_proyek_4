import 'package:flutter/material.dart';
import '../../../models/event_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final List<EventModel> subEvents;
  final bool isExpanded;
  final bool canUpdateMain, canDeleteMain, canCreateSub, canUpdateSub, canDeleteSub;
  final ValueChanged<bool> onExpandToggle;
  final Function(EventModel) onEdit;
  final Function(EventModel) onDelete;
  final Function(EventModel) onAddSubEvent;
  final Function(String) onScan;
  final VoidCallback onCardTap;

  const EventCard({
    super.key,
    required this.event,
    required this.subEvents,
    required this.isExpanded,
    required this.canUpdateMain,
    required this.canDeleteMain,
    required this.canCreateSub,
    required this.canUpdateSub,
    required this.canDeleteSub,
    required this.onExpandToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onAddSubEvent,
    required this.onScan,
    required this.onCardTap,
  });

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }

  String _formatDateTime(DateTime date) {
    final datePart = _formatDate(date);
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$datePart $hh:$mm';
  }

  Color _getJenisColor(String jenis) {
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
                    onEdit(subEvent);
                  } else if (value == 'delete') {
                    onDelete(subEvent);
                  }
                },
                itemBuilder: (context) {
                  return <PopupMenuEntry<String>>[
                    if (canUpdateSub)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                    if (canDeleteSub)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus'),
                      ),
                  ];
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getJenisColor(subEvent.jenis).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  subEvent.jenis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getJenisColor(subEvent.jenis),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSubEvents = subEvents.isNotEmpty;
    final hasLocation = (event.lokasi ?? '').trim().isNotEmpty;
    final dateLabel = _formatDateTime(event.jamMulai ?? event.tanggalMulai);

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
        onTap: onCardTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getJenisColor(event.jenis).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  event.jenis.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: _getJenisColor(event.jenis),
                  ),
                ),
              ),
              if (event.penyelenggara != null && event.penyelenggara!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    event.penyelenggara!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal,
                    ),
                  ),
                ),
              ],
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
                          event.nama,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                                  event.lokasi!.trim(),
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
                    IconButton(
                      icon: Icon(
                        isExpanded 
                            ? Icons.expand_less 
                            : Icons.expand_more,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        onExpandToggle(!isExpanded);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  else if (canCreateSub)
                    IconButton(
                      tooltip: 'Tambah Sub Event',
                      onPressed: () => onAddSubEvent(event),
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
                        onEdit(event);
                      } else if (value == 'delete') {
                        onDelete(event);
                      }
                    },
                    itemBuilder: (context) {
                      return <PopupMenuEntry<String>>[
                        if (canUpdateMain)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                        if (canDeleteMain)
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
                  '${subEvents.length} sub event',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                    if (canUpdateMain)
                      FilledButton.icon(
                        onPressed: () => onScan(event.eventId),
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                ...subEvents.map((subEvent) => _buildSubEventItem(context, subEvent)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
