import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:material_ui/material_ui.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: buildDetailAppBar(context, title: 'Privacy policy'));
}
