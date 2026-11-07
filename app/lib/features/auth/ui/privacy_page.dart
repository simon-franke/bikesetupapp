import 'package:bikesetupapp/common/ui/app_components.dart';
import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: buildDetailAppBar(context, title: 'Privacy policy'));
}
