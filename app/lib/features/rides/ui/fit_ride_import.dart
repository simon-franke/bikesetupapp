import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_selector/file_selector.dart';
import 'package:bikesetupapp/common/ui/app_sheet.dart';
import 'package:bikesetupapp/common/ui/command_feedback.dart';
import '../controllers/rides_controller.dart';
import '../models/fit_activity_decoder.dart';
import 'fit_import_preview.dart';

Future<String?> importFitRides(BuildContext context,
    {required RidesController controller,
    required String bikeId,
    required String bikeName}) async {
  try {
    final file = await openFile(acceptedTypeGroups: const [
      XTypeGroup(
          label: 'FIT activities',
          extensions: ['fit'],
          uniformTypeIdentifiers: ['public.data'])
    ]);
    if (file == null || !context.mounted) return null;

    if (await file.length() > FitActivityDecoder.maxBytes) {
      throw const FormatException('Choose a FIT file smaller than 20 MB.');
    }

    final rides =
        await compute(FitActivityDecoder.decode, await file.readAsBytes());
    if (!context.mounted) return null;

    final confirmed = await showAppSheet<bool>(
        context: context,
        builder: (ctx) => FitImportPreview(bikeName: bikeName, rides: rides));
    if (confirmed != true || !context.mounted) return null;

    var inserted = 0;
    final saved = await presentCommand(context, () async {
      final result =
          await controller.save(rides.map((r) => r.forBike(bikeId)).toList());
      if (result.isSuccess) inserted = result.requireValue();
      return result;
    });
    return saved
        ? '$inserted rides imported. ${rides.length - inserted} duplicates skipped.'
        : null;
  } on FormatException catch (e) {
    return e.message;
  } catch (e, stack) {
    FlutterError.reportError(FlutterErrorDetails(exception: e, stack: stack));
    return 'Could not read this file. Choose a valid activity FIT file and try again.';
  }
}
