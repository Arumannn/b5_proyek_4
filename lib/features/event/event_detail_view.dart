import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/services/hive_service.dart';
import '../../models/attendance_record.dart';
import '../../models/event_invitation.dart';
import '../../models/event_model.dart';
import '../../models/member_model.dart';
import '../../models/permission_record.dart';
import '../attendance/scan_screen.dart';
import 'event_permission.dart';
import 'event_controller.dart';
import 'event_form_view.dart';
import '../member/invitation_response_page.dart';
import '../../widgets/custom_snackbar.dart';

class EventDetailView extends StatefulWidget {
  final EventModel event;
  final String userRole;

  const EventDetailView({
    super.key,
    required this.event,
    required this.userRole,
  });

  @override
  State<EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends State<EventDetailView> {
  late EventModel _currentEvent;
  final EventController _controller = EventController.instance;
  

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
  }

  bool get _canUpdate => widget.event.parentEventId == null 
      ? EventPermission.canUpdateMainEvent(widget.userRole)
      : EventPermission.canUpdateSubEvent(widget.userRole);

  bool get _canDelete => widget.event.parentEventId == null
      ? EventPermission.canDeleteMainEvent(widget.userRole)
      : EventPermission.canDeleteSubEvent(widget.userRole);

  bool get _canAddSubEvent => widget.event.parentEventId == null && EventPermission.canCreateSubEvent(widget.userRole);

  bool get _canManageInvitationResponses {
    final role = widget.userRole.trim().toLowerCase();
    return role == 'executive' || role == 'manager';
  }

  List<EventParentOption> get _parentOptions {
    return _controller
        .getRootEvents()
        .map((event) => EventParentOption(id: event.eventId, name: event.nama))
        .toList(growable: false);
  }

  String _formatDate(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = _monthName(value.month);
    final yyyy = value.year.toString();
    return '$dd $mm $yyyy';
  }

