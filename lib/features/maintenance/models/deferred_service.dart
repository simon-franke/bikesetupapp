/// A synthetic service baseline that makes the next service due after [extendKm].
double deferredServiceMileage(
        {required double currentMileageKm,
        required int extendKm,
        required int serviceIntervalKm}) =>
    (currentMileageKm + extendKm - serviceIntervalKm)
        .clamp(0.0, double.infinity);
