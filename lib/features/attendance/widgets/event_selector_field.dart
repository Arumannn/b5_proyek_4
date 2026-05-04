import 'package:flutter/material.dart';
import '../../../models/event_model.dart';

class EventSelectorField extends StatelessWidget {
  final String? selectedEventId;
  final List<EventModel> events;
  final String Function(String eventId) labelBuilder;
  final ValueChanged<String?> onChanged;

  const EventSelectorField({
    super.key,
    required this.selectedEventId,
    required this.events,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedEventId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Pilih Event / Sub-Event',
        border: OutlineInputBorder(),
      ),
      items: events
          .map(
            (event) => DropdownMenuItem<String>(
              value: event.eventId,
              child: Text(
                labelBuilder(event.eventId),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(growable: false),
      onChanged: onChanged,
    );
  }
}
