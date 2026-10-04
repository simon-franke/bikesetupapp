import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature boundaries keep persistence and UI implementations separate',
      () {
    for (final file in Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final source = file.readAsStringSync();
      if (file.path.contains('/ui/') ||
          file.path.contains('/controllers/') ||
          file.path.contains('/models/')) {
        expect(source, isNot(contains('package:cloud_firestore/')),
            reason: file.path);
        expect(source, isNot(contains('FirebaseFirestore.instance')),
            reason: file.path);
      }
      if (file.path.contains('/ui/')) {
        expect(source, isNot(matches(r"import .*repositories/")),
            reason: file.path);
        expect(source, isNot(contains('FirebaseAuth.instance')),
            reason: file.path);
      }
      if (file.path.contains('/controllers/')) {
        expect(
            source,
            isNot(matches(
                r"import .*repositories/(firestore_|firebase_|platform_|shared_preferences_)")),
            reason: file.path);
        expect(source, isNot(contains('ScaffoldMessenger')), reason: file.path);
        expect(source, isNot(contains('BuildContext')), reason: file.path);
      }
      if (file.path.contains('/models/')) {
        expect(
            source, isNot(matches(r"import .*[/](controllers|repositories)/")),
            reason: file.path);
        expect(source, isNot(contains('package:flutter/')), reason: file.path);
      }
      if (file.path.contains('/controllers/') ||
          file.path.contains('/repositories/') ||
          file.path.contains('/models/')) {
        expect(source, isNot(matches(r"import .*[/]ui/")), reason: file.path);
      }
    }
  });
}
