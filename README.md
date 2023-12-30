# bikesetupapp
> Flutter App to Store Bike Setup Information in Google Firestore Database with Google SignIn
## Features
* Setup Information is linked to Google Account (alternative: Anonymus SignIn)
* Multiple Bikes (App opens with the last opened bike)
* Page to easily create new Bikes and set basic settings like wheelsize, travel, shock/fork type
* Quick and easy changing and viewing of frequently used settings
* Settings are categorised by 5 categories (Rear Tire, Front Tire, Shock, Fork, General/Frame)
* easily change categories
* "Unlimited" number of settings in each category
* Settings Page to log out your account and change the theme

## Implemention details
### DatabaseService
Class with every method that acceses the Database

### ThemeData
Contains information about light and dark Theme

### AuthService
handles authentication with Firestore Database

### AlertDialogs
contains all Alert Dialogs

### Bubbles
This widget takes two methods as Parameters, which are implemented in the widget's parent widget but called within the widget itself. This allows the methods to change variables of the parent widget. The 'onValueChanged' function passes a string from its StreamBuilder to the parent Widget.

## Description

When the application is launched, it checks if the user is logged in and if their default bike exists. If either of these conditions is not met, the user is redirected to the login page.  If both conditions are met, the user is directed to the HomePage. 
The settings are displayed on this page using a StreamBuilder, which allows for immediate display upon availability, as opposed to a FutureBuilder. The HomePage allows users to modify, delete, and add settings. 
The NavDrawer provides access to bike modification, editing, and creation. 
The settings page enables users to log in or out of the app and change the theme.

## Screenshots
<img src="https://github.com/SimonFran/bikesetupapp/assets/40801103/aedfd251-af2b-4139-95f1-0301e571d4d3" alt="drawing" width="200"/>
<img src="https://github.com/SimonFran/bikesetupapp/assets/40801103/93cf4c54-6876-4c50-b7bb-99b460a82b4a)" alt="drawing" width="200"/>
<img src="https://github.com/SimonFran/bikesetupapp/assets/40801103/330b1e93-f7e5-4bba-87b5-69158183cced" alt="drawing" width="200"/>
<img src="https://github.com/SimonFran/bikesetupapp/assets/40801103/6ca8094c-138b-46de-a058-75ac4d906c8c" alt="drawing" width="200"/>
