import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../widgets/gradient_header.dart';
import '../auth/auth_controller.dart';
import 'widgets/participant_selector.dart';

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
  final String? penyelenggara;

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
    this.penyelenggara,
  });
}

/// Form tambah/edit event — Enhanced Week 9 Sub-Tahap B
/// 
/// FITUR BARU:
/// - Field deskripsi (opsional)
/// - Multi-select target peserta (divisi)
/// - Dropdown jenis event
/// - Better validation & UX
class EventFormView extends StatefulWidget {
  final String title;
  final EventFormValue? initialValue;
  final List<EventParentOption> parentOptions;
  final bool canChangeHierarchy;

  const EventFormView({
    super.key,
    this.title = 'Tambah Event',
    this.initialValue,
    this.parentOptions = const [],
    this.canChangeHierarchy = true,
  });

  @override
  State<EventFormView> createState() => _EventFormViewState();
}

class _EventFormViewState extends State<EventFormView> {
  late final TextEditingController _nameController;
  late final TextEditingController _lokasiController;
  late final TextEditingController _deskripsiController;
  late DateTime _selectedDate;
  late DateTime _selectedEndDate;
  DateTime? _selectedJamSelesai;
  late bool _isSubEvent;
  String? _parentId;
  late String _selectedJenis;
  late List<String> _selectedTargetIds;
  String? _selectedPenyelenggara;

  final _formKey = GlobalKey<FormState>();

    String get _currentRole =>
      (AuthController.instance.currentUser.value?.role ?? '').trim().toLowerCase();

    bool get _hasAccess =>
      _currentRole == AppConstants.roleExecutive.toLowerCase() ||
      _currentRole == 'executive' ||
      _currentRole == 'eksekutif' ||
      _currentRole == 'admin' ||
      _currentRole == AppConstants.roleManager.toLowerCase();

