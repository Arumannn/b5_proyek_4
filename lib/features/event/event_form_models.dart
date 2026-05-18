class EventParentOption {
  final String id;
  final String name;

  const EventParentOption({required this.id, required this.name});
}

class EventFormValue {
  final String name;
  final DateTime date;
  final DateTime? endDate;
  final DateTime? jamSelesai;
  final bool isSubEvent;
  final String? parentId;
  final String jenis;
  final String? lokasi;
  final String? deskripsi;
  final List<String> targetPeserta;
  final bool requiresInvitation;

  const EventFormValue({
    required this.name,
    required this.date,
    required this.endDate,
    this.jamSelesai,
    required this.isSubEvent,
    this.parentId,
    this.jenis = 'Kegiatan',
    this.lokasi,
    this.deskripsi,
    this.targetPeserta = const [],
    this.requiresInvitation = false,
  });
}
