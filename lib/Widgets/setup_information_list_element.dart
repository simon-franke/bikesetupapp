import 'package:flutter/material.dart';

class SetupInformationListElement extends StatelessWidget {
  final String name;
  final String value;
  final bool visible;
  const SetupInformationListElement(
      {super.key,
      required this.name,
      required this.value,
      required this.visible});

  @override
  Widget build(BuildContext context) {
    return Visibility(
        visible: visible,
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(value, style: Theme.of(context).textTheme.titleMedium)
            ],
          ),
        ));
  }
}
