import 'package:flutter/material.dart';
import '../event_controller.dart';

class EventFilterChips extends StatelessWidget {
  final EventController controller;
  final VoidCallback onJenisFilterTap;
  final VoidCallback onDateFilterTap;
  final VoidCallback onClearFilters;

  const EventFilterChips({
    super.key,
    required this.controller,
    required this.onJenisFilterTap,
    required this.onDateFilterTap,
    required this.onClearFilters,
  });

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: controller.selectedJenisFilter,
      builder: (_, jenisFilter, _) {
        return ValueListenableBuilder<DateTimeRange?>(
          valueListenable: controller.selectedDateRangeFilter,
          builder: (_, dateRange, _) {
            final hasFilters = controller.hasActiveFilters;
            final chipShape = RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Filter Jenis Button
                  FilterChip(
                    label: Text(jenisFilter ?? 'Semua Jenis'),
                    selected: jenisFilter != null,
                    onSelected: (_) => onJenisFilterTap(),
                    avatar: const Icon(Icons.category_outlined, size: 18),
                    shape: chipShape,
                    showCheckmark: false,
                    selectedColor: const Color(0xFFDBEAFE),
                    labelStyle: TextStyle(
                      fontWeight: jenisFilter != null
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: jenisFilter != null
                          ? const Color(0xFF1D4ED8)
                          : Colors.black87,
                    ),
                  ),
                  
                  // Filter Tanggal Button
                  FilterChip(
                    label: Text(
                      dateRange != null
                          ? '${_formatDate(dateRange.start)} - ${_formatDate(dateRange.end)}'
                          : 'Semua Tanggal',
                    ),
                    selected: dateRange != null,
                    onSelected: (_) => onDateFilterTap(),
                    avatar: const Icon(Icons.date_range, size: 18),
                    shape: chipShape,
                    showCheckmark: false,
                    selectedColor: const Color(0xFFDCFCE7),
                    labelStyle: TextStyle(
                      fontWeight: dateRange != null
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: dateRange != null
                          ? const Color(0xFF166534)
                          : Colors.black87,
                    ),
                  ),

                  // Clear All Filters
                  if (hasFilters)
                    ActionChip(
                      label: const Text('Reset Filter'),
                      onPressed: onClearFilters,
                      avatar: const Icon(Icons.clear_all, size: 18),
                      shape: chipShape,
                      backgroundColor: const Color(0xFFF3F4F6),
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}