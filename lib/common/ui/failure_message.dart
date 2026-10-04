import '../models/command_result.dart';

String failureMessage(AppFailure failure) => switch (failure.code) {
      FailureCode.permissionDenied =>
        'You do not have permission to make this change.',
      FailureCode.unavailable => 'Check your connection and try again.',
      FailureCode.saveFailed => 'Could not save your changes. Try again.',
      FailureCode.loadFailed => 'Could not load data. Try again.',
      FailureCode.authenticationFailed => 'Could not sign in. Try again.',
      FailureCode.invalidCredentials =>
        'Check your email and password and try again.',
      FailureCode.emailInUse => 'An account with this email already exists.',
      FailureCode.weakPassword => 'Choose a stronger password.',
      FailureCode.invalidInput => 'Check the entered values and try again.',
      FailureCode.connectionExpired =>
        'Strava connection could not be renewed. Reconnect Strava in Settings.',
      FailureCode.noStravaBikes =>
        'No bikes found in Strava. Add a bike under My Gear in Strava.',
      FailureCode.missingProfileScope =>
        'Strava did not provide bike data. Reconnect Strava and grant permission to read your full profile.',
      FailureCode.insufficientActivityScope =>
        'Reconnect Strava in Settings and grant access to all activities to fetch historical mileage.',
      FailureCode.stravaInactive =>
        'Strava has disabled this API application. Its owner must check their Strava subscription and reactivate the app at strava.com/settings/api.',
      FailureCode.stravaDenied =>
        'Strava denied access. Check the API application status and granted permissions.',
      FailureCode.rateLimited =>
        'Strava’s request limit has been reached. Try again later.',
      FailureCode.network =>
        'Could not reach Strava. Check your connection and try again.',
      FailureCode.invalidResponse =>
        'Could not read Strava’s data. Try again later.',
      FailureCode.stravaError =>
        'Strava returned an error (${failure.statusCode ?? 'unknown'}). Try again later.',
    };
