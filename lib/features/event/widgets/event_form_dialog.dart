import 'package:flutter/material.dart';

import '../../../core/controllers/config_controller.dart';
import '../../../core/services/hive_service.dart';
import '../../../core/services/sync_manager.dart';
import '../../../models/event_model.dart';
import '../../../models/member_model.dart';

class EventFormData {
  const EventFormData({
    required this.name,
    required this.date,
    required this.jenis,
    this.parentEventId,
    this.lokasi,
    this.deskripsi,
    this.targetPeserta = const <String>[],
    this.requiresInvitation = false,
    this.penyelenggara,
    this.penanggungJawab,
  });

  final String name;
  final DateTime date;
  final String jenis;
  final String? parentEventId;
  final String? lokasi;
  final String? deskripsi;
  final List<String> targetPeserta;
  final bool requiresInvitation;
  final String? penyelenggara;
  final String? penanggungJawab;
}

class EventFormDialog extends StatefulWidget {
  const EventFormDialog({
    super.key,
    required this.title,
    this.initial,
    this.forcedParentId,
    required this.parentOptions,
  });

  final String title;
  final EventModel? initial;
  final String? forcedParentId;
  final List<EventModel> parentOptions;

  @override
  State<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _lokasiController;
  late final TextEditingController _descController;
  late final TextEditingController _penanggungJawabController;

  late DateTime _selectedDate;
  late String _selectedJenis;
  late bool _isSubEvent;
  String? _parentId;
  final List<String> _targetDivisi = [];
  String? _selectedPenyelenggara;
  late bool _requiresInvitation;

