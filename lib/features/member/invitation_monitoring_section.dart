import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/services/hive_service.dart';
import '../../models/event_invitation.dart';
import '../../core/enums/status_enums.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state_box.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/alert_banner.dart';

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
          final s = inv.responseStatusEnum;
          return s == InvitationStatus.approved || s == InvitationStatus.autoApproved;
        }).length;
        final izin = all.where((inv) => inv.responseStatusEnum == InvitationStatus.permissionRequested).length;
        final menunggu = all.where((inv) {
          final s = inv.responseStatusEnum;
          return !(s == InvitationStatus.approved || s == InvitationStatus.autoApproved || s == InvitationStatus.permissionRequested);
        }).length;

        // Apply search & filter
        final filtered = all.where((inv) {
          final member = HiveService.members.get(inv.nim);
          final name = member?.nama ?? inv.nim;
          final matchesSearch = _search.trim().isEmpty || name.toLowerCase().contains(_search.toLowerCase()) || inv.nim.contains(_search);

          if (!matchesSearch) return false;

          if (_filter == 'Semua') return true;
          final s = inv.responseStatusEnum;
          if (_filter == 'Hadir') return (s == InvitationStatus.approved || s == InvitationStatus.autoApproved);
          if (_filter == 'Izin') return s == InvitationStatus.permissionRequested;
          if (_filter == 'Menunggu') return !(s == InvitationStatus.approved || s == InvitationStatus.autoApproved || s == InvitationStatus.permissionRequested);
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
                      Expanded(child: StatCard(label: 'Total', value: total, color: const Color(0xFF2563EB))),
                      const SizedBox(width: 8),
                      Expanded(child: StatCard(label: 'Hadir', value: hadir, color: const Color(0xFF16A34A))),
                      const SizedBox(width: 8),
                      Expanded(child: StatCard(label: 'Izin', value: izin, color: const Color(0xFFEA580C))),
                      const SizedBox(width: 8),
                      Expanded(child: StatCard(label: 'Menunggu', value: menunggu, color: const Color(0xFF6B7280))),
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
                    const EmptyStateBox(message: 'Tidak ada respons sesuai filter/pencarian.')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final invitation = filtered[index];
                        final member = HiveService.members.get(invitation.nim);
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
                                  UserAvatar(name: member?.nama ?? invitation.nim, radius: 20),
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
                                            StatusBadge(status: invitation.responseStatus),
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
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFF59E0B),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            elevation: 0,
                                            minimumSize: Size.zero, // Mencegah bentrok dengan global theme (double.infinity)
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: const Text('Cek Izin', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                                        )
                                      : const Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                              if (invitation.responseStatus.toLowerCase() == 'permission_requested') ...[
                                const SizedBox(height: 10),
                                AlertBanner(
                                  message: _getPermissionSummaryStr(invitation),
                                  type: AlertType.warning,
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

  String _getPermissionSummaryStr(EventInvitation invitation) {
    final permissionRecords = HiveService.permissions.values
        .where((record) => record.eventId == invitation.eventId && record.nim == invitation.nim)
        .toList(growable: false);

    if (permissionRecords.isEmpty) {
      return 'Tidak ada alasan terlampir.';
    }

    final latest = permissionRecords.last;
    return '${latest.jenisIzin} • ${latest.alasan}';
  }

  // Removed _statBox, _statusLabel, _permissionSummary, _initials, and _getStatusColor as they are now reusable widgets.
  
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
      // ignore: use_build_context_synchronously
      context,
      invitation,
      approved ? InvitationStatus.approved : InvitationStatus.rejected,
    );
  }

  Future<void> _updateInvitationStatus(
    BuildContext context,
    EventInvitation invitation,
    InvitationStatus status,
  ) async {
    try {
      invitation.responseStatusEnum = status;
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
