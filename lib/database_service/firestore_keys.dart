abstract class FirestoreKeys {
  // Collections
  static const String userBikeSetup = 'UserBikeSetup';
  static const String bikes = 'Bikes';
  static const String setupList = 'SetupList';
  static const String todoList = 'ToDoList';
  static const String myList = 'MyList';

  // User document fields
  static const String defaultBike = 'default_bike';

  // Bike document fields
  static const String bikeName = 'bike_name';
  static const String bikeType = 'bike_type';
  static const String defaultSetup = 'defaultSetup';

  // Setup document fields
  static const String setupName = 'setup_name';

  // Todo document fields
  static const String taskName = 'task_name';
  static const String taskDescription = 'task_description';
  static const String part = 'Part';
  static const String done = 'done';
  static const String created = 'created';

  // Service tracking collections
  static const String serviceComponents = 'ServiceComponents';
  static const String serviceEntries = 'ServiceEntries';
  static const String stravaBikes = 'StravaBikes';

  // ServiceComponent fields
  static const String bikeId = 'bike_id';
  static const String componentType = 'component_type';
  static const String componentName = 'component_name';
  static const String serviceIntervalKm = 'service_interval_km';
  static const String createdAt = 'created_at';

  // ServiceEntry fields
  static const String componentId = 'component_id';
  static const String mileageAtServiceKm = 'mileage_at_service_km';
  static const String serviceDate = 'service_date';
  static const String serviceNote = 'service_note';

  // StravaBike fields
  static const String stravaGearId = 'strava_gear_id';
  static const String stravaBikeName = 'strava_bike_name';
  static const String distanceMeters = 'distance_meters';
  static const String linkedBikeId = 'linked_bike_id';

  // Mileage offset field (on bike document)
  static const String mileageOffsetKm = 'mileage_offset_km';
}
