import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../models/event_model.dart';
import '../../../../models/notulensi_model.dart';

class EventNotulensiSection extends StatefulWidget {
  final EventModel currentEvent;
  final String userRole;
  final bool isManagerOrExecutive;

  const EventNotulensiSection({
    super.key,
    required this.currentEvent,
    required this.userRole,
    required this.isManagerOrExecutive,
  });

  @override
  State<EventNotulensiSection> createState() => _EventNotulensiSectionState();
}

class _EventNotulensiSectionState extends State<EventNotulensiSection> {
  bool _isEditingNotulensi = false;
  final TextEditingController _notulensiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final notulensiRecord = HiveService.notulensi.get(widget.currentEvent.eventId);
    _notulensiController.text = notulensiRecord?.content ?? '';
  }

  @override
  void dispose() {
    _notulensiController.dispose();
    super.dispose();
  }

  Future<void> _saveNotulensi() async {
    final newNotulensi = _notulensiController.text.trim();
    
    if (newNotulensi.isEmpty) {
      await HiveService.notulensi.delete(widget.currentEvent.eventId);
    } else {
      final record = NotulensiModel(
        eventId: widget.currentEvent.eventId,
        content: newNotulensi,
        updatedAt: DateTime.now(),
        updatedBy: widget.userRole,
        isSynced: false,
      );
      await HiveService.notulensi.put(widget.currentEvent.eventId, record);
    }

    setState(() {
      _isEditingNotulensi = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'NOTULENSI EVENT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  letterSpacing: 0.5,
                ),
              ),
              if (widget.isManagerOrExecutive)
                GestureDetector(
                  onTap: () {
                    if (_isEditingNotulensi) {
                      _saveNotulensi();
                    } else {
                      setState(() {
                        _isEditingNotulensi = true;
                        _notulensiController.text = HiveService.notulensi.get(widget.currentEvent.eventId)?.content ?? '';
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isEditingNotulensi ? Icons.save_outlined : Icons.edit_note_outlined, 
                          size: 12, 
                          color: const Color(0xFF2563EB)
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isEditingNotulensi ? 'Simpan Teks' : 'Edit (MD)',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_isEditingNotulensi)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextFormField(
              controller: _notulensiController,
              maxLines: null,
              minLines: 5,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
              decoration: const InputDecoration(
                hintText: 'Tulis notulensi event di sini (Markdown)...',
                hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF3F4F6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ValueListenableBuilder(
              valueListenable: HiveService.notulensi.listenable(keys: [widget.currentEvent.eventId]),
              builder: (context, box, child) {
                final notulensi = box.get(widget.currentEvent.eventId)?.content.trim();
                final hasNotulensi = notulensi != null && notulensi.isNotEmpty;
                
                if (!hasNotulensi) {
                  return const Center(
                    child: Text(
                      'Belum ada notulensi.',
                      style: TextStyle(
                        fontSize: 13, 
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  );
                }

                return MarkdownBody(
                  data: notulensi,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                    h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                    h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                    h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                    listBullet: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
