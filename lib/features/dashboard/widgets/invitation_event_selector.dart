import 'package:flutter/material.dart';

import '../../../models/event_model.dart';

class InvitationEventSelector extends StatelessWidget {
  final List<EventModel> mainEvents;
  final String? selectedMainEventId;
  final ValueChanged<String?> onMainEventChanged;
  final List<EventModel> subEventsForSelectedMain;
  final String? selectedSubEventId;
  final ValueChanged<String?> onSubEventChanged;

  const InvitationEventSelector({
    super.key,
    required this.mainEvents,
    required this.selectedMainEventId,
    required this.onMainEventChanged,
    required this.subEventsForSelectedMain,
    required this.selectedSubEventId,
    required this.onSubEventChanged,
  });

  Widget _buildDropdown({
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(fontSize: 14)),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (mainEvents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Text(
          'Belum ada event yang tersedia.',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PILIH EVENT/SUB-EVENT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _buildDropdown(
            value: selectedMainEventId,
            items: mainEvents
                .map((e) => DropdownMenuItem(
                      value: e.eventId,
                      child: Text(e.nama, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: onMainEventChanged,
            hint: 'Pilih Event Utama',
          ),
          if (subEventsForSelectedMain.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDropdown(
              value: selectedSubEventId,
              items: subEventsForSelectedMain
                  .map((e) => DropdownMenuItem(
                        value: e.eventId,
                        child: Text(e.nama, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: onSubEventChanged,
              hint: 'Pilih Sub-Event',
            ),
          ],
        ],
      ),
    );
  }
}
