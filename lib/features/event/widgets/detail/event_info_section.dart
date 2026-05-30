import 'package:flutter/material.dart';
import '../../../../models/event_model.dart';

class EventInfoSection extends StatelessWidget {
  final EventModel currentEvent;

  const EventInfoSection({
    super.key,
    required this.currentEvent,
  });

  String _formatDate(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = _monthName(value.month);
    final yyyy = value.year.toString();
    return '$dd $mm $yyyy';
  }

  String _formatTime(DateTime start, DateTime? end) {
    final hhStart = start.hour.toString().padLeft(2, '0');
    final minStart = start.minute.toString().padLeft(2, '0');
    if (end == null) return '$hhStart:$minStart';
    
    final hhEnd = end.hour.toString().padLeft(2, '0');
    final minEnd = end.minute.toString().padLeft(2, '0');
    return '$hhStart:$minStart - $hhEnd:$minEnd';
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  String _formatDateRange(EventModel event) {
    final startDateStr = _formatDate(event.tanggalMulai);
    final endDateStr = event.tanggalSelesai != null ? _formatDate(event.tanggalSelesai!) : startDateStr;
    
    if (startDateStr == endDateStr) {
      return startDateStr;
    }
    return '$startDateStr - $endDateStr';
  }

  String _formatTimeRange(EventModel event) {
    final startTime = event.jamMulai ?? event.tanggalMulai;
    final endTime = event.jamSelesai ?? event.tanggalSelesai;
    return '${_formatTime(startTime, endTime)} WIB';
  }

  String _eventLocation(EventModel event) {
    final lokasi = event.lokasi?.trim();
    if (lokasi != null && lokasi.isNotEmpty) return lokasi;
    return 'Lokasi belum diatur';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Tanggal',
            value: _formatDateRange(currentEvent),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.access_time_outlined,
            label: 'Waktu',
            value: _formatTimeRange(currentEvent),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Lokasi',
            value: _eventLocation(currentEvent),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.category_outlined,
            label: 'Jenis',
            value: currentEvent.jenis,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.business_outlined,
            label: 'Penyelenggara',
            value: currentEvent.penyelenggara?.trim().isNotEmpty == true
                ? currentEvent.penyelenggara!
                : 'Belum diatur',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: 'Penanggung Jawab',
            value: currentEvent.penanggungJawab?.trim().isNotEmpty == true
                ? currentEvent.penanggungJawab!
                : 'Belum diatur',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9CA3AF),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
