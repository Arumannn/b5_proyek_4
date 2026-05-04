import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../widgets/gradient_header.dart';
import '../auth/auth_controller.dart';

class EventParentOption {
  final String id;
  final String name;

  const EventParentOption({required this.id, required this.name});
}

class EventFormValue {
  final String name;
  final DateTime date;
  final bool isSubEvent;
  final String? parentId;
  final String jenis;
  final String? lokasi;
  final String? deskripsi;
  final List<String> targetPeserta;

  const EventFormValue({
    required this.name,
    required this.date,
    required this.isSubEvent,
    this.parentId,
    this.jenis = 'Kegiatan',
    this.lokasi,
    this.deskripsi,
    this.targetPeserta = const [],
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
  late bool _isSubEvent;
  String? _parentId;
  late String _selectedJenis;
  late Set<String> _selectedDivisi;

  final _formKey = GlobalKey<FormState>();

    String get _currentRole =>
      (AuthController.instance.currentUser.value?.role ?? '').trim().toLowerCase();

    bool get _hasAccess =>
      _currentRole == AppConstants.roleExecutive.toLowerCase() ||
      _currentRole == 'executive' ||
      _currentRole == 'eksekutif' ||
      _currentRole == 'admin' ||
      _currentRole == AppConstants.roleManager.toLowerCase();

  // Daftar divisi yang tersedia (bisa di-customize sesuai organisasi)
  static const List<String> _availableDivisi = [
    'Core',
    'Kadep & Wakadep',
    'Pengembangan Aplikasi',
    'UI/UX Design',
    'Data Science',
    'Cyber Security',
    'Networking',
    'Multimedia',
    'Public Relations',
    'Anggota',
  ];

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
    _isSubEvent = widget.initialValue?.isSubEvent ?? false;
    _parentId = widget.initialValue?.parentId;
    _selectedJenis = widget.initialValue?.jenis ?? 'Kegiatan';
    _selectedDivisi = Set<String>.from(widget.initialValue?.targetPeserta ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lokasiController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
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

  Future<void> _showDivisiPicker() async {
    final tempSelected = Set<String>.from(_selectedDivisi);
    
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Pilih Target Peserta'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: _availableDivisi.map((divisi) {
                    final isSelected = tempSelected.contains(divisi);
                    return CheckboxListTile(
                      title: Text(divisi),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            tempSelected.add(divisi);
                          } else {
                            tempSelected.remove(divisi);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _selectedDivisi = tempSelected;
                    });
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
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
        isSubEvent: _isSubEvent,
        parentId: _isSubEvent ? _parentId : null,
        jenis: _selectedJenis,
        lokasi: _lokasiController.text.trim().isEmpty
            ? null
            : _lokasiController.text.trim(),
        deskripsi: _deskripsiController.text.trim().isEmpty 
            ? null 
            : _deskripsiController.text.trim(),
        targetPeserta: _selectedDivisi.toList(),
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

  String _getSelectedDivisiText() {
    if (_selectedDivisi.isEmpty) {
      return 'Semua Divisi';
    } else if (_selectedDivisi.length <= 2) {
      return _selectedDivisi.join(', ');
    } else {
      return '${_selectedDivisi.length} divisi dipilih';
    }
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D4ED8),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: GradientHeader(
        title: widget.title,
        subtitle: 'Form pembuatan dan pengeditan event',
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _submit,
            tooltip: 'Simpan',
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionCard(
                title: 'Informasi Umum',
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Event *',
                      hintText: 'Contoh: Rapat Evaluasi Bulanan',
                      prefixIcon: Icon(Icons.event),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama event wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedJenis,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Event *',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: _jenisOptions
                        .map((jenis) => DropdownMenuItem<String>(
                              value: jenis,
                              child: Text(jenis),
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
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: SwitchListTile(
                      title: const Text('Jadikan Sub Event', style: TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: _isSubEvent 
                          ? const Text('Event ini merupakan bagian dari event utama')
                          : null,
                      value: _isSubEvent,
                      activeColor: const Color(0xFF2563EB),
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
                    DropdownButtonFormField<String>(
                      value: _parentId,
                      decoration: const InputDecoration(
                        labelText: 'Parent Event *',
                        prefixIcon: Icon(Icons.account_tree_outlined),
                      ),
                      hint: const Text('Pilih parent event'),
                      items: widget.parentOptions
                          .map(
                            (event) => DropdownMenuItem<String>(
                              value: event.id,
                              child: Text(event.name),
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
                          return 'Parent event wajib dipilih untuk sub event';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),

              _buildSectionCard(
                title: 'Waktu & Lokasi',
                children: [
                  ListTile(
                    title: const Text('Tanggal Event *'),
                    subtitle: Text(
                      _formatDate(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    leading: const Icon(Icons.calendar_today_outlined, color: Color(0xFF2563EB)),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: _pickDate,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Waktu Dimulai *'),
                    subtitle: Text(
                      _formatTime(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    leading: const Icon(Icons.schedule_outlined, color: Color(0xFF2563EB)),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: _pickTime,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lokasiController,
                    decoration: const InputDecoration(
                      labelText: 'Lokasi (Opsional)',
                      hintText: 'Contoh: Ruang Seminar Informatika, Lt. 3',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),

              _buildSectionCard(
                title: 'Peserta & Deskripsi',
                children: [
                  ListTile(
                    title: const Text('Target Peserta'),
                    subtitle: Text(
                      _getSelectedDivisiText(),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _selectedDivisi.isEmpty 
                            ? Colors.grey 
                            : const Color(0xFF2563EB),
                      ),
                    ),
                    leading: const Icon(Icons.people_outline, color: Color(0xFF2563EB)),
                    trailing: const Icon(Icons.arrow_drop_down),
                    onTap: _showDivisiPicker,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _deskripsiController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi (Opsional)',
                      hintText: 'Tulis deskripsi event.',
                      prefixIcon: Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),

              // ── Info Wajib ──────────────────────────────────
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Field bertanda * wajib diisi',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tombol Simpan ───────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Simpan Event'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}