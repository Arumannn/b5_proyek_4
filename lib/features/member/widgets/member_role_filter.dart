import 'package:flutter/material.dart';
import '../member_controller.dart';

/// Division filter chips for member list
class MemberRoleFilter extends StatelessWidget {
  final MemberController controller;

  const MemberRoleFilter({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F7FD),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: ValueListenableBuilder<List<String>>(
        valueListenable: controller.availableDivisions,
        builder: (context, divisions, _) {
          return ValueListenableBuilder<String>(
            valueListenable: controller.selectedDivision,
            builder: (context, selectedDiv, _) {
              return SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: divisions.length,
                  itemBuilder: (context, index) {
                    final div = divisions[index];
                    final isSelected = div == selectedDiv;
                    final count = controller.getDivisionCount(div);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$div ($count)'),
                        selected: isSelected,
                        onSelected: (_) => controller.setDivision(div),
                        selectedColor: const Color(0xFFDBEAFE),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : Colors.grey.shade200,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF1D4ED8)
                              : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
