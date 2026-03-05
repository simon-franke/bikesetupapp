import 'package:bikesetupapp/widgets/progress_indicator.dart';
import 'package:bikesetupapp/bike_enums/category.dart';
import 'package:bikesetupapp/database_service/database.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class Bubble extends StatefulWidget {
  final User user;
  final double left;
  final double bottom;
  final String bikeName;
  final Category category;
  final Category chosenCategory;
  final String setup;
  final VoidCallback? onPressed;
  final Function(String) onValueChange;
  final bool show;
  const Bubble(
      {super.key,
      required this.user,
      required this.left,
      required this.bottom,
      required this.bikeName,
      required this.category,
      required this.chosenCategory,
      required this.setup,
      required this.onPressed,
      required this.onValueChange,
      required this.show});

  @override
  State<Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<Bubble> {
  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: widget.show,
      child: Positioned(
        left: widget.left,
        bottom: widget.bottom,
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(0),
            fixedSize: const Size(50, 50),
            shape: const CircleBorder(),
          ),
          child: Container(
              decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        spreadRadius: 3,
                        blurRadius: 5,
                        offset: const Offset(0, 2))
                  ],
                  shape: BoxShape.circle,
                  color: (widget.chosenCategory == widget.category)
                      ? Theme.of(context).cardTheme.color
                      : Theme.of(context).cardColor),
              height: 50,
              width: 50,
              child: Center(
                child: StreamBuilder(
                    stream: DatabaseService(widget.user.uid).getDocumentElement(
                        widget.bikeName,
                        widget.category.category,
                        widget.setup),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (ConnectionState.waiting == snapshot.connectionState) {
                        return PulsatingCircle(
                            color: Theme.of(context).cardColor, size: 50);
                      }
                      if (snapshot.hasError ||
                          snapshot.data == null ||
                          !snapshot.hasData ||
                          snapshot.data.toString().isEmpty) {
                        return const Icon(
                          Icons.error,
                          color: Colors.white,
                          size: 30,
                        );
                      }
                      if (widget.category == Category.generalSettings) {
                        return GestureDetector(
                            onLongPress: () {
                              HapticFeedback.mediumImpact();
                              widget.onValueChange("");
                            },
                            child: const Icon(
                              Icons.settings,
                              color: Colors.white,
                              size: 30,
                            ));
                      }
                      final String element;
                      try {
                        element = snapshot.data?['Pressure'];
                      } catch (e) {
                        return const Icon(
                          Icons.error,
                          color: Colors.white,
                          size: 30,
                        );
                      }
                      if (element.isEmpty) {
                        return const Icon(
                          Icons.error,
                          color: Colors.white,
                          size: 30,
                        );
                      }
                      return GestureDetector(
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          widget.onValueChange(element);
                        },
                        child: Text(
                          element.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }),
              )),
        ),
      ),
    );
  }
}