  @override
  void initState() {
    super.initState();
    SyncManager.instance.pullOrganizationConfigFromCloud();
    _nameController = TextEditingController(text: widget.initial?.nama ?? '');
    _lokasiController = TextEditingController(text: widget.initial?.lokasi ?? '');
    _descController = TextEditingController(text: widget.initial?.deskripsi ?? '');
    _penanggungJawabController = TextEditingController(text: widget.initial?.penanggungJawab ?? '');

    _selectedDate = widget.initial?.tanggalMulai ?? DateTime.now();
    _selectedJenis = widget.initial?.jenis ?? ConfigController.instance.eventTypes.first;
    _isSubEvent = widget.forcedParentId != null || widget.initial?.parentEventId != null;
    _parentId = widget.forcedParentId ?? widget.initial?.parentEventId;
    
    if (widget.initial != null) {
      final allMembers = HiveService.members.values.toList();
      for (final nim in widget.initial!.targetPeserta) {
        final m = allMembers.firstWhere(
          (element) => element.nim == nim, 
          orElse: () => MemberModel(nim: '', nama: '', divisi: '', role: '', password: '', qrCodeValue: '')
        );
        if (m.nim.isNotEmpty) {
          if (m.divisi.isNotEmpty) _targetDivisi.add(m.divisi);
          if (m.jobTitle != null && m.jobTitle!.isNotEmpty) _targetDivisi.add(m.jobTitle!);
        }
      }
    }
    
    final targetDivisiSet = _targetDivisi.toSet();
    _targetDivisi.clear();
    _targetDivisi.addAll(targetDivisiSet);
    
    _selectedPenyelenggara = widget.initial?.penyelenggara;
    _requiresInvitation = widget.initial?.requiresInvitation ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lokasiController.dispose();
    _descController.dispose();
    _penanggungJawabController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_targetDivisi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target divisi wajib dipilih (minimal 1).')),
      );
      return;
    }
    
    final Set<String> targetNims = {};
    final allMembers = HiveService.members.values.toList();
    for (final div in _targetDivisi) {
      final normalizedDiv = div.trim().toLowerCase();
      final membersInDiv = allMembers.where((m) {
        final matchDivisi = m.divisi.trim().toLowerCase() == normalizedDiv;
        final matchJobTitle = (m.jobTitle?.trim().toLowerCase() ?? '') == normalizedDiv;
        return matchDivisi || matchJobTitle;
      });
      for (final m in membersInDiv) {
        targetNims.add(m.nim);
      }
    }

    Navigator.of(context).pop(
      EventFormData(
        name: _nameController.text.trim(),
        date: _selectedDate,
        jenis: _selectedJenis,
        parentEventId: _isSubEvent ? _parentId : null,
        lokasi: _lokasiController.text.trim().isEmpty ? null : _lokasiController.text.trim(),
        deskripsi: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        targetPeserta: targetNims.toList(growable: false),
        requiresInvitation: _requiresInvitation,
        penyelenggara: _selectedPenyelenggara,
        penanggungJawab: _penanggungJawabController.text.trim().isEmpty ? null : _penanggungJawabController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allDbu = ConfigController.instance.allDbuOptions;
    
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Event',
                    prefixIcon: Icon(Icons.event_note_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama event wajib diisi.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                ListenableBuilder(
                  listenable: ConfigController.instance,
                  builder: (context, _) {
                    final eventTypes = ConfigController.instance.eventTypes;
                    final jenisMatch = eventTypes.where((e) => e.trim().toLowerCase() == _selectedJenis.trim().toLowerCase()).toList();
                    if (jenisMatch.isNotEmpty) {
                      _selectedJenis = jenisMatch.first;
                    } else if (eventTypes.isNotEmpty) {
                      _selectedJenis = eventTypes.first;
                    }
                    return DropdownButtonFormField<String>(
                      value: _selectedJenis,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Event',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: eventTypes
                          .map(
                            (jenis) => DropdownMenuItem<String>(
                              value: jenis,
                              child: Text(jenis),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedJenis = value;
                        });
                      },
                    );
                  }
                ),
                const SizedBox(height: 12),
                ListenableBuilder(
                  listenable: ConfigController.instance,
                  builder: (context, _) {
                    final penyelenggaraOptions = ConfigController.instance.penyelenggaraOptions;
                    if (_selectedPenyelenggara != null) {
                      final penyeMatch = penyelenggaraOptions.where((o) => o.trim().toLowerCase() == _selectedPenyelenggara!.trim().toLowerCase()).toList();
                      if (penyeMatch.isNotEmpty) {
                        _selectedPenyelenggara = penyeMatch.first;
                      } else if (!penyelenggaraOptions.contains(_selectedPenyelenggara)) {
                        _selectedPenyelenggara = penyelenggaraOptions.isNotEmpty ? penyelenggaraOptions.first : null;
                      }
                    }
                    return DropdownButtonFormField<String>(
                      value: _selectedPenyelenggara,
                      decoration: const InputDecoration(
                        labelText: 'Penyelenggara',
                        prefixIcon: Icon(Icons.group_outlined),
                      ),
                      isExpanded: true,
                      items: penyelenggaraOptions
                          .map(
                            (p) => DropdownMenuItem<String>(
                              value: p,
                              child: Text(p),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        setState(() {
                          _selectedPenyelenggara = value;
                        });
                      },
                    );
                  }
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _penanggungJawabController,
                  decoration: const InputDecoration(
                    labelText: 'Penanggung Jawab',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Tanggal'),
                  subtitle: Text(_formatDate(_selectedDate)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lokasiController,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                ),
                if (widget.forcedParentId == null) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _isSubEvent,
                    title: const Text('Jadikan Sub-Event'),
                    onChanged: (value) {
                      setState(() {
                        _isSubEvent = value;
                        if (!value) _parentId = null;
                      });
                    },
                  ),
                ],
                if (_isSubEvent) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _parentId,
                    decoration: const InputDecoration(
                      labelText: 'Main Event (Parent)',
                      prefixIcon: Icon(Icons.account_tree_outlined),
                    ),
                    items: widget.parentOptions
                        .where(
                          (e) =>
                              widget.initial == null ||
                              e.eventId != widget.initial!.eventId,
                        )
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e.eventId,
                            child: Text(e.nama),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: widget.forcedParentId != null
                        ? null
                        : (value) {
                            setState(() {
                              _parentId = value;
                            });
                          },
                    validator: (value) {
                      if (!_isSubEvent) return null;
                      if (value == null || value.isEmpty) {
                        return 'Pilih parent event.';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Target Divisi *',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allDbu
                      .map((divisi) {
                        final selected = _targetDivisi.contains(divisi);
                        return FilterChip(
                          label: Text(divisi),
                          selected: selected,
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                _targetDivisi.add(divisi);
                              } else {
                                _targetDivisi.remove(divisi);
                              }
                            });
                          },
                        );
                      })
                      .toList(growable: false),
                ),
                const SizedBox(height: 8),
                if (_targetDivisi.isEmpty)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Wajib pilih minimal 1 target divisi.',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Aktifkan Undangan', style: TextStyle(fontSize: 14)),
                  contentPadding: EdgeInsets.zero,
                  value: _requiresInvitation,
                  onChanged: (value) {
                    setState(() {
                      _requiresInvitation = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
