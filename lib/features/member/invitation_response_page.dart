import 'package:flutter/material.dart';
import 'invitation_monitoring_section.dart';

class InvitationResponsePage extends StatelessWidget {
  final String eventId;
  final String? eventName;

  const InvitationResponsePage({
    super.key,
    required this.eventId,
    this.eventName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(eventName == null ? 'Tanggapan Undangan' : 'Tanggapan: ${eventName!}'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: InvitationMonitoringSection(eventId: eventId),
      ),
    );
  }
}
