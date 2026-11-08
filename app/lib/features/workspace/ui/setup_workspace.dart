import 'package:bikesetupapp/common/ui/app_haptics.dart';
import 'package:bikesetupapp/features/setups/ui/add_category_sheet.dart';
import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:bikesetupapp/common/ui/delete_confirmation_sheet.dart';
import 'package:bikesetupapp/features/setups/ui/field_meta.dart';
import 'package:bikesetupapp/common/ui/app_scroll_edge.dart';
import 'package:bikesetupapp/features/setups/models/setup_configuration.dart';
import 'package:flutter/cupertino.dart';
import 'package:bikesetupapp/features/setups/ui/setup_category_view.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import 'package:bikesetupapp/app/app_dependencies.dart';
import 'package:bikesetupapp/app/routing/app_routes.dart';
import 'package:bikesetupapp/features/setups/ui/setup_overview.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SetupWorkspace extends StatefulWidget {
  const SetupWorkspace(
      {super.key,
      required this.user,
      required this.bike,
      required this.setup,
      required this.configuration,
      required this.navigatorKey,
      required this.reloadConfiguration});

  final User user;
  final String bike, setup;
  final SetupConfiguration configuration;
  final GlobalKey<NavigatorState> navigatorKey;
  final Future<SetupConfiguration?> Function() reloadConfiguration;

  @override
  State<SetupWorkspace> createState() => _SetupWorkspaceState();
}

class _SetupWorkspaceState extends State<SetupWorkspace> {
  late Future<SetupConfiguration?> _configurationFuture;

  @override
  Widget build(BuildContext context) => SetupOverview(
        user: widget.user,
        bike: widget.bike,
        setup: widget.setup,
        configuration: widget.configuration,
        onAddCategory: () => _addCategory(widget.configuration),
        onCategory: (category) => _openCategory(category, widget.configuration),
      );

  Future<bool> _changeCategory(String category, bool enabled,
      {String? suspensionType}) async {
    final saved = await presentCommand(
        context,
        () => AppDependencies.of(context)
                .forUser(widget.user.uid)
                .setups
                .setCategoryEnabled(
              widget.bike,
              widget.setup,
              category,
              enabled,
              suspensionType: suspensionType,
              addedFields: {
                ...kDefaultFieldKeys,
                if (suspensionType != null)
                  category: suspensionFields(
                      suspensionType, ['Rebound', 'Compression']),
              },
            ));
    if (saved && mounted) {
      _configurationFuture = widget.reloadConfiguration();
    }

    return saved;
  }

  Future<void> _addCategory(SetupConfiguration configuration) async {
    final active = configuration.fields.keys.toSet();
    final category = await showAddCategorySheet(context, active,
        retained: configuration.disabledCategories);
    if (category == null || !mounted) return;

    String? suspensionType;
    if ((category == 'Fork' || category == 'Shock') &&
        !configuration.storedFields.containsKey(category)) {
      suspensionType = await showSuspensionTypeSheet(context, category);
      if (suspensionType == null || !mounted) return;
    }

    if (await _changeCategory(category, true, suspensionType: suspensionType) &&
        mounted) {
      final configuration = await _configurationFuture;
      if (mounted && configuration != null) {
        _openCategory(category, configuration);
      }
    }
  }

  Future<void> _categoryOptions(
      BuildContext routeContext, String category) async {
    final action = await showAppOptionsSheet(
      context: routeContext,
      title: categoryLabel(category),
      entries: const [
        AppSheetOption(
            value: 'remove',
            label: 'Remove category',
            icon: CupertinoIcons.trash,
            destructive: true)
      ],
    );
    if (action != 'remove' || !routeContext.mounted) return;

    final confirmed = await showDeleteConfirmationSheet(
      routeContext,
      title: 'Remove ${categoryLabel(category)}?',
      message: 'Saved settings are kept if you add it again.',
      actionLabel: 'Remove',
    );
    if (!confirmed || !mounted || !routeContext.mounted) return;

    if (await _changeCategory(category, false) && routeContext.mounted) {
      Navigator.of(routeContext).pop();
    }
  }

  void _openCategory(String category, SetupConfiguration configuration) {
    widget.navigatorKey.currentState!.push(AppRoutes.fadeSlide(Builder(
        builder: (routeContext) => Scaffold(
              extendBody: true,
              appBar: buildDetailAppBar(routeContext,
                  title: categoryLabel(category),
                  actions: [
                    IconButton(
                      tooltip: 'Category options',
                      icon: const Icon(CupertinoIcons.ellipsis),
                      onPressed: AppHaptics.wrap(
                          () => _categoryOptions(routeContext, category)),
                    )
                  ]),
              body: AppScrollEdge(
                  child: SetupCategoryView(
                      user: widget.user,
                      bike: widget.bike,
                      setup: widget.setup,
                      category: category,
                      configuration: configuration)),
            ))));
  }
}
