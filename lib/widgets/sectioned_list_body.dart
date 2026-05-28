import 'package:flutter/material.dart';

/// Generic layout for list-based feature pages.
///
/// It composes the main page sections while supporting older call sites.
class SectionedListBody extends StatelessWidget {
  final Widget? header;
  final Widget? searchArea;
  final Widget? searchBar;
  final Widget? filterArea;
  final Widget? content;
  final WidgetBuilder? listBuilder;
  final Widget? emptyState;
  final Future<void> Function()? onRefresh;
  final EdgeInsetsGeometry searchPadding;
  final EdgeInsetsGeometry? filterPadding;

  const SectionedListBody({
    super.key,
    this.header,
    this.searchArea,
    this.searchBar,
    this.content,
    this.listBuilder,
    this.emptyState,
    this.onRefresh,
    this.filterArea,
    this.searchPadding = const EdgeInsets.fromLTRB(16, 14, 16, 10),
    this.filterPadding,
  });

  @override
  Widget build(BuildContext context) {
    final Widget? effectiveSearch = searchBar ?? searchArea;
    final Widget? effectiveContent = content ?? (listBuilder != null ? listBuilder!(context) : emptyState);

    return Column(
      children: [
        if (header != null) header!,
        if (effectiveSearch != null)
          Padding(
            padding: searchPadding,
            child: effectiveSearch,
          ),
        if (filterArea != null)
          Padding(
            padding: filterPadding ?? EdgeInsets.zero,
            child: filterArea!,
          ),
        Expanded(
          child: effectiveContent ?? const SizedBox.shrink(),
        ),
      ],
    );
  }
}
