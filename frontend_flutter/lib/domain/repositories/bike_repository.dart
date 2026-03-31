import '../../core/error/result.dart';
import '../entities/bike_profile.dart';

/// Abstract contract for bike profile persistence.
abstract interface class BikeRepository {
  Future<Result<List<BikeProfile>>> getBikes();
  Future<Result<BikeProfile>> createBike(BikeProfile bike);
  Future<Result<BikeProfile>> updateBike(String slug, BikeProfile bike);
  Future<Result<void>> deleteBike(String slug);
  Future<Result<BikeProfile>> getBike(String slug);
}
