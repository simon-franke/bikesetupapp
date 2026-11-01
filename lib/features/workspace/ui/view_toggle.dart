import 'package:bikesetupapp/common/ui/app_haptics.dart';
import 'package:bikesetupapp/common/ui/app_glass_surface.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bikesetupapp/common/theme/theme_data.dart';
import '../models/active_view.dart';
export '../models/active_view.dart';

/// Standard Flutter tabs on the package's glass surface. Selection, focus,
/// keyboard interaction and semantics remain owned by TabBar.
class ViewToggle extends StatefulWidget {
  const ViewToggle(
      {super.key,
      required this.activeView,
      required this.onChanged,
      this.showServiceAlert = false});
  final ActiveView activeView;
  final ValueChanged<ActiveView> onChanged;
  final bool showServiceAlert;
  @override
  State<ViewToggle> createState() => _ViewToggleState();
}

class _ViewToggleState extends State<ViewToggle> with TickerProviderStateMixin {
  TabController? _controller;
  bool _reducedMotion = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (_controller == null || reduced != _reducedMotion) {
      _controller?.dispose();
      _reducedMotion = reduced;
      _controller = TabController(
          length: ActiveView.values.length,
          vsync: this,
          initialIndex: widget.activeView.index,
          animationDuration:
              reduced ? Duration.zero : const Duration(milliseconds: 220));
    }
  }

  @override
  void didUpdateWidget(ViewToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller!.index != widget.activeView.index) {
      _controller!.animateTo(widget.activeView.index);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bottom =
        (MediaQuery.viewPaddingOf(context).bottom - 12).clamp(8.0, 24.0);
    return Padding(
        key: const ValueKey('navigation-inset'),
        padding: EdgeInsets.fromLTRB(20, 8, 20, bottom),
        child: AppGlassSurface(
            child: TabBar(
                controller: _controller,
                onTap: (index) {
                  if (index != widget.activeView.index) AppHaptics.selection();
                  widget.onChanged(ActiveView.values[index]);
                },
                dividerColor: Colors.transparent,
                labelColor: p.accentText,
                unselectedLabelColor: p.inkMuted,
                labelStyle: AppTextStyles.caption,
                unselectedLabelStyle: AppTextStyles.caption,
                labelPadding: EdgeInsets.zero,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                    color: p.accentText.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(25)),
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.pressed)
                        ? Colors.transparent
                        : null),
                tabs: [
              const Tab(
                  height: 64,
                  iconMargin: EdgeInsets.only(bottom: 5),
                  icon: Icon(CupertinoIcons.slider_horizontal_3,
                      size: AppIconSizes.navigation),
                  text: 'Setup'),
              const Tab(
                  height: 64,
                  iconMargin: EdgeInsets.only(bottom: 5),
                  icon: Icon(CupertinoIcons.lab_flask,
                      size: AppIconSizes.navigation),
                  text: 'Experiments'),
              Tab(
                  height: 64,
                  iconMargin: const EdgeInsets.only(bottom: 5),
                  icon: const Icon(CupertinoIcons.wrench,
                      size: AppIconSizes.navigation),
                  child: Text('Service',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      semanticsLabel: widget.showServiceAlert
                          ? 'Service, maintenance due'
                          : 'Service')),
            ])));
  }
}
