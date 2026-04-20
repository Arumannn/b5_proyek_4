import 'package:flutter/material.dart';

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

  const EventFormValue({
    required this.name,
    required this.date,
    required this.isSubEvent,
    this.parentId,
  });
}

/// Form tambah/edit event — Implementasi penuh: Week 9
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
  late DateTime _selectedDate;
  late bool _isSubEvent;
  String? _parentId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialValue?.name ?? '');
    _selectedDate = widget.initialValue?.date ?? DateTime.now();
    _isSubEvent = widget.initialValue?.isSubEvent ?? false;
    _parentId = widget.initialValue?.parentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() {
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
      ),
    );
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama event',
                  hintText: 'Contoh: Rapat Evaluasi',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Jadikan Sub Event'),
                value: _isSubEvent,
                onChanged: widget.canChangeHierarchy
                    ? (value) {
                        setState(() {
                          _isSubEvent = value;
                          if (!_isSubEvent) _parentId = null;
                        });
                      }
                    : null,
              ),
              if (_isSubEvent) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _parentId,
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
                ),
              ],
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tanggal event'),
                subtitle: Text(_formatDate(_selectedDate)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickDate,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}