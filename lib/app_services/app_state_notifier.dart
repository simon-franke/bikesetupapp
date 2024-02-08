import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppStateNotifier extends ChangeNotifier {
  late bool isDarkModeOn;

  AppStateNotifier(this.isDarkModeOn);

  void updateTheme(bool isDarkModeOn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkModeOn', isDarkModeOn);
    this.isDarkModeOn = isDarkModeOn;
    notifyListeners();
  }
}
