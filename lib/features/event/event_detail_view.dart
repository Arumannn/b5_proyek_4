import 'package:flutter/material.dart';
import '../../models/attendance_record.dart';
import '../../models/event_invitation.dart';
import '../../models/event_model.dart';
import '../../models/member_model.dart';
import '../../models/permission_record.dart';
import '../../core/services/hive_service.dart';
import '../../core/enums/status_enums.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/custom_confirm_dialog.dart';
import '../attendance/attendance_recap_view.dart';
import 'event_permission.dart';
import 'event_controller.dart';
import 'event_form_view.dart';
import 'widgets/detail/event_header_section.dart';
import 'widgets/detail/event_info_section.dart';
import 'widgets/detail/event_sub_events_section.dart';
import 'widgets/detail/event_notulensi_section.dart';
import 'widgets/detail/event_attendance_section.dart';

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
    if (widget.event.parentEventId == null) {
      return EventPermission.canUpdateMainEvent(widget.userRole);
    } else {
      return EventPermission.canUpdateSubEvent(widget.userRole);
    }
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

  List<EventModel> _subEventsOf(String eventId) {
    return _controller.getSubEvents(eventId)
      ..sort((a, b) => a.tanggalMulai.compareTo(b.tanggalMulai));
  }

  List<EventInvitation> _invitationsByEvent(String eventId) {
    return HiveService.invitations.values
        .where((inv) => inv.eventId == eventId)
        .toList(growable: false)
      ..sort((a, b) => b.invitedAt.compareTo(a.invitedAt));
  }

  List<AttendanceParticipantItem> _attendanceParticipants(
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
      for (final inv in invitations) {
        final response = inv.responseStatusEnum;
        if (response == InvitationStatus.approved || response == InvitationStatus.autoApproved) {
          participantNims.add(inv.nim);
        }
      }
      participantNims.addAll(attendanceByNim.keys.where((nim) => nim.trim().isNotEmpty));
    } else {
      participantNims.addAll(event.targetPeserta.where((nim) => nim.trim().isNotEmpty));
      participantNims.addAll(attendanceByNim.keys.where((nim) => nim.trim().isNotEmpty));
      participantNims.addAll(permissionByNim.keys.where((nim) => nim.trim().isNotEmpty));
    }

    final items = participantNims.map((nim) {
      final member = memberByNim[nim];
      final attendance = attendanceByNim[nim];
      final permission = permissionByNim[nim];

      String status;
      DateTime? time;

      if (attendance != null) {
        status = attendance.status;
        time = attendance.timestamp;
      } else if (permission != null) {
        final izinStatus = permission.statusEnum;
        if (izinStatus == PermissionStatus.approved) {
          status = permission.jenisIzin;
        } else if (izinStatus == PermissionStatus.rejected) {
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

      return AttendanceParticipantItem(
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
      lokasi: event.lokasi,
      jenis: event.jenis,
      penyelenggara: event.penyelenggara,
      penanggungJawab: event.penanggungJawab,
      deskripsi: event.deskripsi,
      isSubEvent: forceSubEvent ? true : (event.parentEventId != null),
      parentId: forcedParentId ?? event.parentEventId,
      requiresInvitation: event.requiresInvitation,
      targetPeserta: event.targetPeserta,
    );
  }

  Future<void> _openEventForm({
    required String title,
    required EventFormValue initialValue,
    required bool isEdit,
  }) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EventFormView(
          title: title,
          initialValue: initialValue,
        ),
      ),
    );
    if (result == true) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return CustomConfirmDialog(
          title: 'Hapus Event',
          content: 'Yakin ingin menghapus "${_currentEvent.nama}"?',
          confirmText: 'Hapus',
          isDestructive: true,
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final ok = await _controller.deleteEvent(_currentEvent.eventId);
    if (!mounted) return;

    if (ok) {
      CustomSnackbar.showSuccess(context, 'Event berhasil dihapus.');
      Navigator.of(context).pop();
    } else {
      CustomSnackbar.showError(context, _controller.errorMessage.value ?? 'Gagal menghapus event.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentEvent = _resolvedEvent();
    final subEvents = _subEventsOf(currentEvent.eventId);
    final parentEvent = _parentEventOf(currentEvent);
    final memberByNim = _memberByNim();
    final attendanceList = _attendanceParticipants(currentEvent, memberByNim);
    
    int hadirCount = 0;
    int izinCount = 0;
    int alphaCount = 0;
    int belumAbsenCount = 0;

    for (final item in attendanceList) {
      final s = AttendanceStatus.fromString(item.status);
      if (s == AttendanceStatus.hadir || s == AttendanceStatus.terlambat) {
        hadirCount++;
      } else if (s == AttendanceStatus.alpha) {
        alphaCount++;
      } else if (s == AttendanceStatus.izin || s == AttendanceStatus.sakit) {
        izinCount++;
      } else if (s == AttendanceStatus.belumAbsen) {
        belumAbsenCount++;
      }
    }

    final isSubEvent = currentEvent.parentEventId != null;
    final eventType = isSubEvent ? 'Sub-Event' : 'Event Utama';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
        title: const Text(
          'Detail Event',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_canUpdate || _canAddSubEvent || _canDelete)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black87),
              color: Colors.white,
              onSelected: (value) {
                if (value == 'edit') {
                  _openEventForm(
                    title: 'Edit Event',
                    initialValue: _toFormValue(currentEvent),
                    isEdit: true,
                  );
                } else if (value == 'add_sub') {
                  _openEventForm(
                    title: 'Buat Sub-Event',
                    initialValue: _toFormValue(
                      currentEvent,
                      forceSubEvent: true,
                      forcedParentId: currentEvent.eventId,
                    ),
                    isEdit: false,
                  );
                } else if (value == 'delete') {
                  _deleteEvent();
                }
              },
              itemBuilder: (context) => [
                if (_canAddSubEvent)
                  const PopupMenuItem(
                    value: 'add_sub',
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF1F2937)),
                        SizedBox(width: 12),
                        Text('Tambah Sub-Event', style: TextStyle(color: Color(0xFF1F2937))),
                      ],
                    ),
                  ),
                if (_canUpdate)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20, color: Color(0xFF1F2937)),
                        SizedBox(width: 12),
                        Text('Edit', style: TextStyle(color: Color(0xFF1F2937))),
                      ],
                    ),
                  ),
                if (_canDelete)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Color(0xFFDC2626)),
                        SizedBox(width: 12),
                        Text('Hapus', style: TextStyle(color: Color(0xFFDC2626))),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EventHeaderSection(
              currentEvent: currentEvent,
              eventType: eventType,
              parentEvent: parentEvent,
              canUpdate: _canUpdate,
              hadirCount: hadirCount,
              izinCount: izinCount,
              alphaCount: alphaCount,
              belumAbsenCount: belumAbsenCount,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  EventInfoSection(currentEvent: currentEvent),
                  const SizedBox(height: 16),
                  if (!isSubEvent) ...[
                    EventSubEventsSection(subEvents: subEvents, userRole: widget.userRole),
                    const SizedBox(height: 16),
                  ],
                  EventNotulensiSection(
                    currentEvent: currentEvent,
                    userRole: widget.userRole,
                    isManagerOrExecutive: widget.userRole.toLowerCase() == 'manager' || widget.userRole.toLowerCase() == 'executive',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            EventAttendanceSection(
              currentEvent: currentEvent,
              canManageInvitationResponses: _canManageInvitationResponses,
              attendanceList: attendanceList,
            ),
          ],
        ),
      ),
    );
  }
}