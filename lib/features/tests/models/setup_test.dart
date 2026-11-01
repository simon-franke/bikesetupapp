import '../../setups/models/unit_system.dart';

typedef SetupValues = Map<String, Map<String, String>>;

SetupValues readValues(Map data) => data.map((key, value) => MapEntry(
    key.toString(),
    (value as Map).map((k, v) => MapEntry(k.toString(), v.toString()))));

bool sameSettingValue(String? a, String? b) {
  if (a == b) return true;
  if (a == null || b == null || a.isEmpty || b.isEmpty) return false;
  final x = SettingValue.parse(a), y = SettingValue.parse(b);
  if (x.number == null || y.number == null) return false;
  if (x.unit != null && y.unit != null && x.family != y.family) return false;
  return (x.number! * (x.unit?.toCanonical ?? 1) -
              y.number! * (y.unit?.toCanonical ?? 1))
          .abs() <
      0.00001;
}

enum TestStage { draft, ride, review, finished }

class RideFeedback {
  static const feelings = [
    'Much worse',
    'Worse',
    'Same',
    'Better',
    'Much better'
  ];
  const RideFeedback({this.feeling, this.note = '', this.time = ''});
  final String? feeling;
  final String note, time;

  String? get validationError {
    if (!feelings.contains(feeling)) {
      return 'Choose how the ride felt.';
    }
    if (time.trim().isNotEmpty &&
        !RegExp(r'^\d{1,3}:[0-5]\d(?:\.\d{3})?$').hasMatch(time.trim())) {
      return 'Use mm:ss or mm:ss.SSS, e.g. 03:42.156.';
    }
    return null;
  }

  RideFeedback get trimmed =>
      RideFeedback(feeling: feeling, note: note.trim(), time: time.trim());

  Map<String, String> toMap() => {
        if (feeling != null) 'feeling': feeling!,
        'note': note,
        'time': time,
      };

  factory RideFeedback.fromMap(Map data) => RideFeedback(
      feeling: data['feeling'] as String?,
      note: data['note'] as String? ?? '',
      time: data['time'] as String? ?? '');
}

class TestChange {
  const TestChange(this.category, this.field, this.before, this.after);
  final String category, field, before, after;
}

class SetupTest {
  SetupTest(
      {required this.id,
      required this.name,
      required this.before,
      required this.values,
      required this.setupInformation,
      this.fieldMetadata = const {},
      this.stage = TestStage.draft,
      this.draftStep = 0,
      this.rides = const [],
      this.result = '',
      this.feedback = const RideFeedback()});
  final String id, name, result;
  final TestStage stage;
  final int draftStep;
  final SetupValues before, values;
  final Map<String, String> setupInformation;
  final SetupValues fieldMetadata;
  final List<RideFeedback> rides;
  final RideFeedback feedback;
  List<TestChange> get changes => [
        for (final category in values.entries)
          for (final field in category.value.entries)
            if (!sameSettingValue(
                before[category.key]?[field.key], field.value))
              TestChange(category.key, field.key,
                  before[category.key]?[field.key] ?? '--', field.value)
      ];
  SetupTest copyWith(
          {String? name,
          int? draftStep,
          SetupValues? values,
          TestStage? stage,
          List<RideFeedback>? rides,
          String? result,
          RideFeedback? feedback}) =>
      SetupTest(
          id: id,
          name: name ?? this.name,
          draftStep: draftStep ?? this.draftStep,
          before: before,
          setupInformation: setupInformation,
          fieldMetadata: fieldMetadata,
          values: values ?? this.values,
          stage: stage ?? this.stage,
          rides: rides ?? this.rides,
          result: result ?? this.result,
          feedback: feedback ?? this.feedback);
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'before': before,
        'setupInformation': setupInformation,
        'fieldMetadata': fieldMetadata,
        'values': values,
        'stage': stage.name,
        'draftStep': draftStep,
        'rides': rides.map((ride) => ride.toMap()).toList(),
        'feedback': feedback.toMap(),
        'result': result
      };
  factory SetupTest.fromMap(Map data) => SetupTest(
      id: data['id'] as String,
      name: data['name'] as String,
      before: readValues(data['before'] as Map),
      setupInformation:
          Map<String, String>.from(data['setupInformation'] as Map),
      fieldMetadata: readValues(data['fieldMetadata'] as Map),
      values: readValues(data['values'] as Map),
      stage: TestStage.values.byName(data['stage'] as String),
      draftStep: (data['draftStep'] as num).toInt(),
      rides: (data['rides'] as List)
          .map((r) => RideFeedback.fromMap(r as Map))
          .toList(),
      feedback: RideFeedback.fromMap(data['feedback'] as Map? ?? {}),
      result: data['result'] as String? ?? '');
}
