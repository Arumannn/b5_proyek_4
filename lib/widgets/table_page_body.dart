import 'package:flutter/material.dart';

/// Reusable composition scaffold for table-based pages (search/filter/table pattern)
/// 
/// Provides structured layout for administrative/data management screens with:
/// - Header widget (decorative or informational)
/// - Summary/stats cards
/// - Search/filter controls
/// - Scrollable data table
/// - Empty state handling
/// - Refresh capability
class TablePageBody extends StatelessWidget {
  /// Header widget (e.g., gradient bar with title/icon)
  final Widget header;

  /// Summary/stats cards displayed above table
  final Widget summaryArea;

  /// Search bar and/or filter chips
  final Widget filterArea;

  /// Builder function that returns the scrollable table widget
  final WidgetBuilder tableBuilder;

  /// Empty state widget to show when no data
  final Widget emptyState;

  /// Refresh callback (e.g., to reload data from API)
  final Future<void> Function() onRefresh;

  const TablePageBody({
    super.key,
    required this.header,
    required this.summaryArea,
    required this.filterArea,
    required this.tableBuilder,
    required this.emptyState,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ── Header (e.g., gradient bar) ─────────────────
          header,

          // ── Summary/Stats Area ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: summaryArea,
          ),

          // ── Search/Filter Area ──────────────────────────
          if (filterArea != SizedBox.shrink())
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: filterArea,
            ),

          // ── Scrollable Table/List ───────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: onRefresh,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: tableBuilder(context),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
