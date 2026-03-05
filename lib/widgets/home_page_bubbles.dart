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

class _BubbleState extends State<Bubble> with TickerProviderStateMixin {
  late AnimationController _tapController;
  late AnimationController _selectController;
  late Animation<double> _tapScale;
  late Animation<double> _selectScale;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _selectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _tapScale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
    _selectScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _selectController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(Bubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chosenCategory != oldWidget.chosenCategory &&
        widget.chosenCategory == widget.category) {
      _selectController.forward(from: 0).then((_) {
        if (mounted) _selectController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _tapController.dispose();
    _selectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: widget.show,
      child: Positioned(
        left: widget.left,
        bottom: widget.bottom,
        child: ScaleTransition(
          scale: _selectScale,
          child: ScaleTransition(
            scale: _tapScale,
            child: ElevatedButton(
              onPressed: () {
                _tapController.forward(from: 0).then((_) {
                  if (mounted) _tapController.reverse();
                });
                widget.onPressed?.call();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(0),
                fixedSize: const Size(50, 50),
                shape: const CircleBorder(),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
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
                      stream: DatabaseService(widget.user.uid)
                          .getDocumentElement(widget.bikeName,
                              widget.category.category, widget.setup),
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        if (ConnectionState.waiting ==
                            snapshot.connectionState) {
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
