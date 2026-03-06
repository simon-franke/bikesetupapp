import 'package:bikesetupapp/database_service/database.dart';
import 'package:bikesetupapp/widgets/field_meta.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class _CardDef {
  final String key;
  final String unit;
  final IconData icon;
  const _CardDef(this.key, this.unit, this.icon);

  factory _CardDef.fromKey(String key) {
    final meta = kFieldMeta[key] ?? kDefaultFieldMeta;
    return _CardDef(key, meta.unit, meta.icon);
  }
}

class ControlPanelGrid extends StatefulWidget {
  final User user;
  final String uBikeID;
  final String category;
  final String uSetupID;
  final double topPadding;

  const ControlPanelGrid({
    super.key,
    required this.user,
    required this.uBikeID,
    required this.category,
    required this.uSetupID,
    this.topPadding = 0,
  });

  @override
  State<ControlPanelGrid> createState() => _ControlPanelGridState();
}

class _ControlPanelGridState extends State<ControlPanelGrid> {

  void _showStepperSheet(
      BuildContext context, _CardDef card, String currentValue, bool isDefault) {
    final int initial = int.tryParse(currentValue) ?? 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        int value = initial;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 32,
                right: 32,
                top: 28,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx)
                          .textTheme
                          .labelSmall
                          ?.color
                          ?.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(card.icon,
                          size: 18,
                          color: Theme.of(ctx)
                              .iconTheme
                              .color
                              ?.withValues(alpha: 0.6)),
                      const SizedBox(width: 8),
                      Text(
                        card.key.toUpperCase(),
                        style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.5,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StepButton(
                        icon: Icons.remove_rounded,
                        onTap: () => setSheetState(
                            () => value = (value - 1).clamp(0, 999)),
                      ),
                      Column(
                        children: [
                          Text(
                            '$value',
                            style: Theme.of(ctx).textTheme.displayMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card.unit,
                            style: Theme.of(ctx).textTheme.labelSmall,
                          ),
                        ],
                      ),
                      _StepButton(
                        icon: Icons.add_rounded,
                        onTap: () => setSheetState(
                            () => value = (value + 1).clamp(0, 999)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(ctx)
                            .floatingActionButtonTheme
                            .backgroundColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        DatabaseService(widget.user.uid).setSetting(
                          card.key,
                          '$value',
                          widget.uBikeID,
                          widget.category,
                          widget.uSetupID,
                        );
                      },
                      child: Text(
                        'Save',
                        style: Theme.of(ctx).textTheme.labelLarge,
                      ),
                    ),
                  ),
                  if (!isDefault) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        DatabaseService(widget.user.uid).deleteSetting(
                          card.key,
                          widget.uBikeID,
                          widget.category,
                          widget.uSetupID,
                        );
                      },
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: DatabaseService(widget.user.uid)
          .getSettings(widget.uBikeID, widget.category, widget.uSetupID),
      builder: (context, snapshot) {
        Map<String, dynamic> settings = {};
        if (snapshot.hasData && snapshot.data?.data() != null) {
          settings = snapshot.data!.data() as Map<String, dynamic>;
        }

        final defaults = kDefaultFieldKeys[widget.category] ?? [];
        final extras =
            settings.keys.where((k) => !defaults.contains(k)).toList();
        final allKeys = [
          ...defaults.where((k) => settings.containsKey(k)),
          ...extras,
        ];

        return GridView.builder(
          padding:
              EdgeInsets.fromLTRB(12, widget.topPadding + 12, 12, 12),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: allKeys.length,
          itemBuilder: (context, index) {
            final key = allKeys[index];
            final card = _CardDef.fromKey(key);
            final value = settings[key]?.toString() ?? '--';
            final isDefault = isRequiredField(widget.category, key);
            return _ControlCard(
              config: card,
              value: value,
              onTap: () =>
                  _showStepperSheet(context, card, value, isDefault),
            );
          },
        );
      },
    );
  }
}

class _ControlCard extends StatelessWidget {
  final _CardDef config;
  final String value;
  final VoidCallback onTap;

  const _ControlCard({
    required this.config,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      config.key.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.2,
                            fontSize: 10,
                          ),
                    ),
                  ),
                  Icon(
                    config.icon,
                    size: 16,
                    color: Theme.of(context)
                        .iconTheme
                        .color
                        ?.withValues(alpha: 0.5),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  config.unit,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context)
              .floatingActionButtonTheme
              .backgroundColor
              ?.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 30),
      ),
    );
  }
}
