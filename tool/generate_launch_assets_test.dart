// Run with: flutter test tool/generate_launch_assets_test.dart
// The launch artwork uses the same font and top-cap asset as the app.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('render Clickwise launch artwork', (tester) async {
    final cap = (await tester.runAsync(() async {
      final font = FontLoader('Sora');
      font.addFont(Future.value(ByteData.sublistView(
        File('assets/fonts/Sora.ttf').readAsBytesSync(),
      )));
      await font.load();
      final codec = await ui.instantiateImageCodec(File(
        'ios/Runner/AppIcon.icon/Assets/top-cap.png',
      ).readAsBytesSync());
      final image = (await codec.getNextFrame()).image;
      codec.dispose();
      return image;
    }))!;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final previewKey = GlobalKey();
    final key = GlobalKey();
    await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
            key: previewKey,
            child: ColoredBox(
              color: const Color(0xFF0D2035),
              child: Center(
                child: RepaintBoundary(
                  key: key,
                  child: SizedBox(
                    width: 240,
                    height: 192,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RawImage(image: cap, width: 136, height: 136),
                        const SizedBox(height: 12),
                        const Text('Clickwise',
                            style: TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEDF5FC),
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ))));
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      for (final scale in [1, 2, 3]) {
        final image = await boundary.toImage(pixelRatio: scale.toDouble());
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
        final suffix = scale == 1 ? '' : '@${scale}x';
        File('ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage$suffix.png')
            .writeAsBytesSync(bytes);
        if (scale == 3) {
          final dir = Directory('android/app/src/main/res/drawable-xxhdpi')
            ..createSync(recursive: true);
          File('${dir.path}/launch_image.png').writeAsBytesSync(bytes);
        }
        image.dispose();
      }
    });
    await tester.runAsync(() async {
      final preview = await (previewKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary)
          .toImage();
      final data = await preview.toByteData(format: ui.ImageByteFormat.png);
      Directory('assets/app-icon/previews').createSync(recursive: true);
      File('assets/app-icon/previews/ClickwiseLaunch.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
      preview.dispose();
    });
    cap.dispose();
  });
}
