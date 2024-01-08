import 'package:bikesetupapp/Services/database.dart';
import 'package:bikesetupapp/Widgets/progressindicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Bubble extends StatefulWidget {
  final User? user;
  final double left;
  final double bottom;
  final String bikename;
  final String category;
  final String chosencategory;
  final String setup;
  final VoidCallback? onPressed;
  final Function(String) onValueChange;
  final bool show;
  const Bubble(
      {super.key,
      required this.user,
      required this.left,
      required this.bottom,
      required this.bikename,
      required this.category,
      required this.chosencategory,
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
    if (!widget.show) {
      return const SizedBox.shrink();
    }
    return Positioned(
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
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 3,
                      blurRadius: 5,
                      offset: const Offset(0, 2))
                ],
                shape: BoxShape.circle,
                color: (widget.chosencategory == widget.category)
                    ? Theme.of(context).cardTheme.color
                    : Theme.of(context).cardColor),
            height: 50,
            width: 50,
            child: Center(
              child: StreamBuilder(
                  stream: DatabaseService('${widget.user?.uid}')
                      .getDocumentElement(
                          widget.bikename, widget.category, widget.setup),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (ConnectionState.waiting == snapshot.connectionState) {
                      return PulsatingCircle(
                          color: Theme.of(context).cardColor, size: 50);
                    } else if (snapshot.hasError) {
                      return const Center(child: Text('Error'));
                    } else if (snapshot.hasData &&
                        snapshot.data.toString() != "") {
                      try {
                        final element = snapshot.data?['Pressure'];

                        if (element != null &&
                            element is String &&
                            element != "") {
                          return GestureDetector(
                            onLongPress: () {
                              widget.onValueChange(element);
                            },
                            child: Text(
                              element.toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        } else {
                          return const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 30,
                          );
                        }
                      } catch (e) {
                        return const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 30,
                        );
                      }
                    } else {
                      return const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 30,
                      );
                    }
                  }),
            )),
      ),
    );
  }
}
