import 'package:flutter/material.dart';

class InlineExpandingDropdownField extends StatefulWidget {
  const InlineExpandingDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.placeholder = 'Pilih salah satu',
    this.validator,
    this.itemLabelBuilder,
    this.enabled = true,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String placeholder;
  final String? Function(String?)? validator;
  final String Function(String value)? itemLabelBuilder;
  final bool enabled;

  @override
  State<InlineExpandingDropdownField> createState() => _InlineExpandingDropdownFieldState();
}

class _InlineExpandingDropdownFieldState extends State<InlineExpandingDropdownField> {
  bool _isExpanded = false;

  String _labelFor(String value) => widget.itemLabelBuilder?.call(value) ?? value;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: ValueKey('${widget.label}:${widget.value}:${widget.options.join('|')}'),
      initialValue: widget.value,
      validator: widget.validator,
      builder: (field) {
        final selectedValue = field.value ?? widget.value;
        final hasSelection = selectedValue.trim().isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: widget.enabled
                  ? () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    }
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: field.hasError ? Colors.redAccent : Colors.grey[200]!,
                    width: field.hasError ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        hasSelection ? _labelFor(selectedValue) : widget.placeholder,
                        style: TextStyle(
                          fontSize: 14,
                          color: hasSelection ? Colors.black87 : Colors.black38,
                        ),
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widget.options.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[100]),
                  itemBuilder: (context, index) {
                    final option = widget.options[index];
                    final isSelected = option == selectedValue;

                    return InkWell(
                      onTap: () {
                        field.didChange(option);
                        widget.onChanged(option);
                        setState(() {
                          _isExpanded = false;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _labelFor(option),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected ? const Color(0xFF2563EB) : Colors.black87,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, size: 18, color: Color(0xFF2563EB)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (field.errorText != null) ...[
              const SizedBox(height: 6),
              Text(
                field.errorText!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ],
        );
      },
    );
  }
}