enum AttendanceStatus {
  hadir('Hadir'),
  terlambat('Terlambat'),
  izin('Izin'),
  sakit('Sakit'),
  alpha('Alpha'),
  belumAbsen('Belum Absen'),
  ditolak('Ditolak'), // Some UI elements use this
  unknown('Unknown');

  final String value;
  const AttendanceStatus(this.value);

  static AttendanceStatus fromString(String status) {
    final s = status.trim().toLowerCase();
    if (s.contains('hadir')) return AttendanceStatus.hadir;
    if (s.contains('terlambat')) return AttendanceStatus.terlambat;
    if (s.contains('izin') || s.contains('disetujui')) return AttendanceStatus.izin;
    if (s.contains('sakit')) return AttendanceStatus.sakit;
    if (s.contains('alpha')) return AttendanceStatus.alpha;
    if (s.contains('belum absen') || s.contains('akan hadir')) return AttendanceStatus.belumAbsen;
    if (s.contains('ditolak')) return AttendanceStatus.ditolak;
    
    return AttendanceStatus.unknown;
  }
}

enum InvitationStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  autoApproved('auto-approved'),
  permissionRequested('permission_requested'),
  unknown('unknown');

  final String value;
  const InvitationStatus(this.value);

  static InvitationStatus fromString(String status) {
    final s = status.trim().toLowerCase();
    switch (s) {
      case 'pending':
        return InvitationStatus.pending;
      case 'approved':
        return InvitationStatus.approved;
      case 'rejected':
        return InvitationStatus.rejected;
      case 'auto-approved':
        return InvitationStatus.autoApproved;
      case 'permission_requested':
        return InvitationStatus.permissionRequested;
      default:
        return InvitationStatus.unknown;
    }
  }
}

enum PermissionStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected'),
  unknown('Unknown');

  final String value;
  const PermissionStatus(this.value);

  static PermissionStatus fromString(String status) {
    final s = status.trim().toLowerCase();
    switch (s) {
      case 'pending':
        return PermissionStatus.pending;
      case 'approved':
        return PermissionStatus.approved;
      case 'rejected':
        return PermissionStatus.rejected;
      default:
        return PermissionStatus.unknown;
    }
  }
}
