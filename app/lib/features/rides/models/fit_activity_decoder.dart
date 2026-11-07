import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'ride.dart';

// FIT protocol message, field and enum identifiers used by this decoder.
const _fileIdMessage = 0, _sessionMessage = 18;
const _fileTypeField = 0, _activityFileType = 4;
const _startTimeField = 2, _sportField = 5, _subSportField = 6;
const _elapsedTimeField = 7, _timerTimeField = 8, _timestampField = 253;
const _cyclingSport = 2, _indoorCycling = 6, _virtualActivity = 58;
const _enumType = 0, _uint8Type = 2, _uint32Type = 6;
const _fitEpochSeconds = 631065600;
const _compressedHeader = 0x80,
    _definitionHeader = 0x40,
    _developerHeader = 0x20;

Never _invalid(String message) => throw FormatException(message);

/// Reads session summaries without counting laps or elapsed time as active time.
/// Unknown messages and developer fields are skipped using definition sizes.
class FitActivityDecoder {
  static const maxBytes = 20 * 1024 * 1024;

  static List<Ride> decode(Uint8List bytes) {
    final reader = _validatedReader(bytes);
    final definitions = <int, _Definition>{};
    final sessions = <Ride>[];
    var activityFile = false;
    while (!reader.isAtEnd) {
      final header = reader.readByte();
      final compressed = header & _compressedHeader != 0;
      final local = compressed ? (header >> 5) & 3 : header & 15;
      if (!compressed && header & _definitionHeader != 0) {
        definitions[local] = _readDefinition(reader, header);
        continue;
      }
      final definition = definitions[local];
      if (definition == null) _invalid('Missing FIT message definition.');
      final values = _readFields(reader, definition, compressed: compressed);
      if (definition.global == _fileIdMessage) {
        activityFile = values[_fileTypeField] == _activityFileType;
      }
      if (definition.global == _sessionMessage &&
          values[_sportField] == _cyclingSport) {
        sessions.add(_decodeCyclingSession(values));
      }
    }
    if (!activityFile) {
      _invalid('Import an activity FIT file, not a course or workout.');
    }
    if (sessions.isEmpty) {
      _invalid('No cycling sessions were found in this FIT file.');
    }
    if (sessions.length > 100) {
      _invalid('Import at most 100 cycling sessions at once.');
    }
    return {for (final ride in sessions) ride.id: ride}.values.toList();
  }

  static _FitReader _validatedReader(Uint8List bytes) {
    if (bytes.length < 14 || bytes.length > maxBytes) {
      _invalid('Choose a FIT file smaller than 20 MB.');
    }
    final data = ByteData.sublistView(bytes);
    final headerSize = bytes[0];
    if ((headerSize != 12 && headerSize != 14) ||
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) != '.FIT') {
      _invalid('This is not a supported FIT file.');
    }
    if (bytes[1] >> 4 > 2) _invalid('Unsupported FIT protocol version.');
    final end = headerSize + data.getUint32(4, Endian.little);
    if (end + 2 != bytes.length) {
      _invalid('The FIT file is truncated or contains extra data.');
    }
    if (headerSize == 14 &&
        data.getUint16(12, Endian.little) != 0 &&
        crc(bytes, 0, 12) != data.getUint16(12, Endian.little)) {
      _invalid('The FIT header is damaged.');
    }
    if (crc(bytes, 0, end) != data.getUint16(end, Endian.little)) {
      _invalid('The FIT file checksum is invalid.');
    }
    return _FitReader(bytes, headerSize, end);
  }

  static _Definition _readDefinition(_FitReader reader, int header) {
    reader.skip(1); // Reserved byte.
    final architecture = reader.readByte();
    if (architecture > 1) _invalid('Invalid FIT byte order.');
    final endian = architecture == 0 ? Endian.little : Endian.big;
    final global = reader.readUint16(endian);
    final count = reader.readByte();
    final fields = <_Field>[];
    for (var i = 0; i < count; i++) {
      fields.add(
          _Field(reader.readByte(), reader.readByte(), reader.readByte() & 31));
    }
    var developerSize = 0;
    if (header & _developerHeader != 0) {
      final count = reader.readByte();
      for (var i = 0; i < count; i++) {
        reader.skip(1); // Field number.
        developerSize += reader.readByte();
        reader.skip(1); // Developer data index.
      }
    }
    return _Definition(global, endian, fields, developerSize);
  }

  static Map<int, int> _readFields(_FitReader reader, _Definition definition,
      {required bool compressed}) {
    final values = <int, int>{};
    for (final field in definition.fields) {
      // Compressed headers replace the timestamp field's bytes.
      if (compressed && field.number == _timestampField) continue;
      int? value;
      if (field.size == 1 &&
          (field.type == _enumType || field.type == _uint8Type)) {
        value = reader.readByte();
        if (value == 0xff) value = null;
      } else if (field.size == 4 && field.type == _uint32Type) {
        value = reader.readUint32(definition.endian);
        if (value == 0xffffffff) value = null;
      } else {
        reader.skip(field.size);
      }
      if (value != null) values[field.number] = value;
    }
    reader.skip(definition.developerSize);
    return values;
  }

  static Ride _decodeCyclingSession(Map<int, int> values) {
    final start = values[_startTimeField], timer = values[_timerTimeField];
    if (start == null || timer == null || timer <= 0) {
      _invalid(
          'A cycling session is missing its start time or active timer duration.');
    }
    final elapsed = values[_elapsedTimeField];
    if (elapsed != null && timer > elapsed + 1000) {
      _invalid('The cycling duration is inconsistent.');
    }
    final date = DateTime.fromMillisecondsSinceEpoch(
        (start + _fitEpochSeconds) * 1000,
        isUtc: true);
    if (date.isAfter(DateTime.now().toUtc())) {
      _invalid('The ride date is in the future.');
    }
    // Semantic identity also catches renamed/re-exported copies of a session.
    final id = 'fit_${sha256.convert(utf8.encode('$start:$timer:cycling'))}';
    return Ride(
        id: id,
        bikeId: '',
        startedAt: date,
        durationSeconds: (timer / 1000).round(),
        source: 'fit',
        name: 'Imported ride',
        indoor: const [_indoorCycling, _virtualActivity]
            .contains(values[_subSportField]));
  }

  static int crc(Uint8List bytes, int start, int end) {
    var crc = 0;
    for (var i = start; i < end; i++) {
      crc ^= bytes[i];
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc & 1 != 0) ? (crc >> 1) ^ 0xa001 : crc >> 1;
      }
    }
    return crc;
  }
}

/// Bounds checks apply to every read and skip within the declared data section.
class _FitReader {
  _FitReader(Uint8List bytes, this._position, this._end)
      : _data = ByteData.sublistView(bytes);
  final ByteData _data;
  final int _end;
  int _position;
  bool get isAtEnd => _position == _end;

  int _take(int count) {
    if (count < 0 || _position + count > _end) {
      _invalid('The FIT file is truncated.');
    }
    final start = _position;
    _position += count;
    return start;
  }

  int readByte() => _data.getUint8(_take(1));
  int readUint16(Endian endian) => _data.getUint16(_take(2), endian);
  int readUint32(Endian endian) => _data.getUint32(_take(4), endian);
  void skip(int count) {
    _take(count);
  }
}

class _Field {
  const _Field(this.number, this.size, this.type);
  final int number, size, type;
}

class _Definition {
  const _Definition(this.global, this.endian, this.fields, this.developerSize);
  final int global, developerSize;
  final Endian endian;
  final List<_Field> fields;
}
