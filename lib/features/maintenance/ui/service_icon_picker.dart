import 'package:flutter/material.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import '../models/component_type.dart';
import '../models/service_icon.dart';
import 'service_component_icon.dart';

Future<ServiceIcon?> pickServiceIcon(
        BuildContext context, ServiceIcon selected) =>
    showAppSheet<ServiceIcon>(
        context: context,
        builder: (context) {
          final p = context.palette;
          return SafeArea(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const AppSheetHandle(),
                    const SizedBox(height: 24),
                    Text('Choose an icon',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 20),
                    LayoutBuilder(builder: (context, constraints) {
                      final columns = constraints.maxWidth < 330 ? 4 : 5;
                      final width =
                          (constraints.maxWidth - (columns - 1) * 8) / columns;
                      return Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final icon in ServiceIcon.values)
                          SizedBox(
                              width: width,
                              child: Semantics(
                                  label: icon.label,
                                  button: true,
                                  excludeSemantics: true,
                                  onTap: () => Navigator.pop(context, icon),
                                  selected: icon == selected,
                                  child: TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, icon),
                                    style: TextButton.styleFrom(
                                        foregroundColor: icon == selected
                                            ? p.accentInk
                                            : p.ink,
                                        backgroundColor: icon == selected
                                            ? p.accent
                                            : p.surface2,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14))),
                                    child: ServiceComponentIcon(
                                        type: ComponentType.other,
                                        customIcon: icon,
                                        size: AppIconSizes.navigation,
                                        color: icon == selected
                                            ? p.accentInk
                                            : p.ink),
                                  )))
                      ]);
                    }),
                  ])));
        });
