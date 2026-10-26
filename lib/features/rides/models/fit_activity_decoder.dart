import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'ride.dart';

/// Reads the standard FIT session summaries, never inferring active time from
/// elapsed time or counting lap summaries a second time. Unknown fields/messages
/// (including developer fields) are skipped using their definition sizes.
class FitActivityDecoder {
  static const maxBytes = 20 * 1024 * 1024;
  static List<Ride> decode(Uint8List bytes) {
    Never invalid(String message) => throw FormatException(message);
    if (bytes.length < 14 || bytes.length > maxBytes) {
      invalid('Choose a FIT file smaller than 20 MB.');
    }
    final data = ByteData.sublistView(bytes);
    final headerSize = bytes[0];
    if ((headerSize != 12 && headerSize != 14) ||
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) != '.FIT') {
      invalid('This is not a supported FIT file.');
    }
    if (bytes[1] >> 4 > 2) invalid('Unsupported FIT protocol version.');
    final end = headerSize + data.getUint32(4, Endian.little);
    if (end + 2 != bytes.length) {
      invalid('The FIT file is truncated or contains extra data.');
    }
    if (headerSize == 14 &&
        data.getUint16(12, Endian.little) != 0 &&
        crc(bytes, 0, 12) != data.getUint16(12, Endian.little)) {
      invalid('The FIT header is damaged.');
    }
    if (crc(bytes, 0, end) != data.getUint16(end, Endian.little)) {
      invalid('The FIT file checksum is invalid.');
    }
    var position = headerSize;
    void need(int count) {
      if (count < 0 || position + count > end) {
        invalid('The FIT file is truncated.');
      }
    }

    final definitions = <int, _Definition>{};
    final sessions = <Ride>[];
    var activityFile = false;
    while (position < end) {
      final header = bytes[position++];
      final compressed = header & 0x80 != 0;
      final local = compressed ? (header >> 5) & 3 : header & 15;
      if (!compressed && header & 0x40 != 0) {
        need(5);
        position++; // reserved
        final architecture = bytes[position++];
        if (architecture > 1) invalid('Invalid FIT byte order.');
        final endian = architecture == 0 ? Endian.little : Endian.big;
        final global = data.getUint16(position, endian);
        position += 2;
        final count = bytes[position++];
        need(count * 3);
        final fields = <_Field>[];
        for (var i = 0; i < count; i++) {
          fields.add(_Field(
              bytes[position], bytes[position + 1], bytes[position + 2] & 31));
          position += 3;
        }
        var developerSize = 0;
        if (header & 0x20 != 0) {
          need(1);
          final count = bytes[position++];
          need(count * 3);
          for (var i = 0; i < count; i++) {
            developerSize += bytes[position + 1];
            position += 3;
          }
        }
        definitions[local] = _Definition(global, endian, fields, developerSize);
      } else {
        final definition = definitions[local];
        if (definition == null) invalid('Missing FIT message definition.');
        final values = <int, int>{};
        for (final field in definition.fields) {
          // Compressed headers replace the timestamp field's bytes.
          if (compressed && field.number == 253) continue;
          need(field.size);
          int? value;
          if (field.size == 1 && [0, 2].contains(field.type)) {
            value = bytes[position];
            if (value == 255) value = null;
          } else if (field.size == 4 && field.type == 6) {
            value = data.getUint32(position, definition.endian);
            if (value == 0xffffffff) value = null;
          }
          if (value != null) values[field.number] = value;
          position += field.size;
        }
        need(definition.developerSize);
        position += definition.developerSize;
        if (definition.global == 0) activityFile = values[0] == 4;
        if (definition.global == 18 && values[5] == 2) {
          final start = values[2], timer = values[8];
          if (start == null || timer == null || timer <= 0) {
            invalid(
                'A cycling session is missing its start time or active timer duration.');
          }
          final elapsed = values[7];
          if (elapsed != null && timer > elapsed + 1000) {
            invalid('The cycling duration is inconsistent.');
          }
          final date = DateTime.fromMillisecondsSinceEpoch(
              (start + 631065600) * 1000,
              isUtc: true);
          if (date
              .isAfter(DateTime.now().toUtc())) {
            invalid('The ride date is in the future.');
          }
          // Semantic identity also catches a renamed/re-exported copy of a session.
          final id =
              'fit_${sha256.convert(utf8.encode('$start:$timer:cycling'))}';
          sessions.add(Ride(
              id: id,
              bikeId: '',
              startedAt: date,
              durationSeconds: (timer / 1000).round(),
              source: 'fit',
              name: 'Imported ride',
              indoor: [6, 58].contains(values[6])));
        }
      }
    }
    if (!activityFile) {
      invalid('Import an activity FIT file, not a course or workout.');
    }
    if (sessions.isEmpty) {
      invalid('No cycling sessions were found in this FIT file.');
    }
    if (sessions.length > 100) { invalid('Import at most 100 cycling sessions at once.'); }
    return {for (final ride in sessions) ride.id: ride}.values.toList();
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
