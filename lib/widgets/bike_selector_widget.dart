import 'package:bikesetupapp/bike_enums/bike_type.dart';
import 'package:flutter/material.dart';

class BikeSelectorWidget extends StatelessWidget {
  final BikeType bikeType;
  const BikeSelectorWidget({super.key, required this.bikeType});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
          height: MediaQuery.of(context).size.height * 0.22,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Hero(
            tag: 'bike-image-${bikeType.path}',
            child: Image.asset(
              bikeType.path,
              fit: BoxFit.contain,
            ),
          )),
    );
  }
}
