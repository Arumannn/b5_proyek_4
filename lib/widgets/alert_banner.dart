import 'package:flutter/material.dart';

enum AlertType { info, warning, error, success }

class AlertBanner extends StatelessWidget {
  final String message;
  final AlertType type;
  final IconData? customIcon;

  const AlertBanner({
    super.key,
    required this.message,
    this.type = AlertType.warning,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;

    switch (type) {
      case AlertType.info:
        bgColor = const Color(0xFFEFF6FF);
        borderColor = const Color(0xFFBFDBFE);
        textColor = const Color(0xFF1D4ED8);
        icon = customIcon ?? Icons.info_outline;
        break;
      case AlertType.warning:
        bgColor = const Color(0xFFFFF7ED);
        borderColor = const Color(0xFFFFEDD5);
        textColor = const Color(0xFF92400E);
        icon = customIcon ?? Icons.warning_amber_rounded;
        break;
      case AlertType.error:
        bgColor = const Color(0xFFFEF2F2);
        borderColor = const Color(0xFFFECACA);
        textColor = const Color(0xFFB91C1C);
        icon = customIcon ?? Icons.error_outline;
        break;
      case AlertType.success:
        bgColor = const Color(0xFFF0FDF4);
        borderColor = const Color(0xFFBBF7D0);
        textColor = const Color(0xFF15803D);
        icon = customIcon ?? Icons.check_circle_outline;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