  String _formatTime(DateTime start, DateTime? end) {
    final hhStart = start.hour.toString().padLeft(2, '0');
    final minStart = start.minute.toString().padLeft(2, '0');
    if (end == null) return '$hhStart:$minStart';
    
    final hhEnd = end.hour.toString().padLeft(2, '0');
    final minEnd = end.minute.toString().padLeft(2, '0');
    return '$hhStart:$minStart - $hhEnd:$minEnd';
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  String _eventLocation([EventModel? event]) {
    final lokasi = (event ?? _currentEvent).lokasi?.trim();
    if (lokasi != null && lokasi.isNotEmpty) return lokasi;
    return 'Lokasi belum diatur';
  }

  EventModel _resolvedEvent() {
    return _controller.events.value.firstWhere(
      (event) => event.eventId == _currentEvent.eventId,
      orElse: () => _currentEvent,
    );
  }

  EventModel? _parentEventOf(EventModel event) {
    final parentId = event.parentEventId?.trim();
    if (parentId == null || parentId.isEmpty) return null;

    try {
      return _controller.events.value.firstWhere((candidate) => candidate.eventId == parentId);
    } catch (_) {
      try {
        return HiveService.events.get(parentId);
      } catch (_) {
        return null;
      }
    }
  }

  String _formatDateTimeRange(EventModel event) {
    final start = event.jamMulai ?? event.tanggalMulai;
    final end = event.jamSelesai ?? event.tanggalSelesai;
    return '${_formatDate(start)} • ${_formatTime(start, end)} WIB';
  }

  List<EventModel> _subEventsOf(String eventId) {
    return _controller.getSubEvents(eventId)
      ..sort((a, b) => a.tanggalMulai.compareTo(b.tanggalMulai));
  }

  List<AttendanceRecord> _attendanceRecords() {
    return HiveService.attendance.values
        .where((r) => r.eventId == _currentEvent.eventId)
        .toList(growable: false)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  List<EventInvitation> _invitationsByEvent(String eventId) {
    return HiveService.invitations.values
        .where((inv) => inv.eventId == eventId)
        .toList(growable: false)
      ..sort((a, b) => b.invitedAt.compareTo(a.invitedAt));
  }

  List<_AttendanceParticipantItem> _attendanceParticipants(
    EventModel event,
    Map<String, MemberModel> memberByNim,
  ) {
    final attendanceByNim = <String, AttendanceRecord>{
      for (final r in HiveService.attendance.values.where((r) => r.eventId == event.eventId)) r.nim: r,
    };

    final invitations = _invitationsByEvent(event.eventId);
    final invitationByNim = <String, EventInvitation>{
      for (final inv in invitations) inv.nim: inv,
    };

    final permissionByNim = <String, PermissionRecord>{};
    for (final permission in HiveService.permissions.values.where((p) => p.eventId == event.eventId)) {
      permissionByNim[permission.nim] = permission;
    }

    final participantNims = <String>{};
    if (event.requiresInvitation) {
      participantNims.addAll(invitationByNim.keys.where((nim) => nim.trim().isNotEmpty));
    } else {
      participantNims.addAll(event.targetPeserta.where((nim) => nim.trim().isNotEmpty));
    }

    final items = participantNims.map((nim) {
      final member = memberByNim[nim];
      final attendance = attendanceByNim[nim];
      final invitation = invitationByNim[nim];
      final permission = permissionByNim[nim];

      String status;
      DateTime? time;

      if (attendance != null) {
        status = attendance.status;
        time = attendance.timestamp;
      } else if (event.requiresInvitation && invitation != null) {
        final response = invitation.responseStatus.toLowerCase();
        if (response == 'approved' || response == 'auto-approved') {
          status = 'Disetujui';
        } else if (response == 'rejected') {
          status = 'Ditolak';
        } else if (response == 'permission_requested') {
          status = 'Izin Diajukan';
        } else {
          status = 'Menunggu';
        }
        time = invitation.respondedAt ?? invitation.invitedAt;
      } else if (permission != null) {
        final izinStatus = permission.status.toLowerCase();
        if (izinStatus == 'approved') {
          status = permission.jenisIzin;
        } else if (izinStatus == 'rejected') {
          status = 'Izin Ditolak';
        } else {
          status = 'Izin Pending';
        }
        time = permission.updatedAt;
      } else {
        status = 'Belum Absen';
        time = null;
      }

      final displayName = (member?.nama.trim().isNotEmpty == true) ? member!.nama : nim;
      final role = (member?.role.trim().isNotEmpty == true) ? member!.role : 'Peserta';

      return _AttendanceParticipantItem(
        nim: nim,
        displayName: displayName,
        role: role,
        status: status,
        time: time,
      );
    }).toList(growable: false)
      ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

    return items;
  }

  Map<String, MemberModel> _memberByNim() {
    return {
      for (final m in HiveService.members.values) m.nim: m,
    };
  }

  EventFormValue _toFormValue(EventModel event, {bool forceSubEvent = false, String? forcedParentId}) {
    return EventFormValue(
      name: event.nama,
      date: event.tanggalMulai,
      endDate: event.tanggalSelesai ?? event.tanggalMulai,
      jamSelesai: event.jamSelesai,
      isSubEvent: forceSubEvent || event.parentEventId != null,
      parentId: forcedParentId ?? event.parentEventId,
      jenis: event.jenis,
      lokasi: event.lokasi,
      deskripsi: event.deskripsi,
      targetPeserta: event.targetPeserta,
      requiresInvitation: event.requiresInvitation,
      penyelenggara: event.penyelenggara,
      penanggungJawab: event.penanggungJawab,
    );
  }

  Future<void> _openEventForm({
    required String title,
    required EventFormValue initialValue,
    required bool isEdit,
  }) async {
    final form = await Navigator.push<EventFormValue>(
      context,
      MaterialPageRoute<EventFormValue>(
        builder: (_) => EventFormView(
          title: title,
          initialValue: initialValue,
          parentOptions: _parentOptions,
          canChangeHierarchy: false,
        ),
      ),
    );

    if (form == null) return;

    final success = isEdit
        ? await _controller.updateEvent(
            _currentEvent.copyWith(
              nama: form.name,
              tanggalMulai: form.date,
              tanggalSelesai: form.endDate,
              jamSelesai: form.jamSelesai,
              parentEventId: form.parentId,
              jenis: form.jenis,
              lokasi: form.lokasi,
              deskripsi: form.deskripsi,
              targetPeserta: form.targetPeserta,
              requiresInvitation: form.requiresInvitation,
              penyelenggara: form.penyelenggara,
              penanggungJawab: form.penanggungJawab,
            ),
          )
        : await _controller.createEvent(
            nama: form.name,
            tanggalMulai: form.date,
            tanggalSelesai: form.endDate,
            jamSelesai: form.jamSelesai,
            parentEventId: form.parentId,
            jenis: form.jenis,
            lokasi: form.lokasi,
            deskripsi: form.deskripsi,
            targetPeserta: form.targetPeserta,
            requiresInvitation: form.requiresInvitation,
            penyelenggara: form.penyelenggara,
            penanggungJawab: form.penanggungJawab,
          );

    if (!mounted) return;

    if (success) {
      if (isEdit) {
        setState(() {
          _currentEvent = _currentEvent.copyWith(
            nama: form.name,
            tanggalMulai: form.date,
            tanggalSelesai: form.endDate,
            jamSelesai: form.jamSelesai,
            parentEventId: form.parentId,
            jenis: form.jenis,
            lokasi: form.lokasi,
            deskripsi: form.deskripsi,
            targetPeserta: form.targetPeserta,
            requiresInvitation: form.requiresInvitation,
            penyelenggara: form.penyelenggara,
            penanggungJawab: form.penanggungJawab,
          );
        });
      }
      CustomSnackbar.showSuccess(
        context,
        isEdit ? 'Kegiatan berhasil diperbarui.' : 'Sub-event berhasil ditambahkan.',
      );
    } else {
      CustomSnackbar.showError(
        context,
        _controller.errorMessage.value ?? 'Gagal menyimpan kegiatan.',
      );
    }
  }

  int _countStatus(List<AttendanceRecord> records, List<String> tokens) {
    return records.where((r) {
      final value = r.status.toLowerCase();
      return tokens.any((t) => value.contains(t));
    }).length;
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Kegiatan'),
          content: Text('Yakin ingin menghapus "${_currentEvent.nama}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final ok = await _controller.deleteEvent(_currentEvent.eventId);
    if (!mounted) return;

    if (ok) {
      CustomSnackbar.showSuccess(context, 'Kegiatan berhasil dihapus.');
      Navigator.of(context).pop();
    } else {
      CustomSnackbar.showError(context, _controller.errorMessage.value ?? 'Gagal menghapus kegiatan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentEvent = _resolvedEvent();
    final subEvents = _subEventsOf(currentEvent.eventId);
    final parentEvent = _parentEventOf(currentEvent);
    final records = _attendanceRecords();
    final memberByNim = _memberByNim();
    final attendanceList = _attendanceParticipants(currentEvent, memberByNim);
    
    final hadirCount = _countStatus(records, ['hadir', 'terlambat']);
    final izinCount = _countStatus(records, ['izin', 'sakit']);
    final alphaCount = _countStatus(records, ['alpha']);
    
    final targetCount = currentEvent.targetPeserta.isEmpty ? memberByNim.length : currentEvent.targetPeserta.length;
    final recordedCount = hadirCount + izinCount + alphaCount;
    final belumAbsenCount = (targetCount - recordedCount).clamp(0, targetCount);

    final isSubEvent = currentEvent.parentEventId != null;
    final eventType = isSubEvent ? 'Sub-Event' : 'Event Utama';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // bg-gray-50
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
        title: const Text(
          'Detail Kegiatan',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80), // pb-20
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Block: Detail Informasi Event
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24), // p-6
              margin: const EdgeInsets.only(bottom: 16), // mb-4
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade100), // border-b border-gray-100
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ], // shadow-sm
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // px-3 py-1.5
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF), // bg-blue-50
                          borderRadius: BorderRadius.circular(6), // rounded-md
                        ),
                        child: Text(
                          eventType.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10, // text-[10px]
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB), // text-blue-600
                            letterSpacing: 0.5, // tracking-wider
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _currentEvent.statusEvent.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                        ),
                      ),
                    ],
                  ),

                  if (parentEvent != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_tree_outlined, size: 18, color: Color(0xFF2563EB)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Parent Event',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  parentEvent.nama,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16), // mt-4
                  
                  // Title
                  Text(
                    currentEvent.nama,
                    style: const TextStyle(
                      fontSize: 24, // text-2xl
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937), // text-gray-800
                      height: 1.2, // leading-tight
                    ),
                  ),

                  // Description (if available)
                  if (currentEvent.deskripsi != null && currentEvent.deskripsi!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      currentEvent.deskripsi!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4B5563), // text-gray-600
                        height: 1.5,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20), // mb-4
                  
                  // Ringkasan Kehadiran Event (Stats Grid 4 columns)
                  Row(
                    children: [
                      _buildStatBox(
                        label: 'Hadir',
                        count: hadirCount,
                        bgColor: const Color(0xFFF0FDF4), // bg-green-50
                        borderColor: const Color(0xFFDCFCE7), // border-green-100
                        labelColor: const Color(0xFF16A34A), // text-green-600
                        countColor: const Color(0xFF15803D), // text-green-700
                      ),
                      const SizedBox(width: 8), // gap-2
                      _buildStatBox(
                        label: 'Izin',
                        count: izinCount,
                        bgColor: const Color(0xFFFFF7ED), // bg-orange-50
                        borderColor: const Color(0xFFFFEDD5), // border-orange-100
                        labelColor: const Color(0xFFEA580C), // text-orange-600
                        countColor: const Color(0xFFC2410C), // text-orange-700
                      ),
                      const SizedBox(width: 8),
                      _buildStatBox(
                        label: 'Alpha',
                        count: alphaCount,
                        bgColor: const Color(0xFFFEF2F2), // bg-red-50
                        borderColor: const Color(0xFFFEE2E2), // border-red-100
                        labelColor: const Color(0xFFDC2626), // text-red-600
                        countColor: const Color(0xFFB91C1C), // text-red-700
                      ),
                      const SizedBox(width: 8),
                      _buildStatBox(
                        label: 'Belum',
                        count: belumAbsenCount,
                        bgColor: const Color(0xFFF3F4F6), // bg-gray-100
                        borderColor: const Color(0xFFE5E7EB), // border-gray-200
                        labelColor: const Color(0xFF6B7280), // text-gray-500
                        countColor: const Color(0xFF374151), // text-gray-700
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24), // mb-6
                  
                  // Info Block
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16), // p-4
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB), // bg-gray-50
                      borderRadius: BorderRadius.circular(12), // rounded-xl
                      border: Border.all(color: const Color(0xFFF3F4F6)), // border-gray-100
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Tanggal',
                          value: _formatDate(currentEvent.tanggalMulai),
                        ),
                        const SizedBox(height: 12), // space-y-3
                        _buildInfoRow(
                          icon: Icons.access_time_outlined,
                          label: 'Waktu',
                          value: _formatDateTimeRange(currentEvent),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Lokasi',
                          value: _eventLocation(currentEvent),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.category_outlined,
                          label: 'Jenis',
                          value: currentEvent.jenis,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.business_outlined,
                          label: 'Penyelenggara',
                          value: currentEvent.penyelenggara?.trim().isNotEmpty == true
                              ? currentEvent.penyelenggara!
                              : 'Belum diatur',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.badge_outlined,
                          label: 'Penanggung Jawab',
                          value: currentEvent.penanggungJawab?.trim().isNotEmpty == true
                              ? currentEvent.penanggungJawab!
                              : 'Belum diatur',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_canManageInvitationResponses || HiveService.invitations.values.any((inv) => inv.eventId == currentEvent.eventId)) ...[
                    ValueListenableBuilder<Box<EventInvitation>>(
                      valueListenable: HiveService.invitations.listenable(),
                      builder: (context, box, _) {
                        final invitations = box.values
                            .where((inv) => inv.eventId == currentEvent.eventId)
                            .toList(growable: false);

                        final approved = invitations.where((inv) {
                          final status = inv.responseStatus.toLowerCase();
                          return status == 'approved' || status == 'auto-approved';
                        }).length;
                        final rejected = invitations.where((inv) => inv.responseStatus.toLowerCase() == 'rejected').length;
                        final pending = invitations.where((inv) => inv.responseStatus.toLowerCase() == 'pending').length;
                        final permission = invitations.where((inv) => inv.responseStatus.toLowerCase() == 'permission_requested').length;
                        final total = invitations.length;

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF97316).withValues(alpha: 0.24),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                right: -6,
                                top: -10,
                                child: Opacity(
                                  opacity: 0.18,
                                  child: Icon(Icons.mail_outline, size: 92, color: Colors.white),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tanggapan Undangan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$total undangan • $approved hadir, $rejected ditolak, $pending menunggu, $permission izin',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFFFF7ED),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute<void>(
                                            builder: (_) => InvitationResponsePage(
                                              eventId: currentEvent.eventId,
                                              eventName: currentEvent.nama,
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(0xFFEA580C),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Text(
                                        'Kelola',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                  ],

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF3F4F6)),
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
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'SUB-EVENT',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${subEvents.length} data',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (subEvents.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: const Text(
                              'Belum ada sub-event untuk event ini.',
                              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                            ),
                          )
                        else
                          Column(
                            children: subEvents.map((subEvent) {
                              final subEventLocation = subEvent.lokasi?.trim().isNotEmpty == true
                                  ? subEvent.lokasi!.trim()
                                  : 'Lokasi belum diatur';
                              final subEventTime = '${_formatDate(subEvent.tanggalMulai)} • ${_formatTime(subEvent.jamMulai ?? subEvent.tanggalMulai, subEvent.jamSelesai ?? subEvent.tanggalSelesai)} WIB';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => EventDetailView(
                                          event: subEvent,
                                          userRole: widget.userRole,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFAFBFF),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDBEAFE),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.event_note_outlined, color: Color(0xFF2563EB), size: 22),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                subEvent.nama,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                subEventTime,
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                subEventLocation,
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),

                  // Actions for Executive/Manager
                  if (_canUpdate || _canDelete || _canAddSubEvent) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'KONTROL EKSEKUTIF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_canUpdate)
                          _buildActionButton(
                            icon: Icons.qr_code_scanner,
                            label: 'Scan QR',
                            bgColor: const Color(0xFF2563EB),
                            textColor: Colors.white,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => ScanScreen(eventId: _currentEvent.eventId),
                                ),
                              );
                            },
                          ),
                        if (_canUpdate)
                          _buildActionButton(
                            icon: Icons.edit_outlined,
                            label: 'Edit',
                            bgColor: const Color(0xFFF3F4F6),
                            textColor: const Color(0xFF1F2937),
                            onTap: () => _openEventForm(
                              title: 'Edit Event',
                              initialValue: _toFormValue(_currentEvent),
                              isEdit: true,
                            ),
                          ),
                        if (_canAddSubEvent)
                          _buildActionButton(
                            icon: Icons.add_circle_outline,
                            label: 'Tambah Sub-Event',
                            bgColor: const Color(0xFFF3F4F6),
                            textColor: const Color(0xFF1F2937),
                            onTap: () => _openEventForm(
                              title: 'Buat Sub-Event',
                              initialValue: _toFormValue(
                                _currentEvent,
                                forceSubEvent: true,
                                forcedParentId: _currentEvent.eventId,
                              ),
                              isEdit: false,
                            ),
                          ),
                        if (_canDelete)
                          _buildActionButton(
                            icon: Icons.delete_outline,
                            label: 'Hapus',
                            bgColor: const Color(0xFFFEF2F2),
                            textColor: const Color(0xFFDC2626),
                            onTap: _deleteEvent,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Bottom Block: Daftar Kehadiran
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16), // px-4
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4), // px-1
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'DAFTAR KEHADIRAN',
                          style: TextStyle(
                            fontSize: 14, // text-sm
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937), // text-gray-800
                            letterSpacing: 0.5, // uppercase tracking-wide
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // px-2 py-1
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB), // bg-gray-200
                            borderRadius: BorderRadius.circular(999), // rounded-full
                          ),
                          child: Text(
                            '${attendanceList.length} Peserta',
                            style: const TextStyle(
                              fontSize: 10, // text-[10px]
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B7280), // text-gray-500
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12), // mb-3
                  
                  if (attendanceList.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      alignment: Alignment.center,
                      child: const Text(
                        'Belum ada data kehadiran.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    )
                  else
                    ...attendanceList.map((item) {
                      final name = item.displayName;
                      final role = item.role;
                      final initial = name.isNotEmpty ? (name.length > 1 ? name.substring(0, 2).toUpperCase() : name[0].toUpperCase()) : '?';
                      final time = item.time == null
                          ? '-'
                          : '${item.time!.hour.toString().padLeft(2, '0')}:${item.time!.minute.toString().padLeft(2, '0')} WIB';
                      
                      final statusLower = item.status.toLowerCase();
                      final isHadir = statusLower.contains('hadir') || statusLower.contains('terlambat');
                      final isIzin = statusLower.contains('izin') || statusLower.contains('sakit') || statusLower.contains('disetujui');
                      final isAlpha = statusLower.contains('alpha');
                      
                      // Avatar Colors
                      Color avatarBg = const Color(0xFFF3F4F6); // bg-gray-100
                      Color avatarText = const Color(0xFF6B7280); // text-gray-500
                      if (isHadir) {
                        avatarBg = const Color(0xFFDCFCE7); // bg-green-100
                        avatarText = const Color(0xFF15803D); // text-green-700
                      } else if (isIzin) {
                        avatarBg = const Color(0xFFFFEDD5); // bg-orange-100
                        avatarText = const Color(0xFFC2410C); // text-orange-700
                      }

                      // Badge Colors
                      Color badgeBg = const Color(0xFFF9FAFB); // bg-gray-50
                      Color badgeText = const Color(0xFF4B5563); // text-gray-600
                      Color badgeBorder = const Color(0xFFE5E7EB); // border-gray-200
                      if (isHadir) {
                        badgeBg = const Color(0xFFF0FDF4); // bg-green-50
                        badgeText = const Color(0xFF16A34A); // text-green-600
                        badgeBorder = const Color(0xFFBBF7D0); // border-green-200
                      } else if (isIzin) {
                        badgeBg = const Color(0xFFFFF7ED); // bg-orange-50
                        badgeText = const Color(0xFFEA580C); // text-orange-600
                        badgeBorder = const Color(0xFFFED7AA); // border-orange-200
                      } else if (isAlpha) {
                        badgeBg = const Color(0xFFFEF2F2); // bg-red-50
                        badgeText = const Color(0xFFDC2626); // text-red-600
                        badgeBorder = const Color(0xFFFECACA); // border-red-200
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12), // space-y-3 mapped to mb
                        padding: const EdgeInsets.all(16), // p-4
                        decoration: BoxDecoration(
                          color: Colors.white, // bg-white
                          borderRadius: BorderRadius.circular(12), // rounded-xl
                          border: Border.all(color: const Color(0xFFF3F4F6)), // border-gray-100
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            )
                          ], // shadow-sm
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Avatar
                            Container(
                              width: 40, // w-10
                              height: 40, // h-10
                              decoration: BoxDecoration(
                                color: avatarBg,
                                shape: BoxShape.circle, // rounded-full
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initial,
                                style: TextStyle(
                                  fontSize: 14, // text-sm
                                  fontWeight: FontWeight.bold,
                                  color: avatarText,
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 12), // space-x-3
                            
                            // Name & Role
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 14, // text-sm
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937), // text-gray-800
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    role,
                                    style: const TextStyle(
                                      fontSize: 12, // text-xs
                                      color: Color(0xFF6B7280), // text-gray-500
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Badge & Time
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // px-2.5 py-1
                                  margin: const EdgeInsets.only(bottom: 4), // mb-1
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(999), // rounded-full
                                    border: Border.all(color: badgeBorder),
                                  ),
                                  child: Text(
                                    item.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10, // text-[10px]
                                      fontWeight: FontWeight.bold,
                                      color: badgeText,
                                      letterSpacing: 0.5, // tracking-wide
                                    ),
                                  ),
                                ),
                                Text(
                                  time,
                                  style: const TextStyle(
                                    fontSize: 10, // text-[10px]
                                    fontWeight: FontWeight.w500, // font-medium
                                    color: Color(0xFF9CA3AF), // text-gray-400
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String label,
    required int count,
    required Color bgColor,
    required Color borderColor,
    required Color labelColor,
    required Color countColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8), // p-2
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12), // rounded-xl
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9, // text-[9px]
                fontWeight: FontWeight.bold,
                color: labelColor,
                letterSpacing: 0.5, // tracking-wide
              ),
            ),
            const SizedBox(height: 4), // mb-1 equivalent spacing
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18, // text-lg
                fontWeight: FontWeight.bold,
                color: countColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2), // mt-0.5
          child: Icon(icon, size: 18, color: const Color(0xFF3B82F6)), // text-blue-500
        ),
        const SizedBox(width: 12), // mr-3
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10, // text-[10px]
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9CA3AF), // text-gray-400
                  letterSpacing: 0.5, // tracking-wide
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14, // text-sm
                  fontWeight: FontWeight.w600, // font-semibold
                  color: Color(0xFF1F2937), // text-gray-800
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceParticipantItem {
  final String nim;
  final String displayName;
  final String role;
  final String status;
  final DateTime? time;

  const _AttendanceParticipantItem({
    required this.nim,
    required this.displayName,
    required this.role,
    required this.status,
    required this.time,
  });
}