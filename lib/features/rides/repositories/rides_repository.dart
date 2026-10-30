import '../models/ride.dart';

abstract interface class RidesRepository {
  Stream<List<Ride>> watch(String bikeId);

  /// Returns the count inserted; existing IDs are never overwritten or reassigned.
  Future<int> insert(List<Ride> rides);
  Future<void> remove(String id);
}
