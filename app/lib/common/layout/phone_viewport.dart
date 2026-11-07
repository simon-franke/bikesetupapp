import 'package:flutter/material.dart';
import '../theme/theme_data.dart';

const double kPhoneMaxWidth = 480;

/// Constrains the entire navigator, including sheets and pushed routes.
class PhoneViewport extends StatelessWidget {
  const PhoneViewport({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
      color: context.palette.bg,
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(0.0, kPhoneMaxWidth);
        final media = MediaQuery.of(context);
        return Center(
          child: SizedBox(
            width: width,
            height: constraints.maxHeight,
            child: MediaQuery(
              data: media.copyWith(size: Size(width, constraints.maxHeight)),
              child: ClipRect(child: child),
            ),
          ),
        );
      }));
}
