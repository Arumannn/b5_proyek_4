import 'package:flutter/material.dart';
import '../../core/services/hive_service.dart';
import '../../models/attendance_record.dart';
import '../../models/event_model.dart';
import '../../models/member_model.dart';
import '../attendance/scan_screen.dart';
import 'event_permission.dart';
import 'event_controller.dart';
import 'event_form_models.dart';
import 'event_form_view.dart';
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

  String _eventLocation() {
    final lokasi = _currentEvent.lokasi?.trim();
    if (lokasi != null && lokasi.isNotEmpty) return lokasi;
    return 'Lokasi belum diatur';
  }

  List<AttendanceRecord> _attendanceRecords() {
    return HiveService.attendance.values
        .where((r) => r.eventId == _currentEvent.eventId)
        .toList(growable: false)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
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
    final records = _attendanceRecords();
    final memberByNim = _memberByNim();
    
    final hadirCount = _countStatus(records, ['hadir', 'terlambat']);
    final izinCount = _countStatus(records, ['izin', 'sakit']);
    final alphaCount = _countStatus(records, ['alpha']);
    
    final targetCount = _currentEvent.targetPeserta.isEmpty ? memberByNim.length : _currentEvent.targetPeserta.length;
    final recordedCount = hadirCount + izinCount + alphaCount;
    final belumAbsenCount = (targetCount - recordedCount).clamp(0, targetCount);

    final isSubEvent = _currentEvent.parentEventId != null;
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
                  
                  const SizedBox(height: 16), // mt-4
                  
                  // Title
                  Text(
                    _currentEvent.nama,
                    style: const TextStyle(
                      fontSize: 24, // text-2xl
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937), // text-gray-800
                      height: 1.2, // leading-tight
                    ),
                  ),

                  // Description (if available)
                  if (_currentEvent.deskripsi != null && _currentEvent.deskripsi!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _currentEvent.deskripsi!,
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
                          value: _formatDate(_currentEvent.tanggalMulai),
                        ),
                        const SizedBox(height: 12), // space-y-3
                        _buildInfoRow(
                          icon: Icons.access_time_outlined,
                          label: 'Waktu',
                          value: '${_formatTime(_currentEvent.jamMulai ?? _currentEvent.tanggalMulai, _currentEvent.jamSelesai ?? _currentEvent.tanggalSelesai)} WIB',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Lokasi',
                          value: _eventLocation(),
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
                            label: 'Sub-Event',
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
                            '${records.length} Peserta',
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
                  
                  if (records.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      alignment: Alignment.center,
                      child: const Text(
                        'Belum ada data kehadiran.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    )
                  else
                    ...records.map((record) {
                      final member = memberByNim[record.nim];
                      final name = member?.nama ?? 'Anggota';
                      final role = member?.role ?? 'Member';
                      final initial = name.isNotEmpty ? (name.length > 1 ? name.substring(0, 2).toUpperCase() : name[0].toUpperCase()) : '?';
                      final time = '${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')} WIB';
                      
                      final statusLower = record.status.toLowerCase();
                      final isHadir = statusLower.contains('hadir') || statusLower.contains('terlambat');
                      final isIzin = statusLower.contains('izin') || statusLower.contains('sakit');
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
                                    record.status.toUpperCase(),
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