import 'package:flutter/material.dart';

import '../../core/controllers/config_controller.dart';
import '../../core/services/sync_manager.dart';
import '../../widgets/white_status_header.dart';
import '../auth/auth_controller.dart';
import 'event_form_models.dart';
import 'event_permission.dart';
import 'widgets/event_form_content.dart';

export 'event_form_models.dart';

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
  late final TextEditingController _penanggungJawabController;
  DateTime? _selectedDate;
  DateTime? _selectedEndDate;
  DateTime? _selectedJamSelesai;
  late bool _isSubEvent;
  String? _parentId;
  late String _selectedJenis;
  late List<String> _selectedTargetIds;
  late bool _requiresInvitation;
  late String _selectedPenyelenggara;

  late final TextEditingController _customPenyelenggaraController;

  final _formKey = GlobalKey<FormState>();

  String get _currentRole =>
      (AuthController.instance.currentUser.value?.role ?? '').trim().toLowerCase();

  bool get _hasAccess {
    if (_isSubEvent) {
      return EventPermission.canCreateSubEvent(_currentRole);
    } else {
      return EventPermission.canCreateMainEvent(_currentRole);
    }
  }

  @override
  void initState() {
    super.initState();
    SyncManager.instance.pullOrganizationConfigFromCloud();
    _nameController = TextEditingController(text: widget.initialValue?.name ?? '');
    _lokasiController = TextEditingController(text: widget.initialValue?.lokasi ?? '');
    _deskripsiController = TextEditingController(text: widget.initialValue?.deskripsi ?? '');
    _penanggungJawabController = TextEditingController(text: widget.initialValue?.penanggungJawab ?? '');
    _selectedDate = widget.initialValue?.date;
    _selectedEndDate = widget.initialValue?.endDate ?? widget.initialValue?.date;
    _selectedJamSelesai = widget.initialValue?.jamSelesai;
    _isSubEvent = (_currentRole == 'manager') ? true : (widget.initialValue?.isSubEvent ?? false);
    _parentId = widget.initialValue?.parentId;
    final eventTypes = ConfigController.instance.eventTypes;
    _selectedJenis = widget.initialValue?.jenis ?? eventTypes.first;
    final jenisMatch = eventTypes.where((e) => e.trim().toLowerCase() == _selectedJenis.trim().toLowerCase()).toList();
    if (jenisMatch.isNotEmpty) {
      _selectedJenis = jenisMatch.first;
    } else if (eventTypes.isNotEmpty) {
      _selectedJenis = eventTypes.first;
    }

    _selectedTargetIds = List<String>.from(widget.initialValue?.targetPeserta ?? []);
    _requiresInvitation = widget.initialValue?.requiresInvitation ?? false;
    
    final options = ConfigController.instance.penyelenggaraOptions;
    _selectedPenyelenggara = widget.initialValue?.penyelenggara ?? options.first;
    _customPenyelenggaraController = TextEditingController();

    final penyeMatch = options.where((o) => o.trim().toLowerCase() == _selectedPenyelenggara.trim().toLowerCase()).toList();
    if (penyeMatch.isNotEmpty) {
      _selectedPenyelenggara = penyeMatch.first;
    } else if (_selectedPenyelenggara != 'Lainnya') {
      _customPenyelenggaraController.text = _selectedPenyelenggara;
      _selectedPenyelenggara = 'Lainnya';
    }

    if (_isSubEvent && (_parentId == null || _parentId!.isEmpty) && widget.parentOptions.isNotEmpty) {
      _parentId = widget.parentOptions.first.id;
    }
  }

  @override
  void didUpdateWidget(covariant EventFormView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isSubEvent && (_parentId == null || _parentId!.isEmpty) && widget.parentOptions.isNotEmpty) {
      _parentId = widget.parentOptions.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lokasiController.dispose();
    _deskripsiController.dispose();
    _penanggungJawabController.dispose();
    _customPenyelenggaraController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final firstDate = DateTime(today.year, today.month, today.day);
    final initialDate = _selectedDate != null && _selectedDate!.isBefore(firstDate) ? firstDate : (_selectedDate ?? firstDate);

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
          _selectedDate?.hour ?? 0,
          _selectedDate?.minute ?? 0,
        );
        _selectedEndDate ??= DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _pickEndDate() async {
    final today = DateTime.now();
    final firstDate = DateTime(today.year, today.month, today.day);
    final initialDate = _selectedEndDate != null && _selectedEndDate!.isBefore(firstDate)
        ? firstDate
        : (_selectedEndDate ?? _selectedDate ?? firstDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
      helpText: 'Pilih Tanggal Selesai',
      cancelText: 'Batal',
      confirmText: 'OK',
    );

    if (picked != null) {
      setState(() {
        _selectedEndDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedEndDate?.hour ?? _selectedJamSelesai?.hour ?? 0,
          _selectedEndDate?.minute ?? _selectedJamSelesai?.minute ?? 0,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedDate != null ? TimeOfDay(
        hour: _selectedDate!.hour,
        minute: _selectedDate!.minute,
      ) : TimeOfDay.now(),
      helpText: 'Pilih Waktu Dimulai',
      cancelText: 'Batal',
      confirmText: 'OK',
    );
    if (picked != null) {
      setState(() {
        final baseDate = _selectedDate ?? DateTime.now();
        _selectedDate = DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _pickEndTime() async {
    final initial = _selectedJamSelesai ?? _selectedDate ?? DateTime.now();
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
        final baseDate = _selectedEndDate ?? _selectedDate ?? DateTime.now();
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

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal dan waktu mulai wajib diisi.')),
      );
      return;
    }

    if (_selectedJamSelesai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waktu selesai wajib diisi.')),
      );
      return;
    }

    final endDate = _selectedEndDate ?? _selectedDate;

    if (_selectedTargetIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target peserta wajib dipilih (minimal 1).')),
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
        date: _selectedDate!,
        endDate: endDate,
        jamSelesai: _selectedJamSelesai,
        isSubEvent: _isSubEvent,
        parentId: _isSubEvent ? _parentId : null,
        jenis: _selectedJenis,
        lokasi: _lokasiController.text.trim().isEmpty ? null : _lokasiController.text.trim(),
        deskripsi: _deskripsiController.text.trim().isEmpty ? null : _deskripsiController.text.trim(),
        targetPeserta: _selectedTargetIds,
        requiresInvitation: _requiresInvitation,
        penyelenggara: _selectedPenyelenggara == 'Lainnya'
            ? _customPenyelenggaraController.text.trim()
            : _selectedPenyelenggara.trim(),
        penanggungJawab: _penanggungJawabController.text.trim().isEmpty
          ? null
          : _penanggungJawabController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    if (!_hasAccess) {
      return Scaffold(
        appBar: const WhiteStatusHeader(
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

    final isManager = _currentRole == 'manager';
    final subtitleStr = isManager ? 'Form pembuatan sub-event khusus manager' : 'Form pembuatan event organisasi';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: WhiteStatusHeader(
        title: widget.title,
        subtitle: subtitleStr,
      ),
      body: ListenableBuilder(
          listenable: ConfigController.instance,
          builder: (context, _) {
            final eventTypes = ConfigController.instance.eventTypes;
            final jenisMatch = eventTypes.where((e) => e.trim().toLowerCase() == _selectedJenis.trim().toLowerCase()).toList();
            if (jenisMatch.isNotEmpty) {
              _selectedJenis = jenisMatch.first;
            } else if (eventTypes.isNotEmpty) {
              _selectedJenis = eventTypes.first;
            }

            final penyelenggaraOptions = [
              ...ConfigController.instance.penyelenggaraOptions,
              'Lainnya'
            ];
            final penyeMatch = penyelenggaraOptions.where((o) => o.trim().toLowerCase() == _selectedPenyelenggara.trim().toLowerCase()).toList();
            if (penyeMatch.isNotEmpty) {
              _selectedPenyelenggara = penyeMatch.first;
            } else if (_selectedPenyelenggara != 'Lainnya') {
              _selectedPenyelenggara = penyelenggaraOptions.first;
            }

            return EventFormContent(
              formKey: _formKey,
              title: widget.title,
              nameController: _nameController,
              lokasiController: _lokasiController,
              deskripsiController: _deskripsiController,
              penanggungJawabController: _penanggungJawabController,
              customPenyelenggaraController: _customPenyelenggaraController,
              selectedDate: _selectedDate,
              selectedEndDate: _selectedEndDate,
              selectedJamSelesai: _selectedJamSelesai,
              isSubEvent: _isSubEvent,
              parentId: _parentId,
              selectedJenis: _selectedJenis,
              eventTypes: eventTypes,
              selectedTargetIds: _selectedTargetIds,
              selectedPenyelenggara: _selectedPenyelenggara,
              penyelenggaraOptions: penyelenggaraOptions,
              parentOptions: widget.parentOptions,
              canChangeHierarchy: widget.canChangeHierarchy,
              onPickDate: _pickDate,
              onPickEndDate: _pickEndDate,
              onPickTime: _pickTime,
              onPickEndTime: _pickEndTime,
              onClearEndTime: () => setState(() => _selectedJamSelesai = null),
              onJenisChanged: (value) => setState(() => _selectedJenis = value),
              onPenyelenggaraChanged: (value) => setState(() => _selectedPenyelenggara = value),
              onSubEventChanged: (value) {
                setState(() {
                  _isSubEvent = value;
                  if (!_isSubEvent) {
                    _parentId = null;
                  } else if ((_parentId == null || _parentId!.isEmpty) && widget.parentOptions.isNotEmpty) {
                    _parentId = widget.parentOptions.first.id;
                  }
                });
              },
              onParentChanged: (value) => setState(() => _parentId = value),
              onTargetChanged: (selectedIds) => setState(() => _selectedTargetIds = selectedIds),
              requiresInvitation: _requiresInvitation,
              onRequiresInvitationChanged: (value) => setState(() => _requiresInvitation = value),
              onSubmit: _submit,
              formatDate: _formatDate,
              formatTime: _formatTime,
            );
          }
        ),
    );
  }
}