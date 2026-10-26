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
  // Legacy values have no suffix and use the field's default unit.
  if (x.unit != null && y.unit != null && x.family != y.family) return false;
  return (x.number! * (x.unit?.toCanonical ?? 1) -
              y.number! * (y.unit?.toCanonical ?? 1))
          .abs() <
      0.00001;
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
      this.stage = 'draft',
      this.rides = const [],
      this.result = '',
      this.feedback = const {}});
  final String id, name, stage, result;
  final SetupValues before, values;
  final List<Map<String, String>> rides;
  final Map<String, String> feedback;
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
          SetupValues? values,
          String? stage,
          List<Map<String, String>>? rides,
          String? result,
          Map<String, String>? feedback}) =>
      SetupTest(
          id: id,
          name: name ?? this.name,
          before: before,
          values: values ?? this.values,
          stage: stage ?? this.stage,
          rides: rides ?? this.rides,
          result: result ?? this.result,
          feedback: feedback ?? this.feedback);
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'before': before,
        'values': values,
        'stage': stage,
        'rides': rides,
        'feedback': feedback,
        'result': result
      };
  factory SetupTest.fromMap(Map data) => SetupTest(
      id: data['id'] as String,
      name: data['name'] as String,
      before: readValues(data['before'] as Map),
      values: readValues(data['values'] as Map),
      stage: data['stage'] as String,
      rides: (data['rides'] as List)
          .map((r) => Map<String, String>.from(r as Map))
          .toList(),
      feedback: Map<String, String>.from(data['feedback'] as Map? ?? {}),
      result: data['result'] as String? ?? '');
}
