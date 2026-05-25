import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/services/hive_service.dart';
import '../../models/event_invitation.dart';
import '../../widgets/custom_snackbar.dart';

class InvitationMonitoringSection extends StatefulWidget {
  final String eventId;

  const InvitationMonitoringSection({
    super.key,
    required this.eventId,
  });

  @override
  State<InvitationMonitoringSection> createState() => _InvitationMonitoringSectionState();
}

class _InvitationMonitoringSectionState extends State<InvitationMonitoringSection> {
  String _filter = 'Semua';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<EventInvitation>>(
      valueListenable: HiveService.invitations.listenable(),
      builder: (context, box, _) {
        final all = box.values
            .where((inv) => inv.eventId == widget.eventId)
            .toList(growable: false)
          ..sort((a, b) => b.invitedAt.compareTo(a.invitedAt));

        if (all.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Text(
              'Belum ada undangan yang dikirim untuk event ini.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          );
        }

        final total = all.length;
        final hadir = all.where((inv) {
          final s = inv.responseStatus.toLowerCase();
          return s == 'approved' || s == 'auto-approved';
        }).length;
        final izin = all.where((inv) => inv.responseStatus.toLowerCase() == 'permission_requested').length;
        final menunggu = all.where((inv) => !(inv.responseStatus.toLowerCase() == 'approved' || inv.responseStatus.toLowerCase() == 'auto-approved' || inv.responseStatus.toLowerCase() == 'permission_requested')).length;

        // Apply search & filter
        final filtered = all.where((inv) {
          final member = HiveService.members.get(inv.nim);
          final name = member?.nama ?? inv.nim;
          final matchesSearch = _search.trim().isEmpty || name.toLowerCase().contains(_search.toLowerCase()) || inv.nim.contains(_search);

          if (!matchesSearch) return false;

          if (_filter == 'Semua') return true;
          if (_filter == 'Hadir') return (inv.responseStatus.toLowerCase() == 'approved' || inv.responseStatus.toLowerCase() == 'auto-approved');
          if (_filter == 'Izin') return inv.responseStatus.toLowerCase() == 'permission_requested';
          if (_filter == 'Menunggu') return !(inv.responseStatus.toLowerCase() == 'approved' || inv.responseStatus.toLowerCase() == 'auto-approved' || inv.responseStatus.toLowerCase() == 'permission_requested');
          return true;
        }).toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats grid (Total, Hadir, Izin, Menunggu)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tanggapan Undangan',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                      ),
                      Text('$total undangan', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _statBox('Total', total, const Color(0xFF2563EB), const Color(0xFFEFF6FF))),
                      const SizedBox(width: 8),
                      Expanded(child: _statBox('Hadir', hadir, const Color(0xFF16A34A), const Color(0xFFF0FDF4))),
                      const SizedBox(width: 8),
                      Expanded(child: _statBox('Izin', izin, const Color(0xFFEA580C), const Color(0xFFFFF7ED))),
                      const SizedBox(width: 8),
                      Expanded(child: _statBox('Menunggu', menunggu, const Color(0xFF6B7280), const Color(0xFFF3F4F6))),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Search + filter
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 20),
                      hintText: 'Cari nama atau NIM...',
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Semua', 'Hadir', 'Izin', 'Menunggu'].map((label) {
                        final selected = _filter == label;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: selected ? Colors.white : const Color(0xFF374151))),
                            selected: selected,
                            selectedColor: const Color(0xFF2563EB),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: BorderSide(color: selected ? Colors.transparent : Colors.grey.shade200)),
                            onSelected: (_) => setState(() => _filter = label),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // List
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Daftar Respons Peserta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
                      Text('${filtered.length} hasil', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
                      child: const Text('Tidak ada respons sesuai filter/pencarian.', style: TextStyle(color: Color(0xFF6B7280))),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final invitation = filtered[index];
                        final member = HiveService.members.get(invitation.nim);
                        final statusLabel = _statusLabel(invitation.responseStatus);
                        final statusColor = _getStatusColor(invitation.responseStatus);
                        final statusBg = statusColor.withValues(alpha: 0.12);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: statusBg,
                                    child: Text(_initials(member?.nama ?? invitation.nim), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(member?.nama ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF111827))),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(999)),
                                              child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(member?.nim ?? invitation.nim, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  invitation.responseStatus.toLowerCase() == 'permission_requested'
                                      ? ElevatedButton(
                                          onPressed: () => _showPermissionApprovalDialog(context, invitation),
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                                          child: const Text('Cek Izin', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                                        )
                                      : Icon(Icons.chevron_right, color: statusColor),
                                ],
                              ),
                              if (invitation.responseStatus.toLowerCase() == 'permission_requested') ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFFEDD5))),
                                  child: Text(_permissionSummary(invitation), style: const TextStyle(fontSize: 12, color: Color(0xFF92400E))),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statBox(String label, int value, Color color, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.12))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'auto-approved':
        return 'Hadir';
      case 'rejected':
        return 'Ditolak';
      case 'permission_requested':
        return 'Izin';
      default:
        return 'Menunggu';
    }
  }



  String _permissionSummary(EventInvitation invitation) {
    final permissionRecords = HiveService.permissions.values
        .where((record) => record.eventId == invitation.eventId && record.nim == invitation.nim)
        .toList(growable: false);

    if (permissionRecords.isEmpty) {
      return 'Tidak ada alasan terlampir.';
    }

    final latest = permissionRecords.last;
    return '${latest.jenisIzin} • ${latest.alasan}';
  }

  String _initials(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return trimmed.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'auto-approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'permission_requested':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showPermissionApprovalDialog(
    BuildContext context,
    EventInvitation invitation,
  ) async {
    final permissionRecords = HiveService.permissions.values
        .where((record) => record.eventId == invitation.eventId && record.nim == invitation.nim)
        .toList(growable: false);

    final latestRecord = permissionRecords.isNotEmpty ? permissionRecords.last : null;
    final reason = latestRecord?.alasan ?? 'Tidak ada alasan terlampir.';
    final jenisIzin = latestRecord?.jenisIzin ?? 'Izin';

    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tinjau Izin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nama: ${invitation.nim}'),
              const SizedBox(height: 8),
              Text('Jenis: $jenisIzin'),
              const SizedBox(height: 8),
              Text('Alasan: $reason'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Tolak'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Setujui'),
            ),
          ],
        );
      },
    );

    if (approved == null) return;

    await _updateInvitationStatus(
      context,
      invitation,
      approved ? 'approved' : 'rejected',
    );
  }

  Future<void> _updateInvitationStatus(
    BuildContext context,
    EventInvitation invitation,
    String status,
  ) async {
    try {
      invitation.responseStatus = status;
      invitation.respondedAt = DateTime.now();
      invitation.isSynced = false;
      await HiveService.invitations.put(invitation.invitationId, invitation);

      if (!context.mounted) return;
      CustomSnackbar.showSuccess(context, 'Respons undangan berhasil diperbarui.');
    } catch (e) {
      if (!context.mounted) return;
      CustomSnackbar.showError(context, 'Gagal memperbarui respons undangan: $e');
    }
  }
}
