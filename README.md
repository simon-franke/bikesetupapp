# bikesetupapp
#### Description:
> Flutter App to Store Bike Setup Information in Google Firestore Database with Google SignIn
## Features
* Setup information linked to Google account (alternative: Anonymous SignIn)
* Multiple bikes (set default bike in settings (bike that opens))
* Multiple setups per bike
* Store basic setup information and see it in bike information popup
* Page to easily create new bikes/setups and set basic settings such as wheel size, travel, shock/fork type
* Quickly and easily change and view frequently used settings
* Settings are divided into 5 categories (rear tyre, front tyre, shock, fork, general/frame)
* Easily change categories
* Unlimited number of settings in each category
* Todo list to keep track of things that need fixing on your bike
* Settings page to log out your account, change theme and set default bike

## Implemention details
### database_service
Contains everything that has to do with writing and retrieving data from Firebase and authenticating the user.

### app_services
contains themeinformation and the appstate notifier that handles the changing of themes

### alert_dialogs
contains all Alert Dialogs

### app_pages
contains every page of the app

### bike_enums
contains the enums biketype, category, new_bike_mode used throughout the application

### widgets
contains widgets, that complement the pages and alert dialogs

## Description


Upon launching the application, it verifies whether the user is logged in and if their default bike exists. If either of these conditions is not met, the user is redirected to the login page.  If both conditions are met, the user is directed to the HomePage. 
The settings are displayed on this page using a StreamBuilder, which enables immediate display upon availability, as opposed to a FutureBuilder. The HomePage enables users to modify, delete, and add settings. The user can easily switch between categories by clicking the bubbles. General information about their setup can be accessed via the 'i' button on the top right.
The NavDrawer allows for bike and setup modification, deletion, and creation. Each bike has its own to-do list for tracking necessary repairs.
The settings page enables users to log in or out of the app, change the theme, and set their default bike.

## Firebase

Each user has their own document that they can reference using their user ID. This document contains collections for Bikes, TodoLists, and UserData. The UserData collection contains two documents: one stores the user's default bike and the other stores a list of the user's bikes with their corresponding bike types.
