import 'package:flutter/material.dart';

import 'event_form_footer.dart';
import 'event_form_header.dart';
import 'participant_selector.dart';
import '../event_form_models.dart';
import '../../../core/widgets/inline_expanding_dropdown_field.dart';
import '../../../core/constants/app_constants.dart';

class EventFormContent extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String title;
  final TextEditingController nameController;
  final TextEditingController lokasiController;
  final TextEditingController deskripsiController;
  final TextEditingController penanggungJawabController;
  final DateTime? selectedDate;
  final DateTime? selectedEndDate;
  final DateTime? selectedJamSelesai;
  final bool isSubEvent;
  final String? parentId;
  final String selectedJenis;
  final List<String> selectedTargetIds;
  final String selectedPenyelenggara;
  final List<EventParentOption> parentOptions;
  final bool canChangeHierarchy;
  final VoidCallback onPickDate;
  final VoidCallback onPickEndDate;
  final VoidCallback onPickTime;
  final VoidCallback onPickEndTime;
  final VoidCallback onClearEndTime;
  final ValueChanged<String> onJenisChanged;
  final ValueChanged<String> onPenyelenggaraChanged;
  final ValueChanged<bool> onSubEventChanged;
  final ValueChanged<String?> onParentChanged;
  final ValueChanged<List<String>> onTargetChanged;
  final bool requiresInvitation;
  final ValueChanged<bool> onRequiresInvitationChanged;
  final VoidCallback onSubmit;
  final String Function(DateTime date) formatDate;
  final String Function(DateTime date) formatTime;

  const EventFormContent({
    super.key,
    required this.formKey,
    required this.title,
    required this.nameController,
    required this.lokasiController,
    required this.deskripsiController,
    required this.penanggungJawabController,
    required this.selectedDate,
    required this.selectedEndDate,
    required this.selectedJamSelesai,
    required this.isSubEvent,
    required this.parentId,
    required this.selectedJenis,
    required this.selectedTargetIds,
    required this.selectedPenyelenggara,
    required this.parentOptions,
    required this.canChangeHierarchy,
    required this.onPickDate,
    required this.onPickEndDate,
    required this.onPickTime,
    required this.onPickEndTime,
    required this.onClearEndTime,
    required this.onJenisChanged,
    required this.onPenyelenggaraChanged,
    required this.onSubEventChanged,
    required this.onParentChanged,
    required this.onTargetChanged,
    required this.requiresInvitation,
    required this.onRequiresInvitationChanged,
    required this.onSubmit,
    required this.formatDate,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EventFormHeader(title: title),
        Expanded(
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildInputLabel('Nama Kegiatan', context),
                TextFormField(
                  controller: nameController,
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
                InlineExpandingDropdownField(
                  label: 'Jenis Kegiatan',
                  value: selectedJenis,
                  options: const ['Rapat', 'Acara', 'Kegiatan', 'Lainnya'],
                  placeholder: 'Pilih jenis kegiatan',
                  onChanged: onJenisChanged,
                ),
                const SizedBox(height: 16),
                InlineExpandingDropdownField(
                  label: 'Penyelenggara',
                  value: selectedPenyelenggara,
                  options: AppConstants.penyelenggaraOptions,
                  placeholder: 'Pilih penyelenggara',
                  onChanged: onPenyelenggaraChanged,
                ),
                const SizedBox(height: 16),
                _buildInputLabel('Penanggung Jawab', context),
                TextFormField(
                  controller: penanggungJawabController,
                  decoration: _inputDecoration(hintText: 'Contoh: Nama PIC event'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel('Tanggal Mulai', context),
                          GestureDetector(
                            onTap: onPickDate,
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: TextEditingController(
                                  text: selectedDate != null ? formatDate(selectedDate!) : 'Pilih Tanggal',
                                ),
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
                          _buildInputLabel('Waktu Mulai', context),
                          GestureDetector(
                            onTap: onPickTime,
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: TextEditingController(
                                  text: selectedDate != null ? formatTime(selectedDate!) : 'Pilih Waktu',
                                ),
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
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel('Tanggal Selesai', context),
                          GestureDetector(
                            onTap: onPickEndDate,
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: TextEditingController(
                                  text: selectedEndDate != null ? formatDate(selectedEndDate!) : 'Pilih Tanggal',
                                ),
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
                          _buildInputLabel('Waktu Selesai', context),
                          GestureDetector(
                            onTap: onPickEndTime,
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: TextEditingController(
                                  text: selectedJamSelesai != null
                                      ? formatTime(selectedJamSelesai!)
                                      : 'Pilih Waktu',
                                ),
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
                _buildInputLabel('Lokasi / Tempat', context),
                TextFormField(
                  controller: lokasiController,
                  decoration: _inputDecoration(hintText: 'Contoh: Ruang Sidang Utama'),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lokasi wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildInputLabel('Deskripsi (Opsional)', context),
                TextFormField(
                  controller: deskripsiController,
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
                    subtitle: isSubEvent
                        ? const Text('Bagian dari event utama', style: TextStyle(fontSize: 12))
                        : null,
                    value: isSubEvent,
                    activeThumbColor: Colors.blue[600],
                    onChanged: canChangeHierarchy
                        ? (value) => onSubEventChanged(value)
                        : null,
                  ),
                ),
                if (isSubEvent) ...[
                  const SizedBox(height: 16),
                  _buildInputLabel('Parent Event', context),
                  DropdownButtonFormField<String>(
                    initialValue: parentId,
                    decoration: _inputDecoration(hintText: 'Pilih parent event'),
                    items: parentOptions
                        .map(
                          (event) => DropdownMenuItem<String>(
                            value: event.id,
                            child: Text(event.name, style: const TextStyle(fontSize: 14)),
                          ),
                        )
                        .toList(),
                    onChanged: canChangeHierarchy ? onParentChanged : null,
                    validator: (value) {
                      if (isSubEvent && (value == null || value.isEmpty)) {
                        return 'Parent event wajib dipilih';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                _buildInputLabel('Target Peserta *', context),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ParticipantSelector(
                    initialSelectedIds: selectedTargetIds,
                    onSelectionChanged: onTargetChanged,
                  ),
                ),
                if (selectedTargetIds.isEmpty) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Wajib pilih minimal 1 target peserta.',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: SwitchListTile(
                    title: const Text('Aktifkan Undangan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Event ini akan muncul di Kelola Target Peserta', style: TextStyle(fontSize: 12)),
                    value: requiresInvitation,
                    activeThumbColor: Colors.blue[600],
                    onChanged: onRequiresInvitationChanged,
                  ),
                ),
                const SizedBox(height: 24),
                EventFormFooter(onSubmit: onSubmit),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String text, BuildContext context) {
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
}
