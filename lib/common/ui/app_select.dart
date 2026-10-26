import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/theme_data.dart';
import 'adaptive_modal.dart';

/// A shared selector with a scrollable choice sheet instead of a popup menu.
class AppSelect<T> extends StatelessWidget {
  const AppSelect({super.key, required this.label, required this.value,
    required this.items, required this.onChanged, this.compact = false});
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool compact;

  Future<void> open(BuildContext context) async {
    FocusScope.of(context).unfocus();
    await showAdaptiveModal<void>(context: context, builder: (sheet) => SafeArea(
      top: false,
      child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * .7),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const AppSheetHandle(), const SizedBox(height: 24),
            Text(label, style: AppTextStyles.inter(size: 22, weight: FontWeight.w600, color: sheet.palette.ink)),
            const SizedBox(height: 20),
            Flexible(child: ListView.separated(shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, index) {
                final item = items[index];
                final selected = item.value == value;
                return Semantics(selected: selected,
                  child: Material(color: sheet.palette.bg, borderRadius: BorderRadius.circular(12),
                    child: ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: DefaultTextStyle(style: AppTextStyles.inter(size: 16,
                          weight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? sheet.palette.accentText : sheet.palette.ink), child: item.child),
                      trailing: selected ? Icon(CupertinoIcons.checkmark, size: 20, color: sheet.palette.accentText) : null,
                      enabled: item.enabled,
                      onTap: item.enabled ? () {
                        Navigator.of(sheet).pop();
                        if (context.mounted) onChanged?.call(item.value);
                      } : null)));
              })),
          ])),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final selected = items.where((item) => item.value == value).firstOrNull;
    return Semantics(button: true, label: label, enabled: onChanged != null,
      child: Material(color: compact ? Colors.transparent : context.palette.surface2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(borderRadius: BorderRadius.circular(12),
          onTap: onChanged == null ? null : () => open(context),
          child: Padding(padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 16, vertical: 14),
            child: Row(mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max, children: [
              Flexible(fit: compact ? FlexFit.loose : FlexFit.tight,
                child: DefaultTextStyle(style: AppTextStyles.inter(size: 15, color: context.palette.ink),
                    child: selected?.child ?? Text(label))),
              const SizedBox(width: 12),
              Icon(CupertinoIcons.chevron_down, size: 14, color: context.palette.inkMuted),
            ])),
        ),
      ),
    );
  }
}
