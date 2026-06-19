import 'package:flutter/material.dart';

class WhiteStatusHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? statusBadge;

  const WhiteStatusHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.statusBadge,
  });

  @override
  Size get preferredSize => const Size.fromHeight(88);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: preferredSize.height + topPadding,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: preferredSize.height,
            child: Row(
              children: [
                if (leading != null)
                  leading!
                else
                  Builder(
                    builder: (innerContext) {
                      final scaffold = Scaffold.maybeOf(innerContext);
                      final hasDrawer = scaffold?.hasDrawer ?? false;
                      final canPop = Navigator.of(innerContext).canPop();

                      if (hasDrawer) {
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.menu, color: Color(0xFF1F2937)),
                            onPressed: () => scaffold!.openDrawer(),
                          ),
                        );
                      } else if (canPop) {
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.chevron_left, color: Color(0xFF1F2937)),
                            onPressed: () => Navigator.of(innerContext).pop(),
                          ),
                        );
                      }
                      return const SizedBox(width: 16);
                    },
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (statusBadge != null) ...[
                        const SizedBox(height: 6),
                        statusBadge!,
                      ],
                    ],
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}