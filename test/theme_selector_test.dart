import 'package:bikesetupapp/common/theme/theme_data.dart';
import 'package:bikesetupapp/features/settings/ui/theme_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
void main() {
  testWidgets('appearance previews select every mode at narrow width and large text', (tester) async {
    var selected = ThemeMode.system;
    await tester.pumpWidget(MaterialApp(theme:ThemeData(extensions:const [AppPalette.light]),
      home: Scaffold(body:MediaQuery(data: MediaQueryData(textScaler:TextScaler.linear(2)),
        child:SizedBox(width:280,child:StatefulBuilder(builder:(context,setState)=>ThemeSelector(
          selected:selected,onChanged:(mode)=>setState(()=>selected=mode))))))));
    for(final label in ['Dark','Light','System']) {
      await tester.tap(find.text(label)); await tester.pumpAndSettle();
      expect(selected.name,label.toLowerCase());
      expect(tester.takeException(),isNull);
    }
  });
}
