import 'package:bikesetupapp/common/ui/app_haptics.dart';
import 'package:flutter/cupertino.dart';
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
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Semantics(
            selected: isSelected,
            child: ListTile(
              selected: isSelected,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              title: Text(name,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: p.ink)),
              onTap: isSelected
                  ? onSelect
                  : AppHaptics.wrap(onSelect, selection: true),
              onLongPress: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (sheet) => SafeArea(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        ListTile(
                            title: const Text('Setup details'),
                            onTap: () {
                              Navigator.pop(sheet);
                              onDetails();
                            }),
                        ListTile(
                            title: const Text('Edit setup'),
                            onTap: () {
                              Navigator.pop(sheet);
                              onEdit();
                            })
                      ]))),
              trailing: isSelected
                  ? Icon(CupertinoIcons.check_mark,
                      size: 20, color: p.accentText)
                  : null,
            )));
  }
}
