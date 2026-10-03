import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:flutter/material.dart';

class SetupChoiceTile extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDetails;

  const SetupChoiceTile({
    super.key,
    required this.name,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: isSelected ? p.accent.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              selected: isSelected,
              child: InkWell(
                onTap: onSelect,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(children: [
                    Icon(
                        isSelected
                            ? Icons.check_circle_outline
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: isSelected ? p.accentText : p.inkMuted),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: TextStyle(
                                fontSize: 14,
                                color: p.ink,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500)),
                        if (isSelected)
                          Text('Current setup',
                              style:
                                  TextStyle(fontSize: 12, color: p.inkMuted)),
                      ],
                    )),
                  ]),
                ),
              ),
            ),
          ),
          if (isSelected)
            IconButton(
                tooltip: 'Setup details',
                onPressed: onDetails,
                icon: Icon(Icons.info_outline, size: 20, color: p.inkMuted)),
          IconButton(
              tooltip: 'Edit setup',
              onPressed: onEdit,
              icon: Icon(Icons.edit_outlined, size: 20, color: p.inkMuted)),
        ],
      ),
    );
  }
}
