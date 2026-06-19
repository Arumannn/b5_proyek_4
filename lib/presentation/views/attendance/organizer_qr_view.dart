import 'package:b5_proyek_4/presentation/widgets/shared/gradient_header.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:b5_proyek_4/data/services/hive_service.dart';
import 'package:b5_proyek_4/domain/controllers/auth/auth_controller.dart';
import 'package:b5_proyek_4/domain/models/event/event_model.dart';
import 'package:b5_proyek_4/domain/models/users/member_model.dart';

class OrganizerQrView extends StatefulWidget {
  const OrganizerQrView({super.key});

  @override
  State<OrganizerQrView> createState() => _OrganizerQrViewState();
}

class _OrganizerQrViewState extends State<OrganizerQrView> {
  List<EventModel> _events = const [];
  String? _selectedEventId;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    final events = HiveService.events.values.toList(growable: false)
      ..sort((a, b) => a.tanggalMulai.compareTo(b.tanggalMulai));

    String? selected = _selectedEventId;
    if (selected == null && events.isNotEmpty) {
      selected = events.first.eventId;
    }
    if (selected != null && !events.any((e) => e.eventId == selected)) {
      selected = events.isNotEmpty ? events.first.eventId : null;
    }

    setState(() {
      _events = events;
      _selectedEventId = selected;
    });
  }

  bool _isAlreadyPresent(MemberModel user) {
    final eventId = _selectedEventId;
    if (eventId == null) return false;
    final compositeKey = '${eventId}_${user.nim}';
    return HiveService.attendance.values.any(
      (r) => r.compositeKey == compositeKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthController.instance.currentUser.value;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Sesi user tidak ditemukan. Silakan login ulang.'),
        ),
      );
    }

    final alreadyPresent = _isAlreadyPresent(user);
    final statusText = alreadyPresent ? 'Sudah Absen' : 'Belum Absen';

    return Scaffold(
      appBar: const GradientHeader(title: 'QR Organizer Saya', subtitle: 'QR unik untuk absensi'),
      body: RefreshIndicator(
        onRefresh: () async => _loadEvents(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      user.nama,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text('NIM: ${user.nim}'),
                    const SizedBox(height: 4),
                    Text('Role: ${user.role}'),
                    const SizedBox(height: 16),
                    InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4,
                      child: QrImageView(
                        data: user.qrCodeValue,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'QR berisi identitas unik pengguna. Tunjukkan ke Executive/Manager saat absensi.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_events.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Belum ada event untuk pengecekan status absensi.',
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Absensi Per Event',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedEventId,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Event',
                          border: OutlineInputBorder(),
                        ),
                        items: _events
                            .map((event) {
                              final prefix = event.parentEventId == null
                                  ? 'Event Utama'
                                  : 'Sub-Event';
                              return DropdownMenuItem<String>(
                                value: event.eventId,
                                child: Text('$prefix - ${event.nama}'),
                              );
                            })
                            .toList(growable: false),
                        onChanged: (value) {
                          setState(() {
                            _selectedEventId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            alreadyPresent
                                ? Icons.check_circle
                                : Icons.schedule,
                            color: alreadyPresent
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: alreadyPresent
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'QR hanya dapat dipakai satu kali per event. Double scan akan ditolak sistem.',
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
