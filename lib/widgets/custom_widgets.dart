/// Custom widgets untuk UI redesign
/// Mengikuti design system dan referensi UI
library;
import 'package:flutter/material.dart';
import '../core/constants/design_system.dart';

/// Card dengan header berwarna (seperti di referensi UI)
class HeaderCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color backgroundColor;
  final Widget? trailing;
  final Widget? child;
  final VoidCallback? onTap;

  const HeaderCard({
    super.key,
    required this.title,
    this.subtitle,
    this.backgroundColor = AppColors.primary,
    this.trailing,
    this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
        if (child != null) ...[const SizedBox(height: AppSpacing.lg), child!],
      ],
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: content,
        ),
      ),
    );
  }
}

/// Statistics card dengan icon dan value
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      color: backgroundColor ?? AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppSpacing.iconLg,
              height: AppSpacing.iconLg,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.primary,
                  size: AppSpacing.iconMd,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              value,
              style: AppTypography.displaySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress bar dengan label dan percentage
class AttendanceProgressBar extends StatelessWidget {
  final String label;
  final int attendanceCount;
  final int totalCount;
  final Color? color;
  final bool showPercentage;

  const AttendanceProgressBar({
    super.key,
    required this.label,
    required this.attendanceCount,
    required this.totalCount,
    this.color,
    this.showPercentage = true,
  });

  double get percentage =>
      totalCount == 0 ? 0 : (attendanceCount / totalCount) * 100;

  @override
  Widget build(BuildContext context) {
    final progressColor = color ?? AppColors.hadir;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showPercentage)
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: AppTypography.labelMedium.copyWith(
                  color: progressColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: percentage / 100,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
        if (showPercentage)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              '$attendanceCount/$totalCount',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Status badge untuk menampilkan status kehadiran
class AttendanceStatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const AttendanceStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  Color _getStatusColor() {
    final normalized = status.toLowerCase().trim();
    if (normalized == 'hadir') return AppColors.hadir;
    if (normalized == 'izin') return AppColors.izin;
    if (normalized == 'alpha') return AppColors.alpha;
    if (normalized == 'terlambat') return AppColors.terlambat;
    return AppColors.textSecondary;
  }

  IconData _getStatusIcon() {
    final normalized = status.toLowerCase().trim();
    if (normalized == 'hadir') return Icons.check_circle;
    if (normalized == 'izin') return Icons.help_outline;
    if (normalized == 'alpha') return Icons.cancel;
    if (normalized == 'terlambat') return Icons.schedule;
    return Icons.help_outline;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    final icon = _getStatusIcon();

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: AppSpacing.xs),
            Text(
              status,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: AppSpacing.iconMd),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              status,
              style: AppTypography.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state widget
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.description,
    this.icon = Icons.folder_open_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              description!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Elevated section header dengan background
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Color? backgroundColor;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: backgroundColor != null
                  ? AppColors.primary
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