  // Jenis event dari AppConstants
  static const List<String> _jenisOptions = [
    'Rapat',
    'Acara',
    'Kegiatan',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialValue?.name ?? '');
    _lokasiController = TextEditingController(text: widget.initialValue?.lokasi ?? '');
    _deskripsiController = TextEditingController(text: widget.initialValue?.deskripsi ?? '');
    _selectedDate = widget.initialValue?.date ?? DateTime.now();
    _selectedEndDate = widget.initialValue?.endDate ?? DateTime.now();
    _selectedJamSelesai = widget.initialValue?.jamSelesai;
    _isSubEvent = widget.initialValue?.isSubEvent ?? false;
    _parentId = widget.initialValue?.parentId;
    _selectedJenis = widget.initialValue?.jenis ?? 'Kegiatan';
    _selectedTargetIds = List<String>.from(widget.initialValue?.targetPeserta ?? []);
    _selectedPenyelenggara = widget.initialValue?.penyelenggara;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lokasiController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final firstDate = DateTime(today.year, today.month, today.day);
    final initialDate = _selectedDate.isBefore(firstDate) ? firstDate : _selectedDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
      helpText: 'Pilih Tanggal Event',
      cancelText: 'Batal',
      confirmText: 'OK',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _selectedDate.hour,
        minute: _selectedDate.minute,
      ),
      helpText: 'Pilih Waktu Dimulai',
      cancelText: 'Batal',
      confirmText: 'OK',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _pickEndTime() async {
    final initial = _selectedJamSelesai ?? _selectedDate;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initial.hour,
        minute: initial.minute,
      ),
      helpText: 'Pilih Waktu Selesai',
      cancelText: 'Batal',
      confirmText: 'OK',
    );
    if (picked != null) {
      setState(() {
        // Gabungkan jam yang dipilih dengan tanggal dari _selectedEndDate (atau _selectedDate jika null)
        final baseDate = _selectedEndDate;
        _selectedJamSelesai = DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama event wajib diisi.')),
      );
      return;
    }

    if (_isSubEvent && (_parentId == null || _parentId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih parent event untuk sub event.')),
      );
      return;
    }

    Navigator.pop(
      context,
      EventFormValue(
        name: name,
        date: _selectedDate,
        endDate: _selectedEndDate,
        jamSelesai: _selectedJamSelesai,
        isSubEvent: _isSubEvent,
        parentId: _isSubEvent ? _parentId : null,
        jenis: _selectedJenis,
        lokasi: _lokasiController.text.trim().isEmpty
            ? null
            : _lokasiController.text.trim(),
        deskripsi: _deskripsiController.text.trim().isEmpty 
            ? null 
            : _deskripsiController.text.trim(),
        targetPeserta: _selectedTargetIds,
        penyelenggara: _selectedPenyelenggara,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }

  String _formatTime(DateTime date) {
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAccess) {
      return Scaffold(
        appBar: const GradientHeader(
          title: 'Form Event',
          subtitle: 'Akses terbatas',
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Halaman form event hanya dapat diakses oleh Executive atau Manager.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.chevron_left, color: Colors.grey[600], size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    _buildInputLabel('Nama Kegiatan'),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(hintText: 'Contoh: Musyawarah Besar'),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama event wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildInputLabel('Jenis Kegiatan'),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedJenis,
                      decoration: _inputDecoration(),
                      items: _jenisOptions
                          .map((jenis) => DropdownMenuItem<String>(
                                value: jenis,
                                child: Text(jenis, style: const TextStyle(fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedJenis = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildInputLabel('Penyelenggara'),
                    DropdownButtonFormField<String>(
                      value: _selectedPenyelenggara,
                      decoration: _inputDecoration(hintText: 'Pilih penyelenggara'),
                      isExpanded: true,
                      items: AppConstants.penyelenggaraOptions
                          .map((p) => DropdownMenuItem<String>(
                                value: p,
                                child: Text(p, style: const TextStyle(fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPenyelenggara = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Grid untuk Tanggal dan Waktu Mulai
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('Tanggal'),
                              GestureDetector(
                                onTap: _pickDate,
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    controller: TextEditingController(text: _formatDate(_selectedDate)),
                                    decoration: _inputDecoration(
                                      suffixIcon: const Icon(Icons.calendar_today, size: 18),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('Waktu (Mulai)'),
                              GestureDetector(
                                onTap: _pickTime,
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    controller: TextEditingController(text: _formatTime(_selectedDate)),
                                    decoration: _inputDecoration(
                                      suffixIcon: const Icon(Icons.access_time, size: 18),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _buildInputLabel('Waktu Selesai (Opsional)'),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickEndTime,
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: TextEditingController(
                                  text: _selectedJamSelesai != null ? _formatTime(_selectedJamSelesai!) : 'Tidak ditentukan'
                                ),
                                decoration: _inputDecoration(
                                  suffixIcon: const Icon(Icons.access_time, size: 18),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_selectedJamSelesai != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () => setState(() => _selectedJamSelesai = null),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildInputLabel('Lokasi / Tempat'),
                    TextFormField(
                      controller: _lokasiController,
                      decoration: _inputDecoration(hintText: 'Contoh: Ruang Sidang Utama'),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),

                    _buildInputLabel('Deskripsi'),
                    TextFormField(
                      controller: _deskripsiController,
                      decoration: _inputDecoration(hintText: 'Tulis deskripsi event...'),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[50],
                      ),
                      child: SwitchListTile(
                        title: const Text('Jadikan Sub Event', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: _isSubEvent 
                            ? const Text('Bagian dari event utama', style: TextStyle(fontSize: 12))
                            : null,
                        value: _isSubEvent,
                        activeThumbColor: Colors.blue[600],
                        onChanged: widget.canChangeHierarchy
                            ? (value) {
                                setState(() {
                                  _isSubEvent = value;
                                  if (!_isSubEvent) _parentId = null;
                                });
                              }
                            : null,
                      ),
                    ),
                    if (_isSubEvent) ...[
                      const SizedBox(height: 16),
                      _buildInputLabel('Parent Event'),
                      DropdownButtonFormField<String>(
                        initialValue: _parentId,
                        decoration: _inputDecoration(hintText: 'Pilih parent event'),
                        items: widget.parentOptions
                            .map(
                              (event) => DropdownMenuItem<String>(
                                value: event.id,
                                child: Text(event.name, style: const TextStyle(fontSize: 14)),
                              ),
                            )
                            .toList(),
                        onChanged: widget.canChangeHierarchy
                            ? (value) {
                                setState(() {
                                  _parentId = value;
                                });
                              }
                            : null,
                        validator: (value) {
                          if (_isSubEvent && (value == null || value.isEmpty)) {
                            return 'Parent event wajib dipilih';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),

                    _buildInputLabel('Target Peserta'),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ParticipantSelector(
                        initialSelectedIds: _selectedTargetIds,
                        onSelectionChanged: (selectedIds) {
                          setState(() {
                            _selectedTargetIds = selectedIds;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        border: Border.all(color: Colors.blue[100]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info, color: Colors.blue[600], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(fontSize: 12, color: Colors.blue[800], height: 1.5),
                                children: const [
                                  TextSpan(text: 'Karena sistem menggunakan konsep '),
                                  TextSpan(text: 'Offline-First', style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: ', data event akan disimpan di memori lokal terlebih dahulu dan otomatis disinkronkan ke cloud saat koneksi tersedia.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.save, color: Colors.white, size: 20),
                        label: const Text('Simpan Event', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: Colors.blue[200],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
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